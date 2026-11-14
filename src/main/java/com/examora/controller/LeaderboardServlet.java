package com.examora.controller;

import com.examora.dao.SettingsDAO;
import com.examora.dao.UserDAO;
import com.examora.model.User;
import jakarta.servlet.ServletException;
import jakarta.servlet.annotation.WebServlet;
import jakarta.servlet.http.HttpServlet;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;
import jakarta.servlet.http.HttpSession;
import org.apache.commons.csv.CSVFormat;
import org.apache.commons.csv.CSVParser;
import org.apache.commons.csv.CSVRecord;

import java.io.IOException;
import java.io.InputStreamReader;
import java.io.Reader;
import java.net.URL;
import java.net.URLConnection;
import java.nio.charset.StandardCharsets;
import java.util.ArrayList;
import java.util.Date;
import java.util.HashMap;
import java.util.LinkedHashMap;
import java.util.List;
import java.util.Map;
import java.util.TreeSet;

/**
 * LeaderboardServlet - Fetches CSV data from a Google Sheets export URL
 * (configurable via admin settings) and displays it as a ranking table.
 * Results are cached for 5 minutes to avoid hammering Google on every request.
 *
 * Each row is enriched with a "_tag" entry (matched from Examora users by
 * email then by name) so the view can filter participants per tag.
 */
@WebServlet("/LeaderboardServlet")
public class LeaderboardServlet extends HttpServlet {
    private SettingsDAO settingsDAO;
    private UserDAO userDAO;

    // In-memory cache (servlet is singleton, single instance per app)
    private static volatile List<Map<String, String>> cachedRows = null;
    private static volatile List<String> cachedHeaders = null;
    private static volatile long cacheTime = 0;
    private static final long CACHE_TTL = 5 * 60 * 1000; // 5 minutes

    private static final String DEFAULT_CSV_URL =
            "https://docs.google.com/spreadsheets/d/1hnEJS2rQFudsxc0QWAdcPtzDE7I2ZI3mz0OYHSxmoLQ/export?format=csv&gid=278631504";

    @Override
    public void init() throws ServletException {
        settingsDAO = new SettingsDAO();
        userDAO = new UserDAO();
    }

    @Override
    protected void doGet(HttpServletRequest request, HttpServletResponse response)
            throws ServletException, IOException {
        HttpSession session = request.getSession();
        User user = (User) session.getAttribute("user");
        if (user == null) {
            response.sendRedirect("LoginServlet");
            return;
        }

        boolean isAdmin = "admin".equals(user.getRole());
        request.setAttribute("isAdmin", isAdmin);

        // Publish gate: peserta cannot access an unpublished leaderboard.
        // Admins always get through (preview mode) so they can verify data
        // before making it visible.
        boolean published = settingsDAO.isLeaderboardPublished();
        getServletContext().setAttribute("leaderboardPublished", published);
        if (!published && !isAdmin) {
            request.setAttribute("unpublished", true);
            request.getRequestDispatcher("/common/leaderboard.jsp").forward(request, response);
            return;
        }
        request.setAttribute("published", published);

        try {
            List<Map<String, String>> rows;
            List<String> headers;
            long fetchedAt;

            long now = System.currentTimeMillis();
            if (cachedRows != null && (now - cacheTime) < CACHE_TTL) {
                rows = cachedRows;
                headers = cachedHeaders;
                fetchedAt = cacheTime;
            } else {
                synchronized (this) {
                    // Double-check after acquiring lock
                    if (cachedRows != null && (System.currentTimeMillis() - cacheTime) < CACHE_TTL) {
                        rows = cachedRows;
                        headers = cachedHeaders;
                        fetchedAt = cacheTime;
                    } else {
                        String csvUrl = settingsDAO.getSetting("leaderboard_csv_url");
                        if (csvUrl == null || csvUrl.trim().isEmpty()) {
                            csvUrl = DEFAULT_CSV_URL;
                        }

                        URL url = new URL(csvUrl.trim());
                        URLConnection conn = url.openConnection();
                        conn.setConnectTimeout(10000);
                        conn.setReadTimeout(15000);
                        conn.setRequestProperty("User-Agent", "Examora/1.0");

                        CSVFormat format = CSVFormat.DEFAULT.builder()
                                .setHeader()
                                .setSkipHeaderRecord(true)
                                .setTrim(true)
                                .build();

                        try (Reader reader = new InputStreamReader(conn.getInputStream(), StandardCharsets.UTF_8);
                             CSVParser parser = format.parse(reader)) {

                            headers = new ArrayList<>(parser.getHeaderNames());
                            rows = new ArrayList<>();
                            for (CSVRecord record : parser) {
                                Map<String, String> row = new LinkedHashMap<>();
                                for (String h : headers) {
                                    row.put(h, record.isSet(h) ? record.get(h) : "");
                                }
                                rows.add(row);
                            }
                        }

                        // Enrich each row with the participant's tag (matched from
                        // Examora users by email, falling back to normalized name).
                        attachTags(rows, headers);

                        cachedRows = rows;
                        cachedHeaders = headers;
                        cacheTime = System.currentTimeMillis();
                        fetchedAt = cacheTime;
                    }
                }
            }

            // --- Tag filter -------------------------------------------------
            // The active filter comes from ?tag=. If the request omits it, fall
            // back to the admin-configured default tag (so an admin can lock the
            // board to a single tag by default).
            String tagFilter = request.getParameter("tag");
            String defaultTag = settingsDAO.getSetting("leaderboard_default_tag");
            boolean hasExplicitFilter = tagFilter != null && !tagFilter.isEmpty();
            boolean filterFromDefault = false;
            if (!hasExplicitFilter && defaultTag != null && !defaultTag.isEmpty()
                    && !"all".equalsIgnoreCase(defaultTag)) {
                tagFilter = defaultTag;
                filterFromDefault = true;
            }
            if (tagFilter == null) tagFilter = "";

            final String fTag = tagFilter;
            List<Map<String, String>> displayRows = rows;
            if ("unmatched".equalsIgnoreCase(fTag)) {
                // Special pseudo-tag: rows that didn't match any Examora user.
                displayRows = new ArrayList<>();
                for (Map<String, String> row : rows) {
                    String t = row.get("_tag");
                    if (t == null || t.isEmpty()) displayRows.add(row);
                }
            } else if (!fTag.isEmpty() && !"all".equalsIgnoreCase(fTag)) {
                displayRows = new ArrayList<>();
                for (Map<String, String> row : rows) {
                    if (fTag.equals(row.get("_tag"))) {
                        displayRows.add(row);
                    }
                }
            }

            // Distinct tags present in the data, sorted, for the filter bar.
            TreeSet<String> tags = new TreeSet<>();
            int unmatchedCount = 0;
            for (Map<String, String> row : rows) {
                String t = row.get("_tag");
                if (t != null && !t.isEmpty()) {
                    tags.add(t);
                } else {
                    unmatchedCount++;
                }
            }

            request.setAttribute("rows", displayRows);
            request.setAttribute("totalRows", rows.size());
            request.setAttribute("unmatchedCount", unmatchedCount);
            request.setAttribute("headers", headers);
            request.setAttribute("fetchedAt", new Date(fetchedAt));
            request.setAttribute("cacheTtlMin", (int) (CACHE_TTL / 60000));
            request.setAttribute("tags", new ArrayList<>(tags));
            request.setAttribute("tagFilter", tagFilter);
            request.setAttribute("filterFromDefault", filterFromDefault);
            request.setAttribute("defaultTag", defaultTag == null ? "" : defaultTag);
            request.getRequestDispatcher("/common/leaderboard.jsp").forward(request, response);

        } catch (Exception e) {
            e.printStackTrace();
            request.setAttribute("error", "Gagal memuat data leaderboard: " + e.getMessage());
            request.getRequestDispatcher("/common/leaderboard.jsp").forward(request, response);
        }
    }

    /**
     * Attach a "_tag" entry to each row by matching the row's email/name against
     * Examora peserta users. Email match wins; otherwise a normalized full-name
     * match is used. Rows with no match get an empty "_tag".
     */
    private void attachTags(List<Map<String, String>> rows, List<String> headers) {
        String nameCol = null, emailCol = null;
        for (String h : headers) {
            String hl = h.toLowerCase().trim();
            if (emailCol == null && (hl.equals("email") || hl.contains("email"))) emailCol = h;
            else if (nameCol == null && (hl.contains("nama") || hl.contains("name"))) nameCol = h;
        }
        if (nameCol == null && !headers.isEmpty()) nameCol = headers.get(0);

        Map<String, String> emailToTag = new HashMap<>();
        Map<String, String> nameToTag = new HashMap<>();
        try {
            List<User> peserta = userDAO.findByRole("peserta");
            for (User u : peserta) {
                if (u.getEmail() != null && !u.getEmail().isEmpty()) {
                    emailToTag.put(u.getEmail().trim().toLowerCase(), u.getTag());
                }
                String n = normalizeName(u.getName());
                if (!n.isEmpty()) {
                    nameToTag.put(n, u.getTag());
                }
            }
        } catch (Exception e) {
            e.printStackTrace();
        }

        for (Map<String, String> row : rows) {
            String tag = "";
            String email = emailCol != null ? row.get(emailCol) : null;
            if (email != null && !email.isEmpty()) {
                tag = emailToTag.get(email.trim().toLowerCase());
            }
            if ((tag == null || tag.isEmpty()) && nameCol != null) {
                String nm = normalizeName(row.get(nameCol));
                if (!nm.isEmpty()) {
                    tag = nameToTag.get(nm);
                }
            }
            row.put("_tag", tag == null ? "" : tag);
        }
    }

    /**
     * Normalize a name for matching: lowercase, strip zero-width / control
     * characters and punctuation, collapse whitespace.
     */
    private static String normalizeName(String s) {
        if (s == null) return "";
        return s.toLowerCase()
                .replaceAll("[\\u200b-\\u200f\\u2028\\u2029\\ufeff]", "")
                .replaceAll("[^a-z0-9 ]", " ")
                .replaceAll("\\s+", " ")
                .trim();
    }

    /**
     * Allow admin to force-clear the in-memory cache (called when settings are
     * updated) so new data is pulled on the next request.
     */
    public static void clearCache() {
        synchronized (LeaderboardServlet.class) {
            cachedRows = null;
            cachedHeaders = null;
            cacheTime = 0;
        }
    }
}

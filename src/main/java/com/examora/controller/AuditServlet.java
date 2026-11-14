package com.examora.controller;

import com.examora.model.AuditLog;
import com.examora.model.User;
import com.examora.service.AuditService;

import jakarta.servlet.ServletException;
import jakarta.servlet.annotation.WebServlet;
import jakarta.servlet.http.HttpServlet;
import jakarta.servlet.http.HttpServlet;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;

import java.io.IOException;
import java.time.LocalDateTime;
import java.time.format.DateTimeFormatter;
import java.time.format.DateTimeParseException;
import java.util.HashMap;
import java.util.List;
import java.util.Map;

/**
 * AuditServlet - Handles audit log viewing
 */
@WebServlet("/AuditServlet")
public class AuditServlet extends HttpServlet {
    private AuditService auditService;
    private static final int PAGE_SIZE = 50;

    @Override
    public void init() throws ServletException {
        auditService = new AuditService();
    }

    @Override
    protected void doGet(HttpServletRequest request, HttpServletResponse response)
            throws ServletException, IOException {
        String action = request.getParameter("action");

        try {
            if ("detail".equals(action)) {
                showDetail(request, response);
            } else if ("cleanup".equals(action)) {
                cleanupLogs(request, response);
            } else if ("export".equals(action)) {
                exportLogs(request, response);
            } else {
                listLogs(request, response);
            }
        } catch (AuditService.ServiceException e) {
            request.setAttribute("error", e.getMessage());
            try {
                listLogs(request, response);
            } catch (AuditService.ServiceException ex) {
                throw new ServletException(ex);
            }
        }
    }

    @Override
    protected void doPost(HttpServletRequest request, HttpServletResponse response)
            throws ServletException, IOException {
        String action = request.getParameter("action");

        try {
            if ("deleteAll".equals(action)) {
                deleteAllLogs(request, response);
            } else {
                response.sendRedirect(request.getContextPath() + "/AuditServlet");
            }
        } catch (AuditService.ServiceException e) {
            request.setAttribute("error", e.getMessage());
            try {
                listLogs(request, response);
            } catch (AuditService.ServiceException ex) {
                throw new ServletException(ex);
            }
        }
    }

    private void listLogs(HttpServletRequest request, HttpServletResponse response)
            throws ServletException, IOException, AuditService.ServiceException {
        // Get filter parameters
        String actionType = request.getParameter("actionType");
        String entityType = request.getParameter("entityType");
        String status = request.getParameter("status");
        String startDateStr = request.getParameter("startDate");
        String endDateStr = request.getParameter("endDate");
        String pageStr = request.getParameter("page");

        int page = 1;
        if (pageStr != null && !pageStr.isEmpty()) {
            try {
                page = Integer.parseInt(pageStr);
                if (page < 1) page = 1;
            } catch (NumberFormatException e) {
                page = 1;
            }
        }

        LocalDateTime startDate = parseDateTime(startDateStr);
        LocalDateTime endDate = parseDateTime(endDateStr);

        // Get filtered logs
        List<AuditLog> logs = auditService.getFilteredLogs(actionType, entityType, status,
                startDate, endDate, page, PAGE_SIZE);
        int totalCount = auditService.countFilteredLogs(actionType, entityType, status,
                startDate, endDate);
        int totalPages = (int) Math.ceil((double) totalCount / PAGE_SIZE);

        request.setAttribute("logs", logs);
        request.setAttribute("currentPage", page);
        request.setAttribute("totalPages", totalPages);
        request.setAttribute("totalCount", totalCount);
        request.setAttribute("actionType", actionType);
        request.setAttribute("entityType", entityType);
        request.setAttribute("status", status);
        request.setAttribute("startDate", startDateStr);
        request.setAttribute("endDate", endDateStr);

        // Get statistics
        Map<String, Integer> stats = getStats();
        request.setAttribute("stats", stats);

        request.getRequestDispatcher("/admin/audit-log.jsp").forward(request, response);
    }

    private void showDetail(HttpServletRequest request, HttpServletResponse response)
            throws ServletException, IOException, AuditService.ServiceException {
        String idStr = request.getParameter("id");
        if (idStr == null || idStr.isEmpty()) {
            response.sendRedirect(request.getContextPath() + "/AuditServlet");
            return;
        }

        Integer id = Integer.parseInt(idStr);
        AuditLog log = auditService.getAllLogs(1, 1000).stream()
                .filter(l -> l.getId().equals(id))
                .findFirst()
                .orElse(null);

        if (log == null) {
            request.setAttribute("error", "Log tidak ditemukan");
            response.sendRedirect(request.getContextPath() + "/AuditServlet");
            return;
        }

        request.setAttribute("log", log);
        request.getRequestDispatcher("/admin/audit-log-detail.jsp").forward(request, response);
    }

    private void cleanupLogs(HttpServletRequest request, HttpServletResponse response)
            throws ServletException, IOException, AuditService.ServiceException {
        String daysStr = request.getParameter("days");
        int days = 90; // Default: keep logs for 90 days

        if (daysStr != null && !daysStr.isEmpty()) {
            try {
                days = Integer.parseInt(daysStr);
            } catch (NumberFormatException e) {
                days = 90;
            }
        }

        int deleted = auditService.cleanupOldLogs(days);
        request.setAttribute("success", deleted + " log lama berhasil dihapus");
        response.sendRedirect(request.getContextPath() + "/AuditServlet");
    }

    private LocalDateTime parseDateTime(String dateStr) {
        if (dateStr == null || dateStr.trim().isEmpty()) {
            return null;
        }

        try {
            return LocalDateTime.parse(dateStr + "T00:00:00");
        } catch (DateTimeParseException e) {
            try {
                return LocalDateTime.parse(dateStr, DateTimeFormatter.ISO_LOCAL_DATE_TIME);
            } catch (DateTimeParseException e2) {
                return null;
            }
        }
    }

    private Map<String, Integer> getStats() {
        Map<String, Integer> stats = new HashMap<>();
        try {
            stats.put("create", auditService.countByAction("CREATE"));
            stats.put("update", auditService.countByAction("UPDATE"));
            stats.put("delete", auditService.countByAction("DELETE"));
            stats.put("login", auditService.countByAction("LOGIN"));
        } catch (Exception e) {
            // Ignore errors
        }
        return stats;
    }

    /**
     * Export logs to CSV format
     */
    private void exportLogs(HttpServletRequest request, HttpServletResponse response)
            throws ServletException, IOException, AuditService.ServiceException {

        String actionType = request.getParameter("actionType");
        String entityType = request.getParameter("entityType");
        String status = request.getParameter("status");

        // Get all logs matching filters (no pagination for export)
        List<AuditLog> logs = auditService.getFilteredLogs(actionType, entityType, status,
                null, null, 1, 10000);

        // Set response headers for CSV download
        response.setContentType("text/csv");
        response.setCharacterEncoding("UTF-8");
        response.setHeader("Content-Disposition", "attachment; filename=\"audit_log_export_" +
            java.time.LocalDate.now().format(java.time.format.DateTimeFormatter.ofPattern("yyyyMMdd")) + ".csv\"");

        DateTimeFormatter dtf = DateTimeFormatter.ofPattern("dd MMM yyyy HH:mm:ss")
            .withZone(java.time.ZoneId.of("Asia/Jakarta"));

        try (java.io.PrintWriter out = response.getWriter()) {
            // CSV Header
            out.println("No,Aksi,Entitas,Referensi,Pengguna,IP Address,Status,Waktu,User Agent,Detail");

            // CSV Data
            int no = 1;
            for (AuditLog log : logs) {
                StringBuilder sb = new StringBuilder();
                sb.append(no++).append(",");
                sb.append("\"").append(escapeCsv(log.getActionType())).append("\",");
                sb.append("\"").append(escapeCsv(log.getEntityType())).append("\",");
                sb.append("\"").append(escapeCsv(log.getEntityName())).append("\",");
                sb.append("\"").append(escapeCsv(log.getUserName())).append("\",");
                sb.append("\"").append(escapeCsv(log.getIpAddress())).append("\",");
                sb.append("\"").append(escapeCsv(log.getStatus())).append("\",");
                sb.append("\"").append(log.getCreatedAt() != null ?
                    log.getCreatedAt().atZone(java.time.ZoneId.systemDefault())
                        .withZoneSameInstant(java.time.ZoneId.of("Asia/Jakarta")).format(dtf) : "").append("\",");
                sb.append("\"").append(escapeCsv(log.getUserAgent())).append("\",");
                sb.append("\"").append(escapeCsv(log.getActionData())).append("\"");
                out.println(sb.toString());
            }
            out.flush();
        }
    }

    /**
     * Escape CSV special characters
     */
    private String escapeCsv(String value) {
        if (value == null) return "";
        return value.replace("\"", "\"\"");
    }

    /**
     * Delete all logs (admin only)
     */
    private void deleteAllLogs(HttpServletRequest request, HttpServletResponse response)
            throws ServletException, IOException, AuditService.ServiceException {

        User currentUser = (User) request.getSession().getAttribute("user");
        if (currentUser == null || !currentUser.isAdmin()) {
            response.sendError(HttpServletResponse.SC_FORBIDDEN, "Access denied");
            return;
        }

        // Verify CSRF token
        String sessionToken = (String) request.getSession().getAttribute("csrfToken");
        String requestToken = request.getParameter("csrfToken");
        if (sessionToken == null || requestToken == null || !sessionToken.equals(requestToken)) {
            request.setAttribute("error", "Invalid CSRF token");
            listLogs(request, response);
            return;
        }

        int deleted = auditService.deleteAllLogs();

        // Log this action
        auditService.log("DELETE", "AUDIT_LOG", null, "Deleted all audit logs (" + deleted + " entries)",
                null, currentUser, request);

        request.getSession().setAttribute("success", deleted + " log berhasil dihapus");
        response.sendRedirect(request.getContextPath() + "/AuditServlet");
    }
}

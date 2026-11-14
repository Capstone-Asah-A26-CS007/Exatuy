package com.examora.dao;

import com.examora.model.CustomPage;
import com.examora.util.DBUtil;

import java.sql.*;
import java.util.ArrayList;
import java.util.List;

/**
 * CustomPage DAO - Manages custom menu links for user dashboard
 */
public class CustomPageDAO {

    /**
     * Create new custom page
     */
    public CustomPage create(CustomPage page) throws SQLException {
        String sql = "INSERT INTO custom_pages (menu_name, menu_link, icon, is_active, sort_order, target_tag, admin_comment) " +
                "VALUES (?, ?, ?, ?, ?, ?, ?)";

        try (Connection conn = DBUtil.getConnection();
             PreparedStatement stmt = conn.prepareStatement(sql, Statement.RETURN_GENERATED_KEYS)) {

            stmt.setString(1, page.getMenuName());
            stmt.setString(2, page.getMenuLink());
            stmt.setString(3, page.getIcon());
            stmt.setBoolean(4, page.getIsActive() != null ? page.getIsActive() : true);
            stmt.setInt(5, page.getSortOrder() != null ? page.getSortOrder() : 0);
            setNullableString(stmt, 6, page.getTargetTag());
            setNullableString(stmt, 7, page.getAdminComment());

            int affectedRows = stmt.executeUpdate();
            if (affectedRows == 0) {
                throw new SQLException("Creating custom page failed");
            }

            try (ResultSet generatedKeys = stmt.getGeneratedKeys()) {
                if (generatedKeys.next()) {
                    page.setId(generatedKeys.getInt(1));
                }
            }
            return page;
        }
    }

    /**
     * Find by ID
     */
    public CustomPage findById(Integer id) throws SQLException {
        String sql = "SELECT * FROM custom_pages WHERE id = ?";

        try (Connection conn = DBUtil.getConnection();
             PreparedStatement stmt = conn.prepareStatement(sql)) {

            stmt.setInt(1, id);
            try (ResultSet rs = stmt.executeQuery()) {
                if (rs.next()) {
                    return mapResultSetToCustomPage(rs);
                }
            }
        }
        return null;
    }

    /**
     * Get all custom pages (admin view)
     */
    public List<CustomPage> findAll() throws SQLException {
        String sql = "SELECT * FROM custom_pages ORDER BY sort_order ASC, created_at DESC";

        List<CustomPage> pages = new ArrayList<>();

        try (Connection conn = DBUtil.getConnection();
             Statement stmt = conn.createStatement();
             ResultSet rs = stmt.executeQuery(sql)) {

            while (rs.next()) {
                pages.add(mapResultSetToCustomPage(rs));
            }
        }
        return pages;
    }

    /**
     * Get all active custom pages for user display
     */
    public List<CustomPage> findActive() throws SQLException {
        String sql = "SELECT * FROM custom_pages WHERE is_active = 1 ORDER BY sort_order ASC, created_at DESC";

        List<CustomPage> pages = new ArrayList<>();

        try (Connection conn = DBUtil.getConnection();
             Statement stmt = conn.createStatement();
             ResultSet rs = stmt.executeQuery(sql)) {

            while (rs.next()) {
                pages.add(mapResultSetToCustomPage(rs));
            }
        }
        return pages;
    }

    /**
     * Get active custom pages visible to a given peserta tag.
     * A page is visible when target_tag IS NULL (semua tag) OR target_tag = userTag.
     * Null/empty userTag returns all active pages (e.g. admin view).
     */
    public List<CustomPage> findActiveForTag(String userTag) throws SQLException {
        StringBuilder sql = new StringBuilder(
            "SELECT * FROM custom_pages WHERE is_active = 1 "
        );
        List<Object> params = new ArrayList<>();
        if (userTag != null && !userTag.trim().isEmpty()) {
            sql.append("AND (target_tag IS NULL OR target_tag = ?) ");
            params.add(userTag.trim());
        }
        sql.append("ORDER BY sort_order ASC, created_at DESC");

        List<CustomPage> pages = new ArrayList<>();
        try (Connection conn = DBUtil.getConnection();
             PreparedStatement stmt = conn.prepareStatement(sql.toString())) {
            for (int i = 0; i < params.size(); i++) {
                stmt.setString(i + 1, (String) params.get(i));
            }
            try (ResultSet rs = stmt.executeQuery()) {
                while (rs.next()) {
                    pages.add(mapResultSetToCustomPage(rs));
                }
            }
        }
        return pages;
    }

    /**
     * Update custom page
     */
    public boolean update(CustomPage page) throws SQLException {
        String sql = "UPDATE custom_pages SET menu_name = ?, menu_link = ?, icon = ?, " +
                "is_active = ?, sort_order = ?, target_tag = ?, admin_comment = ? WHERE id = ?";

        try (Connection conn = DBUtil.getConnection();
             PreparedStatement stmt = conn.prepareStatement(sql)) {

            stmt.setString(1, page.getMenuName());
            stmt.setString(2, page.getMenuLink());
            stmt.setString(3, page.getIcon());
            stmt.setBoolean(4, page.getIsActive());
            stmt.setInt(5, page.getSortOrder() != null ? page.getSortOrder() : 0);
            setNullableString(stmt, 6, page.getTargetTag());
            setNullableString(stmt, 7, page.getAdminComment());
            stmt.setInt(8, page.getId());

            return stmt.executeUpdate() > 0;
        }
    }

    /**
     * Delete custom page
     */
    public boolean delete(Integer id) throws SQLException {
        String sql = "DELETE FROM custom_pages WHERE id = ?";

        try (Connection conn = DBUtil.getConnection();
             PreparedStatement stmt = conn.prepareStatement(sql)) {

            stmt.setInt(1, id);
            return stmt.executeUpdate() > 0;
        }
    }

    /**
     * Toggle active status
     */
    public boolean toggleActive(Integer id) throws SQLException {
        String sql = "UPDATE custom_pages SET is_active = NOT is_active WHERE id = ?";

        try (Connection conn = DBUtil.getConnection();
             PreparedStatement stmt = conn.prepareStatement(sql)) {

            stmt.setInt(1, id);
            return stmt.executeUpdate() > 0;
        }
    }

    private CustomPage mapResultSetToCustomPage(ResultSet rs) throws SQLException {
        CustomPage page = new CustomPage();
        page.setId(rs.getInt("id"));
        page.setMenuName(rs.getString("menu_name"));
        page.setMenuLink(rs.getString("menu_link"));
        page.setIcon(rs.getString("icon"));
        page.setIsActive(rs.getBoolean("is_active"));
        page.setSortOrder(rs.getInt("sort_order"));
        page.setTargetTag(rs.getString("target_tag"));
        page.setAdminComment(rs.getString("admin_comment"));

        Timestamp created = rs.getTimestamp("created_at");
        if (created != null) {
            page.setCreatedAt(created.toLocalDateTime());
        }

        Timestamp updated = rs.getTimestamp("updated_at");
        if (updated != null) {
            page.setUpdatedAt(updated.toLocalDateTime());
        }

        return page;
    }

    /**
     * Bind a possibly-null string. Empty/whitespace-only strings are stored as
     * NULL so that "no value" is consistent with the null semantics expected by
     * findActiveForTag() and the JSP display.
     */
    private void setNullableString(PreparedStatement stmt, int index, String value) throws SQLException {
        if (value == null || value.trim().isEmpty()) {
            stmt.setNull(index, Types.VARCHAR);
        } else {
            stmt.setString(index, value.trim());
        }
    }
}

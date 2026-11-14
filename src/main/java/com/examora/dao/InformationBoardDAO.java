package com.examora.dao;

import com.examora.model.InformationBoard;
import com.examora.util.DBUtil;

import java.sql.*;
import java.util.ArrayList;
import java.util.List;

/**
 * InformationBoard DAO - Manages announcements and information for users
 */
public class InformationBoardDAO {

    private static final String COLUMNS = "ib.id, ib.title, ib.content, ib.info_type, " +
            "ib.priority, ib.target_audience, ib.is_active, ib.show_until, ib.created_by, " +
            "ib.created_at, ib.updated_at, u.name as creator_name";

    /**
     * Create new information
     */
    public InformationBoard create(InformationBoard info) throws SQLException {
        String sql = "INSERT INTO information_board (title, content, info_type, priority, " +
                "target_audience, is_active, show_until, created_by) VALUES (?, ?, ?, ?, ?, ?, ?, ?)";

        try (Connection conn = DBUtil.getConnection();
             PreparedStatement stmt = conn.prepareStatement(sql, Statement.RETURN_GENERATED_KEYS)) {

            stmt.setString(1, info.getTitle());
            stmt.setString(2, info.getContent());
            stmt.setString(3, info.getInfoType());
            stmt.setString(4, info.getPriority());
            stmt.setString(5, info.getTargetAudience());
            stmt.setBoolean(6, info.getIsActive() != null ? info.getIsActive() : true);
            if (info.getShowUntil() != null) {
                stmt.setTimestamp(7, Timestamp.valueOf(info.getShowUntil()));
            } else {
                stmt.setNull(7, Types.TIMESTAMP);
            }
            stmt.setInt(8, info.getCreatedBy());

            int affectedRows = stmt.executeUpdate();
            if (affectedRows == 0) {
                throw new SQLException("Creating information failed");
            }

            try (ResultSet generatedKeys = stmt.getGeneratedKeys()) {
                if (generatedKeys.next()) {
                    info.setId(generatedKeys.getInt(1));
                }
            }
            return info;
        }
    }

    /**
     * Find by ID
     */
    public InformationBoard findById(Integer id) throws SQLException {
        String sql = "SELECT " + COLUMNS + " FROM information_board ib " +
                "LEFT JOIN users u ON ib.created_by = u.id WHERE ib.id = ?";

        try (Connection conn = DBUtil.getConnection();
             PreparedStatement stmt = conn.prepareStatement(sql)) {

            stmt.setInt(1, id);
            try (ResultSet rs = stmt.executeQuery()) {
                if (rs.next()) {
                    return mapResultSetToInformationBoard(rs);
                }
            }
        }
        return null;
    }

    /**
     * Get all active information for target audience
     */
    public List<InformationBoard> findActiveForTarget(String targetAudience) throws SQLException {
        String sql = "SELECT " + COLUMNS + " FROM information_board ib " +
                "LEFT JOIN users u ON ib.created_by = u.id WHERE ib.is_active = 1 " +
                "AND (ib.target_audience = 'all' OR ib.target_audience = ?) " +
                "AND (ib.show_until IS NULL OR ib.show_until > NOW()) " +
                "ORDER BY ib.priority DESC, ib.created_at DESC";

        List<InformationBoard> infos = new ArrayList<>();

        try (Connection conn = DBUtil.getConnection();
             PreparedStatement stmt = conn.prepareStatement(sql)) {

            stmt.setString(1, targetAudience);
            try (ResultSet rs = stmt.executeQuery()) {
                while (rs.next()) {
                    infos.add(mapResultSetToInformationBoard(rs));
                }
            }
        }
        return infos;
    }

    /**
     * Get all information (admin view)
     */
    public List<InformationBoard> findAll() throws SQLException {
        String sql = "SELECT " + COLUMNS + " FROM information_board ib " +
                "LEFT JOIN users u ON ib.created_by = u.id ORDER BY ib.created_at DESC";

        List<InformationBoard> infos = new ArrayList<>();

        try (Connection conn = DBUtil.getConnection();
             Statement stmt = conn.createStatement();
             ResultSet rs = stmt.executeQuery(sql)) {

            while (rs.next()) {
                infos.add(mapResultSetToInformationBoard(rs));
            }
        }
        return infos;
    }

    /**
     * Update information
     */
    public boolean update(InformationBoard info) throws SQLException {
        String sql = "UPDATE information_board SET title = ?, content = ?, info_type = ?, " +
                "priority = ?, target_audience = ?, is_active = ?, show_until = ? WHERE id = ?";

        try (Connection conn = DBUtil.getConnection();
             PreparedStatement stmt = conn.prepareStatement(sql)) {

            stmt.setString(1, info.getTitle());
            stmt.setString(2, info.getContent());
            stmt.setString(3, info.getInfoType());
            stmt.setString(4, info.getPriority());
            stmt.setString(5, info.getTargetAudience());
            stmt.setBoolean(6, info.getIsActive());
            if (info.getShowUntil() != null) {
                stmt.setTimestamp(7, Timestamp.valueOf(info.getShowUntil()));
            } else {
                stmt.setNull(7, Types.TIMESTAMP);
            }
            stmt.setInt(8, info.getId());

            return stmt.executeUpdate() > 0;
        }
    }

    /**
     * Delete information
     */
    public boolean delete(Integer id) throws SQLException {
        String sql = "DELETE FROM information_board WHERE id = ?";

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
        String sql = "UPDATE information_board SET is_active = NOT is_active WHERE id = ?";

        try (Connection conn = DBUtil.getConnection();
             PreparedStatement stmt = conn.prepareStatement(sql)) {

            stmt.setInt(1, id);
            return stmt.executeUpdate() > 0;
        }
    }

    private InformationBoard mapResultSetToInformationBoard(ResultSet rs) throws SQLException {
        InformationBoard info = new InformationBoard();
        info.setId(rs.getInt("id"));
        info.setTitle(rs.getString("title"));
        info.setContent(rs.getString("content"));
        info.setInfoType(rs.getString("info_type"));
        info.setPriority(rs.getString("priority"));
        info.setTargetAudience(rs.getString("target_audience"));
        info.setIsActive(rs.getBoolean("is_active"));
        info.setCreatorName(rs.getString("creator_name"));

        Timestamp showUntil = rs.getTimestamp("show_until");
        if (showUntil != null) {
            info.setShowUntil(showUntil.toLocalDateTime());
        }

        Timestamp created = rs.getTimestamp("created_at");
        if (created != null) {
            info.setCreatedAt(created.toLocalDateTime());
        }

        Timestamp updated = rs.getTimestamp("updated_at");
        if (updated != null) {
            info.setUpdatedAt(updated.toLocalDateTime());
        }

        return info;
    }
}

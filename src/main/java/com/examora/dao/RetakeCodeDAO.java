package com.examora.dao;

import com.examora.model.RetakeCode;
import com.examora.util.DBUtil;

import java.sql.*;
import java.util.ArrayList;
import java.util.List;
import java.util.UUID;

/**
 * DAO class for retake codes
 */
public class RetakeCodeDAO {

    /**
     * Generate unique retake code
     */
    public static String generateCode() {
        return "RET-" + UUID.randomUUID().toString().substring(0, 8).toUpperCase();
    }

    /**
     * Create new retake code
     */
    public RetakeCode create(RetakeCode retakeCode) throws SQLException {
        String sql = "INSERT INTO retake_codes (quiz_id, user_id, retake_code, created_by, expires_at) " +
                     "VALUES (?, ?, ?, ?, ?)";

        try (Connection conn = DBUtil.getConnection();
             PreparedStatement stmt = conn.prepareStatement(sql, Statement.RETURN_GENERATED_KEYS)) {

            stmt.setInt(1, retakeCode.getQuizId());
            stmt.setInt(2, retakeCode.getUserId());
            stmt.setString(3, retakeCode.getRetakeCode());
            stmt.setInt(4, retakeCode.getCreatedBy());
            stmt.setTimestamp(5, retakeCode.getExpiresAt() != null ?
                Timestamp.valueOf(retakeCode.getExpiresAt()) : null);

            int rows = stmt.executeUpdate();

            if (rows > 0) {
                try (ResultSet rs = stmt.getGeneratedKeys()) {
                    if (rs.next()) {
                        retakeCode.setId(rs.getInt(1));
                    }
                }
            }
        }
        return retakeCode;
    }

    /**
     * Validate retake code
     */
    public RetakeCode validateCode(String code) throws SQLException {
        String sql = "SELECT * FROM retake_codes WHERE retake_code = ?";

        try (Connection conn = DBUtil.getConnection();
             PreparedStatement stmt = conn.prepareStatement(sql)) {

            stmt.setString(1, code);
            try (ResultSet rs = stmt.executeQuery()) {
                if (rs.next()) {
                    return mapResultSetToRetakeCode(rs);
                }
            }
        }
        return null;
    }

    /**
     * Mark code as used
     */
    public boolean markAsUsed(Integer codeId, Integer userId) throws SQLException {
        String sql = "UPDATE retake_codes SET is_used = TRUE, used_at = NOW() " +
                     "WHERE id = ? AND user_id = ? AND is_used = FALSE";

        try (Connection conn = DBUtil.getConnection();
             PreparedStatement stmt = conn.prepareStatement(sql)) {

            stmt.setInt(1, codeId);
            stmt.setInt(2, userId);
            return stmt.executeUpdate() > 0;
        }
    }

    /**
     * Get retake codes by quiz and user
     */
    public RetakeCode getByQuizAndUser(Integer quizId, Integer userId) throws SQLException {
        String sql = "SELECT * FROM retake_codes WHERE quiz_id = ? AND user_id = ? ORDER BY created_at DESC LIMIT 1";

        try (Connection conn = DBUtil.getConnection();
             PreparedStatement stmt = conn.prepareStatement(sql)) {

            stmt.setInt(1, quizId);
            stmt.setInt(2, userId);
            try (ResultSet rs = stmt.executeQuery()) {
                if (rs.next()) {
                    return mapResultSetToRetakeCode(rs);
                }
            }
        }
        return null;
    }

    /**
     * Get all retake codes for a quiz with user info
     */
    public List<RetakeCodeInfo> getByQuiz(Integer quizId) throws SQLException {
        String sql = "SELECT rc.*, u.name as user_name, u.email as user_email " +
                     "FROM retake_codes rc " +
                     "LEFT JOIN users u ON rc.user_id = u.id " +
                     "WHERE rc.quiz_id = ? " +
                     "ORDER BY rc.created_at DESC";

        List<RetakeCodeInfo> codes = new ArrayList<>();

        try (Connection conn = DBUtil.getConnection();
             PreparedStatement stmt = conn.prepareStatement(sql)) {

            stmt.setInt(1, quizId);
            try (ResultSet rs = stmt.executeQuery()) {
                while (rs.next()) {
                    RetakeCodeInfo info = new RetakeCodeInfo();
                    info.retakeCode = mapResultSetToRetakeCode(rs);
                    info.userName = rs.getString("user_name");
                    info.userEmail = rs.getString("user_email");
                    codes.add(info);
                }
            }
        }
        return codes;
    }

    /**
     * Delete retake code
     */
    public boolean delete(Integer codeId) throws SQLException {
        String sql = "DELETE FROM retake_codes WHERE id = ?";

        try (Connection conn = DBUtil.getConnection();
             PreparedStatement stmt = conn.prepareStatement(sql)) {

            stmt.setInt(1, codeId);
            return stmt.executeUpdate() > 0;
        }
    }

    /**
     * Map ResultSet to RetakeCode object
     */
    private RetakeCode mapResultSetToRetakeCode(ResultSet rs) throws SQLException {
        RetakeCode code = new RetakeCode();
        code.setId(rs.getInt("id"));
        code.setQuizId(rs.getInt("quiz_id"));
        code.setUserId(rs.getInt("user_id"));
        code.setRetakeCode(rs.getString("retake_code"));
        code.setIsUsed(rs.getBoolean("is_used"));
        code.setCreatedAt(rs.getTimestamp("created_at").toLocalDateTime());
        code.setExpiresAt(rs.getTimestamp("expires_at") != null ?
            rs.getTimestamp("expires_at").toLocalDateTime() : null);
        code.setUsedAt(rs.getTimestamp("used_at") != null ?
            rs.getTimestamp("used_at").toLocalDateTime() : null);
        code.setCreatedBy(rs.getInt("created_by"));
        return code;
    }

    /**
     * Inner class for retake code with user info
     */
    public static class RetakeCodeInfo {
        public RetakeCode retakeCode;
        public String userName;
        public String userEmail;
    }
}

package com.examora.dao;

import com.examora.model.QuizAccessCode;
import com.examora.util.DBUtil;

import java.sql.*;
import java.util.ArrayList;
import java.util.List;
import java.util.UUID;

/**
 * Quiz Access Code DAO
 */
public class QuizAccessCodeDAO {

    // Generate unique access code
    public static String generateCode() {
        return "ACCESS-" + UUID.randomUUID().toString().substring(0, 8).toUpperCase();
    }

    // Create new access code
    public QuizAccessCode create(QuizAccessCode accessCode) throws SQLException {
        String sql = "INSERT INTO quiz_access_codes (quiz_id, access_code, code_name, max_uses, expires_at, created_by) " +
                     "VALUES (?, ?, ?, ?, ?, ?)";

        try (Connection conn = DBUtil.getConnection();
             PreparedStatement stmt = conn.prepareStatement(sql, Statement.RETURN_GENERATED_KEYS)) {

            stmt.setInt(1, accessCode.getQuizId());
            stmt.setString(2, accessCode.getAccessCode());
            stmt.setString(3, accessCode.getCodeName());
            stmt.setObject(4, accessCode.getMaxUses());
            stmt.setTimestamp(5, accessCode.getExpiresAt() != null ?
                Timestamp.valueOf(accessCode.getExpiresAt()) : null);
            stmt.setInt(6, accessCode.getCreatedBy());

            int rows = stmt.executeUpdate();

            if (rows > 0) {
                try (ResultSet rs = stmt.getGeneratedKeys()) {
                    if (rs.next()) {
                        accessCode.setId(rs.getInt(1));
                    }
                }
            }
        }
        return accessCode;
    }

    // Validate access code
    public QuizAccessCode validateCode(String code) throws SQLException {
        String sql = "SELECT * FROM quiz_access_codes WHERE access_code = ?";

        try (Connection conn = DBUtil.getConnection();
             PreparedStatement stmt = conn.prepareStatement(sql)) {

            stmt.setString(1, code);
            try (ResultSet rs = stmt.executeQuery()) {
                if (rs.next()) {
                    return mapResultSetToQuizAccessCode(rs);
                }
            }
        }
        return null;
    }

    // Increment used count
    public boolean incrementUsedCount(Integer codeId) throws SQLException {
        String sql = "UPDATE quiz_access_codes SET used_count = used_count + 1 WHERE id = ?";

        try (Connection conn = DBUtil.getConnection();
             PreparedStatement stmt = conn.prepareStatement(sql)) {

            stmt.setInt(1, codeId);
            return stmt.executeUpdate() > 0;
        }
    }

    // Get access codes by quiz
    public List<QuizAccessCode> getByQuizId(Integer quizId) throws SQLException {
        String sql = "SELECT * FROM quiz_access_codes WHERE quiz_id = ? ORDER BY created_at DESC";
        List<QuizAccessCode> codes = new ArrayList<>();

        try (Connection conn = DBUtil.getConnection();
             PreparedStatement stmt = conn.prepareStatement(sql)) {

            stmt.setInt(1, quizId);
            try (ResultSet rs = stmt.executeQuery()) {
                while (rs.next()) {
                    codes.add(mapResultSetToQuizAccessCode(rs));
                }
            }
        }
        return codes;
    }

    // Get access code with quiz info
    public List<AccessCodeInfo> getAccessCodesWithQuizInfo() throws SQLException {
        String sql = "SELECT qac.*, q.title as quiz_title FROM quiz_access_codes qac " +
                     "LEFT JOIN quiz q ON qac.quiz_id = q.id " +
                     "ORDER BY qac.created_at DESC";
        List<AccessCodeInfo> codes = new ArrayList<>();

        try (Connection conn = DBUtil.getConnection();
             PreparedStatement stmt = conn.prepareStatement(sql)) {

            try (ResultSet rs = stmt.executeQuery()) {
                while (rs.next()) {
                    AccessCodeInfo info = new AccessCodeInfo();
                    info.accessCode = mapResultSetToQuizAccessCode(rs);
                    info.quizTitle = rs.getString("quiz_title");
                    codes.add(info);
                }
            }
        }
        return codes;
    }

    // Delete access code
    public boolean delete(Integer codeId) throws SQLException {
        String sql = "DELETE FROM quiz_access_codes WHERE id = ?";

        try (Connection conn = DBUtil.getConnection();
             PreparedStatement stmt = conn.prepareStatement(sql)) {

            stmt.setInt(1, codeId);
            return stmt.executeUpdate() > 0;
        }
    }

    // Update access code
    public boolean update(QuizAccessCode accessCode) throws SQLException {
        String sql = "UPDATE quiz_access_codes SET code_name = ?, max_uses = ?, " +
                     "expires_at = ?, is_active = ? WHERE id = ?";

        try (Connection conn = DBUtil.getConnection();
             PreparedStatement stmt = conn.prepareStatement(sql)) {

            stmt.setString(1, accessCode.getCodeName());
            stmt.setObject(2, accessCode.getMaxUses());
            stmt.setTimestamp(3, accessCode.getExpiresAt() != null ?
                Timestamp.valueOf(accessCode.getExpiresAt()) : null);
            stmt.setBoolean(4, accessCode.getIsActive());
            stmt.setInt(5, accessCode.getId());

            return stmt.executeUpdate() > 0;
        }
    }

    // Check if user has used access code for this quiz
    public boolean hasUserUsedCode(Integer quizId, Integer userId) throws SQLException {
        String sql = "SELECT COUNT(*) as count FROM user_quiz_access WHERE quiz_id = ? AND user_id = ?";

        try (Connection conn = DBUtil.getConnection();
             PreparedStatement stmt = conn.prepareStatement(sql)) {

            stmt.setInt(1, quizId);
            stmt.setInt(2, userId);
            try (ResultSet rs = stmt.executeQuery()) {
                if (rs.next()) {
                    return rs.getInt("count") > 0;
                }
            }
        }
        return false;
    }

    // Record that user has used access code for this quiz
    public boolean recordUserAccess(Integer quizId, Integer userId, Integer accessCodeId) throws SQLException {
        String sql = "INSERT INTO user_quiz_access (quiz_id, user_id, access_code_id, accessed_at) " +
                     "VALUES (?, ?, ?, NOW()) ON DUPLICATE KEY UPDATE access_count = access_count + 1";

        try (Connection conn = DBUtil.getConnection();
             PreparedStatement stmt = conn.prepareStatement(sql)) {

            stmt.setInt(1, quizId);
            stmt.setInt(2, userId);
            stmt.setInt(3, accessCodeId);
            return stmt.executeUpdate() > 0;
        }
    }

    private QuizAccessCode mapResultSetToQuizAccessCode(ResultSet rs) throws SQLException {
        QuizAccessCode code = new QuizAccessCode();
        code.setId(rs.getInt("id"));
        code.setQuizId(rs.getInt("quiz_id"));
        code.setAccessCode(rs.getString("access_code"));
        code.setCodeName(rs.getString("code_name"));
        code.setMaxUses((Integer) rs.getObject("max_uses"));
        code.setUsedCount(rs.getInt("used_count"));
        code.setIsActive(rs.getBoolean("is_active"));
        code.setCreatedAt(rs.getTimestamp("created_at").toLocalDateTime());
        code.setExpiresAt(rs.getTimestamp("expires_at") != null ?
            rs.getTimestamp("expires_at").toLocalDateTime() : null);
        code.setCreatedBy(rs.getInt("created_by"));
        return code;
    }

    /**
     * Inner class to hold access code info with quiz title
     */
    public static class AccessCodeInfo {
        public QuizAccessCode accessCode;
        public String quizTitle;
    }
}

package com.examora.dao;

import com.examora.model.QuizExemption;
import com.examora.util.DBUtil;

import java.sql.*;
import java.util.ArrayList;
import java.util.List;

/**
 * QuizExemption Data Access Object - Handles database operations for quiz exemptions
 */
public class QuizExemptionDAO {

    /**
     * Create a new quiz exemption
     */
    public QuizExemption create(QuizExemption exemption) throws SQLException {
        String sql = "INSERT INTO quiz_exemptions (quiz_id, user_id, exempted_by, notes) VALUES (?, ?, ?, ?)";

        try (Connection conn = DBUtil.getConnection();
             PreparedStatement stmt = conn.prepareStatement(sql, Statement.RETURN_GENERATED_KEYS)) {

            stmt.setInt(1, exemption.getQuizId());
            stmt.setInt(2, exemption.getUserId());
            stmt.setInt(3, exemption.getExemptedBy());
            stmt.setString(4, exemption.getNotes());

            int affectedRows = stmt.executeUpdate();

            if (affectedRows == 0) {
                throw new SQLException("Creating exemption failed, no rows affected.");
            }

            try (ResultSet generatedKeys = stmt.getGeneratedKeys()) {
                if (generatedKeys.next()) {
                    exemption.setId(generatedKeys.getInt(1));
                } else {
                    throw new SQLException("Creating exemption failed, no ID obtained.");
                }
            }

            return exemption;
        }
    }

    /**
     * Find exemption by ID
     */
    public QuizExemption findById(Integer id) throws SQLException {
        String sql = "SELECT qe.*, u.name as user_name, u.email as user_email, u.tag as user_tag, " +
                     "eb.name as exempted_by_name, q.title as quiz_title " +
                     "FROM quiz_exemptions qe " +
                     "LEFT JOIN users u ON qe.user_id = u.id " +
                     "LEFT JOIN users eb ON qe.exempted_by = eb.id " +
                     "LEFT JOIN quiz q ON qe.quiz_id = q.id " +
                     "WHERE qe.id = ?";

        try (Connection conn = DBUtil.getConnection();
             PreparedStatement stmt = conn.prepareStatement(sql)) {

            stmt.setInt(1, id);

            try (ResultSet rs = stmt.executeQuery()) {
                if (rs.next()) {
                    return mapResultSetToExemption(rs);
                }
            }
        }
        return null;
    }

    /**
     * Get all exemptions for a quiz
     */
    public List<QuizExemption> findByQuizId(Integer quizId) throws SQLException {
        String sql = "SELECT qe.*, u.name as user_name, u.email as user_email, u.tag as user_tag, " +
                     "eb.name as exempted_by_name, q.title as quiz_title " +
                     "FROM quiz_exemptions qe " +
                     "LEFT JOIN users u ON qe.user_id = u.id " +
                     "LEFT JOIN users eb ON qe.exempted_by = eb.id " +
                     "LEFT JOIN quiz q ON qe.quiz_id = q.id " +
                     "WHERE qe.quiz_id = ? " +
                     "ORDER BY u.name ASC";

        List<QuizExemption> exemptions = new ArrayList<>();

        try (Connection conn = DBUtil.getConnection();
             PreparedStatement stmt = conn.prepareStatement(sql)) {

            stmt.setInt(1, quizId);

            try (ResultSet rs = stmt.executeQuery()) {
                while (rs.next()) {
                    exemptions.add(mapResultSetToExemption(rs));
                }
            }
        }
        return exemptions;
    }

    /**
     * Get all exemptions for a user
     */
    public List<QuizExemption> findByUserId(Integer userId) throws SQLException {
        String sql = "SELECT qe.*, u.name as user_name, u.email as user_email, u.tag as user_tag, " +
                     "eb.name as exempted_by_name, q.title as quiz_title " +
                     "FROM quiz_exemptions qe " +
                     "LEFT JOIN users u ON qe.user_id = u.id " +
                     "LEFT JOIN users eb ON qe.exempted_by = eb.id " +
                     "LEFT JOIN quiz q ON qe.quiz_id = q.id " +
                     "WHERE qe.user_id = ? " +
                     "ORDER BY qe.created_at DESC";

        List<QuizExemption> exemptions = new ArrayList<>();

        try (Connection conn = DBUtil.getConnection();
             PreparedStatement stmt = conn.prepareStatement(sql)) {

            stmt.setInt(1, userId);

            try (ResultSet rs = stmt.executeQuery()) {
                while (rs.next()) {
                    exemptions.add(mapResultSetToExemption(rs));
                }
            }
        }
        return exemptions;
    }

    /**
     * Check if user is exempted from a quiz
     */
    public boolean isExempted(Integer quizId, Integer userId) throws SQLException {
        String sql = "SELECT COUNT(*) FROM quiz_exemptions WHERE quiz_id = ? AND user_id = ?";

        try (Connection conn = DBUtil.getConnection();
             PreparedStatement stmt = conn.prepareStatement(sql)) {

            stmt.setInt(1, quizId);
            stmt.setInt(2, userId);

            try (ResultSet rs = stmt.executeQuery()) {
                if (rs.next()) {
                    return rs.getInt(1) > 0;
                }
            }
        }
        return false;
    }

    /**
     * Delete exemption by ID
     */
    public boolean delete(Integer id) throws SQLException {
        String sql = "DELETE FROM quiz_exemptions WHERE id = ?";

        try (Connection conn = DBUtil.getConnection();
             PreparedStatement stmt = conn.prepareStatement(sql)) {

            stmt.setInt(1, id);
            return stmt.executeUpdate() > 0;
        }
    }

    /**
     * Delete all exemptions for a quiz
     */
    public boolean deleteByQuizId(Integer quizId) throws SQLException {
        String sql = "DELETE FROM quiz_exemptions WHERE quiz_id = ?";

        try (Connection conn = DBUtil.getConnection();
             PreparedStatement stmt = conn.prepareStatement(sql)) {

            stmt.setInt(1, quizId);
            return stmt.executeUpdate() > 0;
        }
    }

    /**
     * Delete exemption for specific user and quiz
     */
    public boolean deleteByQuizAndUser(Integer quizId, Integer userId) throws SQLException {
        String sql = "DELETE FROM quiz_exemptions WHERE quiz_id = ? AND user_id = ?";

        try (Connection conn = DBUtil.getConnection();
             PreparedStatement stmt = conn.prepareStatement(sql)) {

            stmt.setInt(1, quizId);
            stmt.setInt(2, userId);
            return stmt.executeUpdate() > 0;
        }
    }

    /**
     * Get available users (non-admin, not yet exempted) for exemption selection
     */
    public List<ExemptableUser> getAvailableUsers(Integer quizId) throws SQLException {
        String sql = "SELECT u.id, u.name, u.email, u.tag " +
                     "FROM users u " +
                     "WHERE u.role = 'peserta' " +
                     "AND u.id NOT IN (SELECT user_id FROM quiz_exemptions WHERE quiz_id = ?) " +
                     "ORDER BY u.name ASC";

        List<ExemptableUser> users = new ArrayList<>();

        try (Connection conn = DBUtil.getConnection();
             PreparedStatement stmt = conn.prepareStatement(sql)) {

            stmt.setInt(1, quizId);

            try (ResultSet rs = stmt.executeQuery()) {
                while (rs.next()) {
                    ExemptableUser user = new ExemptableUser();
                    user.userId = rs.getInt("id");
                    user.name = rs.getString("name");
                    user.email = rs.getString("email");
                    user.tag = rs.getString("tag");
                    users.add(user);
                }
            }
        }
        return users;
    }

    /**
     * Helper class for exemptable user info
     */
    public static class ExemptableUser {
        public Integer userId;
        public String name;
        public String email;
        public String tag;
    }

    /**
     * Map ResultSet to QuizExemption object
     */
    private QuizExemption mapResultSetToExemption(ResultSet rs) throws SQLException {
        QuizExemption exemption = new QuizExemption();
        exemption.setId(rs.getInt("id"));
        exemption.setQuizId(rs.getInt("quiz_id"));
        exemption.setUserId(rs.getInt("user_id"));
        exemption.setExemptedBy(rs.getInt("exempted_by"));
        exemption.setNotes(rs.getString("notes"));

        Timestamp createdAt = rs.getTimestamp("created_at");
        if (createdAt != null) {
            exemption.setCreatedAt(createdAt.toLocalDateTime());
        }

        // Related data
        exemption.setUserName(rs.getString("user_name"));
        exemption.setUserEmail(rs.getString("user_email"));
        exemption.setUserTag(rs.getString("user_tag"));
        exemption.setExemptedByName(rs.getString("exempted_by_name"));
        exemption.setQuizTitle(rs.getString("quiz_title"));

        return exemption;
    }
}

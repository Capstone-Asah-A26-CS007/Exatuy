package com.examora.dao;

import com.examora.util.DBUtil;

import java.sql.*;
import java.util.ArrayList;
import java.util.List;

/**
 * Quiz Participant DAO - Manage which users are allowed to take a quiz
 */
public class QuizParticipantDAO {

    /**
     * Add or update participant permission for a quiz
     */
    public boolean setParticipantPermission(Integer quizId, Integer userId, boolean allowed) throws SQLException {
        String sql = "INSERT INTO quiz_participants (quiz_id, user_id, allowed) " +
                     "VALUES (?, ?, ?) " +
                     "ON DUPLICATE KEY UPDATE allowed = VALUES(allowed)";

        try (Connection conn = DBUtil.getConnection();
             PreparedStatement stmt = conn.prepareStatement(sql)) {

            stmt.setInt(1, quizId);
            stmt.setInt(2, userId);
            stmt.setBoolean(3, allowed);

            int rows = stmt.executeUpdate();
            return rows > 0;
        }
    }

    /**
     * Check if a user is allowed to take a quiz
     */
    public boolean isUserAllowed(Integer quizId, Integer userId) throws SQLException {
        String sql = "SELECT allowed FROM quiz_participants WHERE quiz_id = ? AND user_id = ?";

        try (Connection conn = DBUtil.getConnection();
             PreparedStatement stmt = conn.prepareStatement(sql)) {

            stmt.setInt(1, quizId);
            stmt.setInt(2, userId);

            try (ResultSet rs = stmt.executeQuery()) {
                if (rs.next()) {
                    return rs.getBoolean("allowed");
                }
                // If no record exists, check if there are ANY participants for this quiz
                // If no participants at all, allow everyone (backward compatibility)
                return !hasAnyParticipants(quizId);
            }
        }
    }

    /**
     * Check if a quiz has any participant restrictions
     */
    public boolean hasAnyParticipants(Integer quizId) throws SQLException {
        String sql = "SELECT COUNT(*) as count FROM quiz_participants WHERE quiz_id = ?";

        try (Connection conn = DBUtil.getConnection();
             PreparedStatement stmt = conn.prepareStatement(sql)) {

            stmt.setInt(1, quizId);

            try (ResultSet rs = stmt.executeQuery()) {
                if (rs.next()) {
                    return rs.getInt("count") > 0;
                }
            }
        }
        return false;
    }

    /**
     * Get all participants for a quiz with their allowed status
     */
    public List<ParticipantInfo> getQuizParticipants(Integer quizId) throws SQLException {
        String sql = "SELECT qp.user_id, u.name, u.email, u.tag, qp.allowed " +
                     "FROM quiz_participants qp " +
                     "LEFT JOIN users u ON qp.user_id = u.id " +
                     "WHERE qp.quiz_id = ? " +
                     "ORDER BY u.name";

        List<ParticipantInfo> participants = new ArrayList<>();

        try (Connection conn = DBUtil.getConnection();
             PreparedStatement stmt = conn.prepareStatement(sql)) {

            stmt.setInt(1, quizId);

            try (ResultSet rs = stmt.executeQuery()) {
                while (rs.next()) {
                    ParticipantInfo info = new ParticipantInfo();
                    info.userId = rs.getInt("user_id");
                    info.name = rs.getString("name");
                    info.email = rs.getString("email");
                    info.tag = rs.getString("tag");
                    info.allowed = rs.getBoolean("allowed");
                    participants.add(info);
                }
            }
        }
        return participants;
    }

    /**
     * Remove participant permission (delete record)
     */
    public boolean removeParticipant(Integer quizId, Integer userId) throws SQLException {
        String sql = "DELETE FROM quiz_participants WHERE quiz_id = ? AND user_id = ?";

        try (Connection conn = DBUtil.getConnection();
             PreparedStatement stmt = conn.prepareStatement(sql)) {

            stmt.setInt(1, quizId);
            stmt.setInt(2, userId);

            int rows = stmt.executeUpdate();
            return rows > 0;
        }
    }

    /**
     * Get all users who are NOT participants for a quiz (for selection list)
     * Only excludes users who have already COMPLETED the quiz successfully
     * Users who timed out are still available for manual permission
     */
    public List<ParticipantInfo> getAvailableUsers(Integer quizId) throws SQLException {
        String sql = "SELECT u.id as user_id, u.name, u.email, u.tag " +
                     "FROM users u " +
                     "WHERE u.role != 'admin' " +
                     "AND u.id NOT IN (SELECT user_id FROM quiz_participants WHERE quiz_id = ?) " +
                     "AND u.id NOT IN (" +
                     "  SELECT s.user_id FROM submissions s " +
                     "  WHERE s.quiz_id = ? AND s.status = 'completed'" +
                     ") " +
                     "ORDER BY u.name";

        List<ParticipantInfo> users = new ArrayList<>();

        try (Connection conn = DBUtil.getConnection();
             PreparedStatement stmt = conn.prepareStatement(sql)) {

            stmt.setInt(1, quizId);
            stmt.setInt(2, quizId);

            try (ResultSet rs = stmt.executeQuery()) {
                while (rs.next()) {
                    ParticipantInfo info = new ParticipantInfo();
                    info.userId = rs.getInt("user_id");
                    info.name = rs.getString("name");
                    info.email = rs.getString("email");
                    info.tag = rs.getString("tag");
                    users.add(info);
                }
            }
        }
        return users;
    }

    /**
     * Clear all participants for a quiz
     */
    public boolean clearAllParticipants(Integer quizId) throws SQLException {
        String sql = "DELETE FROM quiz_participants WHERE quiz_id = ?";

        try (Connection conn = DBUtil.getConnection();
             PreparedStatement stmt = conn.prepareStatement(sql)) {

            stmt.setInt(1, quizId);

            int rows = stmt.executeUpdate();
            return rows >= 0;
        }
    }

    /**
     * Alias for getQuizParticipants for backward compatibility
     */
    public List<ParticipantInfo> getParticipantsByQuizId(Integer quizId) throws SQLException {
        return getQuizParticipants(quizId);
    }

    /**
     * Add a participant to a quiz (sets allowed = true)
     */
    public boolean addParticipant(Integer quizId, Integer userId) throws SQLException {
        return setParticipantPermission(quizId, userId, true);
    }

    /**
     * Inner class to hold participant information
     */
    public static class ParticipantInfo {
        public Integer userId;
        public String name;
        public String email;
        public String tag;
        public boolean allowed;
    }
}

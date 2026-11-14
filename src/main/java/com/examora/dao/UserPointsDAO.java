package com.examora.dao;

import com.examora.model.UserPoints;
import com.examora.util.DBUtil;

import java.sql.*;
import java.util.ArrayList;
import java.util.List;

/**
 * UserPoints DAO - Manages user points and levels
 */
public class UserPointsDAO {

    private static final String COLUMNS = "up.id, up.user_id, up.total_points, up.level, " +
            "up.experience_points, up.created_at, up.updated_at, u.name as user_name";

    /**
     * Create user points record
     */
    public UserPoints create(UserPoints userPoints) throws SQLException {
        String sql = "INSERT INTO user_points (user_id, total_points, level, experience_points) " +
                "VALUES (?, ?, ?, ?)";

        try (Connection conn = DBUtil.getConnection();
             PreparedStatement stmt = conn.prepareStatement(sql, Statement.RETURN_GENERATED_KEYS)) {

            stmt.setInt(1, userPoints.getUserId());
            stmt.setInt(2, userPoints.getTotalPoints() != null ? userPoints.getTotalPoints() : 0);
            stmt.setInt(3, userPoints.getLevel() != null ? userPoints.getLevel() : 1);
            stmt.setInt(4, userPoints.getExperiencePoints() != null ? userPoints.getExperiencePoints() : 0);

            int affectedRows = stmt.executeUpdate();
            if (affectedRows == 0) {
                throw new SQLException("Creating user points failed");
            }

            try (ResultSet generatedKeys = stmt.getGeneratedKeys()) {
                if (generatedKeys.next()) {
                    userPoints.setId(generatedKeys.getInt(1));
                }
            }
            return userPoints;
        }
    }

    /**
     * Find user points by user ID
     */
    public UserPoints findByUserId(Integer userId) throws SQLException {
        String sql = "SELECT " + COLUMNS + " FROM user_points up " +
                "LEFT JOIN users u ON up.user_id = u.id WHERE up.user_id = ?";

        try (Connection conn = DBUtil.getConnection();
             PreparedStatement stmt = conn.prepareStatement(sql)) {

            stmt.setInt(1, userId);
            try (ResultSet rs = stmt.executeQuery()) {
                if (rs.next()) {
                    return mapResultSetToUserPoints(rs);
                }
            }
        }
        return null;
    }

    /**
     * Get or create user points
     */
    public UserPoints getOrCreate(Integer userId) throws SQLException {
        UserPoints points = findByUserId(userId);
        if (points == null) {
            points = new UserPoints(userId);
            create(points);
        }
        return points;
    }

    /**
     * Get leaderboard (top users by points)
     */
    public List<UserPoints> getLeaderboard(int limit, String periodType) throws SQLException {
        String sql = "SELECT " + COLUMNS + " FROM user_points up " +
                "LEFT JOIN users u ON up.user_id = u.id " +
                "ORDER BY up.total_points DESC LIMIT ?";

        List<UserPoints> leaderboard = new ArrayList<>();

        try (Connection conn = DBUtil.getConnection();
             PreparedStatement stmt = conn.prepareStatement(sql)) {

            stmt.setInt(1, limit);
            try (ResultSet rs = stmt.executeQuery()) {
                int rank = 1;
                while (rs.next()) {
                    UserPoints up = mapResultSetToUserPoints(rs);
                    up.setRank(String.valueOf(rank++));
                    leaderboard.add(up);
                }
            }
        }
        return leaderboard;
    }

    /**
     * Update user points
     */
    public boolean update(UserPoints userPoints) throws SQLException {
        String sql = "UPDATE user_points SET total_points = ?, level = ?, experience_points = ? WHERE user_id = ?";

        try (Connection conn = DBUtil.getConnection();
             PreparedStatement stmt = conn.prepareStatement(sql)) {

            stmt.setInt(1, userPoints.getTotalPoints());
            stmt.setInt(2, userPoints.getLevel());
            stmt.setInt(3, userPoints.getExperiencePoints());
            stmt.setInt(4, userPoints.getUserId());

            return stmt.executeUpdate() > 0;
        }
    }

    /**
     * Add points to user
     */
    public boolean addPoints(Integer userId, Integer points) throws SQLException {
        String sql = "UPDATE user_points SET total_points = total_points + ?, " +
                "updated_at = NOW() WHERE user_id = ?";

        try (Connection conn = DBUtil.getConnection();
             PreparedStatement stmt = conn.prepareStatement(sql)) {

            stmt.setInt(1, points);
            stmt.setInt(2, userId);
            return stmt.executeUpdate() > 0;
        }
    }

    /**
     * Get user rank
     */
    public int getUserRank(Integer userId) throws SQLException {
        String sql = "SELECT COUNT(*) + 1 as rank FROM user_points WHERE total_points > " +
                "(SELECT total_points FROM user_points WHERE user_id = ?)";

        try (Connection conn = DBUtil.getConnection();
             PreparedStatement stmt = conn.prepareStatement(sql)) {

            stmt.setInt(1, userId);
            try (ResultSet rs = stmt.executeQuery()) {
                if (rs.next()) {
                    return rs.getInt("rank");
                }
            }
        }
        return 0;
    }

    private UserPoints mapResultSetToUserPoints(ResultSet rs) throws SQLException {
        UserPoints up = new UserPoints();
        up.setId(rs.getInt("id"));
        up.setUserId(rs.getInt("user_id"));
        up.setTotalPoints(rs.getInt("total_points"));
        up.setLevel(rs.getInt("level"));
        up.setExperiencePoints(rs.getInt("experience_points"));
        up.setUserName(rs.getString("user_name"));

        Timestamp created = rs.getTimestamp("created_at");
        if (created != null) {
            up.setCreatedAt(created.toLocalDateTime());
        }

        Timestamp updated = rs.getTimestamp("updated_at");
        if (updated != null) {
            up.setUpdatedAt(updated.toLocalDateTime());
        }

        return up;
    }
}

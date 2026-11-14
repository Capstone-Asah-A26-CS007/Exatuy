package com.examora.dao;

import com.examora.model.PointTransaction;
import com.examora.util.DBUtil;

import java.sql.*;
import java.util.ArrayList;
import java.util.List;

/**
 * PointTransaction DAO - Manages point transaction history
 */
public class PointTransactionDAO {

    private static final String COLUMNS = "pt.id, pt.user_id, pt.points, pt.transaction_type, " +
            "pt.source_type, pt.source_id, pt.description, pt.created_at, u.name as user_name";

    /**
     * Create transaction record
     */
    public PointTransaction create(PointTransaction transaction) throws SQLException {
        String sql = "INSERT INTO point_transactions (user_id, points, transaction_type, source_type, source_id, description) " +
                "VALUES (?, ?, ?, ?, ?, ?)";

        try (Connection conn = DBUtil.getConnection();
             PreparedStatement stmt = conn.prepareStatement(sql, Statement.RETURN_GENERATED_KEYS)) {

            stmt.setInt(1, transaction.getUserId());
            stmt.setInt(2, transaction.getPoints());
            stmt.setString(3, transaction.getTransactionType());
            stmt.setString(4, transaction.getSourceType());
            if (transaction.getSourceId() != null) {
                stmt.setInt(5, transaction.getSourceId());
            } else {
                stmt.setNull(5, Types.INTEGER);
            }
            stmt.setString(6, transaction.getDescription());

            int affectedRows = stmt.executeUpdate();
            if (affectedRows == 0) {
                throw new SQLException("Creating transaction failed");
            }

            try (ResultSet generatedKeys = stmt.getGeneratedKeys()) {
                if (generatedKeys.next()) {
                    transaction.setId(generatedKeys.getInt(1));
                }
            }
            return transaction;
        }
    }

    /**
     * Get transactions by user
     */
    public List<PointTransaction> findByUserId(Integer userId) throws SQLException {
        String sql = "SELECT " + COLUMNS + " FROM point_transactions pt " +
                "LEFT JOIN users u ON pt.user_id = u.id WHERE pt.user_id = ? " +
                "ORDER BY pt.created_at DESC LIMIT 50";

        List<PointTransaction> transactions = new ArrayList<>();

        try (Connection conn = DBUtil.getConnection();
             PreparedStatement stmt = conn.prepareStatement(sql)) {

            stmt.setInt(1, userId);
            try (ResultSet rs = stmt.executeQuery()) {
                while (rs.next()) {
                    transactions.add(mapResultSetToPointTransaction(rs));
                }
            }
        }
        return transactions;
    }

    /**
     * Get recent transactions (admin view)
     */
    public List<PointTransaction> findRecent(int limit) throws SQLException {
        String sql = "SELECT " + COLUMNS + " FROM point_transactions pt " +
                "LEFT JOIN users u ON pt.user_id = u.id ORDER BY pt.created_at DESC LIMIT ?";

        List<PointTransaction> transactions = new ArrayList<>();

        try (Connection conn = DBUtil.getConnection();
             PreparedStatement stmt = conn.prepareStatement(sql)) {

            stmt.setInt(1, limit);
            try (ResultSet rs = stmt.executeQuery()) {
                while (rs.next()) {
                    transactions.add(mapResultSetToPointTransaction(rs));
                }
            }
        }
        return transactions;
    }

    /**
     * Get total points earned by user
     */
    public int getTotalPointsByUser(Integer userId) throws SQLException {
        String sql = "SELECT COALESCE(SUM(points), 0) FROM point_transactions WHERE user_id = ? AND points > 0";

        try (Connection conn = DBUtil.getConnection();
             PreparedStatement stmt = conn.prepareStatement(sql)) {

            stmt.setInt(1, userId);
            try (ResultSet rs = stmt.executeQuery()) {
                if (rs.next()) {
                    return rs.getInt(1);
                }
            }
        }
        return 0;
    }

    private PointTransaction mapResultSetToPointTransaction(ResultSet rs) throws SQLException {
        PointTransaction pt = new PointTransaction();
        pt.setId(rs.getInt("id"));
        pt.setUserId(rs.getInt("user_id"));
        pt.setPoints(rs.getInt("points"));
        pt.setTransactionType(rs.getString("transaction_type"));
        pt.setSourceType(rs.getString("source_type"));

        int sourceId = rs.getInt("source_id");
        if (!rs.wasNull()) {
            pt.setSourceId(sourceId);
        }

        pt.setDescription(rs.getString("description"));
        pt.setUserName(rs.getString("user_name"));

        Timestamp created = rs.getTimestamp("created_at");
        if (created != null) {
            pt.setCreatedAt(created.toLocalDateTime());
        }

        return pt;
    }
}

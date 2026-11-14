package com.examora.dao;

import com.examora.model.ApiKey;
import com.examora.util.DBUtil;

import java.sql.*;
import java.util.ArrayList;
import java.util.List;

/**
 * ApiKey DAO - Manages API keys for external integrations
 */
public class ApiKeyDAO {

    private static final String COLUMNS = "ak.id, ak.key_name, ak.key_value, ak.key_type, " +
            "ak.description, ak.created_by, ak.last_used_at, ak.expires_at, ak.is_active, " +
            "ak.created_at, ak.updated_at, u.name as creator_name";

    /**
     * Create new API key
     */
    public ApiKey create(ApiKey apiKey) throws SQLException {
        String sql = "INSERT INTO api_keys (key_name, key_value, key_type, description, created_by, expires_at) " +
                "VALUES (?, ?, ?, ?, ?, ?)";

        try (Connection conn = DBUtil.getConnection();
             PreparedStatement stmt = conn.prepareStatement(sql, Statement.RETURN_GENERATED_KEYS)) {

            stmt.setString(1, apiKey.getKeyName());
            stmt.setString(2, apiKey.getKeyValue());
            stmt.setString(3, apiKey.getKeyType());
            stmt.setString(4, apiKey.getDescription());
            stmt.setInt(5, apiKey.getCreatedBy());
            if (apiKey.getExpiresAt() != null) {
                stmt.setTimestamp(6, Timestamp.valueOf(apiKey.getExpiresAt()));
            } else {
                stmt.setNull(6, Types.TIMESTAMP);
            }

            int affectedRows = stmt.executeUpdate();
            if (affectedRows == 0) {
                throw new SQLException("Creating API key failed, no rows affected.");
            }

            try (ResultSet generatedKeys = stmt.getGeneratedKeys()) {
                if (generatedKeys.next()) {
                    apiKey.setId(generatedKeys.getInt(1));
                }
            }
            return apiKey;
        }
    }

    /**
     * Find API key by ID
     */
    public ApiKey findById(Integer id) throws SQLException {
        String sql = "SELECT " + COLUMNS + " FROM api_keys ak " +
                "LEFT JOIN users u ON ak.created_by = u.id WHERE ak.id = ?";

        try (Connection conn = DBUtil.getConnection();
             PreparedStatement stmt = conn.prepareStatement(sql)) {

            stmt.setInt(1, id);
            try (ResultSet rs = stmt.executeQuery()) {
                if (rs.next()) {
                    return mapResultSetToApiKey(rs);
                }
            }
        }
        return null;
    }

    /**
     * Get all API keys
     */
    public List<ApiKey> findAll() throws SQLException {
        String sql = "SELECT " + COLUMNS + " FROM api_keys ak " +
                "LEFT JOIN users u ON ak.created_by = u.id ORDER BY ak.created_at DESC";
        List<ApiKey> keys = new ArrayList<>();

        try (Connection conn = DBUtil.getConnection();
             Statement stmt = conn.createStatement();
             ResultSet rs = stmt.executeQuery(sql)) {

            while (rs.next()) {
                keys.add(mapResultSetToApiKey(rs));
            }
        }
        return keys;
    }

    /**
     * Get active API keys
     */
    public List<ApiKey> findActive() throws SQLException {
        String sql = "SELECT " + COLUMNS + " FROM api_keys ak " +
                "LEFT JOIN users u ON ak.created_by = u.id WHERE ak.is_active = 1 " +
                "ORDER BY ak.created_at DESC";
        List<ApiKey> keys = new ArrayList<>();

        try (Connection conn = DBUtil.getConnection();
             Statement stmt = conn.createStatement();
             ResultSet rs = stmt.executeQuery(sql)) {

            while (rs.next()) {
                keys.add(mapResultSetToApiKey(rs));
            }
        }
        return keys;
    }

    /**
     * Get API keys by type
     */
    public List<ApiKey> findByType(String keyType) throws SQLException {
        String sql = "SELECT " + COLUMNS + " FROM api_keys ak " +
                "LEFT JOIN users u ON ak.created_by = u.id WHERE ak.key_type = ? " +
                "ORDER BY ak.created_at DESC";
        List<ApiKey> keys = new ArrayList<>();

        try (Connection conn = DBUtil.getConnection();
             PreparedStatement stmt = conn.prepareStatement(sql)) {

            stmt.setString(1, keyType);
            try (ResultSet rs = stmt.executeQuery()) {
                while (rs.next()) {
                    keys.add(mapResultSetToApiKey(rs));
                }
            }
        }
        return keys;
    }

    /**
     * Update API key
     */
    public boolean update(ApiKey apiKey) throws SQLException {
        String sql = "UPDATE api_keys SET key_name = ?, description = ?, is_active = ?, expires_at = ? WHERE id = ?";

        try (Connection conn = DBUtil.getConnection();
             PreparedStatement stmt = conn.prepareStatement(sql)) {

            stmt.setString(1, apiKey.getKeyName());
            stmt.setString(2, apiKey.getDescription());
            stmt.setBoolean(3, apiKey.getIsActive());
            if (apiKey.getExpiresAt() != null) {
                stmt.setTimestamp(4, Timestamp.valueOf(apiKey.getExpiresAt()));
            } else {
                stmt.setNull(4, Types.TIMESTAMP);
            }
            stmt.setInt(5, apiKey.getId());

            return stmt.executeUpdate() > 0;
        }
    }

    /**
     * Update last used timestamp
     */
    public boolean updateLastUsed(Integer id) throws SQLException {
        String sql = "UPDATE api_keys SET last_used_at = NOW() WHERE id = ?";

        try (Connection conn = DBUtil.getConnection();
             PreparedStatement stmt = conn.prepareStatement(sql)) {

            stmt.setInt(1, id);
            return stmt.executeUpdate() > 0;
        }
    }

    /**
     * Delete API key
     */
    public boolean delete(Integer id) throws SQLException {
        String sql = "DELETE FROM api_keys WHERE id = ?";

        try (Connection conn = DBUtil.getConnection();
             PreparedStatement stmt = conn.prepareStatement(sql)) {

            stmt.setInt(1, id);
            return stmt.executeUpdate() > 0;
        }
    }

    /**
     * Check if key name exists
     */
    public boolean existsByName(String keyName, Integer excludeId) throws SQLException {
        String sql = "SELECT COUNT(*) FROM api_keys WHERE key_name = ?";
        if (excludeId != null) {
            sql += " AND id != ?";
        }

        try (Connection conn = DBUtil.getConnection();
             PreparedStatement stmt = conn.prepareStatement(sql)) {

            stmt.setString(1, keyName);
            if (excludeId != null) {
                stmt.setInt(2, excludeId);
            }

            try (ResultSet rs = stmt.executeQuery()) {
                if (rs.next()) {
                    return rs.getInt(1) > 0;
                }
            }
        }
        return false;
    }

    /**
     * Find API key by key value
     */
    public ApiKey findByKeyValue(String keyValue) throws SQLException {
        String sql = "SELECT " + COLUMNS + " FROM api_keys ak " +
                "LEFT JOIN users u ON ak.created_by = u.id WHERE ak.key_value = ?";

        try (Connection conn = DBUtil.getConnection();
             PreparedStatement stmt = conn.prepareStatement(sql)) {

            stmt.setString(1, keyValue);
            try (ResultSet rs = stmt.executeQuery()) {
                if (rs.next()) {
                    return mapResultSetToApiKey(rs);
                }
            }
        }
        return null;
    }

    private ApiKey mapResultSetToApiKey(ResultSet rs) throws SQLException {
        ApiKey key = new ApiKey();
        key.setId(rs.getInt("id"));
        key.setKeyName(rs.getString("key_name"));
        key.setKeyValue(rs.getString("key_value"));
        key.setKeyType(rs.getString("key_type"));
        key.setDescription(rs.getString("description"));
        key.setCreatedBy(rs.getInt("created_by"));
        key.setCreatorName(rs.getString("creator_name"));

        Timestamp lastUsed = rs.getTimestamp("last_used_at");
        if (lastUsed != null) {
            key.setLastUsedAt(lastUsed.toLocalDateTime());
        }

        Timestamp expires = rs.getTimestamp("expires_at");
        if (expires != null) {
            key.setExpiresAt(expires.toLocalDateTime());
        }

        key.setIsActive(rs.getBoolean("is_active"));

        Timestamp created = rs.getTimestamp("created_at");
        if (created != null) {
            key.setCreatedAt(created.toLocalDateTime());
        }

        Timestamp updated = rs.getTimestamp("updated_at");
        if (updated != null) {
            key.setUpdatedAt(updated.toLocalDateTime());
        }

        return key;
    }
}

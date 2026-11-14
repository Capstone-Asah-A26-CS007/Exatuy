package com.examora.dao;

import com.examora.util.DBUtil;
import java.sql.Connection;
import java.sql.PreparedStatement;
import java.sql.ResultSet;
import java.sql.SQLException;
import java.util.HashMap;
import java.util.Map;

/**
 * Settings DAO - Manages application settings
 */
public class SettingsDAO {

    /**
     * Get all settings as a map
     */
    public Map<String, String> getAllSettings() {
        Map<String, String> settings = new HashMap<>();
        String sql = "SELECT setting_key, setting_value FROM app_settings";

        try (Connection conn = DBUtil.getConnection();
             PreparedStatement stmt = conn.prepareStatement(sql);
             ResultSet rs = stmt.executeQuery()) {

            while (rs.next()) {
                settings.put(rs.getString("setting_key"), rs.getString("setting_value"));
            }

        } catch (SQLException e) {
            e.printStackTrace();
        }

        return settings;
    }

    /**
     * Get a specific setting value
     */
    public String getSetting(String key) {
        String sql = "SELECT setting_value FROM app_settings WHERE setting_key = ?";

        try (Connection conn = DBUtil.getConnection();
             PreparedStatement stmt = conn.prepareStatement(sql)) {

            stmt.setString(1, key);
            ResultSet rs = stmt.executeQuery();

            if (rs.next()) {
                return rs.getString("setting_value");
            }

        } catch (SQLException e) {
            e.printStackTrace();
        }

        return null;
    }

    /**
     * Get boolean setting (defaults to false if not found)
     */
    public boolean getBooleanSetting(String key) {
        String value = getSetting(key);
        return "true".equalsIgnoreCase(value);
    }

    /**
     * Update a setting value
     */
    public boolean updateSetting(String key, String value) {
        String sql = "UPDATE app_settings SET setting_value = ? WHERE setting_key = ?";

        try (Connection conn = DBUtil.getConnection();
             PreparedStatement stmt = conn.prepareStatement(sql)) {

            stmt.setString(1, value);
            stmt.setString(2, key);

            return stmt.executeUpdate() > 0;

        } catch (SQLException e) {
            e.printStackTrace();
        }

        return false;
    }

    /**
     * Insert a new setting (if not exists)
     */
    public boolean insertSetting(String key, String value) {
        String sql = "INSERT INTO app_settings (setting_key, setting_value) VALUES (?, ?) " +
                     "ON DUPLICATE KEY UPDATE setting_value = VALUES(setting_value)";

        try (Connection conn = DBUtil.getConnection();
             PreparedStatement stmt = conn.prepareStatement(sql)) {

            stmt.setString(1, key);
            stmt.setString(2, value);

            return stmt.executeUpdate() > 0;

        } catch (SQLException e) {
            e.printStackTrace();
        }

        return false;
    }

    /**
     * Check if registration is enabled
     */
    public boolean isRegistrationEnabled() {
        return getBooleanSetting("registration_enabled");
    }

    /**
     * Check if chat is enabled (defaults to true if not set)
     */
    public boolean isChatEnabled() {
        String value = getSetting("chat_enabled");
        // Default to true if not set
        return value == null || "true".equalsIgnoreCase(value);
    }

    /**
     * Check if file management is enabled (defaults to true if not set)
     */
    public boolean isFileManagementEnabled() {
        String value = getSetting("file_management_enabled");
        // Default to true if not set
        return value == null || "true".equalsIgnoreCase(value);
    }

    /**
     * Check if the leaderboard page is published/visible to peserta.
     * Defaults to true so existing behavior is unchanged until an admin
     * explicitly unpublishes it.
     */
    public boolean isLeaderboardPublished() {
        String value = getSetting("leaderboard_published");
        return value == null || "true".equalsIgnoreCase(value);
    }
}

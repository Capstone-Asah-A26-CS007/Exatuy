package com.examora.dao;

import com.examora.model.ChatMessage;
import com.examora.util.DBUtil;

import java.sql.*;
import java.util.ArrayList;
import java.util.List;
import java.util.logging.Level;
import java.util.logging.Logger;

/**
 * Chat Data Access Object - Handles database operations for chat messages
 */
public class ChatDAO {
    private static final Logger logger = Logger.getLogger(ChatDAO.class.getName());
    private static boolean tableExists = false;
    private static boolean tableChecked = false;

    /**
     * Check if chat_messages table exists
     */
    private synchronized boolean checkTableExists() {
        if (tableChecked) {
            return tableExists;
        }

        try (Connection conn = DBUtil.getConnection()) {
            DatabaseMetaData meta = conn.getMetaData();
            try (ResultSet rs = meta.getTables(null, null, "chat_messages", null)) {
                tableExists = rs.next();
                tableChecked = true;
                if (!tableExists) {
                    logger.log(Level.WARNING, "Table 'chat_messages' does not exist. Please run sql/add_chat.sql");
                }
                return tableExists;
            }
        } catch (SQLException e) {
            logger.log(Level.SEVERE, "Error checking if chat_messages table exists: " + e.getMessage(), e);
            tableChecked = true;
            return false;
        }
    }

    /**
     * Create a new chat message
     */
    public ChatMessage create(ChatMessage message) throws SQLException {
        // Check if table exists first
        if (!checkTableExists()) {
            throw new SQLException("Table 'chat_messages' does not exist. Please run sql/add_chat.sql to create it.");
        }

        String sql = "INSERT INTO chat_messages (user_id, sender_type, admin_id, message_text, is_read) VALUES (?, ?, ?, ?, ?)";

        try (Connection conn = DBUtil.getConnection();
             PreparedStatement stmt = conn.prepareStatement(sql, Statement.RETURN_GENERATED_KEYS)) {

            stmt.setInt(1, message.getUserId());
            stmt.setString(2, message.getSenderType());
            if (message.getAdminId() != null) {
                stmt.setInt(3, message.getAdminId());
            } else {
                stmt.setNull(3, Types.INTEGER);
            }
            stmt.setString(4, message.getMessageText());
            stmt.setBoolean(5, message.getIsRead() != null ? message.getIsRead() : false);

            int affectedRows = stmt.executeUpdate();

            if (affectedRows == 0) {
                throw new SQLException("Creating chat message failed, no rows affected.");
            }

            try (ResultSet generatedKeys = stmt.getGeneratedKeys()) {
                if (generatedKeys.next()) {
                    message.setId(generatedKeys.getInt(1));
                } else {
                    throw new SQLException("Creating chat message failed, no ID obtained.");
                }
            }

            return message;
        }
    }

    /**
     * Find all messages for a specific user (thread)
     */
    public List<ChatMessage> findByUserId(Integer userId) throws SQLException {
        // Check if table exists first
        if (!checkTableExists()) {
            throw new SQLException("Table 'chat_messages' does not exist. Please run sql/add_chat.sql to create it.");
        }

        String sql = "SELECT cm.*, " +
                     "CASE WHEN cm.sender_type = 'user' THEN u.name ELSE a.name END AS sender_name, " +
                     "CASE WHEN cm.sender_type = 'user' THEN u.photo ELSE a.photo END AS sender_photo " +
                     "FROM chat_messages cm " +
                     "LEFT JOIN users u ON cm.sender_type = 'user' AND cm.user_id = u.id " +
                     "LEFT JOIN users a ON cm.sender_type = 'admin' AND cm.admin_id = a.id " +
                     "WHERE cm.user_id = ? " +
                     "ORDER BY cm.created_at ASC";

        List<ChatMessage> messages = new ArrayList<>();

        try (Connection conn = DBUtil.getConnection();
             PreparedStatement stmt = conn.prepareStatement(sql)) {

            stmt.setInt(1, userId);

            try (ResultSet rs = stmt.executeQuery()) {
                while (rs.next()) {
                    messages.add(mapResultSetToChatMessage(rs));
                }
            }
        }
        return messages;
    }

    /**
     * Find all chat threads (for admin view)
     * Returns list of users who have chatted, with last message and unread count
     */
    public List<ChatMessage> findAllThreads() throws SQLException {
        // Check if table exists first
        if (!checkTableExists()) {
            throw new SQLException("Table 'chat_messages' does not exist. Please run sql/add_chat.sql to create it.");
        }

        String sql = "SELECT cm.*, u.name AS sender_name, u.photo AS sender_photo " +
                     "FROM chat_messages cm " +
                     "INNER JOIN users u ON cm.user_id = u.id " +
                     "INNER JOIN ( " +
                     "    SELECT user_id, MAX(created_at) as max_created " +
                     "    FROM chat_messages " +
                     "    GROUP BY user_id " +
                     ") latest ON cm.user_id = latest.user_id AND cm.created_at = latest.max_created " +
                     "ORDER BY cm.created_at DESC";

        List<ChatMessage> threads = new ArrayList<>();

        try (Connection conn = DBUtil.getConnection();
             Statement stmt = conn.createStatement();
             ResultSet rs = stmt.executeQuery(sql)) {

            while (rs.next()) {
                threads.add(mapResultSetToChatMessage(rs));
            }
        }
        return threads;
    }

    /**
     * Find message by ID
     */
    public ChatMessage findById(Integer id) throws SQLException {
        String sql = "SELECT cm.*, " +
                     "CASE WHEN cm.sender_type = 'user' THEN u.name ELSE a.name END AS sender_name, " +
                     "CASE WHEN cm.sender_type = 'user' THEN u.photo ELSE a.photo END AS sender_photo " +
                     "FROM chat_messages cm " +
                     "LEFT JOIN users u ON cm.sender_type = 'user' AND cm.user_id = u.id " +
                     "LEFT JOIN users a ON cm.sender_type = 'admin' AND cm.admin_id = a.id " +
                     "WHERE cm.id = ?";

        try (Connection conn = DBUtil.getConnection();
             PreparedStatement stmt = conn.prepareStatement(sql)) {

            stmt.setInt(1, id);

            try (ResultSet rs = stmt.executeQuery()) {
                if (rs.next()) {
                    return mapResultSetToChatMessage(rs);
                }
            }
        }
        return null;
    }

    /**
     * Mark a specific message as read
     */
    public boolean markAsRead(Integer messageId) throws SQLException {
        String sql = "UPDATE chat_messages SET is_read = TRUE WHERE id = ?";

        try (Connection conn = DBUtil.getConnection();
             PreparedStatement stmt = conn.prepareStatement(sql)) {

            stmt.setInt(1, messageId);
            return stmt.executeUpdate() > 0;
        }
    }

    /**
     * Mark all messages as read for a user from a specific sender type
     */
    public int markAllAsRead(Integer userId, String senderType) throws SQLException {
        String sql = "UPDATE chat_messages SET is_read = TRUE WHERE user_id = ? AND sender_type = ? AND is_read = FALSE";

        try (Connection conn = DBUtil.getConnection();
             PreparedStatement stmt = conn.prepareStatement(sql)) {

            stmt.setInt(1, userId);
            stmt.setString(2, senderType);
            return stmt.executeUpdate();
        }
    }

    /**
     * Count unread messages for a user (from admin)
     */
    public int countUnreadForUser(Integer userId) throws SQLException {
        // Return 0 if table doesn't exist
        if (!checkTableExists()) {
            return 0;
        }

        String sql = "SELECT COUNT(*) FROM chat_messages WHERE user_id = ? AND sender_type = 'admin' AND is_read = FALSE";

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

    /**
     * Count total unread messages for admin (from all users)
     */
    public int countUnreadForAdmin() throws SQLException {
        // Return 0 if table doesn't exist
        if (!checkTableExists()) {
            return 0;
        }

        String sql = "SELECT COUNT(*) FROM chat_messages WHERE sender_type = 'user' AND is_read = FALSE";

        try (Connection conn = DBUtil.getConnection();
             Statement stmt = conn.createStatement();
             ResultSet rs = stmt.executeQuery(sql)) {

            if (rs.next()) {
                return rs.getInt(1);
            }
        }
        return 0;
    }

    /**
     * Count unread messages for admin from a specific user
     */
    public int countUnreadFromUser(Integer userId) throws SQLException {
        // Return 0 if table doesn't exist
        if (!checkTableExists()) {
            return 0;
        }

        String sql = "SELECT COUNT(*) FROM chat_messages WHERE user_id = ? AND sender_type = 'user' AND is_read = FALSE";

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

    /**
     * Get the last message in a user's thread
     */
    public ChatMessage getLastMessage(Integer userId) throws SQLException {
        String sql = "SELECT cm.*, " +
                     "CASE WHEN cm.sender_type = 'user' THEN u.name ELSE a.name END AS sender_name, " +
                     "CASE WHEN cm.sender_type = 'user' THEN u.photo ELSE a.photo END AS sender_photo " +
                     "FROM chat_messages cm " +
                     "LEFT JOIN users u ON cm.sender_type = 'user' AND cm.user_id = u.id " +
                     "LEFT JOIN users a ON cm.sender_type = 'admin' AND cm.admin_id = a.id " +
                     "WHERE cm.user_id = ? " +
                     "ORDER BY cm.created_at DESC LIMIT 1";

        try (Connection conn = DBUtil.getConnection();
             PreparedStatement stmt = conn.prepareStatement(sql)) {

            stmt.setInt(1, userId);

            try (ResultSet rs = stmt.executeQuery()) {
                if (rs.next()) {
                    return mapResultSetToChatMessage(rs);
                }
            }
        }
        return null;
    }

    /**
     * Delete all messages for a user
     */
    public int deleteByUserId(Integer userId) throws SQLException {
        String sql = "DELETE FROM chat_messages WHERE user_id = ?";

        try (Connection conn = DBUtil.getConnection();
             PreparedStatement stmt = conn.prepareStatement(sql)) {

            stmt.setInt(1, userId);
            return stmt.executeUpdate();
        }
    }

    /**
     * Get messages with pagination for a user
     */
    public List<ChatMessage> findByUserIdPaginated(Integer userId, int page, int pageSize) throws SQLException {
        String sql = "SELECT cm.*, " +
                     "CASE WHEN cm.sender_type = 'user' THEN u.name ELSE a.name END AS sender_name, " +
                     "CASE WHEN cm.sender_type = 'user' THEN u.photo ELSE a.photo END AS sender_photo " +
                     "FROM chat_messages cm " +
                     "LEFT JOIN users u ON cm.sender_type = 'user' AND cm.user_id = u.id " +
                     "LEFT JOIN users a ON cm.sender_type = 'admin' AND cm.admin_id = a.id " +
                     "WHERE cm.user_id = ? " +
                     "ORDER BY cm.created_at ASC LIMIT ? OFFSET ?";

        List<ChatMessage> messages = new ArrayList<>();
        int offset = (page - 1) * pageSize;

        try (Connection conn = DBUtil.getConnection();
             PreparedStatement stmt = conn.prepareStatement(sql)) {

            stmt.setInt(1, userId);
            stmt.setInt(2, pageSize);
            stmt.setInt(3, offset);

            try (ResultSet rs = stmt.executeQuery()) {
                while (rs.next()) {
                    messages.add(mapResultSetToChatMessage(rs));
                }
            }
        }
        return messages;
    }

    /**
     * Count total messages for a user
     */
    public int countByUserId(Integer userId) throws SQLException {
        String sql = "SELECT COUNT(*) FROM chat_messages WHERE user_id = ?";

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

    /**
     * Map ResultSet to ChatMessage object
     */
    private ChatMessage mapResultSetToChatMessage(ResultSet rs) throws SQLException {
        ChatMessage message = new ChatMessage();
        message.setId(rs.getInt("id"));
        message.setUserId(rs.getInt("user_id"));
        message.setSenderType(rs.getString("sender_type"));

        // Handle nullable admin_id
        int adminId = rs.getInt("admin_id");
        if (!rs.wasNull()) {
            message.setAdminId(adminId);
        }

        message.setMessageText(rs.getString("message_text"));
        message.setIsRead(rs.getBoolean("is_read"));
        message.setCreatedAt(rs.getTimestamp("created_at").toLocalDateTime());

        // Display fields
        message.setSenderName(rs.getString("sender_name"));
        message.setSenderPhoto(rs.getString("sender_photo"));

        return message;
    }
}

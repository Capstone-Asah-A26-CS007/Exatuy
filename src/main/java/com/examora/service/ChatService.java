package com.examora.service;

import com.examora.dao.ChatDAO;
import com.examora.dao.UserDAO;
import com.examora.model.ChatMessage;
import com.examora.model.User;
import com.examora.util.ValidationUtil;

import jakarta.servlet.http.HttpServletRequest;
import java.sql.SQLException;
import java.util.HashMap;
import java.util.List;
import java.util.Map;
import java.util.concurrent.ConcurrentHashMap;
import java.util.concurrent.atomic.AtomicInteger;
import java.util.logging.Level;
import java.util.logging.Logger;

/**
 * ChatService - Business logic for chat operations
 */
public class ChatService {
    private ChatDAO chatDAO;
    private UserDAO userDAO;
    private AuditService auditService;

    // Rate limiting for chat messages
    private static final int MAX_MESSAGES_PER_MINUTE = 20;
    private static final Map<String, MessageRateRecord> messageRateStore = new ConcurrentHashMap<>();
    private static final AtomicInteger cleanupCounter = new AtomicInteger(0);
    private static final int CLEANUP_INTERVAL = 100;

    public ChatService() {
        try {
            this.chatDAO = new ChatDAO();
            this.userDAO = new UserDAO();
            this.auditService = new AuditService();
        } catch (Exception e) {
            Logger.getLogger(ChatService.class.getName()).log(Level.SEVERE, "Failed to initialize ChatService: " + e.getMessage(), e);
            throw new RuntimeException("Failed to initialize ChatService", e);
        }
    }

    /**
     * Send a message from user to admin
     */
    public ChatMessage sendMessage(Integer userId, String messageText, HttpServletRequest request)
            throws ServiceException {
        // Validate inputs
        if (userId == null) {
            throw new ServiceException("User ID tidak valid");
        }
        if (!ValidationUtil.isNotEmpty(messageText)) {
            throw new ServiceException("Pesan tidak boleh kosong");
        }
        if (messageText.length() > 5000) {
            throw new ServiceException("Pesan terlalu panjang (maksimal 5000 karakter)");
        }

        // Rate limiting
        String rateKey = "user_" + userId;
        checkRateLimit(rateKey);

        try {
            // Verify user exists
            User user = userDAO.findById(userId);
            if (user == null) {
                throw new ServiceException("User tidak ditemukan");
            }

            // Sanitize message
            String sanitizedMessage = sanitizeMessage(messageText);

            // Create message
            ChatMessage message = new ChatMessage(userId, "user", sanitizedMessage);
            message = chatDAO.create(message);

            // Audit log
            Map<String, Object> data = new HashMap<>();
            data.put("messageId", message.getId());
            data.put("messagePreview", truncatePreview(sanitizedMessage));
            auditService.logCreate("CHAT", message.getId(), "User: " + user.getName(), data, user, request);

            return message;

        } catch (SQLException e) {
            throw new ServiceException("Gagal mengirim pesan: " + e.getMessage(), e);
        }
    }

    /**
     * Reply to a user's message from admin
     */
    public ChatMessage replyMessage(Integer userId, Integer adminId, String messageText, HttpServletRequest request)
            throws ServiceException {
        // Validate inputs
        if (userId == null) {
            throw new ServiceException("User ID tidak valid");
        }
        if (adminId == null) {
            throw new ServiceException("Admin ID tidak valid");
        }
        if (!ValidationUtil.isNotEmpty(messageText)) {
            throw new ServiceException("Pesan tidak boleh kosong");
        }
        if (messageText.length() > 5000) {
            throw new ServiceException("Pesan terlalu panjang (maksimal 5000 karakter)");
        }

        // Rate limiting
        String rateKey = "admin_" + adminId;
        checkRateLimit(rateKey);

        try {
            // Verify user and admin exist
            User user = userDAO.findById(userId);
            if (user == null) {
                throw new ServiceException("User tidak ditemukan");
            }

            User admin = userDAO.findById(adminId);
            if (admin == null || !admin.isAdmin()) {
                throw new ServiceException("Admin tidak valid");
            }

            // Sanitize message
            String sanitizedMessage = sanitizeMessage(messageText);

            // Create message
            ChatMessage message = new ChatMessage(userId, "admin", adminId, sanitizedMessage);
            message = chatDAO.create(message);

            // Audit log
            Map<String, Object> data = new HashMap<>();
            data.put("messageId", message.getId());
            data.put("targetUserId", userId);
            data.put("targetUserName", user.getName());
            data.put("messagePreview", truncatePreview(sanitizedMessage));
            auditService.logCreate("CHAT", message.getId(), "Admin to: " + user.getName(), data, admin, request);

            return message;

        } catch (SQLException e) {
            throw new ServiceException("Gagal mengirim balasan: " + e.getMessage(), e);
        }
    }

    /**
     * Get chat thread for a user
     */
    public List<ChatMessage> getUserThread(Integer userId) throws ServiceException {
        if (userId == null) {
            throw new ServiceException("User ID tidak valid");
        }

        try {
            return chatDAO.findByUserId(userId);
        } catch (SQLException e) {
            throw new ServiceException("Gagal mengambil pesan: " + e.getMessage(), e);
        }
    }

    /**
     * Get all chat threads for admin
     */
    public List<ChatMessage> getAllThreadsForAdmin() throws ServiceException {
        try {
            return chatDAO.findAllThreads();
        } catch (SQLException e) {
            throw new ServiceException("Gagal mengambil threads: " + e.getMessage(), e);
        }
    }

    /**
     * Mark messages as read
     */
    public int markAsRead(Integer userId, String senderType) throws ServiceException {
        if (userId == null) {
            throw new ServiceException("User ID tidak valid");
        }
        if (senderType == null || (!senderType.equals("user") && !senderType.equals("admin"))) {
            throw new ServiceException("Sender type tidak valid");
        }

        try {
            return chatDAO.markAllAsRead(userId, senderType);
        } catch (SQLException e) {
            throw new ServiceException("Gagal menandai pesan: " + e.getMessage(), e);
        }
    }

    /**
     * Get unread count for a user (messages from admin)
     */
    public int getUnreadCountForUser(Integer userId) throws ServiceException {
        if (userId == null) {
            return 0;
        }

        try {
            return chatDAO.countUnreadForUser(userId);
        } catch (SQLException e) {
            throw new ServiceException("Gagal menghitung pesan: " + e.getMessage(), e);
        }
    }

    /**
     * Get total unread count for admin (from all users)
     */
    public int getUnreadCountForAdmin() throws ServiceException {
        try {
            return chatDAO.countUnreadForAdmin();
        } catch (SQLException e) {
            throw new ServiceException("Gagal menghitung pesan: " + e.getMessage(), e);
        }
    }

    /**
     * Get unread count from a specific user (for admin view)
     */
    public int getUnreadCountFromUser(Integer userId) throws ServiceException {
        if (userId == null) {
            return 0;
        }

        try {
            return chatDAO.countUnreadFromUser(userId);
        } catch (SQLException e) {
            throw new ServiceException("Gagal menghitung pesan: " + e.getMessage(), e);
        }
    }

    /**
     * Get last message for a user thread
     */
    public ChatMessage getLastMessage(Integer userId) throws ServiceException {
        if (userId == null) {
            return null;
        }

        try {
            return chatDAO.getLastMessage(userId);
        } catch (SQLException e) {
            throw new ServiceException("Gagal mengambil pesan: " + e.getMessage(), e);
        }
    }

    /**
     * Delete all messages for a user (admin only)
     */
    public int deleteUserThread(Integer userId, User admin, HttpServletRequest request) throws ServiceException {
        if (userId == null) {
            throw new ServiceException("User ID tidak valid");
        }
        if (admin == null || !admin.isAdmin()) {
            throw new ServiceException("Hanya admin yang dapat menghapus thread");
        }

        try {
            User user = userDAO.findById(userId);
            String userName = user != null ? user.getName() : "User #" + userId;

            int deleted = chatDAO.deleteByUserId(userId);

            // Audit log
            Map<String, Object> data = new HashMap<>();
            data.put("userId", userId);
            data.put("userName", userName);
            data.put("deletedCount", deleted);
            auditService.logDelete("CHAT", userId, "Thread: " + userName, admin, request);

            return deleted;

        } catch (SQLException e) {
            throw new ServiceException("Gagal menghapus thread: " + e.getMessage(), e);
        }
    }

    /**
     * Sanitize message text (basic XSS prevention)
     */
    private String sanitizeMessage(String message) {
        if (message == null) return null;

        return message
                .replace("&", "&amp;")
                .replace("<", "&lt;")
                .replace(">", "&gt;")
                .replace("\"", "&quot;")
                .replace("'", "&#x27;");
    }

    /**
     * Truncate message for preview
     */
    private String truncatePreview(String message) {
        if (message == null) return null;
        return message.length() > 50 ? message.substring(0, 50) + "..." : message;
    }

    /**
     * Check rate limit for message sending
     */
    private void checkRateLimit(String key) throws ServiceException {
        // Periodic cleanup
        if (cleanupCounter.incrementAndGet() % CLEANUP_INTERVAL == 0) {
            cleanupRateStore();
        }

        MessageRateRecord record = messageRateStore.computeIfAbsent(key, k -> new MessageRateRecord());

        synchronized (record) {
            long now = System.currentTimeMillis();

            // Reset if window expired
            if (now - record.windowStart > 60000) {
                record.count = 0;
                record.windowStart = now;
            }

            // Check limit
            if (record.count >= MAX_MESSAGES_PER_MINUTE) {
                throw new ServiceException("Terlalu banyak pesan. Tunggu beberapa saat dan coba lagi.");
            }

            record.count++;
        }
    }

    /**
     * Cleanup old rate limit records
     */
    private void cleanupRateStore() {
        long now = System.currentTimeMillis();
        messageRateStore.entrySet().removeIf(entry -> {
            MessageRateRecord record = entry.getValue();
            synchronized (record) {
                return now - record.windowStart > 120000; // Remove records older than 2 minutes
            }
        });
    }

    /**
     * Export chat thread to text format
     */
    public String exportThreadAsText(Integer userId) throws ServiceException {
        if (userId == null) {
            throw new ServiceException("User ID tidak valid");
        }

        try {
            User user = userDAO.findById(userId);
            if (user == null) {
                throw new ServiceException("User tidak ditemukan");
            }

            List<ChatMessage> messages = chatDAO.findByUserId(userId);
            if (messages == null || messages.isEmpty()) {
                throw new ServiceException("Tidak ada pesan untuk di-export");
            }

            StringBuilder sb = new StringBuilder();
            sb.append("=".repeat(60)).append("\n");
            sb.append("CHAT EXPORT - EXAMORA\n");
            sb.append("=".repeat(60)).append("\n\n");

            sb.append("User: ").append(user.getName()).append("\n");
            sb.append("Email: ").append(user.getEmail()).append("\n");
            sb.append("Export Date: ").append(java.time.LocalDateTime.now().format(
                java.time.format.DateTimeFormatter.ofPattern("dd MMM yyyy HH:mm:ss"))).append("\n");
            sb.append("Total Messages: ").append(messages.size()).append("\n");
            sb.append("\n").append("-".repeat(60)).append("\n");
            sb.append("MESSAGES\n");
            sb.append("-".repeat(60)).append("\n\n");

            java.time.format.DateTimeFormatter dateFormatter =
                java.time.format.DateTimeFormatter.ofPattern("dd MMM yyyy HH:mm:ss")
                    .withZone(java.time.ZoneId.of("Asia/Jakarta"));

            for (ChatMessage msg : messages) {
                String sender = "user".equals(msg.getSenderType()) ? user.getName() : "Admin";
                String time = msg.getCreatedAt() != null ?
                    dateFormatter.format(msg.getCreatedAt().atZone(java.time.ZoneId.systemDefault())) : "-";

                sb.append("[").append(time).append("]\n");
                sb.append(sender).append(":\n");
                sb.append(msg.getMessageText()).append("\n");
                sb.append("\n");
            }

            sb.append("-".repeat(60)).append("\n");
            sb.append("End of Export\n");
            sb.append("-".repeat(60)).append("\n");

            return sb.toString();

        } catch (SQLException e) {
            throw new ServiceException("Gagal export chat: " + e.getMessage(), e);
        }
    }

    /**
     * Inner class for rate limiting
     */
    private static class MessageRateRecord {
        int count;
        long windowStart;

        MessageRateRecord() {
            this.count = 0;
            this.windowStart = System.currentTimeMillis();
        }
    }

    /**
     * Service Exception
     */
    public static class ServiceException extends Exception {
        public ServiceException(String message) {
            super(message);
        }

        public ServiceException(String message, Throwable cause) {
            super(message, cause);
        }
    }
}

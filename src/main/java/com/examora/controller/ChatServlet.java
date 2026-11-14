package com.examora.controller;

import com.examora.dao.SettingsDAO;
import com.examora.model.ChatMessage;
import com.examora.model.User;
import com.examora.service.ChatService;
import com.examora.util.ValidationUtil;
import com.google.gson.Gson;
import com.google.gson.GsonBuilder;

import jakarta.servlet.ServletException;
import jakarta.servlet.annotation.WebServlet;
import jakarta.servlet.http.HttpServlet;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;
import java.io.IOException;
import java.io.PrintWriter;
import java.util.HashMap;
import java.util.List;
import java.util.Map;
import java.util.logging.Level;
import java.util.logging.Logger;

/**
 * Chat Servlet - Handles chat operations for users and admins
 */
@WebServlet("/ChatServlet")
public class ChatServlet extends HttpServlet {
    private static final Logger logger = Logger.getLogger(ChatServlet.class.getName());
    private static final Gson gson = new GsonBuilder().create();
    private ChatService chatService;
    private SettingsDAO settingsDAO;

    @Override
    public void init() throws ServletException {
        try {
            chatService = new ChatService();
            settingsDAO = new SettingsDAO();
        } catch (Exception e) {
            logger.log(Level.SEVERE, "Failed to initialize ChatService: " + e.getMessage(), e);
            throw new ServletException("Failed to initialize ChatService", e);
        }
    }

    @Override
    protected void doGet(HttpServletRequest request, HttpServletResponse response)
            throws ServletException, IOException {
        // Check authentication
        User user = (User) request.getSession().getAttribute("user");
        if (user == null) {
            if (isAjaxRequest(request)) {
                sendJsonError(response, "Unauthorized", HttpServletResponse.SC_UNAUTHORIZED);
            } else {
                response.sendRedirect(request.getContextPath() + "/LoginServlet");
            }
            return;
        }

        // Check if chat is enabled (skip for admin)
        if (!user.isAdmin() && !settingsDAO.isChatEnabled()) {
            if (isAjaxRequest(request)) {
                sendJsonError(response, "Fitur chat dinonaktifkan oleh admin", HttpServletResponse.SC_FORBIDDEN);
            } else {
                request.setAttribute("error", "Fitur chat dinonaktifkan oleh admin.");
                request.getRequestDispatcher("/user/dashboard.jsp").forward(request, response);
            }
            return;
        }

        String action = request.getParameter("action");

        try {
            switch (action != null ? action : "thread") {
                case "thread":
                    getThread(request, response, user);
                    break;
                case "threads":
                    getAllThreads(request, response, user);
                    break;
                case "unread":
                    getUnreadCount(request, response, user);
                    break;
                default:
                    getThread(request, response, user);
            }
        } catch (ChatService.ServiceException e) {
            logger.log(Level.WARNING, "Chat service error: " + e.getMessage(), e);
            if (isAjaxRequest(request)) {
                sendJsonError(response, e.getMessage(), HttpServletResponse.SC_BAD_REQUEST);
            } else {
                request.setAttribute("error", e.getMessage());
                forwardToPage(request, response, user);
            }
        } catch (Exception e) {
            logger.log(Level.SEVERE, "Unexpected error in chat: " + e.getMessage(), e);
            if (isAjaxRequest(request)) {
                sendJsonError(response, "Terjadi kesalahan pada server. Silakan coba lagi nanti.", HttpServletResponse.SC_INTERNAL_SERVER_ERROR);
            } else {
                request.setAttribute("error", "Terjadi kesalahan pada server. Silakan coba lagi nanti.");
                forwardToPage(request, response, user);
            }
        }
    }

    @Override
    protected void doPost(HttpServletRequest request, HttpServletResponse response)
            throws ServletException, IOException {
        // Set character encoding
        request.setCharacterEncoding("UTF-8");
        response.setCharacterEncoding("UTF-8");

        // Check authentication
        User user = (User) request.getSession().getAttribute("user");
        if (user == null) {
            if (isAjaxRequest(request)) {
                sendJsonError(response, "Unauthorized", HttpServletResponse.SC_UNAUTHORIZED);
            } else {
                response.sendRedirect(request.getContextPath() + "/LoginServlet");
            }
            return;
        }

        // Check if chat is enabled for non-admin users
        if (!user.isAdmin() && !settingsDAO.isChatEnabled()) {
            if (isAjaxRequest(request)) {
                sendJsonError(response, "Fitur chat dinonaktifkan oleh admin", HttpServletResponse.SC_FORBIDDEN);
            } else {
                request.setAttribute("error", "Fitur chat dinonaktifkan oleh admin.");
                request.getRequestDispatcher("/user/dashboard.jsp").forward(request, response);
            }
            return;
        }

        // Note: CSRF validation is handled by CSRFProtectionFilter

        String action = request.getParameter("action");

        try {
            switch (action != null ? action : "") {
                case "send":
                    sendMessage(request, response, user);
                    break;
                case "reply":
                    replyMessage(request, response, user);
                    break;
                case "markRead":
                    markAsRead(request, response, user);
                    break;
                case "deleteThread":
                    deleteThread(request, response, user);
                    break;
                case "exportThread":
                    exportThread(request, response, user);
                    break;
                default:
                    if (isAjaxRequest(request)) {
                        sendJsonError(response, "Invalid action", HttpServletResponse.SC_BAD_REQUEST);
                    } else {
                        response.sendRedirect(request.getContextPath() + "/ChatServlet");
                    }
            }
        } catch (ChatService.ServiceException e) {
            logger.log(Level.WARNING, "Chat service error: " + e.getMessage(), e);
            if (isAjaxRequest(request)) {
                sendJsonError(response, e.getMessage(), HttpServletResponse.SC_BAD_REQUEST);
            } else {
                request.setAttribute("error", e.getMessage());
                forwardToPage(request, response, user);
            }
        } catch (Exception e) {
            logger.log(Level.SEVERE, "Unexpected error in chat: " + e.getMessage(), e);
            if (isAjaxRequest(request)) {
                sendJsonError(response, "Terjadi kesalahan pada server. Silakan coba lagi nanti.", HttpServletResponse.SC_INTERNAL_SERVER_ERROR);
            } else {
                request.setAttribute("error", "Terjadi kesalahan pada server. Silakan coba lagi nanti.");
                forwardToPage(request, response, user);
            }
        }
    }

    /**
     * Get chat thread
     * - For user: their own thread
     * - For admin: thread of a specific user (requires userId parameter)
     */
    private void getThread(HttpServletRequest request, HttpServletResponse response, User user)
            throws ServletException, IOException, ChatService.ServiceException {

        Integer targetUserId;
        List<ChatMessage> messages;

        if (user.isAdmin()) {
            // Admin viewing a specific user's thread
            String userIdStr = request.getParameter("userId");
            if (userIdStr == null || userIdStr.isEmpty()) {
                // No userId specified, redirect to threads list
                response.sendRedirect(request.getContextPath() + "/ChatServlet?action=threads");
                return;
            }

            try {
                targetUserId = Integer.parseInt(userIdStr);
            } catch (NumberFormatException e) {
                throw new ChatService.ServiceException("User ID tidak valid");
            }

            messages = chatService.getUserThread(targetUserId);

            // Mark user messages as read when admin views
            chatService.markAsRead(targetUserId, "user");

            request.setAttribute("targetUserId", targetUserId);

            // Get target user info
            request.setAttribute("threads", chatService.getAllThreadsForAdmin());

        } else {
            // Regular user viewing their own thread
            targetUserId = user.getId();
            messages = chatService.getUserThread(targetUserId);

            // Mark admin messages as read when user views
            chatService.markAsRead(targetUserId, "admin");
        }

        request.setAttribute("messages", messages);
        request.setAttribute("unreadCount", getUnreadCountForRole(user));

        forwardToPage(request, response, user);
    }

    /**
     * Get all threads (admin only)
     */
    private void getAllThreads(HttpServletRequest request, HttpServletResponse response, User user)
            throws ServletException, IOException, ChatService.ServiceException {

        if (!user.isAdmin()) {
            response.sendRedirect(request.getContextPath() + "/ChatServlet");
            return;
        }

        List<ChatMessage> threads = chatService.getAllThreadsForAdmin();
        request.setAttribute("threads", threads);
        request.setAttribute("unreadCount", chatService.getUnreadCountForAdmin());

        request.getRequestDispatcher("/admin/chat.jsp").forward(request, response);
    }

    /**
     * Get unread count (JSON response)
     */
    private void getUnreadCount(HttpServletRequest request, HttpServletResponse response, User user)
            throws ServletException, IOException, ChatService.ServiceException {

        int unreadCount = getUnreadCountForRole(user);

        Map<String, Object> result = new HashMap<>();
        result.put("success", true);
        result.put("unreadCount", unreadCount);

        sendJsonResponse(response, result);
    }

    /**
     * Send message from user to admin
     */
    private void sendMessage(HttpServletRequest request, HttpServletResponse response, User user)
            throws ServletException, IOException, ChatService.ServiceException {

        if (user.isAdmin()) {
            throw new ChatService.ServiceException("Admin tidak dapat menggunakan aksi ini");
        }

        String messageText = ValidationUtil.trim(request.getParameter("message"));

        // Validate message
        if (!ValidationUtil.isValidChatMessage(messageText)) {
            throw new ChatService.ServiceException("Pesan tidak valid (1-5000 karakter)");
        }

        // Check for potential attacks
        if (ValidationUtil.containsXss(messageText)) {
            throw new ChatService.ServiceException("Pesan mengandung konten yang tidak diizinkan");
        }

        ChatMessage message = chatService.sendMessage(user.getId(), messageText, request);

        if (isAjaxRequest(request)) {
            Map<String, Object> result = new HashMap<>();
            result.put("success", true);
            result.put("message", messageToMap(message));
            sendJsonResponse(response, result);
        } else {
            request.setAttribute("success", "Pesan berhasil dikirim");
            response.sendRedirect(request.getContextPath() + "/ChatServlet");
        }
    }

    /**
     * Reply to user from admin
     */
    private void replyMessage(HttpServletRequest request, HttpServletResponse response, User user)
            throws ServletException, IOException, ChatService.ServiceException {

        if (!user.isAdmin()) {
            throw new ChatService.ServiceException("Hanya admin yang dapat membalas pesan");
        }

        String userIdStr = request.getParameter("userId");
        String messageText = ValidationUtil.trim(request.getParameter("message"));

        // Validate user ID
        Integer targetUserId = ValidationUtil.validateId(userIdStr);
        if (targetUserId == null) {
            throw new ChatService.ServiceException("User ID tidak valid");
        }

        // Validate message
        if (!ValidationUtil.isValidChatMessage(messageText)) {
            throw new ChatService.ServiceException("Pesan tidak valid (1-5000 karakter)");
        }

        // Check for potential attacks
        if (ValidationUtil.containsXss(messageText)) {
            throw new ChatService.ServiceException("Pesan mengandung konten yang tidak diizinkan");
        }

        ChatMessage message = chatService.replyMessage(targetUserId, user.getId(), messageText, request);

        if (isAjaxRequest(request)) {
            Map<String, Object> result = new HashMap<>();
            result.put("success", true);
            result.put("message", messageToMap(message));
            sendJsonResponse(response, result);
        } else {
            request.setAttribute("success", "Balasan berhasil dikirim");
            response.sendRedirect(request.getContextPath() + "/ChatServlet?action=thread&userId=" + targetUserId);
        }
    }

    /**
     * Mark messages as read
     */
    private void markAsRead(HttpServletRequest request, HttpServletResponse response, User user)
            throws ServletException, IOException, ChatService.ServiceException {

        String userIdStr = request.getParameter("userId");
        String senderType = request.getParameter("senderType");

        Integer targetUserId;
        if (user.isAdmin()) {
            if (userIdStr == null || userIdStr.isEmpty()) {
                throw new ChatService.ServiceException("User ID diperlukan");
            }
            try {
                targetUserId = Integer.parseInt(userIdStr);
            } catch (NumberFormatException e) {
                throw new ChatService.ServiceException("User ID tidak valid");
            }
            // Admin marks user messages as read
            if (senderType == null) senderType = "user";
        } else {
            targetUserId = user.getId();
            // User marks admin messages as read
            if (senderType == null) senderType = "admin";
        }

        int updated = chatService.markAsRead(targetUserId, senderType);

        Map<String, Object> result = new HashMap<>();
        result.put("success", true);
        result.put("updatedCount", updated);
        sendJsonResponse(response, result);
    }

    /**
     * Delete chat thread (admin only)
     */
    private void deleteThread(HttpServletRequest request, HttpServletResponse response, User user)
            throws ServletException, IOException, ChatService.ServiceException {

        if (!user.isAdmin()) {
            throw new ChatService.ServiceException("Hanya admin yang dapat menghapus thread");
        }

        String userIdStr = request.getParameter("userId");
        if (userIdStr == null || userIdStr.isEmpty()) {
            throw new ChatService.ServiceException("User ID diperlukan");
        }

        Integer targetUserId;
        try {
            targetUserId = Integer.parseInt(userIdStr);
        } catch (NumberFormatException e) {
            throw new ChatService.ServiceException("User ID tidak valid");
        }

        int deleted = chatService.deleteUserThread(targetUserId, user, request);

        if (isAjaxRequest(request)) {
            Map<String, Object> result = new HashMap<>();
            result.put("success", true);
            result.put("deletedCount", deleted);
            result.put("message", "Thread berhasil dihapus");
            sendJsonResponse(response, result);
        } else {
            request.setAttribute("success", "Thread chat berhasil dihapus (" + deleted + " pesan)");
            response.sendRedirect(request.getContextPath() + "/ChatServlet?action=threads");
        }
    }

    /**
     * Export chat thread to text file (admin only)
     */
    private void exportThread(HttpServletRequest request, HttpServletResponse response, User user)
            throws ServletException, IOException, ChatService.ServiceException {

        if (!user.isAdmin()) {
            throw new ChatService.ServiceException("Hanya admin yang dapat export thread");
        }

        String userIdStr = request.getParameter("userId");
        if (userIdStr == null || userIdStr.isEmpty()) {
            throw new ChatService.ServiceException("User ID diperlukan");
        }

        Integer targetUserId;
        try {
            targetUserId = Integer.parseInt(userIdStr);
        } catch (NumberFormatException e) {
            throw new ChatService.ServiceException("User ID tidak valid");
        }

        String exportContent = chatService.exportThreadAsText(targetUserId);

        // Set response headers for file download
        response.setContentType("text/plain");
        response.setCharacterEncoding("UTF-8");
        response.setHeader("Content-Disposition", "attachment; filename=\"chat_export_user_" + targetUserId + "_" +
            java.time.LocalDate.now().format(java.time.format.DateTimeFormatter.ofPattern("yyyyMMdd")) + ".txt\"");

        try (PrintWriter out = response.getWriter()) {
            out.print(exportContent);
            out.flush();
        }
    }

    /**
     * Get unread count based on user role
     */
    private int getUnreadCountForRole(User user) throws ChatService.ServiceException {
        if (user.isAdmin()) {
            return chatService.getUnreadCountForAdmin();
        } else {
            return chatService.getUnreadCountForUser(user.getId());
        }
    }

    /**
     * Forward to appropriate page based on user role
     */
    private void forwardToPage(HttpServletRequest request, HttpServletResponse response, User user)
            throws ServletException, IOException {
        if (user.isAdmin()) {
            request.getRequestDispatcher("/admin/chat.jsp").forward(request, response);
        } else {
            request.getRequestDispatcher("/user/chat.jsp").forward(request, response);
        }
    }

    /**
     * Check if request is AJAX
     */
    private boolean isAjaxRequest(HttpServletRequest request) {
        return "XMLHttpRequest".equals(request.getHeader("X-Requested-With")) ||
               "true".equals(request.getParameter("ajax"));
    }

    /**
     * Send JSON response
     */
    private void sendJsonResponse(HttpServletResponse response, Map<String, Object> data)
            throws IOException {
        response.setContentType("application/json");
        response.setCharacterEncoding("UTF-8");
        try (PrintWriter out = response.getWriter()) {
            out.print(gson.toJson(data));
            out.flush();
        }
    }

    /**
     * Send JSON error response
     */
    private void sendJsonError(HttpServletResponse response, String message, int statusCode)
            throws IOException {
        response.setStatus(statusCode);
        Map<String, Object> error = new HashMap<>();
        error.put("success", false);
        error.put("error", message);
        sendJsonResponse(response, error);
    }

    /**
     * Convert ChatMessage to Map for JSON serialization
     */
    private Map<String, Object> messageToMap(ChatMessage message) {
        Map<String, Object> map = new HashMap<>();
        map.put("id", message.getId());
        map.put("userId", message.getUserId());
        map.put("senderType", message.getSenderType());
        map.put("adminId", message.getAdminId());
        map.put("messageText", message.getMessageText());
        map.put("isRead", message.getIsRead());
        map.put("senderName", message.getSenderName());
        map.put("senderPhoto", message.getSenderPhoto());
        map.put("timeAgo", message.getTimeAgo());
        map.put("formattedTime", message.getFormattedTime());
        map.put("formattedDateTime", message.getFormattedDateTime());
        map.put("fromUser", message.isFromUser());
        map.put("fromAdmin", message.isFromAdmin());
        return map;
    }
}

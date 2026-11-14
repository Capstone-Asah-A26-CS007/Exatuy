<%@ page contentType="text/html;charset=UTF-8" language="java" %>
<%@ taglib prefix="c" uri="http://java.sun.com/jsp/jstl/core" %>
<%@ page import="com.examora.model.User" %>
<%@ page import="com.examora.model.ChatMessage" %>
<%@ page import="com.examora.util.ValidationUtil" %>
<%@ page import="java.util.List" %>
<%
    User currentUser = (User) session.getAttribute("user");
    if (currentUser == null) {
        response.sendRedirect("../LoginServlet");
        return;
    }
    if (!currentUser.isAdmin()) {
        response.sendRedirect("../ExamServlet?action=dashboard");
        return;
    }

    List<ChatMessage> threads = (List<ChatMessage>) request.getAttribute("threads");
    List<ChatMessage> messages = (List<ChatMessage>) request.getAttribute("messages");
    Integer targetUserId = (Integer) request.getAttribute("targetUserId");
    Integer unreadCount = (Integer) request.getAttribute("unreadCount");
    String success = (String) request.getAttribute("success");
    String error = (String) request.getAttribute("error");

    // Generate CSRF token
    String csrfToken = (String) session.getAttribute("csrfToken");
    if (csrfToken == null) {
        csrfToken = java.util.UUID.randomUUID().toString();
        session.setAttribute("csrfToken", csrfToken);
    }
%>
<!DOCTYPE html>
<html lang="id">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Chat Support - Exatuy Admin</title>
    <link href="https://cdn.jsdelivr.net/npm/bootstrap@5.3.0/dist/css/bootstrap.min.css" rel="stylesheet">
    <link href="https://cdn.jsdelivr.net/npm/bootstrap-icons@1.10.0/font/bootstrap-icons.css" rel="stylesheet">
    <link href="../assets/css/style.css" rel="stylesheet">
    <link href="../assets/css/admin-style.css" rel="stylesheet">
    <link rel="icon" type="image/svg+xml" type="image/svg+xml" href="../assets/img/favicon.svg?v=3">
    <style>
        .chat-layout {
            display: flex;
            height: calc(100vh - 100px);
            min-height: 500px;
        }
        .threads-sidebar {
            width: 300px;
            border-right: 1px solid #dee2e6;
            overflow-y: auto;
            background-color: #f8f9fa;
        }
        .chat-main {
            flex: 1;
            display: flex;
            flex-direction: column;
            background-color: white;
        }
        .thread-item {
            padding: 1rem;
            border-bottom: 1px solid #dee2e6;
            cursor: pointer;
            transition: background-color 0.2s;
        }
        .thread-item:hover {
            background-color: #e9ecef;
        }
        .thread-item.active {
            background-color: #cfe2ff;
            border-left: 3px solid #0d6efd;
        }
        .thread-avatar {
            width: 40px;
            height: 40px;
            border-radius: 50%;
            background-color: #6c757d;
            display: flex;
            align-items: center;
            justify-content: center;
            color: white;
            font-weight: bold;
        }
        .thread-preview {
            font-size: 0.85rem;
            color: #6c757d;
            white-space: nowrap;
            overflow: hidden;
            text-overflow: ellipsis;
        }
        .chat-header {
            padding: 1rem;
            border-bottom: 1px solid #dee2e6;
            background-color: #f8f9fa;
        }
        .chat-messages {
            flex: 1;
            overflow-y: auto;
            padding: 1rem;
            background-color: #f8f9fa;
        }
        .message-bubble {
            max-width: 70%;
            padding: 0.75rem 1rem;
            border-radius: 1rem;
            margin-bottom: 0.75rem;
            word-wrap: break-word;
        }
        .message-user {
            background-color: white;
            border: 1px solid #dee2e6;
            border-bottom-left-radius: 0.25rem;
        }
        .message-admin {
            background-color: #0d6efd;
            color: white;
            margin-left: auto;
            border-bottom-right-radius: 0.25rem;
        }
        .message-time {
            font-size: 0.7rem;
            opacity: 0.7;
        }
        .message-sender {
            font-weight: 600;
            font-size: 0.8rem;
            margin-bottom: 0.25rem;
        }
        .message-user .message-sender {
            color: #0d6efd;
        }
        .chat-input-area {
            padding: 1rem;
            border-top: 1px solid #dee2e6;
            background-color: white;
        }
        .unread-badge {
            min-width: 20px;
            height: 20px;
            font-size: 0.7rem;
        }
        .empty-chat {
            display: flex;
            flex-direction: column;
            align-items: center;
            justify-content: center;
            height: 100%;
            color: #6c757d;
        }
        .empty-chat i {
            font-size: 5rem;
            opacity: 0.3;
            margin-bottom: 1rem;
        }
        @media (max-width: 768px) {
            .chat-layout {
                flex-direction: column;
                height: auto;
            }
            .threads-sidebar {
                width: 100%;
                max-height: 300px;
            }
            .chat-main {
                min-height: 400px;
            }
        }
    </style>
<link href="../assets/css/handdrawn.css" rel="stylesheet">
</head>
<body>
    <div class="d-flex">
        <%@ include file="sidebar.jsp" %>

        <!-- Main Content -->
        <div class="main-content flex-grow-1">
            <div class="container-fluid p-4">
                <!-- Page Header -->
                <div class="d-flex justify-content-between align-items-center mb-4">
                    <div>
                        <h4 class="mb-1">
                            <i class="bi bi-chat-dots me-2"></i>Chat Support
                        </h4>
                        <small class="text-muted">Kelola percakapan dengan user</small>
                    </div>
                    <% if (unreadCount != null && unreadCount > 0) { %>
                    <span class="badge bg-danger"><%= unreadCount %> pesan belum dibaca</span>
                    <% } %>
                </div>

                <% if (success != null) { %>
                <div class="alert alert-success alert-dismissible fade show">
                    <i class="bi bi-check-circle me-2"></i><%= ValidationUtil.sanitizeHtml(success) %>
                    <button type="button" class="btn-close" data-bs-dismiss="alert"></button>
                </div>
                <% } %>

                <% if (error != null) { %>
                <div class="alert alert-danger alert-dismissible fade show">
                    <i class="bi bi-exclamation-triangle me-2"></i><%= ValidationUtil.sanitizeHtml(error) %>
                    <button type="button" class="btn-close" data-bs-dismiss="alert"></button>
                </div>
                <% } %>

                <!-- Chat Layout -->
                <div class="card border-0 shadow-sm">
                    <div class="chat-layout rounded">
                        <!-- Threads Sidebar -->
                        <div class="threads-sidebar rounded-start">
                            <div class="p-3 border-bottom bg-white">
                                <h6 class="mb-0">
                                    <i class="bi bi-people me-2"></i>Daftar Percakapan
                                </h6>
                            </div>
                            <% if (threads != null && !threads.isEmpty()) { %>
                                <% for (ChatMessage thread : threads) { %>
                                <a href="../ChatServlet?action=thread&userId=<%= thread.getUserId() %>"
                                   class="thread-item text-decoration-none text-dark d-block <%= targetUserId != null && targetUserId.equals(thread.getUserId()) ? "active" : "" %>">
                                    <div class="d-flex align-items-center">
                                        <div class="thread-avatar me-3">
                                            <%= ValidationUtil.sanitizeHtml(thread.getSenderName() != null ? thread.getSenderName().substring(0, 1).toUpperCase() : "U") %>
                                        </div>
                                        <div class="flex-grow-1 overflow-hidden">
                                            <div class="d-flex justify-content-between align-items-center">
                                                <strong class="text-truncate"><%= ValidationUtil.sanitizeHtml(thread.getSenderName() != null ? thread.getSenderName() : "User") %></strong>
                                                <small class="text-muted"><%= ValidationUtil.sanitizeHtml(thread.getTimeAgo()) %></small>
                                            </div>
                                            <div class="thread-preview">
                                                <%= thread.isFromUser() ? "" : "Anda: " %><%= ValidationUtil.sanitizeHtml(thread.getMessageText()) %>
                                            </div>
                                        </div>
                                        <% try {
                                            int unread = new com.examora.service.ChatService().getUnreadCountFromUser(thread.getUserId());
                                            if (unread > 0) { %>
                                            <span class="badge bg-danger unread-badge ms-2"><%= unread %></span>
                                        <% } } catch (Exception e) { } %>
                                    </div>
                                </a>
                                <% } %>
                            <% } else { %>
                                <div class="p-4 text-center text-muted">
                                    <i class="bi bi-chat-square d-block fs-1 mb-2 opacity-50"></i>
                                    <small>Belum ada percakapan</small>
                                </div>
                            <% } %>
                        </div>

                        <!-- Chat Main Area -->
                        <div class="chat-main rounded-end">
                            <% if (targetUserId != null && messages != null) { %>
                                <!-- Chat Header -->
                                <div class="chat-header">
                                    <div class="d-flex align-items-center justify-content-between">
                                        <div class="d-flex align-items-center">
                                            <% ChatMessage lastThread = null;
                                               if (threads != null) {
                                                   for (ChatMessage t : threads) {
                                                       if (t.getUserId().equals(targetUserId)) {
                                                           lastThread = t;
                                                           break;
                                                       }
                                                   }
                                               }
                                            %>
                                            <div class="thread-avatar me-3">
                                                <%= ValidationUtil.sanitizeHtml(lastThread != null && lastThread.getSenderName() != null ? lastThread.getSenderName().substring(0, 1).toUpperCase() : "U") %>
                                            </div>
                                            <div>
                                                <h6 class="mb-0"><%= ValidationUtil.sanitizeHtml(lastThread != null && lastThread.getSenderName() != null ? lastThread.getSenderName() : "User") %></h6>
                                                <small class="text-muted">User ID: <%= targetUserId %></small>
                                            </div>
                                        </div>
                                        <div class="btn-group btn-group-sm">
                                            <a href="../ChatServlet?action=exportThread&userId=<%= targetUserId %>"
                                               class="btn btn-outline-success" title="Export Chat">
                                                <i class="bi bi-download"></i> Export
                                            </a>
                                            <button type="button" class="btn btn-outline-danger"
                                                    onclick="confirmDeleteThread(<%= targetUserId %>)" title="Hapus Thread">
                                                <i class="bi bi-trash"></i> Hapus
                                            </button>
                                        </div>
                                    </div>
                                </div>

                                <!-- Chat Messages -->
                                <div class="chat-messages" id="chatMessages">
                                    <% if (!messages.isEmpty()) { %>
                                        <% for (ChatMessage msg : messages) { %>
                                        <div class="d-flex <%= msg.isFromAdmin() ? "justify-content-end" : "justify-content-start" %>">
                                            <div class="message-bubble <%= msg.isFromAdmin() ? "message-admin" : "message-user" %>">
                                                <% if (msg.isFromUser()) { %>
                                                <div class="message-sender">
                                                    <i class="bi bi-person me-1"></i><%= ValidationUtil.sanitizeHtml(msg.getSenderName() != null ? msg.getSenderName() : "User") %>
                                                </div>
                                                <% } %>
                                                <div class="message-text"><%= ValidationUtil.sanitizeHtml(msg.getMessageText()) %></div>
                                                <div class="message-time text-end mt-1">
                                                    <%= ValidationUtil.sanitizeHtml(msg.getFormattedDateTime()) %>
                                                </div>
                                            </div>
                                        </div>
                                        <% } %>
                                    <% } else { %>
                                        <div class="empty-chat">
                                            <i class="bi bi-chat-dots"></i>
                                            <p>Belum ada pesan</p>
                                        </div>
                                    <% } %>
                                </div>

                                <!-- Chat Input -->
                                <div class="chat-input-area">
                                    <form id="chatForm" method="post" action="../ChatServlet?action=reply">
                                        <input type="hidden" name="csrfToken" value="<%= csrfToken %>">
                                        <input type="hidden" name="userId" value="<%= targetUserId %>">
                                        <div class="input-group">
                                            <input type="text" class="form-control" id="messageInput" name="message"
                                                   placeholder="Ketik balasan Anda..." required maxlength="5000"
                                                   autocomplete="off">
                                            <button type="submit" class="btn btn-primary" id="sendBtn">
                                                <i class="bi bi-send me-1"></i>Kirim
                                            </button>
                                        </div>
                                    </form>
                                </div>
                            <% } else { %>
                                <!-- No Thread Selected -->
                                <div class="empty-chat h-100">
                                    <i class="bi bi-chat-square-text"></i>
                                    <h5>Pilih percakapan</h5>
                                    <p>Pilih user dari daftar di sebelah kiri untuk memulai chat</p>
                                </div>
                            <% } %>
                        </div>
                    </div>
                </div>
            </div>
        </div>
    </div>

    <script src="https://cdn.jsdelivr.net/npm/bootstrap@5.3.0/dist/js/bootstrap.bundle.min.js"></script>
    <script>
        // Scroll to bottom of chat
        function scrollToBottom() {
            const chatMessages = document.getElementById('chatMessages');
            if (chatMessages) {
                chatMessages.scrollTop = chatMessages.scrollHeight;
            }
        }

        // Initial scroll
        scrollToBottom();

        // Handle form submission via AJAX
        const chatForm = document.getElementById('chatForm');
        if (chatForm) {
            chatForm.addEventListener('submit', function(e) {
                e.preventDefault();

                const messageInput = document.getElementById('messageInput');
                const csrfTokenInput = document.querySelector('input[name="csrfToken"]');
                const userIdInput = document.querySelector('input[name="userId"]');
                const message = messageInput.value.trim();
                const sendBtn = document.getElementById('sendBtn');

                if (!message) return;

                // Disable input while sending
                messageInput.disabled = true;
                sendBtn.disabled = true;

                // Use URLSearchParams for application/x-www-form-urlencoded
                const params = new URLSearchParams();
                params.append('message', message);
                params.append('csrfToken', csrfTokenInput ? csrfTokenInput.value : '');
                params.append('userId', userIdInput ? userIdInput.value : '');
                params.append('action', 'reply');

                fetch('../ChatServlet?action=reply&ajax=true', {
                    method: 'POST',
                    body: params,
                    headers: {
                        'Content-Type': 'application/x-www-form-urlencoded',
                        'X-Requested-With': 'XMLHttpRequest'
                    }
                })
                .then(response => response.json())
                .then(data => {
                    if (data.success) {
                        // Add message to chat
                        addMessageToChat(data.message);
                        messageInput.value = '';
                    } else {
                        alert(data.error || 'Gagal mengirim pesan');
                    }
                })
                .catch(error => {
                    console.error('Error:', error);
                    alert('Terjadi kesalahan. Silakan coba lagi.');
                })
                .finally(() => {
                    messageInput.disabled = false;
                    sendBtn.disabled = false;
                    messageInput.focus();
                });
            });
        }

        // Add message to chat UI
        function addMessageToChat(msg) {
            const chatMessages = document.getElementById('chatMessages');

            // Remove empty state if exists
            const emptyChat = chatMessages.querySelector('.empty-chat');
            if (emptyChat) {
                emptyChat.remove();
            }

            const messageDiv = document.createElement('div');
            messageDiv.className = 'd-flex justify-content-end';
            messageDiv.innerHTML = '<div class="message-bubble message-admin">' +
                '<div class="message-text">' + escapeHtml(msg.messageText) + '</div>' +
                '<div class="message-time text-end mt-1">' + escapeHtml(msg.formattedDateTime) + '</div>' +
                '</div>';

            chatMessages.appendChild(messageDiv);
            scrollToBottom();
        }

        // Escape HTML to prevent XSS
        function escapeHtml(text) {
            const div = document.createElement('div');
            div.textContent = text;
            return div.innerHTML;
        }

        // Enter key to send
        const messageInput = document.getElementById('messageInput');
        if (messageInput) {
            messageInput.addEventListener('keypress', function(e) {
                if (e.key === 'Enter' && !e.shiftKey) {
                    e.preventDefault();
                    if (chatForm) chatForm.dispatchEvent(new Event('submit'));
                }
            });
        }

        // Auto-refresh messages every 5 seconds
        let lastMessageId = <%= messages != null && !messages.isEmpty() ? messages.get(messages.size() - 1).getId() : 0 %>;
        const currentUserId = <%= targetUserId != null ? targetUserId : 0 %>;

        function refreshMessages() {
            if (!currentUserId) return;

            fetch('../ChatServlet?action=thread&userId=' + currentUserId + '&ajax=true&lastId=' + lastMessageId)
                .then(response => response.json())
                .then(data => {
                    if (data.success && data.messages && data.messages.length > 0) {
                        const chatMessages = document.getElementById('chatMessages');

                        // Remove empty state if exists
                        const emptyChat = chatMessages.querySelector('.empty-chat');
                        if (emptyChat) {
                            emptyChat.remove();
                        }

                        data.messages.forEach(msg => {
                            // Only add new messages
                            if (msg.id > lastMessageId) {
                                const messageDiv = document.createElement('div');
                                messageDiv.className = 'd-flex ' + (msg.senderType === 'admin' ? 'justify-content-end' : 'justify-content-start');
                                messageDiv.innerHTML = '<div class="message-bubble ' + (msg.senderType === 'admin' ? 'message-admin' : 'message-user') + '">' +
                                    (msg.senderType === 'user' ? '<div class="message-sender"><i class="bi bi-person me-1"></i>' + escapeHtml(msg.senderName || 'User') + '</div>' : '') +
                                    '<div class="message-text">' + escapeHtml(msg.messageText) + '</div>' +
                                    '<div class="message-time text-end mt-1">' + escapeHtml(msg.formattedDateTime) + '</div>' +
                                    '</div>';
                                chatMessages.appendChild(messageDiv);
                                lastMessageId = msg.id;
                            }
                        });

                        scrollToBottom();
                    }
                })
                .catch(error => console.error('Refresh error:', error));
        }

        // Start auto-refresh
        setInterval(refreshMessages, 5000);

        // Confirm delete thread
        function confirmDeleteThread(userId) {
            if (confirm('PERINGATAN!\n\nAnda yakin ingin menghapus seluruh thread chat dengan user ini?\n\nTindakan ini tidak dapat dibatalkan!')) {
                // Create form and submit
                const form = document.createElement('form');
                form.method = 'POST';
                form.action = '../ChatServlet?action=deleteThread';

                const userIdInput = document.createElement('input');
                userIdInput.type = 'hidden';
                userIdInput.name = 'userId';
                userIdInput.value = userId;
                form.appendChild(userIdInput);

                const csrfInput = document.createElement('input');
                csrfInput.type = 'hidden';
                csrfInput.name = 'csrfToken';
                csrfInput.value = document.querySelector('input[name="csrfToken"]')?.value || '';
                form.appendChild(csrfInput);

                document.body.appendChild(form);
                form.submit();
            }
        }
    </script>
</body>
</html>

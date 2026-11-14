<%@ page contentType="text/html;charset=UTF-8" language="java" %>
<%@ taglib prefix="c" uri="http://java.sun.com/jsp/jstl/core" %>
<%@ page import="com.examora.model.User" %>
<%@ page import="com.examora.model.Material" %>
<%@ page import="com.examora.model.MaterialCategory" %>
<%@ page import="com.examora.dao.SettingsDAO" %>
<%@ page import="com.examora.service.ChatService" %>
<%@ page import="com.examora.util.ValidationUtil" %>
<%@ page import="java.util.List" %>
<%
    User currentUser = (User) session.getAttribute("user");
    if (currentUser == null) { response.sendRedirect("../LoginServlet"); return; }

    List<Material> materials = (List<Material>) request.getAttribute("materials");
    List<MaterialCategory> categories = (List<MaterialCategory>) request.getAttribute("categories");
    String userTag = (String) request.getAttribute("userTag");

    boolean chatEnabled = new SettingsDAO().isChatEnabled();
    boolean fileManagementEnabled = new SettingsDAO().isFileManagementEnabled();
    int chatUnreadCount = 0;
    if (chatEnabled) {
        try { chatUnreadCount = new ChatService().getUnreadCountForUser(currentUser.getId()); } catch (Exception e) {}
    }
%>
<!DOCTYPE html>
<html lang="id">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Materi Belajar - Exatuy</title>
    <link href="https://cdn.jsdelivr.net/npm/bootstrap@5.3.0/dist/css/bootstrap.min.css" rel="stylesheet">
    <link href="https://cdn.jsdelivr.net/npm/bootstrap-icons@1.10.0/font/bootstrap-icons.css" rel="stylesheet">
    <link href="../assets/css/style.css" rel="stylesheet">
    <link rel="icon" type="image/svg+xml" href="../assets/img/favicon.svg?v=4">
<link href="../assets/css/handdrawn.css" rel="stylesheet">
</head>
<body>
    <!-- Navbar -->
    <nav class="navbar navbar-expand-md navbar-dark bg-primary">
        <div class="container">
            <a class="navbar-brand fw-bold" href="../ExamServlet?action=dashboard">
                <i class="bi bi-journal-check me-2"></i>Exatuy
            </a>
            <button class="navbar-toggler" type="button" data-bs-toggle="collapse" data-bs-target="#navbarNav">
                <span class="navbar-toggler-icon"></span>
            </button>
            <div class="collapse navbar-collapse" id="navbarNav">
                <ul class="navbar-nav me-auto">
                    <li class="nav-item">
                        <a class="nav-link" href="../ExamServlet?action=dashboard">
                            <i class="bi bi-house me-1"></i>Dashboard
                        </a>
                    </li>
                    <li class="nav-item">
                        <a class="nav-link" href="../ExamServlet?action=list">
                            <i class="bi bi-journal-text me-1"></i>Quiz Tersedia
                        </a>
                    </li>
                    <li class="nav-item">
                        <a class="nav-link active" href="../MateriServlet">
                            <i class="bi bi-book me-1"></i>Materi
                        </a>
                    </li>
                    <li class="nav-item">
                        <a class="nav-link" href="../AttendanceServlet?action=view">
                            <i class="bi bi-check2-square me-1"></i>Absensi
                        </a>
                    </li>
                    <li class="nav-item">
                        <a class="nav-link" href="../ExamServlet?action=history">
                            <i class="bi bi-clock-history me-1"></i>Riwayat
                        </a>
                    </li>
                    <li class="nav-item">
                        <a class="nav-link" href="../TranscriptServlet?action=mine">
                            <i class="bi bi-card-list me-1"></i>Transcript
                        </a>
                    </li>
                    <% if (chatEnabled) { %>
                    <li class="nav-item">
                        <a class="nav-link" href="../ChatServlet">
                            <i class="bi bi-chat-dots me-1"></i>Chat
                            <% if (chatUnreadCount > 0) { %><span class="badge bg-danger"><%= chatUnreadCount %></span><% } %>
                        </a>
                    </li>
                    <% } %>
                </ul>
                <div class="d-none d-md-flex align-items-center">
                    <div class="dropdown">
                        <a href="#" class="d-flex align-items-center text-white text-decoration-none dropdown-toggle" data-bs-toggle="dropdown">
                            <i class="bi bi-person-circle me-1 fs-5"></i>
                            <span><%= ValidationUtil.sanitizeHtml(currentUser.getName()) %></span>
                        </a>
                        <ul class="dropdown-menu dropdown-menu-end">
                            <li><a class="dropdown-item" href="../ProfileServlet"><i class="bi bi-person me-2"></i>Profil Saya</a></li>
                            <li><hr class="dropdown-divider"></li>
                            <li><a class="dropdown-item" href="../LogoutServlet"><i class="bi bi-box-arrow-left me-2"></i>Logout</a></li>
                        </ul>
                    </div>
                </div>
            </div>
        </div>
    </nav>

    <div class="container py-4">
        <div class="mb-4">
            <h2 class="mb-1"><i class="bi bi-book me-2"></i>Materi Belajar</h2>
            <p class="text-muted mb-0">
                Modul, silabus, dan artikel bacaan
                <% if (userTag != null && !userTag.trim().isEmpty()) { %>
                untuk kelas <strong><%= userTag %></strong>
                <% } %>
            </p>
        </div>

        <!-- Kategori -->
        <div class="row g-3 mb-4">
            <% if (categories != null) { for (MaterialCategory cat : categories) {
                 int count = 0;
                 if (materials != null) for (Material m : materials) if (m.getCategoryId() != null && m.getCategoryId().equals(cat.getId())) count++;
                 if (count == 0) continue;
            %>
            <div class="col-lg-3 col-md-4 col-sm-6">
                <div class="card h-100">
                    <div class="card-body">
                        <div class="d-flex justify-content-between align-items-start mb-2">
                            <span class="badge badge-primary"><%= cat.getJenjang() %></span>
                            <span class="badge bg-secondary"><%= count %></span>
                        </div>
                        <h6 class="fw-bold mb-1"><%= cat.getNama() %></h6>
                        <p class="small text-muted mb-0"><%= cat.getMataPelajaran() != null ? cat.getMataPelajaran() : "Umum" %></p>
                    </div>
                </div>
            </div>
            <% } } %>
        </div>

        <!-- Daftar materi -->
        <% if (materials == null || materials.isEmpty()) { %>
        <div class="card">
            <div class="card-body">
                <div class="empty-state">
                    <i class="bi bi-folder-x"></i>
                    <h3>Belum ada materi tersedia</h3>
                    <p class="mb-0">
                        <% if (userTag != null && !userTag.trim().isEmpty()) { %>
                        Belum ada materi untuk kelas <strong><%= userTag %></strong>. Hubungi pengajar Anda.
                        <% } else { %>
                        Materi akan muncul di sini setelah pengajar menguploadnya.
                        <% } %>
                    </p>
                </div>
            </div>
        </div>
        <% } else { %>
        <div class="row g-4">
            <% for (Material m : materials) { %>
            <div class="col-lg-4 col-md-6">
                <div class="card h-100">
                    <div class="card-body">
                        <div class="d-flex justify-content-between align-items-start mb-2">
                            <span class="badge badge-primary"><%= m.getCategoryName() != null ? m.getCategoryName() : "Materi" %></span>
                            <span class="badge bg-secondary"><%= m.getFileType() != null ? m.getFileType().toUpperCase() : "TEXT" %></span>
                        </div>
                        <h6 class="fw-bold mb-2"><%= m.getTitle() %></h6>
                        <p class="small text-muted mb-3">
                            <%= m.getSummary() != null ? m.getSummary() : "Klik untuk membaca materi lengkap." %>
                        </p>
                        <div class="d-flex gap-2">
                            <a href="../MateriServlet?action=view&id=<%= m.getId() %>" class="btn btn-sm btn-primary">
                                <i class="bi bi-book me-1"></i>Baca
                            </a>
                            <% if (m.getFilePath() != null && !m.getFilePath().isEmpty()) { %>
                            <a href="../MateriServlet?action=download&id=<%= m.getId() %>" class="btn btn-sm btn-outline-primary">
                                <i class="bi bi-download me-1"></i>Unduh
                            </a>
                            <% } %>
                        </div>
                    </div>
                    <div class="card-footer bg-transparent border-0 pt-0">
                        <small class="text-muted">
                            <i class="bi bi-eye me-1"></i><%= m.getViewCount() != null ? m.getViewCount() : 0 %> kali dibaca
                        </small>
                    </div>
                </div>
            </div>
            <% } %>
        </div>
        <% } %>
    </div>

    <script src="https://cdn.jsdelivr.net/npm/bootstrap@5.3.0/dist/js/bootstrap.bundle.min.js"></script>
</body>
</html>

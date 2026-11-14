<%@ page contentType="text/html;charset=UTF-8" language="java" %>
<%@ taglib prefix="c" uri="http://java.sun.com/jsp/jstl/core" %>
<%@ page import="com.examora.model.User" %>
<%@ page import="com.examora.model.FileItem" %>
<%@ page import="com.examora.util.ValidationUtil" %>
<%@ page import="java.util.List" %>
<%
    User currentUser = (User) session.getAttribute("user");
    if (currentUser == null) {
        response.sendRedirect("../LoginServlet");
        return;
    }
    List<FileItem> files = (List<FileItem>) request.getAttribute("files");
    String error = (String) request.getAttribute("error");
    String success = (String) request.getAttribute("success");
    String searchQuery = (String) request.getAttribute("searchQuery");
%>
<!DOCTYPE html>
<html lang="id">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Files - Exatuy</title>
    <link href="https://cdn.jsdelivr.net/npm/bootstrap@5.3.0/dist/css/bootstrap.min.css" rel="stylesheet">
    <link href="https://cdn.jsdelivr.net/npm/bootstrap-icons@1.10.0/font/bootstrap-icons.css" rel="stylesheet">
    <link href="../assets/css/style.css" rel="stylesheet">
    <link rel="icon" type="image/svg+xml" href="../assets/img/favicon.svg?v=3">
<link href="../assets/css/handdrawn.css" rel="stylesheet">
</head>
<body>
    <!-- Navbar -->
    <nav class="navbar navbar-expand-md navbar-dark bg-primary">
        <div class="container">
            <a class="navbar-brand fw-bold" href="../ExamServlet?action=dashboard">
                <i class="bi bi-journal-check me-2"></i>Exatuy
            </a>
            <button class="navbar-toggler" type="button" data-bs-toggle="collapse" data-bs-target="#navbarNav" aria-controls="navbarNav" aria-expanded="false" aria-label="Toggle navigation">
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
                        <a class="nav-link active" href="../FileManagementServlet?action=list">
                            <i class="bi bi-folder me-1"></i>Files
                        </a>
                    </li>
                    <%@ include file="custom-menu-items.jspf" %>
                </ul>
                <%-- Mobile: Profile menu items shown in nav list --%>
                    <li class="nav-item d-md-none">
                        <hr class="my-2 border-light">
                    </li>
                    <li class="nav-item d-md-none">
                        <div class="d-flex align-items-center text-white py-2">
                            <i class="bi bi-person-circle me-2 fs-5"></i>
                            <span><%= ValidationUtil.sanitizeHtml(currentUser.getName()) %></span>
                        </div>
                    </li>
                    <% if (currentUser.isAdmin()) { %>
                    <li class="nav-item d-md-none">
                        <a class="nav-link" href="../AdminServlet?action=dashboard">
                            <i class="bi bi-speedometer2 me-2"></i>Admin Dashboard
                        </a>
                    </li>
                    <% } %>
                    <li class="nav-item d-md-none">
                        <a class="nav-link" href="../ProfileServlet">
                            <i class="bi bi-person me-2"></i>Profile
                        </a>
                    </li>
                    <li class="nav-item d-md-none">
                        <a class="nav-link" href="../LogoutServlet">
                            <i class="bi bi-box-arrow-left me-2"></i>Logout
                        </a>
                    </li>
                </ul>
                <%-- Desktop: Profile dropdown shown outside nav list --%>
                <div class="d-none d-md-flex align-items-center">
                    <div class="dropdown">
                        <a href="#" class="d-flex align-items-center text-white text-decoration-none dropdown-toggle" data-bs-toggle="dropdown">
                            <i class="bi bi-person-circle me-1 fs-5"></i>
                            <span><%= ValidationUtil.sanitizeHtml(currentUser.getName()) %></span>
                        </a>
                        <ul class="dropdown-menu dropdown-menu-end">
                            <% if (currentUser.isAdmin()) { %>
                            <li><a class="dropdown-item" href="../AdminServlet?action=dashboard"><i class="bi bi-speedometer2 me-2"></i>Admin Dashboard</a></li>
                            <li><hr class="dropdown-divider"></li>
                            <% } %>
                            <li><a class="dropdown-item" href="../ProfileServlet"><i class="bi bi-person me-2"></i>Profile</a></li>
                            <li><hr class="dropdown-divider"></li>
                            <li><a class="dropdown-item" href="../LogoutServlet"><i class="bi bi-box-arrow-left me-2"></i>Logout</a></li>
                        </ul>
                    </div>
                </div>
            </div>
        </div>
    </nav>

    <div class="container mt-4">
        <!-- Page Header -->
        <div class="d-flex justify-content-between align-items-center mb-4">
            <div>
                <h2 class="fw-bold"><i class="bi bi-folder-fill me-2 text-primary"></i>Files</h2>
                <p class="text-muted mb-0">File yang tersedia untuk diunduh</p>
            </div>
        </div>

        <!-- Messages -->
        <% if (error != null) { %>
        <div class="alert alert-danger alert-dismissible fade show" role="alert">
            <i class="bi bi-exclamation-triangle me-2"></i><%= ValidationUtil.sanitizeHtml(error) %>
            <button type="button" class="btn-close" data-bs-dismiss="alert"></button>
        </div>
        <% } %>
        <% if (success != null) { %>
        <div class="alert alert-success alert-dismissible fade show" role="alert">
            <i class="bi bi-check-circle me-2"></i><%= ValidationUtil.sanitizeHtml(success) %>
            <button type="button" class="btn-close" data-bs-dismiss="alert"></button>
        </div>
        <% } %>

        <!-- Search and Filter Bar -->
        <div class="card mb-4">
            <div class="card-body">
                <form action="../FileManagementServlet" method="get" class="row g-3">
                    <input type="hidden" name="action" value="search">
                    <div class="col-md-10">
                        <div class="input-group">
                            <span class="input-group-text"><i class="bi bi-search"></i></span>
                            <input type="text" name="q" class="form-control" placeholder="Cari file..." value="<%= searchQuery != null ? ValidationUtil.sanitizeHtml(searchQuery) : "" %>">
                        </div>
                    </div>
                    <div class="col-md-2">
                        <button type="submit" class="btn btn-outline-primary w-100">Search</button>
                    </div>
                </form>
            </div>
        </div>

        <!-- Files Grid -->
        <% if (files == null || files.isEmpty()) { %>
        <div class="text-center py-5">
            <i class="bi bi-folder-plus" style="font-size: 4rem; opacity: 0.3;"></i>
            <h4 class="mt-3 text-muted">Belum ada file</h4>
            <p class="text-muted">File yang tersedia akan muncul di sini</p>
        </div>
        <% } else { %>
        <div class="row row-cols-1 row-cols-md-2 row-cols-lg-3 row-cols-xl-4 g-4">
            <% for (FileItem file : files) { %>
            <div class="col">
                <div class="card file-card h-100">
                    <div class="card-body text-center">
                        <i class="bi <%= ValidationUtil.sanitizeHtml(file.getFileIconClass()) %> file-icon mb-3"></i>
                        <h6 class="card-title text-truncate" title="<%= ValidationUtil.sanitizeHtml(file.getOriginalName()) %>">
                            <%= ValidationUtil.sanitizeHtml(file.getOriginalName()) %>
                        </h6>
                        <% if (file.getIsPublic()) { %>
                        <span class="badge bg-success mb-2"><i class="bi bi-globe me-1"></i>Public</span>
                        <% } else { %>
                        <span class="badge bg-secondary mb-2"><i class="bi bi-lock me-1"></i>Private</span>
                        <% } %>
                        <p class="card-text text-muted small">
                            <i class="bi bi-download me-1"></i><%= file.getDownloadCount() %> download
                        </p>
                    </div>
                    <div class="card-footer bg-transparent border-top">
                        <div class="d-grid">
                            <a href="../FileManagementServlet?action=download&id=<%= file.getId() %>"
                               class="btn btn-sm btn-outline-primary">
                                <i class="bi bi-download me-1"></i>Download
                            </a>
                        </div>
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

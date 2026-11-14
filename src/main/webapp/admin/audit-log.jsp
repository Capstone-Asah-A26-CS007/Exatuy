<%@ page contentType="text/html;charset=UTF-8" language="java" %>
<%@ taglib prefix="c" uri="http://java.sun.com/jsp/jstl/core" %>
<%@ page import="com.examora.model.User" %>
<%@ page import="com.examora.model.AuditLog" %>
<%@ page import="java.util.List" %>
<%@ page import="java.util.Map" %>
<%@ page import="java.time.format.DateTimeFormatter" %>
<%@ page import="java.time.ZoneId" %>
<%@ page import="java.time.ZonedDateTime" %>
<%!
    public String esc(String input) {
        if (input == null) return "";
        return input.replace("&", "&amp;").replace("<", "&lt;").replace(">", "&gt;").replace("\"", "&quot;").replace("'", "&#39;");
    }
    public String escJs(String input) {
        if (input == null) return "";
        return input
            .replace("\\", "\\\\")
            .replace("\"", "\\\"")
            .replace("'", "\\'")
            .replace("\n", "\\n")
            .replace("\r", "\\r");
    }
%>
<%
    User currentUser = (User) session.getAttribute("user");
    if (currentUser == null || !currentUser.isAdmin()) {
        response.sendRedirect("../LoginServlet");
        return;
    }

    // Generate CSRF token
    String csrfToken = (String) session.getAttribute("csrfToken");
    if (csrfToken == null) {
        csrfToken = java.util.UUID.randomUUID().toString();
        session.setAttribute("csrfToken", csrfToken);
    }

    List<AuditLog> logs = (List<AuditLog>) request.getAttribute("logs");
    Integer currentPage = (Integer) request.getAttribute("currentPage");
    Integer totalPages = (Integer) request.getAttribute("totalPages");
    Integer totalCount = (Integer) request.getAttribute("totalCount");
    String actionType = (String) request.getAttribute("actionType");
    String entityType = (String) request.getAttribute("entityType");
    String status = (String) request.getAttribute("status");
    String success = (String) request.getAttribute("success");
    String error = (String) request.getAttribute("error");
    Map<String, Integer> stats = (Map<String, Integer>) request.getAttribute("stats");
    ZoneId jakartaZone = ZoneId.of("Asia/Jakarta");
    DateTimeFormatter dtf = DateTimeFormatter.ofPattern("dd MMM yyyy, HH:mm:ss").withZone(jakartaZone);

    int statCreate = 0, statUpdate = 0, statDelete = 0;
    if (stats != null) {
        if (stats.get("create") != null) statCreate = stats.get("create");
        if (stats.get("update") != null) statUpdate = stats.get("update");
        if (stats.get("delete") != null) statDelete = stats.get("delete");
    }
%>
<!DOCTYPE html>
<html lang="id">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Log Aktivitas - Exatuy</title>
    <link href="https://cdn.jsdelivr.net/npm/bootstrap@5.3.0/dist/css/bootstrap.min.css" rel="stylesheet">
    <link href="https://cdn.jsdelivr.net/npm/bootstrap-icons@1.10.0/font/bootstrap-icons.css" rel="stylesheet">
    <link href="../assets/css/style.css" rel="stylesheet">
    <link rel="icon" type="image/svg+xml" type="image/svg+xml" href="../assets/img/favicon.svg?v=3">
    <style>
        .stat-card { border-radius: 12px; border: none; transition: all 0.3s ease; }
        .stat-card:hover { transform: translateY(-2px); box-shadow: 0 8px 25px rgba(0,0,0,0.1); }
        .stat-card .stat-icon { width: 50px; height: 50px; border-radius: 12px; display: flex; align-items: center; justify-content: center; font-size: 1.5rem; }
        .stat-card .stat-value { font-size: 1.75rem; font-weight: 700; line-height: 1; }
        .stat-card .stat-label { font-size: 0.8rem; text-transform: uppercase; letter-spacing: 0.5px; }
        .action-create { background: rgba(25, 135, 84, 0.1); color: #198754; }
        .action-update { background: rgba(255, 193, 7, 0.15); color: #b38f00; }
        .action-delete { background: rgba(220, 53, 69, 0.1); color: #dc3545; }
        .action-login { background: rgba(13, 110, 253, 0.1); color: #0d6efd; }
        .action-logout { background: rgba(108, 117, 125, 0.1); color: #6c757d; }
        .action-other { background: rgba(102, 16, 242, 0.1); color: #6610f2; }
        .filter-card { border-radius: 12px; border: 1px solid #e9ecef; }
        .filter-card .form-select { border-radius: 8px; border-color: #dee2e6; }
        .btn-filter { border-radius: 8px; padding: 10px 24px; font-weight: 500; }
        .detail-row { padding: 12px 0; border-bottom: 1px solid #f0f0f0; }
        .detail-row:last-child { border-bottom: none; }
        .detail-label { font-size: 0.75rem; text-transform: uppercase; color: #6c757d; letter-spacing: 0.5px; }
        .detail-value { font-weight: 500; color: #343a40; }
        /* Table styles */
        .table th { font-size: 0.75rem; text-transform: uppercase; letter-spacing: 0.5px; color: #6c757d; font-weight: 600; border-bottom-width: 1px; background: #f8f9fa; }
        .log-row { transition: all 0.15s ease; }
        .log-row:hover { background-color: rgba(13, 110, 253, 0.04) !important; }
        .log-row:hover td { border-color: #dee2e6; }
        .log-row td { vertical-align: middle; padding: 14px 8px; }
        .pagination .page-link { border-radius: 6px; margin: 0 2px; border: 1px solid #dee2e6; }
        .pagination .page-item.active .page-link { background-color: #0d6efd; border-color: #0d6efd; }
    </style>
<link href="../assets/css/handdrawn.css" rel="stylesheet">
</head>
<body>
    <input type="hidden" name="csrfToken" value="<%= csrfToken %>">
    <%@ include file="sidebar.jsp" %>

    <div class="main-content">
        <!-- Header -->
        <div class="d-flex justify-content-between align-items-center mb-4">
            <div>
                <h1 class="h3 mb-1 fw-bold"><i class="bi bi-activity me-2 text-primary"></i>Log Aktivitas</h1>
                <nav aria-label="breadcrumb">
                    <ol class="breadcrumb mb-0">
                        <li class="breadcrumb-item"><a href="../AdminServlet?action=dashboard">Dashboard</a></li>
                        <li class="breadcrumb-item active">Log Aktivitas</li>
                    </ol>
                </nav>
            </div>
            <div class="d-flex gap-2">
                <a href="AuditServlet?action=export&actionType=<%= actionType != null ? actionType : "" %>&entityType=<%= entityType != null ? entityType : "" %>&status=<%= status != null ? status : "" %>"
                   class="btn btn-success">
                    <i class="bi bi-download me-1"></i>Export
                </a>
                <button class="btn btn-outline-danger" onclick="confirmDeleteLogs()">
                    <i class="bi bi-trash me-1"></i>Hapus Log
                </button>
                <button class="btn btn-outline-secondary" onclick="location.reload()">
                    <i class="bi bi-arrow-clockwise me-1"></i>Refresh
                </button>
            </div>
        </div>

        <% if (success != null) { %>
        <div class="alert alert-success alert-dismissible fade show">
            <i class="bi bi-check-circle me-2"></i><%= esc(success) %>
            <button type="button" class="btn-close" data-bs-dismiss="alert"></button>
        </div>
        <% } %>
        <% if (error != null) { %>
        <div class="alert alert-danger alert-dismissible fade show">
            <i class="bi bi-exclamation-triangle me-2"></i><%= esc(error) %>
            <button type="button" class="btn-close" data-bs-dismiss="alert"></button>
        </div>
        <% } %>

        <!-- Statistics Cards -->
        <div class="row mb-4">
            <div class="col-md-3 col-6 mb-3">
                <div class="card stat-card h-100">
                    <div class="card-body">
                        <div class="d-flex align-items-center">
                            <div class="stat-icon bg-primary bg-opacity-10 text-primary me-3">
                                <i class="bi bi-list-check"></i>
                            </div>
                            <div>
                                <div class="stat-value text-primary"><%= totalCount != null ? totalCount : 0 %></div>
                                <div class="stat-label text-muted">Total Log</div>
                            </div>
                        </div>
                    </div>
                </div>
            </div>
            <div class="col-md-3 col-6 mb-3">
                <div class="card stat-card h-100">
                    <div class="card-body">
                        <div class="d-flex align-items-center">
                            <div class="stat-icon bg-success bg-opacity-10 text-success me-3">
                                <i class="bi bi-plus-circle"></i>
                            </div>
                            <div>
                                <div class="stat-value text-success"><%= statCreate %></div>
                                <div class="stat-label text-muted">Create</div>
                            </div>
                        </div>
                    </div>
                </div>
            </div>
            <div class="col-md-3 col-6 mb-3">
                <div class="card stat-card h-100">
                    <div class="card-body">
                        <div class="d-flex align-items-center">
                            <div class="stat-icon bg-warning bg-opacity-10 text-warning me-3">
                                <i class="bi bi-pencil-square"></i>
                            </div>
                            <div>
                                <div class="stat-value text-warning"><%= statUpdate %></div>
                                <div class="stat-label text-muted">Update</div>
                            </div>
                        </div>
                    </div>
                </div>
            </div>
            <div class="col-md-3 col-6 mb-3">
                <div class="card stat-card h-100">
                    <div class="card-body">
                        <div class="d-flex align-items-center">
                            <div class="stat-icon bg-danger bg-opacity-10 text-danger me-3">
                                <i class="bi bi-trash"></i>
                            </div>
                            <div>
                                <div class="stat-value text-danger"><%= statDelete %></div>
                                <div class="stat-label text-muted">Delete</div>
                            </div>
                        </div>
                    </div>
                </div>
            </div>
        </div>

        <!-- Filters -->
        <div class="card filter-card mb-4">
            <div class="card-body">
                <form method="get" action="AuditServlet" id="filterForm">
                    <div class="row g-3 align-items-end">
                        <div class="col-md-3">
                            <label class="form-label"><i class="bi bi-funnel me-1"></i>Tipe Aksi</label>
                            <select class="form-select" name="actionType">
                                <option value="">Semua Aksi</option>
                                <option value="CREATE" <%= "CREATE".equals(actionType) ? "selected" : "" %>>CREATE</option>
                                <option value="UPDATE" <%= "UPDATE".equals(actionType) ? "selected" : "" %>>UPDATE</option>
                                <option value="DELETE" <%= "DELETE".equals(actionType) ? "selected" : "" %>>DELETE</option>
                                <option value="LOGIN" <%= "LOGIN".equals(actionType) ? "selected" : "" %>>LOGIN</option>
                                <option value="LOGOUT" <%= "LOGOUT".equals(actionType) ? "selected" : "" %>>LOGOUT</option>
                            </select>
                        </div>
                        <div class="col-md-2">
                            <label class="form-label"><i class="bi bi-box me-1"></i>Entitas</label>
                            <select class="form-select" name="entityType">
                                <option value="">Semua Entitas</option>
                                <option value="USER" <%= "USER".equals(entityType) ? "selected" : "" %>>User</option>
                                <option value="QUIZ" <%= "QUIZ".equals(entityType) ? "selected" : "" %>>Quiz</option>
                                <option value="QUESTION" <%= "QUESTION".equals(entityType) ? "selected" : "" %>>Question</option>
                                <option value="ATTENDANCE" <%= "ATTENDANCE".equals(entityType) ? "selected" : "" %>>Attendance</option>
                                <option value="RETAKE_CODE" <%= "RETAKE_CODE".equals(entityType) ? "selected" : "" %>>Retake Code</option>
                                <option value="ACCESS_CODE" <%= "ACCESS_CODE".equals(entityType) ? "selected" : "" %>>Access Code</option>
                                <option value="SUBMISSION" <%= "SUBMISSION".equals(entityType) ? "selected" : "" %>>Submission</option>
                                <option value="SETTINGS" <%= "SETTINGS".equals(entityType) ? "selected" : "" %>>Settings</option>
                                <option value="CHAT" <%= "CHAT".equals(entityType) ? "selected" : "" %>>Chat</option>
                                <option value="SYSTEM" <%= "SYSTEM".equals(entityType) ? "selected" : "" %>>System</option>
                            </select>
                        </div>
                        <div class="col-md-2">
                            <label class="form-label"><i class="bi bi-calendar me-1"></i>Tanggal Mulai</label>
                            <input type="date" class="form-control" name="startDate" value="<%= request.getParameter("startDate") != null ? request.getParameter("startDate") : "" %>">
                        </div>
                        <div class="col-md-2">
                            <label class="form-label"><i class="bi bi-calendar-check me-1"></i>Tanggal Akhir</label>
                            <input type="date" class="form-control" name="endDate" value="<%= request.getParameter("endDate") != null ? request.getParameter("endDate") : "" %>">
                        </div>
                        <div class="col-md-2">
                            <label class="form-label"><i class="bi bi-check-circle me-1"></i>Status</label>
                            <select class="form-select" name="status">
                                <option value="">Semua</option>
                                <option value="SUCCESS" <%= "SUCCESS".equals(status) ? "selected" : "" %>>Success</option>
                                <option value="FAILED" <%= "FAILED".equals(status) ? "selected" : "" %>>Failed</option>
                            </select>
                        </div>
                        <div class="col-md-3">
                            <div class="d-flex gap-2">
                                <button type="submit" class="btn btn-primary btn-filter flex-grow-1">
                                    <i class="bi bi-search me-1"></i>Filter
                                </button>
                                <a href="AuditServlet" class="btn btn-outline-secondary btn-filter">
                                    <i class="bi bi-x-lg"></i>
                                </a>
                            </div>
                        </div>
                    </div>
                </form>
            </div>
        </div>

        <!-- Log List -->
        <div class="card" style="border-radius: 12px; border: 1px solid #e9ecef;">
            <div class="card-header bg-white py-3" style="border-radius: 12px 12px 0 0; border-bottom: 1px solid #e9ecef;">
                <div class="d-flex justify-content-between align-items-center">
                    <h5 class="mb-0 fw-bold">
                        <i class="bi bi-clock-history me-2 text-primary"></i>Riwayat Aktivitas
                    </h5>
                    <span class="badge bg-light text-dark py-2 px-3">
                        <%= totalCount != null ? totalCount : 0 %> entri
                    </span>
                </div>
            </div>
            <div class="card-body p-0">
                <% if (logs != null && !logs.isEmpty()) { %>
                <div class="table-responsive">
                    <table class="table table-hover align-middle mb-0">
                        <thead class="table-light">
                            <tr>
                                <th class="ps-4" style="width: 50px;">No</th>
                                <th style="width: 100px;">Aksi</th>
                                <th style="width: 100px;">Entitas</th>
                                <th>Detail</th>
                                <th style="width: 140px;">Pengguna</th>
                                <th style="width: 110px;">IP Address</th>
                                <th style="width: 80px;">Status</th>
                                <th style="width: 160px;">Waktu</th>
                            </tr>
                        </thead>
                        <tbody>
                            <% int no = 1;
                               int cp = currentPage != null ? currentPage : 1;
                               int ps = 20; // page size
                               int startNo = (cp - 1) * ps + 1;

                               for (AuditLog log : logs) {
                                   String actionClass = "action-other";
                                   String actionIcon = "bi-arrow-right-circle";
                                   if ("CREATE".equals(log.getActionType())) {
                                       actionClass = "action-create"; actionIcon = "bi-plus-lg";
                                   } else if ("UPDATE".equals(log.getActionType())) {
                                       actionClass = "action-update"; actionIcon = "bi-pencil";
                                   } else if ("DELETE".equals(log.getActionType())) {
                                       actionClass = "action-delete"; actionIcon = "bi-trash";
                                   } else if ("LOGIN".equals(log.getActionType())) {
                                       actionClass = "action-login"; actionIcon = "bi-box-arrow-in-right";
                                   } else if ("LOGOUT".equals(log.getActionType())) {
                                       actionClass = "action-logout"; actionIcon = "bi-box-arrow-right";
                                   }
                            %>
                            <tr onclick="showLogDetail(<%= log.getId() %>)" style="cursor: pointer;" class="log-row">
                                <td class="ps-4 text-muted"><%= startNo++ %></td>
                                <td>
                                    <span class="badge <%= actionClass %>">
                                        <i class="bi <%= actionIcon %> me-1"></i><%= log.getActionType() %>
                                    </span>
                                </td>
                                <td>
                                    <span class="badge bg-secondary bg-opacity-10 text-secondary"><%= log.getEntityType() %></span>
                                </td>
                                <td>
                                    <% if (log.getEntityName() != null && !log.getEntityName().isEmpty()) { %>
                                    <span class="text-truncate d-inline-block" style="max-width: 200px;" title="<%= esc(log.getEntityName()) %>">
                                        <%= esc(log.getEntityName().length() > 30 ? log.getEntityName().substring(0, 30) + "..." : log.getEntityName()) %>
                                    </span>
                                    <% } else { %>
                                    <span class="text-muted">-</span>
                                    <% } %>
                                </td>
                                <td>
                                    <span class="fw-medium"><%= esc(log.getUserName()) %></span>
                                </td>
                                <td>
                                    <% if (log.getIpAddress() != null && !log.getIpAddress().isEmpty()) { %>
                                    <code class="small"><%= esc(log.getIpAddress()) %></code>
                                    <% } else { %>
                                    <span class="text-muted">-</span>
                                    <% } %>
                                </td>
                                <td>
                                    <% if ("SUCCESS".equals(log.getStatus())) { %>
                                    <span class="badge bg-success bg-opacity-10 text-success">
                                        <i class="bi bi-check-circle me-1"></i>Success
                                    </span>
                                    <% } else { %>
                                    <span class="badge bg-danger bg-opacity-10 text-danger">
                                        <i class="bi bi-x-circle me-1"></i>Failed
                                    </span>
                                    <% } %>
                                </td>
                                <td>
                                    <span class="text-muted small">
                                        <i class="bi bi-clock me-1"></i>
                                        <%= log.getCreatedAt() != null ? log.getCreatedAt().atZone(ZoneId.systemDefault()).withZoneSameInstant(jakartaZone).format(dtf) : "-" %>
                                    </span>
                                </td>
                            </tr>
                            <% } %>
                        </tbody>
                    </table>
                </div>

                <!-- Pagination -->
                <% if (totalPages != null && totalPages > 1) { %>
                <div class="d-flex justify-content-between align-items-center px-4 py-3" style="border-top: 1px solid #e9ecef;">
                    <div class="text-muted small">
                        Menampilkan halaman <%= cp %> dari <%= totalPages %> (<%= totalCount %> total entri)
                    </div>
                    <nav>
                        <ul class="pagination pagination-sm mb-0">
                            <!-- First Page -->
                            <li class="page-item <%= cp == 1 ? "disabled" : "" %>">
                                <a class="page-link" href="?page=1&actionType=<%= actionType != null ? actionType : "" %>&entityType=<%= entityType != null ? entityType : "" %>&status=<%= status != null ? status : "" %>" title="Halaman pertama">
                                    <i class="bi bi-chevron-double-left"></i>
                                </a>
                            </li>
                            <!-- Previous Page -->
                            <li class="page-item <%= cp == 1 ? "disabled" : "" %>">
                                <a class="page-link" href="?page=<%= cp - 1 %>&actionType=<%= actionType != null ? actionType : "" %>&entityType=<%= entityType != null ? entityType : "" %>&status=<%= status != null ? status : "" %>" title="Halaman sebelumnya">
                                    <i class="bi bi-chevron-left"></i>
                                </a>
                            </li>
                            <!-- Page Numbers -->
                            <%
                                int startPage = Math.max(1, cp - 2);
                                int endPage = Math.min(totalPages, cp + 2);
                                if (startPage > 1) {
                            %>
                            <li class="page-item disabled"><span class="page-link">...</span></li>
                            <% } %>
                            <% for (int i = startPage; i <= endPage; i++) { %>
                            <li class="page-item <%= i == cp ? "active" : "" %>">
                                <a class="page-link" href="?page=<%= i %>&actionType=<%= actionType != null ? actionType : "" %>&entityType=<%= entityType != null ? entityType : "" %>&status=<%= status != null ? status : "" %>"><%= i %></a>
                            </li>
                            <% } %>
                            <% if (endPage < totalPages) { %>
                            <li class="page-item disabled"><span class="page-link">...</span></li>
                            <% } %>
                            <!-- Next Page -->
                            <li class="page-item <%= cp == totalPages ? "disabled" : "" %>">
                                <a class="page-link" href="?page=<%= cp + 1 %>&actionType=<%= actionType != null ? actionType : "" %>&entityType=<%= entityType != null ? entityType : "" %>&status=<%= status != null ? status : "" %>" title="Halaman selanjutnya">
                                    <i class="bi bi-chevron-right"></i>
                                </a>
                            </li>
                            <!-- Last Page -->
                            <li class="page-item <%= cp == totalPages ? "disabled" : "" %>">
                                <a class="page-link" href="?page=<%= totalPages %>&actionType=<%= actionType != null ? actionType : "" %>&entityType=<%= entityType != null ? entityType : "" %>&status=<%= status != null ? status : "" %>" title="Halaman terakhir">
                                    <i class="bi bi-chevron-double-right"></i>
                                </a>
                            </li>
                        </ul>
                    </nav>
                </div>
                <% } else if (totalCount != null && totalCount > 0) { %>
                <div class="px-4 py-3 text-muted small" style="border-top: 1px solid #e9ecef;">
                    Menampilkan <%= totalCount %> entri
                </div>
                <% } %>
                <% } else { %>
                <div class="text-center py-5">
                    <div class="mb-3">
                        <i class="bi bi-clipboard2-data display-1 text-muted opacity-25"></i>
                    </div>
                    <h5 class="text-muted">Tidak ada log ditemukan</h5>
                    <p class="text-muted small mb-0">Belum ada aktivitas yang tercatat atau filter tidak menghasilkan data.</p>
                </div>
                <% } %>
            </div>
        </div>
    </div>

    <!-- Log Detail Modal -->
    <div class="modal fade" id="logDetailModal" tabindex="-1">
        <div class="modal-dialog">
            <div class="modal-content" style="border-radius: 12px;">
                <div class="modal-header" style="border-bottom: 1px solid #e9ecef;">
                    <h5 class="modal-title fw-bold"><i class="bi bi-info-circle me-2 text-primary"></i>Detail Log</h5>
                    <button type="button" class="btn-close" data-bs-dismiss="modal"></button>
                </div>
                <div class="modal-body" id="logDetailBody">
                </div>
                <div class="modal-footer" style="border-top: 1px solid #e9ecef;">
                    <button type="button" class="btn btn-secondary" data-bs-dismiss="modal">Tutup</button>
                </div>
            </div>
        </div>
    </div>

    <script src="https://cdn.jsdelivr.net/npm/bootstrap@5.3.0/dist/js/bootstrap.bundle.min.js"></script>
    <script>
        const logData = {
            <% if (logs != null) {
                for (AuditLog log : logs) { %>
            <%= log.getId() %>: {
                action: '<%= escJs(log.getActionType()) %>',
                entity: '<%= escJs(log.getEntityType()) %>',
                entityName: '<%= escJs(log.getEntityName()) %>',
                user: '<%= escJs(log.getUserName()) %>',
                ip: '<%= escJs(log.getIpAddress()) %>',
                status: '<%= escJs(log.getStatus()) %>',
                time: '<%= log.getCreatedAt() != null ? log.getCreatedAt().atZone(ZoneId.systemDefault()).withZoneSameInstant(jakartaZone).format(dtf) : "-" %>',
                userAgent: '<%= escJs(log.getUserAgent()) %>',
                details: '<%= escJs(log.getActionData()) %>'
            },
            <% } } %>
        };

        function showLogDetail(logId) {
            const log = logData[logId];
            if (!log) return;

            const actionClass = {
                'CREATE': 'bg-success',
                'UPDATE': 'bg-warning text-dark',
                'DELETE': 'bg-danger',
                'LOGIN': 'bg-primary',
                'LOGOUT': 'bg-secondary'
            }[log.action] || 'bg-info';

            let html = '<div class="detail-row"><div class="detail-label">Aksi</div><div class="detail-value"><span class="badge ' + actionClass + '">' + log.action + '</span></div></div>';
            html += '<div class="detail-row"><div class="detail-label">Entitas</div><div class="detail-value">' + log.entity + '</div></div>';
            html += '<div class="detail-row"><div class="detail-label">Referensi</div><div class="detail-value">' + (log.entityName || '-') + '</div></div>';

            // Entity-specific rendering
            if (log.entity === 'RETAKE_CODE' && log.details) {
                html += renderRetakeCodeDetails(log.details);
            } else if (log.entity === 'ACCESS_CODE' && log.details) {
                html += renderAccessCodeDetails(log.details);
            } else if (log.entity === 'SUBMISSION' && log.details) {
                html += renderSubmissionDetails(log.details);
            } else if (log.entity === 'USER' && log.details) {
                html += renderUserDetails(log.details);
            } else if (log.entity === 'CHAT' && log.details) {
                html += renderChatDetails(log.details);
            } else if (log.entity === 'SETTINGS' && log.details) {
                html += renderSettingsDetails(log.details);
            } else if (log.details && log.details !== 'null') {
                html += renderGenericDetails(log.details);
            }

            html += '<div class="detail-row"><div class="detail-label">Pengguna</div><div class="detail-value">' + log.user + '</div></div>';
            html += '<div class="detail-row"><div class="detail-label">IP Address</div><div class="detail-value"><code>' + (log.ip || '-') + '</code></div></div>';
            html += '<div class="detail-row"><div class="detail-label">Status</div><div class="detail-value"><span class="badge ' + (log.status === 'SUCCESS' ? 'bg-success' : 'bg-danger') + '">' + log.status + '</span></div></div>';
            html += '<div class="detail-row"><div class="detail-label">Waktu</div><div class="detail-value">' + log.time + '</div></div>';

            if (log.userAgent) {
                html += '<div class="detail-row"><div class="detail-label">User Agent</div><div class="detail-value small text-muted">' + log.userAgent + '</div></div>';
            }

            document.getElementById('logDetailBody').innerHTML = html;
            new bootstrap.Modal(document.getElementById('logDetailModal')).show();
        }

        // Render retake code details
        function renderRetakeCodeDetails(detailsJson) {
            try {
                const data = JSON.parse(detailsJson);
                let html = '<div class="detail-row"><div class="detail-label">Detail Kode Retake</div>';
                html += '<div class="detail-value">';
                html += '<div class="card bg-light"><div class="card-body p-2">';
                html += '<div class="row g-2">';

                if (data.retakeCode) {
                    html += '<div class="col-6"><span class="text-muted small">Kode:</span><br><strong class="text-primary">' + esc(data.retakeCode) + '</strong></div>';
                }
                if (data.quizId) {
                    html += '<div class="col-6"><span class="text-muted small">Quiz ID:</span><br><strong>' + data.quizId + '</strong></div>';
                }
                if (data.userId) {
                    html += '<div class="col-6"><span class="text-muted small">User ID:</span><br><strong>' + data.userId + '</strong></div>';
                }
                if (data.validityHours) {
                    html += '<div class="col-6"><span class="text-muted small">Berlaku:</span><br><strong>' + data.validityHours + ' jam</strong></div>';
                }
                if (data.maxUses) {
                    html += '<div class="col-6"><span class="text-muted small">Max Penggunaan:</span><br><strong>' + data.maxUses + '</strong></div>';
                }
                if (data.expiresAt) {
                    html += '<div class="col-6"><span class="text-muted small">Kadaluarsa:</span><br><strong>' + esc(data.expiresAt) + '</strong></div>';
                }

                html += '</div></div></div></div>';
                return html;
            } catch (e) {
                return renderGenericDetails(detailsJson);
            }
        }

        // Render access code details
        function renderAccessCodeDetails(detailsJson) {
            try {
                const data = JSON.parse(detailsJson);
                let html = '<div class="detail-row"><div class="detail-label">Detail Access Code</div>';
                html += '<div class="detail-value">';
                html += '<div class="card bg-light"><div class="card-body p-2">';
                html += '<div class="row g-2">';

                if (data.accessCode) {
                    html += '<div class="col-6"><span class="text-muted small">Kode:</span><br><strong class="text-success">' + esc(data.accessCode) + '</strong></div>';
                }
                if (data.codeName) {
                    html += '<div class="col-6"><span class="text-muted small">Nama:</span><br><strong>' + esc(data.codeName) + '</strong></div>';
                }
                if (data.maxUses) {
                    html += '<div class="col-6"><span class="text-muted small">Max Penggunaan:</span><br><strong>' + data.maxUses + '</strong></div>';
                }
                if (data.validityHours) {
                    html += '<div class="col-6"><span class="text-muted small">Berlaku:</span><br><strong>' + data.validityHours + ' jam</strong></div>';
                }
                if (data.quizId) {
                    html += '<div class="col-6"><span class="text-muted small">Quiz ID:</span><br><strong>' + data.quizId + '</strong></div>';
                }
                if (data.useCount !== undefined) {
                    html += '<div class="col-6"><span class="text-muted small">Terpakai:</span><br><strong>' + data.useCount + '</strong></div>';
                }

                html += '</div></div></div></div>';
                return html;
            } catch (e) {
                return renderGenericDetails(detailsJson);
            }
        }

        // Render submission details
        function renderSubmissionDetails(detailsJson) {
            try {
                const data = JSON.parse(detailsJson);
                let html = '<div class="detail-row"><div class="detail-label">Detail Submission</div>';
                html += '<div class="detail-value">';
                html += '<div class="card bg-light"><div class="card-body p-2">';
                html += '<div class="row g-2">';

                if (data.score !== undefined) {
                    html += '<div class="col-4"><span class="text-muted small">Score:</span><br><strong class="text-primary">' + data.score + '</strong></div>';
                }
                if (data.status) {
                    const statusClass = data.status === 'completed' ? 'success' : data.status === 'timeout' ? 'warning' : 'secondary';
                    html += '<div class="col-4"><span class="text-muted small">Status:</span><br><span class="badge bg-' + statusClass + '">' + data.status + '</span></div>';
                }
                if (data.quizId) {
                    html += '<div class="col-4"><span class="text-muted small">Quiz ID:</span><br><strong>' + data.quizId + '</strong></div>';
                }
                if (data.userId) {
                    html += '<div class="col-4"><span class="text-muted small">User ID:</span><br><strong>' + data.userId + '</strong></div>';
                }
                if (data.isRetake) {
                    html += '<div class="col-4"><span class="badge bg-info">Retake Submission</span></div>';
                }
                if (data.completionTime) {
                    html += '<div class="col-4"><span class="text-muted small">Waktu Pengerjaan:</span><br><strong>' + esc(data.completionTime) + '</strong></div>';
                }
                if (data.totalQuestions) {
                    html += '<div class="col-4"><span class="text-muted small">Total Soal:</span><br><strong>' + data.totalQuestions + '</strong></div>';
                }
                if (data.correctAnswers !== undefined) {
                    html += '<div class="col-4"><span class="text-muted small">Jawaban Benar:</span><br><strong>' + data.correctAnswers + '</strong></div>';
                }

                html += '</div></div></div></div>';
                return html;
            } catch (e) {
                return renderGenericDetails(detailsJson);
            }
        }

        // Render user details
        function renderUserDetails(detailsJson) {
            try {
                const data = JSON.parse(detailsJson);
                let html = '<div class="detail-row"><div class="detail-label">Detail User</div>';
                html += '<div class="detail-value">';
                html += '<div class="card bg-light"><div class="card-body p-2">';
                html += '<div class="row g-2">';

                if (data.name) {
                    html += '<div class="col-6"><span class="text-muted small">Nama:</span><br><strong>' + esc(data.name) + '</strong></div>';
                }
                if (data.email) {
                    html += '<div class="col-6"><span class="text-muted small">Email:</span><br><strong>' + esc(data.email) + '</strong></div>';
                }
                if (data.role) {
                    const roleClass = data.role === 'admin' ? 'danger' : 'primary';
                    html += '<div class="col-6"><span class="text-muted small">Role:</span><br><span class="badge bg-' + roleClass + '">' + data.role + '</span></div>';
                }
                if (data.tag) {
                    html += '<div class="col-6"><span class="text-muted small">Tag:</span><br><span class="badge bg-secondary">' + esc(data.tag) + '</span></div>';
                }
                if (data.userId) {
                    html += '<div class="col-6"><span class="text-muted small">User ID:</span><br><strong>' + data.userId + '</strong></div>';
                }
                if (data.oldRole && data.newRole) {
                    html += '<div class="col-6"><span class="text-muted small">Role Lama:</span><br><span class="badge bg-secondary">' + data.oldRole + '</span></div>';
                    html += '<div class="col-6"><span class="text-muted small">Role Baru:</span><br><span class="badge bg-primary">' + data.newRole + '</span></div>';
                }

                html += '</div></div></div></div>';
                return html;
            } catch (e) {
                return renderGenericDetails(detailsJson);
            }
        }

        // Render chat details
        function renderChatDetails(detailsJson) {
            try {
                const data = JSON.parse(detailsJson);
                let html = '<div class="detail-row"><div class="detail-label">Detail Chat</div>';
                html += '<div class="detail-value">';
                html += '<div class="card bg-light"><div class="card-body p-2">';

                if (data.messagePreview) {
                    html += '<div class="mb-2"><span class="text-muted small">Pesan:</span><br><em class="text-dark">' + esc(data.messagePreview) + '</em></div>';
                }
                if (data.targetUserName) {
                    html += '<div class="mb-1"><span class="text-muted small">Ke:</span> <strong>' + esc(data.targetUserName) + '</strong></div>';
                }
                if (data.targetUserId) {
                    html += '<div class="mb-1"><span class="text-muted small">User ID:</span> <strong>' + data.targetUserId + '</strong></div>';
                }
                if (data.deletedCount) {
                    html += '<div><span class="text-danger"><strong>' + data.deletedCount + ' pesan dihapus</strong></span></div>';
                }
                if (data.messageCount) {
                    html += '<div><span class="text-success"><strong>' + data.messageCount + ' pesan terkirim</strong></span></div>';
                }

                html += '</div></div></div>';
                return html;
            } catch (e) {
                return renderGenericDetails(detailsJson);
            }
        }

        // Render settings details
        function renderSettingsDetails(detailsJson) {
            try {
                const data = JSON.parse(detailsJson);
                let html = '<div class="detail-row"><div class="detail-label">Detail Settings</div>';
                html += '<div class="detail-value">';
                html += '<div class="card bg-light"><div class="card-body p-2">';
                html += '<div class="row g-2">';

                if (data.settingKey) {
                    html += '<div class="col-6"><span class="text-muted small">Key:</span><br><strong>' + esc(data.settingKey) + '</strong></div>';
                }
                if (data.oldValue !== undefined) {
                    html += '<div class="col-6"><span class="text-muted small">Nilai Lama:</span><br><code class="small">' + esc(String(data.oldValue)) + '</code></div>';
                }
                if (data.newValue !== undefined) {
                    html += '<div class="col-6"><span class="text-muted small">Nilai Baru:</span><br><code class="small text-success">' + esc(String(data.newValue)) + '</code></div>';
                }
                if (data.settingsUpdated) {
                    html += '<div class="col-12"><span class="badge bg-info">' + data.settingsUpdated + ' settings diupdate</span></div>';
                }

                // Display any other fields
                for (const [key, value] of Object.entries(data)) {
                    if (!['settingKey', 'oldValue', 'newValue', 'settingsUpdated'].includes(key)) {
                        let displayValue = value;
                        if (typeof value === 'object') {
                            displayValue = JSON.stringify(value);
                        }
                        html += '<div class="col-6"><span class="text-muted small">' + esc(key) + ':</span><br><strong>' + esc(String(displayValue)) + '</strong></div>';
                    }
                }

                html += '</div></div></div></div>';
                return html;
            } catch (e) {
                return renderGenericDetails(detailsJson);
            }
        }

        // Render generic JSON details
        function renderGenericDetails(detailsJson) {
            let html = '<div class="detail-row"><div class="detail-label">Detail</div>';
            html += '<div class="detail-value">';

            try {
                const data = JSON.parse(detailsJson);
                html += '<div class="card bg-light"><div class="card-body p-2">';
                html += '<div class="row g-2">';

                for (const [key, value] of Object.entries(data)) {
                    let displayValue = value;
                    if (typeof value === 'object' && value !== null) {
                        displayValue = JSON.stringify(value);
                    }
                    html += '<div class="col-md-6"><span class="text-muted small">' + esc(key) + ':</span><br><strong>' + esc(String(displayValue)) + '</strong></div>';
                }

                html += '</div></div></div>';
            } catch (e) {
                html += '<code class="small">' + esc(detailsJson) + '</code>';
            }

            html += '</div>';
            return html;
        }

        // Helper function to escape HTML
        function esc(str) {
            if (!str) return '';
            return String(str).replace(/&/g, '&amp;')
                .replace(/</g, '&lt;')
                .replace(/>/g, '&gt;')
                .replace(/"/g, '&quot;')
                .replace(/'/g, '&#39;');
        }

        // Confirm delete logs
        function confirmDeleteLogs() {
            if (confirm('PERINGATAN!\n\nAnda yakin ingin menghapus SEMUA log aktivitas?\n\nTindakan ini TIDAK DAPAT dibatalkan!\n\nKetik "HAPUS" untuk konfirmasi.')) {
                const confirmation = prompt('Ketik "HAPUS" untuk mengkonfirmasi penghapusan:');
                if (confirmation === 'HAPUS') {
                    // Create form and submit
                    const form = document.createElement('form');
                    form.method = 'POST';
                    form.action = 'AuditServlet?action=deleteAll';

                    const csrfInput = document.createElement('input');
                    csrfInput.type = 'hidden';
                    csrfInput.name = 'csrfToken';
                    csrfInput.value = document.querySelector('input[name="csrfToken"]')?.value || '';
                    form.appendChild(csrfInput);

                    document.body.appendChild(form);
                    form.submit();
                } else if (confirmation !== null) {
                    alert('Konfirmasi gagal. Log tidak dihapus.');
                }
            }
        }
    </script>
</body>
</html>

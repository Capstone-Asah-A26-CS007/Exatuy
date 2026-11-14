<%@ page contentType="text/html;charset=UTF-8" language="java" %>
<%@ taglib prefix="c" uri="http://java.sun.com/jsp/jstl/core" %>
<%@ page import="com.examora.model.User" %>
<%@ page import="com.examora.model.AttendanceSession" %>
<%@ page import="com.examora.model.AttendanceRecord" %>
<%@ page import="com.examora.util.ValidationUtil" %>
<%@ page import="java.util.List" %>
<%@ page import="java.util.TimeZone" %>
<%
    User currentUser = (User) session.getAttribute("user");
    if (currentUser == null || !currentUser.isAdmin()) {
        response.sendRedirect("../LoginServlet");
        return;
    }

    AttendanceSession attSession = (AttendanceSession) request.getAttribute("session");
    List<AttendanceRecord> records = (List<AttendanceRecord>) request.getAttribute("records");
    List<AttendanceRecord> presentRecords = (List<AttendanceRecord>) request.getAttribute("presentRecords");
    List<AttendanceRecord> lateRecords = (List<AttendanceRecord>) request.getAttribute("lateRecords");
    List<User> absentUsers = (List<User>) request.getAttribute("absentUsers");

    Integer statsPresent = (Integer) request.getAttribute("statsPresent");
    Integer statsLate = (Integer) request.getAttribute("statsLate");
    Integer statsTotal = (Integer) request.getAttribute("statsTotal");
    Integer totalExpectedUsers = (Integer) request.getAttribute("totalExpectedUsers");
    Integer absentCount = (Integer) request.getAttribute("absentCount");
    Double attendancePercentage = (Double) request.getAttribute("attendancePercentage");

    String success = (String) request.getAttribute("success");
    String error = (String) request.getAttribute("error");

    String csrfToken = (String) session.getAttribute("csrfToken");
    if (csrfToken == null) {
        csrfToken = java.util.UUID.randomUUID().toString();
        session.setAttribute("csrfToken", csrfToken);
    }

    // Date formatters with Jakarta timezone
    java.text.SimpleDateFormat dateFormat = new java.text.SimpleDateFormat("dd MMMM yyyy");
    java.text.SimpleDateFormat timeFormat = new java.text.SimpleDateFormat("HH:mm");
    dateFormat.setTimeZone(TimeZone.getTimeZone("Asia/Jakarta"));
    timeFormat.setTimeZone(TimeZone.getTimeZone("Asia/Jakarta"));

    // Calculate percentages
    double presentPercent = totalExpectedUsers != null && totalExpectedUsers > 0 ?
        (double) (statsPresent != null ? statsPresent : 0) / totalExpectedUsers * 100 : 0;
    double latePercent = totalExpectedUsers != null && totalExpectedUsers > 0 ?
        (double) (statsLate != null ? statsLate : 0) / totalExpectedUsers * 100 : 0;
    double absentPercent = totalExpectedUsers != null && totalExpectedUsers > 0 ?
        (double) (absentCount != null ? absentCount : 0) / totalExpectedUsers * 100 : 0;
%>
<!DOCTYPE html>
<html lang="id">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Detail Absensi - Exatuy</title>
    <link href="https://cdn.jsdelivr.net/npm/bootstrap@5.3.0/dist/css/bootstrap.min.css" rel="stylesheet">
    <link href="https://cdn.jsdelivr.net/npm/bootstrap-icons@1.10.0/font/bootstrap-icons.css" rel="stylesheet">
    <link href="../assets/css/style.css" rel="stylesheet">
    <link rel="icon" type="image/svg+xml" type="image/svg+xml" href="../assets/img/favicon.svg?v=3">
    <style>
        :root {
            --primary-color: #4361ee;
            --secondary-color: #3f37c9;
            --success-color: #4cc9f0;
            --warning-color: #f72585;
            --danger-color: #ef476f;
            --light-bg: #f8f9fa;
            --card-shadow: 0 4px 6px rgba(0, 0, 0, 0.07);
            --card-hover-shadow: 0 10px 20px rgba(0, 0, 0, 0.1);
        }

        body {
            background-color: var(--light-bg);
            font-family: 'Segoe UI', Tahoma, Geneva, Verdana, sans-serif;
        }

        .main-content {
            padding: 2rem;
            max-width: calc(100% - 280px); /* Account for sidebar (250px) + gap (30px) */
        }

        .stats-card {
            background: white;
            border-radius: 16px;
            box-shadow: var(--card-shadow);
            transition: all 0.3s ease;
            overflow: hidden;
        }

        .stats-card:hover {
            transform: translateY(-5px);
            box-shadow: var(--card-hover-shadow);
        }

        .stats-card .icon-wrapper {
            width: 60px;
            height: 60px;
            border-radius: 12px;
            display: flex;
            align-items: center;
            justify-content: center;
            font-size: 1.5rem;
        }

        .stats-card.success .icon-wrapper {
            background: linear-gradient(135deg, #10b981 0%, #059669 100%);
            color: white;
        }

        .stats-card.warning .icon-wrapper {
            background: linear-gradient(135deg, #f59e0b 0%, #d97706 100%);
            color: white;
        }

        .stats-card.danger .icon-wrapper {
            background: linear-gradient(135deg, #ef4444 0%, #dc2626 100%);
            color: white;
        }

        .stats-card.info .icon-wrapper {
            background: linear-gradient(135deg, #6366f1 0%, #4f46e5 100%);
            color: white;
        }

        .stats-card h3 {
            font-size: 2rem;
            font-weight: 700;
            margin: 0;
        }

        .stats-card p {
            color: #6b7280;
            margin: 0;
            font-size: 0.875rem;
        }

        .session-info-card {
            background: linear-gradient(135deg, var(--primary-color) 0%, var(--secondary-color) 100%);
            color: white;
            border-radius: 16px;
            padding: 1.5rem;
            box-shadow: var(--card-shadow);
        }

        .session-info-item {
            display: flex;
            align-items: center;
            gap: 1rem;
        }

        .session-info-item i {
            font-size: 1.5rem;
            opacity: 0.8;
        }

        .nav-tabs .nav-link {
            border: none;
            color: #6b7280;
            font-weight: 500;
            padding: 1rem 1.5rem;
            transition: all 0.3s ease;
        }

        .nav-tabs .nav-link:hover {
            color: var(--primary-color);
        }

        .nav-tabs .nav-link.active {
            color: var(--primary-color);
            background: transparent;
            border-bottom: 3px solid var(--primary-color);
        }

        .nav-tabs .nav-link .badge {
            font-size: 0.75rem;
            padding: 0.25rem 0.5rem;
        }

        .participant-card {
            background: white;
            border-radius: 12px;
            padding: 1rem;
            box-shadow: var(--card-shadow);
            margin-bottom: 1rem;
            transition: all 0.3s ease;
            display: flex;
            align-items: center;
            gap: 1rem;
        }

        .participant-card:hover {
            box-shadow: var(--card-hover-shadow);
        }

        .participant-avatar {
            width: 50px;
            height: 50px;
            border-radius: 50%;
            background: linear-gradient(135deg, var(--primary-color) 0%, var(--secondary-color) 100%);
            display: flex;
            align-items: center;
            justify-content: center;
            color: white;
            font-weight: 600;
            font-size: 1.25rem;
        }

        .participant-info {
            flex: 1;
        }

        .participant-info h6 {
            margin: 0;
            font-weight: 600;
        }

        .participant-info p {
            margin: 0;
            color: #6b7280;
            font-size: 0.875rem;
        }

        .status-badge {
            padding: 0.5rem 1rem;
            border-radius: 8px;
            font-weight: 500;
            font-size: 0.875rem;
        }

        .status-badge.present {
            background: #d1fae5;
            color: #065f46;
        }

        .status-badge.late {
            background: #fef3c7;
            color: #92400e;
        }

        .status-badge.absent {
            background: #fee2e2;
            color: #991b1b;
        }

        .tab-content {
            background: white;
            border-radius: 16px;
            padding: 1.5rem;
            box-shadow: var(--card-shadow);
            min-height: 400px;
        }

        .empty-state {
            text-align: center;
            padding: 3rem;
            color: #9ca3af;
        }

        .empty-state i {
            font-size: 4rem;
            margin-bottom: 1rem;
            opacity: 0.5;
        }

        .progress-custom {
            height: 12px;
            border-radius: 6px;
            background: #e5e7eb;
            overflow: hidden;
        }

        .progress-custom .progress-bar {
            border-radius: 6px;
        }

        @media (max-width: 768px) {
            .main-content {
                padding: 1rem;
            }

            .stats-card h3 {
                font-size: 1.5rem;
            }
        }
    </style>
<link href="../assets/css/handdrawn.css" rel="stylesheet">
</head>
<body>
    <!-- Sidebar -->
    <%@ include file="sidebar.jsp" %>

    <!-- Main Content -->
    <div class="main-content">
        <!-- Header -->
        <div class="d-flex justify-content-between align-items-start mb-4">
            <div>
                <a href="../AttendanceServlet?action=list" class="btn btn-outline-secondary btn-sm mb-2">
                    <i class="bi bi-arrow-left me-1"></i>Kembali
                </a>
                <h1 class="h3 mb-0"><%= ValidationUtil.sanitizeHtml(attSession != null ? attSession.getSessionName() : "Detail Absensi") %></h1>
                <p class="text-muted mb-0">Rekap kehadiran peserta</p>
            </div>
            <div class="btn-group">
                <% if (attSession != null) { %>
                <a href="AttendanceServlet?action=export&sessionId=<%= attSession.getId() %>&format=csv"
                   class="btn btn-outline-success">
                    <i class="bi bi-file-earmark-excel me-2"></i>CSV
                </a>
                <a href="AttendanceServlet?action=export&sessionId=<%= attSession.getId() %>&format=pdf"
                   class="btn btn-outline-danger">
                    <i class="bi bi-file-earmark-pdf me-2"></i>PDF
                </a>
                <% } %>
            </div>
        </div>

        <% if (success != null) { %>
        <div class="alert alert-success alert-dismissible fade show" role="alert">
            <i class="bi bi-check-circle me-2"></i><%= ValidationUtil.sanitizeHtml(success) %>
            <button type="button" class="btn-close" data-bs-dismiss="alert"></button>
        </div>
        <% } %>

        <% if (error != null) { %>
        <div class="alert alert-danger alert-dismissible fade show" role="alert">
            <i class="bi bi-exclamation-triangle me-2"></i><%= ValidationUtil.sanitizeHtml(error) %>
            <button type="button" class="btn-close" data-bs-dismiss="alert"></button>
        </div>
        <% } %>

        <% if (attSession != null) { %>
        <!-- Session Info Card -->
        <div class="session-info-card mb-4">
            <div class="row">
                <div class="col-md-3 col-6 mb-3 mb-md-0">
                    <div class="session-info-item">
                        <i class="bi bi-hash"></i>
                        <div>
                            <small class="opacity-75">Kode Sesi</small>
                            <h5 class="mb-0 font-monospace"><%= ValidationUtil.sanitizeHtml(attSession.getSessionCode()) %></h5>
                        </div>
                    </div>
                </div>
                <div class="col-md-3 col-6 mb-3 mb-md-0">
                    <div class="session-info-item">
                        <i class="bi bi-calendar-event"></i>
                        <div>
                            <small class="opacity-75">Tanggal</small>
                            <h5 class="mb-0"><%= dateFormat.format(attSession.getSessionDate()) %></h5>
                        </div>
                    </div>
                </div>
                <div class="col-md-3 col-6 mb-3 mb-md-0">
                    <div class="session-info-item">
                        <i class="bi bi-clock"></i>
                        <div>
                            <small class="opacity-75">Waktu</small>
                            <h5 class="mb-0">
                                <%= timeFormat.format(attSession.getStartTime()) %> -
                                <%= timeFormat.format(attSession.getEndTime()) %>
                            </h5>
                        </div>
                    </div>
                </div>
                <div class="col-md-3 col-6">
                    <div class="session-info-item">
                        <i class="bi bi-tag"></i>
                        <div>
                            <small class="opacity-75">Target</small>
                            <h5 class="mb-0"><%= ValidationUtil.sanitizeHtml(attSession.getTargetTag() != null && !attSession.getTargetTag().isEmpty() ? attSession.getTargetTag() : "Semua Peserta") %></h5>
                        </div>
                    </div>
                </div>
            </div>
        </div>

        <!-- Statistics Cards -->
        <div class="row g-3 mb-4">
            <div class="col-6 col-md-3">
                <div class="stats-card success p-3">
                    <div class="d-flex justify-content-between align-items-center">
                        <div>
                            <p class="mb-1">Hadir</p>
                            <h3><%= statsPresent != null ? statsPresent : 0 %></h3>
                        </div>
                        <div class="icon-wrapper">
                            <i class="bi bi-check-circle"></i>
                        </div>
                    </div>
                    <div class="progress-custom mt-2">
                        <div class="progress-bar bg-success" style="width: <%= presentPercent %>%" role="progressbar"></div>
                    </div>
                    <small class="text-muted"><%= String.format("%.1f", presentPercent) %>%</small>
                </div>
            </div>
            <div class="col-6 col-md-3">
                <div class="stats-card warning p-3">
                    <div class="d-flex justify-content-between align-items-center">
                        <div>
                            <p class="mb-1">Terlambat</p>
                            <h3><%= statsLate != null ? statsLate : 0 %></h3>
                        </div>
                        <div class="icon-wrapper">
                            <i class="bi bi-clock-history"></i>
                        </div>
                    </div>
                    <div class="progress-custom mt-2">
                        <div class="progress-bar bg-warning" style="width: <%= latePercent %>%" role="progressbar"></div>
                    </div>
                    <small class="text-muted"><%= String.format("%.1f", latePercent) %>%</small>
                </div>
            </div>
            <div class="col-6 col-md-3">
                <div class="stats-card danger p-3">
                    <div class="d-flex justify-content-between align-items-center">
                        <div>
                            <p class="mb-1">Tidak Hadir</p>
                            <h3><%= absentCount != null ? absentCount : 0 %></h3>
                        </div>
                        <div class="icon-wrapper">
                            <i class="bi bi-x-circle"></i>
                        </div>
                    </div>
                    <div class="progress-custom mt-2">
                        <div class="progress-bar bg-danger" style="width: <%= absentPercent %>%" role="progressbar"></div>
                    </div>
                    <small class="text-muted"><%= String.format("%.1f", absentPercent) %>%</small>
                </div>
            </div>
            <div class="col-6 col-md-3">
                <div class="stats-card info p-3">
                    <div class="d-flex justify-content-between align-items-center">
                        <div>
                            <p class="mb-1">Total Peserta</p>
                            <h3><%= totalExpectedUsers != null ? totalExpectedUsers : 0 %></h3>
                        </div>
                        <div class="icon-wrapper">
                            <i class="bi bi-people"></i>
                        </div>
                    </div>
                    <div class="mt-2">
                        <span class="badge bg-light text-dark">Kehadiran: <%= attendancePercentage != null ? String.format("%.1f", attendancePercentage) : "0.0" %>%</span>
                    </div>
                </div>
            </div>
        </div>

        <!-- Tabs and Content -->
        <ul class="nav nav-tabs mb-3" id="attendanceTabs" role="tablist">
            <li class="nav-item" role="presentation">
                <button class="nav-link active" id="present-tab" data-bs-toggle="tab" data-bs-target="#present" type="button" role="tab">
                    <i class="bi bi-check-circle-fill text-success me-1"></i>
                    Hadir
                    <span class="badge bg-success ms-1"><%= statsPresent != null ? statsPresent : 0 %></span>
                </button>
            </li>
            <li class="nav-item" role="presentation">
                <button class="nav-link" id="late-tab" data-bs-toggle="tab" data-bs-target="#late" type="button" role="tab">
                    <i class="bi bi-clock-history text-warning me-1"></i>
                    Terlambat
                    <span class="badge bg-warning text-dark ms-1"><%= statsLate != null ? statsLate : 0 %></span>
                </button>
            </li>
            <li class="nav-item" role="presentation">
                <button class="nav-link" id="absent-tab" data-bs-toggle="tab" data-bs-target="#absent" type="button" role="tab">
                    <i class="bi bi-x-circle-fill text-danger me-1"></i>
                    Tidak Hadir
                    <span class="badge bg-danger ms-1"><%= absentCount != null ? absentCount : 0 %></span>
                </button>
            </li>
        </ul>

        <div class="tab-content" id="attendanceTabContent">
            <!-- Present Tab -->
            <div class="tab-pane fade show active" id="present" role="tabpanel">
                <% if (presentRecords != null && !presentRecords.isEmpty()) { %>
                    <% for (AttendanceRecord record : presentRecords) { %>
                    <div class="participant-card">
                        <div class="participant-avatar">
                            <%= ValidationUtil.sanitizeHtml(record.getUserName() != null ? String.valueOf(record.getUserName().charAt(0)) : "U") %>
                        </div>
                        <div class="participant-info">
                            <h6><%= ValidationUtil.sanitizeHtml(record.getUserName() != null ? record.getUserName() : "-") %></h6>
                            <p><%= ValidationUtil.sanitizeHtml(record.getUserEmail() != null ? record.getUserEmail() : "-") %></p>
                        </div>
                        <% if (record.getUserTag() != null && !record.getUserTag().isEmpty()) { %>
                        <span class="badge bg-info"><%= ValidationUtil.sanitizeHtml(record.getUserTag()) %></span>
                        <% } %>
                        <span class="status-badge present">
                            <i class="bi bi-check-circle me-1"></i>Hadir
                        </span>
                        <span class="text-muted small">
                            <i class="bi bi-clock me-1"></i><%= record.getFormattedAttendanceTime() %>
                        </span>
                    </div>
                    <% } %>
                <% } else { %>
                <div class="empty-state">
                    <i class="bi bi-check-circle"></i>
                    <p>Tidak ada peserta yang hadir tepat waktu.</p>
                </div>
                <% } %>
            </div>

            <!-- Late Tab -->
            <div class="tab-pane fade" id="late" role="tabpanel">
                <% if (lateRecords != null && !lateRecords.isEmpty()) { %>
                    <% for (AttendanceRecord record : lateRecords) { %>
                    <div class="participant-card">
                        <div class="participant-avatar" style="background: linear-gradient(135deg, #f59e0b 0%, #d97706 100%);">
                            <%= ValidationUtil.sanitizeHtml(record.getUserName() != null ? String.valueOf(record.getUserName().charAt(0)) : "U") %>
                        </div>
                        <div class="participant-info">
                            <h6><%= ValidationUtil.sanitizeHtml(record.getUserName() != null ? record.getUserName() : "-") %></h6>
                            <p><%= ValidationUtil.sanitizeHtml(record.getUserEmail() != null ? record.getUserEmail() : "-") %></p>
                        </div>
                        <% if (record.getUserTag() != null && !record.getUserTag().isEmpty()) { %>
                        <span class="badge bg-info"><%= ValidationUtil.sanitizeHtml(record.getUserTag()) %></span>
                        <% } %>
                        <span class="status-badge late">
                            <i class="bi bi-clock-history me-1"></i>Terlambat
                        </span>
                        <span class="text-muted small">
                            <i class="bi bi-clock me-1"></i><%= record.getFormattedAttendanceTime() %>
                        </span>
                        <% if (record.getNotes() != null && !record.getNotes().isEmpty()) { %>
                        <span class="badge bg-secondary"><%= ValidationUtil.sanitizeHtml(record.getNotes()) %></span>
                        <% } %>
                    </div>
                    <% } %>
                <% } else { %>
                <div class="empty-state">
                    <i class="bi bi-clock-history"></i>
                    <p>Tidak ada peserta yang terlambat.</p>
                </div>
                <% } %>
            </div>

            <!-- Absent Tab -->
            <div class="tab-pane fade" id="absent" role="tabpanel">
                <% if (absentUsers != null && !absentUsers.isEmpty()) { %>
                    <% for (User user : absentUsers) { %>
                    <div class="participant-card">
                        <div class="participant-avatar" style="background: linear-gradient(135deg, #ef4444 0%, #dc2626 100%);">
                            <%= ValidationUtil.sanitizeHtml(user.getName() != null ? String.valueOf(user.getName().charAt(0)) : "U") %>
                        </div>
                        <div class="participant-info">
                            <h6><%= ValidationUtil.sanitizeHtml(user.getName() != null ? user.getName() : "-") %></h6>
                            <p><%= ValidationUtil.sanitizeHtml(user.getEmail() != null ? user.getEmail() : "-") %></p>
                        </div>
                        <% if (user.getTag() != null && !user.getTag().isEmpty()) { %>
                        <span class="badge bg-info"><%= ValidationUtil.sanitizeHtml(user.getTag()) %></span>
                        <% } %>
                        <span class="status-badge absent">
                            <i class="bi bi-x-circle me-1"></i>Tidak Hadir
                        </span>
                    </div>
                    <% } %>
                <% } else { %>
                <div class="empty-state">
                    <i class="bi bi-people"></i>
                    <p>Semua peserta hadir! 🎉</p>
                </div>
                <% } %>
            </div>
        </div>
        <% } else { %>
        <div class="alert alert-warning">
            <i class="bi bi-exclamation-triangle me-2"></i>Sesi tidak ditemukan.
        </div>
        <% } %>
    </div>

    <script src="https://cdn.jsdelivr.net/npm/bootstrap@5.3.0/dist/js/bootstrap.bundle.min.js"></script>
    <script>
        // Save the active tab in localStorage
        const tabButtons = document.querySelectorAll('#attendanceTabs button[data-bs-toggle="tab"]');
        tabButtons.forEach(button => {
            button.addEventListener('shown.bs.tab', function(event) {
                localStorage.setItem('activeAttendanceTab', event.target.id);
            });
        });

        // Restore active tab from localStorage
        const activeTabId = localStorage.getItem('activeAttendanceTab');
        if (activeTabId) {
            const activeTab = document.querySelector('#attendanceTabs button#' + activeTabId);
            if (activeTab) {
                const tabInstance = new bootstrap.Tab(activeTab);
                tabInstance.show();
            }
        }
    </script>
</body>
</html>

<%@ page contentType="text/html;charset=UTF-8" language="java" %>
<%@ taglib prefix="c" uri="http://java.sun.com/jsp/jstl/core" %>
<%@ page import="com.examora.model.User" %>
<%@ page import="com.examora.model.Quiz" %>
<%@ page import="com.examora.model.Submission" %>
<%@ page import="java.util.List" %>
<%@ page import="java.util.Map" %>
<%@ page import="java.util.Set" %>
<%@ page import="java.util.TreeSet" %>
<%@ page import="java.time.format.DateTimeFormatter" %>
<%@ page import="java.time.ZoneId" %>
<%!
    public String esc(String input) {
        if (input == null) return "";
        return input.replace("&", "&amp;").replace("<", "&lt;").replace(">", "&gt;").replace("\"", "&quot;").replace("'", "&#39;");
    }

    public String jsEsc(String input) {
        if (input == null) return "";
        return input.replace("\\", "\\\\").replace("\"", "\\\"").replace("'", "\\'").replace("\n", "\\n").replace("\r", "\\r");
    }

    public String formatTime(Integer seconds) {
        if (seconds == null || seconds <= 0) return "0:00";
        int minutes = seconds / 60;
        int secs = seconds % 60;
        return minutes + ":" + (secs < 10 ? "0" : "") + secs;
    }

    public String getTagColorClass(String tag) {
        if (tag == null || tag.isEmpty()) return "";
        String[] colors = {"purple", "blue", "green", "yellow", "red", "orange", "pink", "cyan", "indigo"};
        int hash = tag.hashCode();
        int index = Math.abs(hash) % colors.length;
        return colors[index];
    }
%>
<%
    User currentUser = (User) session.getAttribute("user");
    if (currentUser == null || !currentUser.isAdmin()) {
        response.sendRedirect("../LoginServlet");
        return;
    }
    List<Quiz> quizzes = (List<Quiz>) request.getAttribute("quizzes");
    Map<String, Object> statistics = (Map<String, Object>) request.getAttribute("statistics");
    List<Map<String, Object>> submissions = (List<Map<String, Object>>) request.getAttribute("submissions");
    Integer selectedQuizId = (Integer) request.getAttribute("selectedQuizId");
    String error = (String) request.getAttribute("error");
    ZoneId jakartaZone = ZoneId.of("Asia/Jakarta");
    DateTimeFormatter dtf = DateTimeFormatter.ofPattern("dd MMM yyyy, HH:mm").withZone(jakartaZone);

    String selectedQuizTitle = "";
    if (quizzes != null && selectedQuizId != null) {
        for (Quiz q : quizzes) {
            if (q.getId().equals(selectedQuizId)) {
                selectedQuizTitle = q.getTitle();
                break;
            }
        }
    }
%>
<!DOCTYPE html>
<html lang="id">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Statistik Quiz - Exatuy</title>
    <link href="https://cdn.jsdelivr.net/npm/bootstrap@5.3.0/dist/css/bootstrap.min.css" rel="stylesheet">
    <link href="https://cdn.jsdelivr.net/npm/bootstrap-icons@1.10.0/font/bootstrap-icons.css" rel="stylesheet">
    <link href="../assets/css/style.css" rel="stylesheet">
    <link rel="icon" type="image/svg+xml" href="../assets/img/favicon.svg?v=3">
    <script src="https://cdn.jsdelivr.net/npm/chart.js"></script>
    <style>
        :root {
            /* Modern Vibrant Color Palette */
            --bg-primary: #f8fafc;
            --bg-secondary: #f1f5f9;
            --bg-card: #ffffff;

            /* Primary - Vibrant Blue */
            --primary: #2563eb;
            --primary-light: #dbeafe;
            --primary-dark: #1d4ed8;

            /* Success - Vibrant Green */
            --success: #10b981;
            --success-light: #d1fae5;
            --success-dark: #059669;

            /* Warning - Vibrant Orange */
            --warning: #f59e0b;
            --warning-light: #fef3c7;
            --warning-dark: #d97706;

            /* Info - Vibrant Cyan */
            --info: #06b6d4;
            --info-light: #cffafe;
            --info-dark: #0891b2;

            /* Danger - Vibrant Red */
            --danger: #ef4444;
            --danger-light: #fee2e2;
            --danger-dark: #dc2626;

            /* Purple - Vibrant */
            --purple: #8b5cf6;
            --purple-light: #ede9fe;
            --purple-dark: #7c3aed;

            /* Text Colors - WCAG AA Compliant */
            --text-primary: #2d3748;  /* Soft dark gray (12.6:1 contrast) */
            --text-secondary: #4a5568;  /* Medium gray (7.5:1 contrast) */
            --text-muted: #718096;  /* Comfortable gray (4.7:1 contrast) - improved from #9ca3af */
            --text-light: #a0aec0;  /* Subtle gray (2.9:1 contrast) */

            /* Border Colors */
            --border-light: #e5e7eb;
            --border-medium: #d1d5db;

            /* Chart Colors */
            --chart-grid: rgba(0, 0, 0, 0.08);
            --chart-tick: #718096;

            /* Icon Opacity */
            --icon-opacity-muted: 0.4;

            /* Shadows */
            --shadow-sm: 0 1px 3px rgba(0, 0, 0, 0.1);
            --shadow-md: 0 4px 12px rgba(0, 0, 0, 0.1);
            --shadow-lg: 0 10px 25px rgba(0, 0, 0, 0.15);
        }

        body {
            background-color: var(--bg-primary);
            color: var(--text-primary);
            font-family: 'Inter', -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, sans-serif;
        }

        .main-content {
            padding: 2rem;
            max-width: 100%; /* Full width for better content display */
        }

        .stat-card {
            background: var(--bg-card);
            border-radius: 16px;
            border: 1px solid var(--border);
            transition: all 0.3s cubic-bezier(0.4, 0, 0.2, 1);
            overflow: hidden;
            box-shadow: var(--shadow-sm);
        }

        .stat-card:hover {
            transform: translateY(-2px);
            box-shadow: var(--shadow-md);
        }

        .stat-card .stat-icon {
            width: 52px;
            height: 52px;
            border-radius: 14px;
            display: flex;
            align-items: center;
            justify-content: center;
            font-size: 1.4rem;
            transition: all 0.3s ease;
        }

        .stat-card.primary .stat-icon {
            background: var(--primary);
            color: var(--primary);
        }

        .stat-card.success .stat-icon {
            background: var(--success);
            color: var(--success);
        }

        .stat-card.info .stat-icon {
            background: var(--info);
            color: var(--info);
        }

        .stat-card.warning .stat-icon {
            background: var(--warning);
            color: var(--warning);
        }

        .stat-card .stat-value {
            font-size: 1.75rem;
            font-weight: 600;
            line-height: 1;
            color: var(--text-primary);
        }

        .stat-card .stat-label {
            font-size: 0.8rem;
            color: var(--text-secondary);
            font-weight: 500;
            text-transform: uppercase;
            letter-spacing: 0.3px;
        }

        .chart-card {
            background: var(--bg-card);
            border-radius: 16px;
            border: 1px solid var(--border);
            overflow: hidden;
            box-shadow: var(--shadow-sm);
            margin-top: 50px;
            margin-bottom: 30px;
        }

        .chart-card:first-of-type {
            margin-top: 0;
        }

        .chart-card .card-header {
            background: var(--bg-card);
            border-bottom: 1px solid var(--border);
            padding: 16px 20px;
        }

        .chart-card .card-body {
            padding: 20px;
        }

        .score-range-card {
            background: var(--bg-card);
            border-radius: 12px;
            border: 1px solid var(--border);
            padding: 20px;
            text-align: center;
            transition: all 0.3s cubic-bezier(0.4, 0, 0.2, 1);
            height: 100%;
        }

        .score-range-card:hover {
            transform: translateY(-2px);
            box-shadow: var(--shadow-md);
        }

        .score-range-card .score-value {
            font-size: 2rem;
            font-weight: 600;
            line-height: 1;
        }

        .score-range-card .score-range {
            font-size: 0.85rem;
            color: var(--text-secondary);
            margin: 8px 0 4px;
            font-weight: 500;
        }

        .participant-row {
            background: var(--bg-card);
            border: 2px solid var(--border-medium);
            border-radius: 12px;
            padding: 14px 16px;
            margin-bottom: 10px;
            transition: all 0.3s cubic-bezier(0.4, 0, 0.2, 1);
            cursor: pointer;
        }

        .participant-row:hover {
            border-color: var(--primary);
            box-shadow: var(--shadow-sm);
            transform: translateX(4px);
        }

        .tag-badge {
            display: inline-flex;
            align-items: center;
            padding: 4px 10px;
            border-radius: 6px;
            font-size: 0.75rem;
            font-weight: 600;
        }

        .tag-badge.purple { background: #a855f7; color: white; }
        .tag-badge.blue { background: #3b82f6; color: white; }
        .tag-badge.green { background: #22c55e; color: white; }
        .tag-badge.yellow { background: #eab308; color: white; }
        .tag-badge.red { background: #ef4444; color: white; }
        .tag-badge.orange { background: #f97316; color: white; }
        .tag-badge.pink { background: #ec4899; color: white; }
        .tag-badge.cyan { background: #06b6d4; color: white; }
        .tag-badge.indigo { background: #6366f1; color: white; }

        .participant-row .participant-name {
            font-weight: 500;
            color: var(--text-primary);
        }

        .participant-row .score-badge {
            min-width: 48px;
            text-align: center;
            padding: 6px 12px;
            border-radius: 8px;
            font-weight: 600;
            font-size: 0.95rem;
            color: white !important;
        }

        /* Score Badge Color Classes */
        .score-badge-success { background-color: var(--success) !important; }
        .score-badge-primary { background-color: var(--primary) !important; }
        .score-badge-info { background-color: var(--info) !important; }
        .score-badge-warning { background-color: var(--warning) !important; }
        .score-badge-danger { background-color: var(--danger-dark) !important; }

        .quiz-selector-card {
            background: linear-gradient(135deg, var(--primary) 0%, var(--primary-dark) 100%);
            border-radius: 16px;
            box-shadow: var(--shadow-sm);
        }

        .quiz-selector-card .form-select {
            border-radius: 10px;
            border: none;
            padding: 12px 16px;
            font-size: 1rem;
            font-weight: 500;
        }

        .info-card {
            background: var(--bg-card);
            border-radius: 12px;
            border: 1px solid var(--border);
        }

        .info-card .info-row {
            display: flex;
            justify-content: space-between;
            align-items: center;
            padding: 12px 0;
            border-bottom: 1px solid var(--border);
        }

        .info-card .info-row:last-child {
            border-bottom: none;
        }

        .info-card .info-label {
            color: var(--text-secondary);
            font-size: 0.9rem;
            font-weight: 500;
        }

        .info-card .info-value {
            font-weight: 600;
            color: var(--text-primary);
        }

        .filter-card {
            background: var(--bg-card);
            border-radius: 12px;
            border: 1px solid var(--border);
        }

        .filter-card .form-control,
        .filter-card .form-select {
            border-radius: 8px;
            border-color: var(--border-medium);
            font-size: 0.9rem;
        }

        .filter-card .form-control:focus,
        .filter-card .form-select:focus {
            border-color: var(--primary);
            box-shadow: 0 0 0 3px var(--primary);
        }

        .user-detail-modal .modal-body {
            max-height: 70vh;
            overflow-y: auto;
        }

        .question-item {
            border-left: 4px solid var(--border-medium);
            padding-left: 16px;
            margin-bottom: 20px;
            border-radius: 0 8px 8px 0;
            background: var(--bg-card);
        }

        .question-item.correct {
            border-left-color: var(--success);
            background: var(--bg-card);
        }

        .question-item.wrong {
            border-left-color: var(--danger);
            background: var(--bg-card);
        }

        .option-item {
            padding: 10px 14px;
            border-radius: 8px;
            margin-bottom: 6px;
            border: 1px solid var(--border);
            font-size: 0.9rem;
            background: var(--bg-card);
        }

        /* User's selected answer (wrong) */
        .option-item.selected {
            background: #fee2e2 !important;
            border-color: var(--danger) !important;
            color: var(--danger-dark);
        }

        /* Correct answer */
        .option-item.correct-answer {
            background: #d1fae5 !important;
            border-color: var(--success) !important;
            color: var(--success-dark);
        }

        /* When selected is also correct (user got it right) */
        .option-item.selected.correct-answer {
            background: #d1fae5 !important;
            border-color: var(--success) !important;
            color: var(--success-dark);
        }

        #userDetailContent {
            background: var(--bg-card);
            padding: 20px;
            border-radius: 12px;
        }

        @media print {
            .no-print {
                display: none !important;
            }
        }

        .empty-state {
            text-align: center;
            padding: 3rem 2rem;
            color: var(--text-muted);
        }

        .empty-state i {
            font-size: 3rem;
            margin-bottom: 1rem;
            opacity: var(--icon-opacity-muted);
        }

        .badge {
            font-weight: 600;
            padding: 6px 12px;
            font-size: 0.8rem;
            color: white !important;
        }

        /* Badge color overrides for readability */
        .badge[style*="primary-light"] {
            background-color: var(--primary) !important;
            color: white !important;
        }

        .badge[style*="success-light"] {
            background-color: var(--success) !important;
            color: white !important;
        }

        .badge[style*="warning-light"] {
            background-color: var(--warning) !important;
            color: white !important;
        }

        .badge[style*="info-light"] {
            background-color: var(--info) !important;
            color: white !important;
        }

        .badge[style*="danger-light"] {
            background-color: var(--danger) !important;
            color: white !important;
        }

        .badge[style*="purple-light"] {
            background-color: var(--purple) !important;
            color: white !important;
        }

        .badge[style*="orange-light"] {
            background-color: var(--orange) !important;
            color: white !important;
        }

        .badge[style*="teal-light"] {
            background-color: var(--teal) !important;
            color: white !important;
        }

        .badge[style*="bg-secondary"] {
            background-color: var(--secondary) !important;
            color: white !important;
        }

        /* Pagination */
        .pagination .page-link {
            border: none;
            color: var(--text-primary);
            border-radius: 8px;
            margin: 0 2px;
            font-weight: 500;
        }

        .pagination .page-item.active .page-link {
            background: var(--primary);
            color: white;
        }

        @media (max-width: 768px) {
            .main-content {
                padding: 1rem;
            }

            .stat-card .stat-value {
                font-size: 1.5rem;
            }

            .score-range-card .score-value {
                font-size: 1.75rem;
            }
        }

        /* Utility Classes for Better Readability */
        .text-muted { color: var(--text-muted) !important; }
        .text-secondary { color: var(--text-secondary) !important; }
        .text-light { color: var(--text-light) !important; }
        .text-primary { color: var(--text-primary) !important; }
        .text-white { color: white !important; }
        .icon-muted { opacity: var(--icon-opacity-muted) !important; }

        /* Color Utility Classes */
        .text-primary-blue { color: var(--primary) !important; }
        .text-success { color: var(--success) !important; }
        .text-danger { color: var(--danger) !important; }
        .text-warning { color: var(--warning) !important; }
        .text-info { color: var(--info) !important; }

        /* Alert Classes */
        .alert-warning { background-color: var(--warning); color: white; border: none; }
        .alert-warning .alert-text { color: white; }

        /* Background Utility Classes */
        .bg-secondary-light { background: var(--bg-secondary) !important; }
        .border-medium { border-color: var(--border-medium) !important; }
        .input-group-text-custom { background: var(--bg-secondary); border-color: var(--border-medium); }

        /* Badge Utility Classes */
        .badge-primary { background: var(--primary) !important; color: white !important; }
        .badge-success { background: var(--success) !important; color: white !important; }
        .badge-danger { background: var(--danger-dark) !important; color: white !important; font-weight: 600; }
        .badge-warning { background: var(--warning) !important; color: white !important; font-weight: 600; }
        .badge-info { background: var(--info) !important; color: white !important; font-weight: 600; }

        /* Table Badge Improvements */
        .table .badge {
            padding: 6px 12px;
            font-size: 0.85rem;
            font-weight: 600;
            letter-spacing: 0.3px;
        }

        /* Participant Number Styling */
        .participant-number {
            font-size: 0.9rem;
            color: var(--text-muted);
            min-width: 30px;
            text-align: center;
            font-weight: 500;
        }

        /* Border Utility Classes */
        .border-custom { border: 1px solid var(--border) !important; }
        .border-top-custom { border-top: 1px solid var(--border) !important; }
        .border-bottom-custom { border-bottom: 1px solid var(--border) !important; }
        .border-danger-custom { border: 1px solid var(--danger) !important; }
        .border-bottom-danger { border-bottom: 1px solid var(--danger) !important; }

        /* Score Stats Utility */
        .score-stat { color: var(--success); font-weight: 600; font-size: 1.1rem; }
        .score-stat-danger { color: var(--danger); font-weight: 600; font-size: 1.1rem; }
        .score-stat-warning { color: var(--warning); font-weight: 600; font-size: 1.1rem; }

        /* Avatar Circle */
        .avatar-circle { width: 48px; height: 48px; border-radius: 50%; background: var(--primary); display: flex; align-items: center; justify-content: center; }
        .avatar-circle.bg-danger { background: var(--danger-dark); }
        .avatar-text { color: white; font-weight: 600; font-size: 1.1rem; }

        /* Button Utility */
        .btn-white-border { background: white; border: 1px solid var(--border-medium); }
        .btn-primary-solid { background: var(--primary); color: white; border: none; border-radius: 8px; }

        /* Card Utility */
        .card-content-rounded { border-radius: 16px; border: 1px solid var(--border); }
        .card-header-transparent { background: transparent; border-bottom: 1px solid var(--danger); }
        .card-footer-border { border-top: 1px solid var(--border); }
        .card-danger-bg { border: 2px solid var(--danger-dark); background: var(--danger-dark); }
        .card-header-danger-transparent { background: var(--danger-dark) !important; border-bottom: 1px solid rgba(255,255,255,0.3); color: white !important; }
        .card-header-danger-transparent h6, .card-header-danger-transparent .h6 { color: white !important; }
        .card-header-danger-transparent i { color: white !important; }
        .card-header-danger-transparent .form-select { background: white; color: var(--text-primary); border: none; }
        .card-header-danger-transparent .form-select:focus { box-shadow: 0 0 0 2px rgba(255,255,255,0.3); }
    </style>
<link href="../assets/css/handdrawn.css" rel="stylesheet">
</head>
<body>
    <%@ include file="sidebar.jsp" %>

    <div class="main-content">
        <!-- Header -->
        <div class="d-flex justify-content-between align-items-start mb-4">
            <div>
                <h1 class="h3 mb-1 fw-bold" class="text-primary">
                    <i class="bi bi-bar-chart-fill me-2" class="text-primary-blue"></i>Statistik Quiz
                </h1>
                <nav aria-label="breadcrumb">
                    <ol class="breadcrumb mb-0">
                        <li class="breadcrumb-item"><a href="../AdminServlet?action=dashboard" class="text-secondary" style="text-decoration: none;">Dashboard</a></li>
                        <li class="breadcrumb-item active" class="text-primary-blue">Statistik Quiz</li>
                    </ol>
                </nav>
            </div>
            <% if (statistics != null && submissions != null && !submissions.isEmpty()) { %>
            <div class="d-flex gap-2">
                <button class="btn btn-outline-success" onclick="exportAllToTxt()">
                    <i class="bi bi-file-earmark-text me-1"></i>Export TXT
                </button>
                <button class="btn btn-outline-primary" onclick="exportAllToPdf()">
                    <i class="bi bi-file-earmark-pdf me-1"></i>Export PDF
                </button>
            </div>
            <% } %>
        </div>

        <% if (error != null) { %>
        <div class="alert alert-danger alert-dismissible fade show" style="border-radius: 12px; border: none; background: var(--danger);">
            <i class="bi bi-exclamation-triangle me-2"></i><%= esc(error) %>
            <button type="button" class="btn-close" data-bs-dismiss="alert"></button>
        </div>
        <% } %>

        <!-- Quiz Selector -->
        <div class="card quiz-selector-card mb-4">
            <div class="card-body py-3">
                <form method="get" action="../AdminServlet" class="row g-3 align-items-center">
                    <input type="hidden" name="action" value="statistics">
                    <div class="col-auto">
                        <label class="form-label text-white mb-0 fs-5">
                            <i class="bi bi-journal-text me-2"></i>Pilih Quiz
                        </label>
                    </div>
                    <div class="col-md-5">
                        <select name="quizId" class="form-select" onchange="this.form.submit()">
                            <option value="">-- Pilih Quiz --</option>
                            <% if (quizzes != null) {
                                for (Quiz quiz : quizzes) { %>
                            <option value="<%= quiz.getId() %>"
                                    <%= selectedQuizId != null && selectedQuizId.equals(quiz.getId()) ? "selected" : "" %>>
                                <%= esc(quiz.getTitle()) %>
                            </option>
                            <% }
                            } %>
                        </select>
                    </div>
                </form>
            </div>
        </div>

        <% if (statistics != null) {
            int totalSubmissions = statistics.get("totalSubmissions") != null ? (Integer) statistics.get("totalSubmissions") : 0;
            double averageScore = statistics.get("averageScore") != null ? (Double) statistics.get("averageScore") : 0;
            double highestScore = statistics.get("highestScore") != null ? (Double) statistics.get("highestScore") : 0;
            double lowestScore = statistics.get("lowestScore") != null ? (Double) statistics.get("lowestScore") : 0;
            double passRate = statistics.get("passRate") != null ? (Double) statistics.get("passRate") : 0;
            int passedCount = statistics.get("passedCount") != null ? (Integer) statistics.get("passedCount") : 0;
            int failedCount = statistics.get("failedCount") != null ? (Integer) statistics.get("failedCount") : 0;
            int avgTime = statistics.get("averageTimeSpent") != null ? (Integer) statistics.get("averageTimeSpent") : 0;
            int minTime = statistics.get("minTimeSpent") != null ? (Integer) statistics.get("minTimeSpent") : 0;
            int maxTime = statistics.get("maxTimeSpent") != null ? (Integer) statistics.get("maxTimeSpent") : 0;
        %>

        <!-- Statistics Overview Cards -->
        <div class="row mb-4">
            <div class="col-lg-3 col-md-6 mb-3">
                <div class="card stat-card primary h-100">
                    <div class="card-body">
                        <div class="d-flex align-items-center">
                            <div class="stat-icon me-3">
                                <i class="bi bi-people-fill"></i>
                            </div>
                            <div>
                                <div class="stat-value"><%= totalSubmissions %></div>
                                <div class="stat-label">Total Peserta</div>
                            </div>
                        </div>
                    </div>
                </div>
            </div>
            <div class="col-lg-3 col-md-6 mb-3">
                <div class="card stat-card success h-100">
                    <div class="card-body">
                        <div class="d-flex align-items-center">
                            <div class="stat-icon me-3">
                                <i class="bi bi-graph-up-arrow"></i>
                            </div>
                            <div>
                                <div class="stat-value"><%= String.format("%.1f", averageScore) %></div>
                                <div class="stat-label">Rata-rata Nilai</div>
                            </div>
                        </div>
                    </div>
                </div>
            </div>
            <div class="col-lg-3 col-md-6 mb-3">
                <div class="card stat-card info h-100">
                    <div class="card-body">
                        <div class="d-flex align-items-center">
                            <div class="stat-icon me-3">
                                <i class="bi bi-trophy-fill"></i>
                            </div>
                            <div>
                                <div class="stat-value"><%= String.format("%.0f", highestScore) %></div>
                                <div class="stat-label">Nilai Tertinggi</div>
                            </div>
                        </div>
                    </div>
                </div>
            </div>
            <div class="col-lg-3 col-md-6 mb-3">
                <div class="card stat-card warning h-100">
                    <div class="card-body">
                        <div class="d-flex align-items-center">
                            <div class="stat-icon me-3">
                                <i class="bi bi-arrow-down-circle-fill"></i>
                            </div>
                            <div>
                                <div class="stat-value"><%= String.format("%.0f", lowestScore) %></div>
                                <div class="stat-label">Nilai Terendah</div>
                            </div>
                        </div>
                    </div>
                </div>
            </div>
        </div>

        <!-- Charts Row -->
        <div class="row mb-4">
            <div class="col-lg-8 mb-4">
                <div class="card chart-card h-100">
                    <div class="card-header d-flex justify-content-between align-items-center">
                        <h6 class="mb-0 fw-bold text-primary">
                            <i class="bi bi-bar-chart me-2 text-primary-blue"></i>Distribusi Nilai
                        </h6>
                        <span class="badge badge-primary"><%= totalSubmissions %> peserta</span>
                    </div>
                    <div class="card-body">
                        <canvas id="scoreDistributionChart" height="120"></canvas>
                    </div>
                </div>
            </div>
            <div class="col-lg-4 mb-4">
                <div class="card chart-card h-100">
                    <div class="card-header">
                        <h6 class="mb-0 fw-bold text-primary">
                            <i class="bi bi-pie-chart me-2 text-success"></i>Tingkat Kelulusan
                        </h6>
                    </div>
                    <div class="card-body d-flex flex-column align-items-center justify-content-center">
                        <canvas id="passRateChart" height="180"></canvas>
                        <div class="d-flex gap-4 mt-3">
                            <div class="text-center">
                                <div class="fw-bold fs-4 text-success"><%= passedCount %></div>
                                <div class="small text-secondary">Lulus</div>
                            </div>
                            <div class="text-center">
                                <div class="fw-bold fs-4 text-danger"><%= failedCount %></div>
                                <div class="small text-secondary">Tidak Lulus</div>
                            </div>
                        </div>
                    </div>
                </div>
            </div>
        </div>

        <!-- Score Distribution Cards -->
        <div class="card chart-card mb-4">
            <div class="card-header">
                <h6 class="mb-0 fw-bold text-primary">
                    <i class="bi bi-distribute-horizontal me-2 text-info"></i>Distribusi Rentang Nilai
                </h6>
            </div>
            <div class="card-body">
                <div class="row g-3">
                    <div class="col">
                        <div class="score-range-card">
                            <div class="score-value text-danger"><%= statistics.get("scoreRange0_40") != null ? statistics.get("scoreRange0_40") : 0 %></div>
                            <div class="score-range">0 - 40</div>
                            <span class="badge badge-danger">Sangat Kurang</span>
                        </div>
                    </div>
                    <div class="col">
                        <div class="score-range-card">
                            <div class="score-value text-warning"><%= statistics.get("scoreRange41_60") != null ? statistics.get("scoreRange41_60") : 0 %></div>
                            <div class="score-range">41 - 60</div>
                            <span class="badge badge-warning">Kurang</span>
                        </div>
                    </div>
                    <div class="col">
                        <div class="score-range-card">
                            <div class="score-value text-info"><%= statistics.get("scoreRange61_75") != null ? statistics.get("scoreRange61_75") : 0 %></div>
                            <div class="score-range">61 - 75</div>
                            <span class="badge badge-info">Cukup</span>
                        </div>
                    </div>
                    <div class="col">
                        <div class="score-range-card">
                            <div class="score-value text-primary-blue"><%= statistics.get("scoreRange76_85") != null ? statistics.get("scoreRange76_85") : 0 %></div>
                            <div class="score-range">76 - 85</div>
                            <span class="badge badge-primary">Baik</span>
                        </div>
                    </div>
                    <div class="col">
                        <div class="score-range-card">
                            <div class="score-value text-success"><%= statistics.get("scoreRange86_100") != null ? statistics.get("scoreRange86_100") : 0 %></div>
                            <div class="score-range">86 - 100</div>
                            <span class="badge badge-success">Sangat Baik</span>
                        </div>
                    </div>
                </div>
            </div>
        </div>

        <!-- Additional Stats Row -->
        <div class="row mb-4">
            <div class="col-md-6 mb-4">
                <div class="card info-card h-100">
                    <div class="card-header py-3">
                        <h6 class="mb-0 fw-bold text-primary">
                            <i class="bi bi-clock-history me-2 text-primary-blue"></i>Statistik Waktu
                        </h6>
                    </div>
                    <div class="card-body">
                        <div class="info-row">
                            <span class="info-label"><i class="bi bi-clock me-2"></i>Rata-rata Waktu</span>
                            <span class="info-value"><%= avgTime %> detik</span>
                        </div>
                        <div class="info-row">
                            <span class="info-label"><i class="bi bi-lightning-charge me-2"></i>Waktu Tercepat</span>
                            <span class="info-value" class="text-success"><%= minTime %> detik</span>
                        </div>
                        <div class="info-row">
                            <span class="info-label"><i class="bi bi-hourglass-split me-2"></i>Waktu Terlama</span>
                            <span class="info-value" class="text-warning"><%= maxTime %> detik</span>
                        </div>
                    </div>
                </div>
            </div>
            <div class="col-md-6 mb-4">
                <div class="card info-card h-100">
                    <div class="card-header py-3">
                        <h6 class="mb-0 fw-bold" class="text-primary">
                            <i class="bi bi-percent me-2" class="text-success"></i>Ringkasan Kelulusan
                        </h6>
                    </div>
                    <div class="card-body">
                        <div class="info-row">
                            <span class="info-label"><i class="bi bi-check-circle me-2"></i>Tingkat Kelulusan</span>
                            <span class="info-value <%= passRate >= 70 ? "text-success" : passRate >= 50 ? "text-warning" : "text-danger" %>">
                                <%= String.format("%.1f", passRate) %>%
                            </span>
                        </div>
                        <div class="info-row">
                            <span class="info-label"><i class="bi bi-person-check me-2"></i>Peserta Lulus</span>
                            <span class="info-value" class="text-success"><%= passedCount %> peserta</span>
                        </div>
                        <div class="info-row">
                            <span class="info-label"><i class="bi bi-person-x me-2"></i>Peserta Tidak Lulus</span>
                            <span class="info-value" class="text-danger"><%= failedCount %> peserta</span>
                        </div>
                    </div>
                </div>
            </div>
        </div>

        <!-- Participant List -->
        <div class="card chart-card">
            <div class="card-header d-flex justify-content-between align-items-center flex-wrap gap-2">
                <h6 class="mb-0 fw-bold" class="text-primary">
                    <i class="bi bi-people me-2" class="text-primary-blue"></i>Daftar Peserta & Nilai
                </h6>
                <div class="d-flex gap-2 align-items-center">
                    <% if (submissions != null && !submissions.isEmpty()) { %>
                    <span class="badge" class="badge-primary" id="totalCount"><%= submissions.size() %> peserta</span>
                    <% } %>
                </div>
            </div>
            <div class="card-body">
                <% if (submissions != null && !submissions.isEmpty()) { %>
                <!-- Filters -->
                <div class="card filter-card mb-4">
                    <div class="card-body py-3">
                        <div class="row g-2 align-items-center">
                            <div class="col-md-4">
                                <div class="input-group">
                                    <span class="input-group-text input-group-text-custom">
                                        <i class="bi bi-search" class="text-muted"></i>
                                    </span>
                                    <input type="text" class="form-control" id="searchInput" placeholder="Cari nama peserta..." onkeyup="filterTable()">
                                </div>
                            </div>
                            <div class="col-md-3">
                                <select class="form-select" id="tagFilter" onchange="filterTable()">
                                    <option value="">Semua Tag</option>
                                    <%
                                        Set<String> uniqueTags = new TreeSet<>();
                                        for (Map<String, Object> sub : submissions) {
                                            String tag = (String) sub.get("userTag");
                                            if (tag != null && !tag.isEmpty()) uniqueTags.add(tag);
                                        }
                                        for (String tag : uniqueTags) {
                                    %>
                                    <option value="<%= tag %>"><%= esc(tag) %></option>
                                    <% } %>
                                </select>
                            </div>
                            <div class="col-md-3">
                                <select class="form-select" id="scoreFilter" onchange="filterTable()">
                                    <option value="">Semua Nilai</option>
                                    <option value="pass">Lulus (>= 60)</option>
                                    <option value="fail">Tidak Lulus (< 60)</option>
                                    <option value="excellent">Sangat Baik (>= 86)</option>
                                    <option value="good">Baik (76-85)</option>
                                    <option value="fair">Cukup (61-75)</option>
                                    <option value="poor">Kurang (< 61)</option>
                                </select>
                            </div>
                            <div class="col-md-2">
                                <select class="form-select" id="pageSize" onchange="changePageSize()">
                                    <option value="25">25 / halaman</option>
                                    <option value="50" selected>50 / halaman</option>
                                    <option value="100">100 / halaman</option>
                                    <option value="all">Semua</option>
                                </select>
                            </div>
                        </div>
                    </div>
                </div>

                <!-- Participant List -->
                <div id="participantsList">
                    <% int participantCounter = 1;
                    for (Map<String, Object> sub : submissions) {
                        Double score = (Double) sub.get("score");
                        String scoreClass = score >= 86 ? "success" : score >= 76 ? "primary" :
                                            score >= 61 ? "info" : score >= 41 ? "warning" : "danger";
                        String userTag = (String) sub.get("userTag");
                        int correctAns = sub.get("correctAnswers") != null ? (Integer) sub.get("correctAnswers") : 0;
                        int wrongCnt = sub.get("wrongCount") != null ? (Integer) sub.get("wrongCount") : 0;
                        int unanswered = sub.get("unanswered") != null ? (Integer) sub.get("unanswered") : 0;
                        int timeSpent = sub.get("timeSpent") != null ? (Integer) sub.get("timeSpent") : 0;
                    %>
                    <div class="participant-row <%= score < 60 ? "border-danger-custom" : "" %>"
                         data-name="<%= sub.get("userName") != null ? ((String)sub.get("userName")).toLowerCase() : "" %>"
                         data-tag="<%= userTag != null ? userTag : "" %>"
                         data-score="<%= score %>"
                         data-index="<%= participantCounter %>"
                         data-submission-id="<%= sub.get("id") %>"
                         data-is-failed="<%= score < 60 %>"
                         onclick="handleParticipantClick(this)">
                        <div class="d-flex align-items-center justify-content-between flex-wrap gap-3">
                            <div class="d-flex align-items-center gap-3">
                                <div class="participant-number text-muted fw-bold" style="min-width: 30px; text-align: center;"><%= participantCounter %></div>
                                <div class="avatar-circle <%= score < 60 ? "bg-danger" : "" %>">
                                    <span class="avatar-text"><%= ((String)sub.get("userName")).substring(0,1).toUpperCase() %></span>
                                </div>
                                <div>
                                    <div class="participant-name">
                                        <%= esc((String)sub.get("userName")) %>
                                        <% if (score < 60) { %>
                                            <span class="badge badge-danger ms-2"><i class="bi bi-exclamation-triangle me-1"></i>TIDAK LULUS</span>
                                        <% } %>
                                    </div>
                                    <div class="d-flex gap-3 align-items-center small" style="margin-top: 4px;">
                                        <% if (userTag != null && !userTag.isEmpty()) { %>
                                        <span class="tag-badge <%= getTagColorClass(userTag) %>">
                                            <i class="bi bi-tag me-1"></i><%= esc(userTag) %>
                                        </span>
                                        <% } %>
                                        <span class="text-secondary">
                                            <i class="bi bi-clock me-1"></i><%= formatTime(timeSpent) %> menit
                                        </span>
                                    </div>
                                </div>
                            </div>
                            <div class="d-flex align-items-center gap-3">
                                <div class="d-none d-md-flex gap-3 text-center">
                                    <div style="min-width: 60px;">
                                        <div class="score-stat"><%= correctAns %></div>
                                        <div class="small text-muted">Benar</div>
                                    </div>
                                    <div style="min-width: 60px;">
                                        <div class="score-stat-danger"><%= wrongCnt %></div>
                                        <div class="small text-muted">Salah</div>
                                    </div>
                                    <div style="min-width: 60px;">
                                        <div class="score-stat-warning"><%= unanswered %></div>
                                        <div class="small text-muted">Kosong</div>
                                    </div>
                                </div>
                                <div class="score-badge score-badge-<%= scoreClass %>">
                                    <%= String.format("%.0f", score) %>
                                </div>
                                <button class="btn btn-sm <%= score < 60 ? "btn-danger" : "btn-outline-warning" %> reset-btn"
                                        data-submission-id="<%= sub.get("id") %>"
                                        data-user-name="<%= jsEsc((String)sub.get("userName")) %>"
                                        data-score="<%= score %>"
                                        onclick="event.stopPropagation(); resetSubmissionFromDataset(this)"
                                        title="<%= score < 60 ? "Izinkan retake untuk peserta tidak lulus" : "Izinkan retake quiz ini" %>">
                                    <% boolean isFailed = score < 60; %>
                                    <i class="bi bi-arrow-<%= isFailed ? "repeat" : "clockwise" %>"></i>
                                </button>
                                <i class="bi bi-chevron-right text-muted"></i>
                            </div>
                        </div>
                    </div>
                    <% participantCounter++; } %>
                </div>

                <!-- Pagination -->
                <div id="paginationWrapper" class="d-flex justify-content-between align-items-center mt-4 pt-3 border-top-custom">
                    <div class="small text-secondary" id="showingInfo"></div>
                    <nav id="paginationNav">
                        <ul class="pagination pagination-sm mb-0" id="paginationList"></ul>
                    </nav>
                </div>

                <% } else { %>
                <div class="empty-state">
                    <i class="bi bi-inbox"></i>
                    <h5>Belum ada peserta yang mengerjakan quiz ini</h5>
                    <p>Statistik akan tersedia setelah ada peserta yang submit jawaban.</p>
                </div>
                <% } %>
            </div>
        </div>

        <!-- Failed Participants Section -->
        <%
            @SuppressWarnings("unchecked")
            List<Submission> timeoutSubmissions = (List<Submission>) request.getAttribute("timeoutSubmissions");
            @SuppressWarnings("unchecked")
            List<Submission> inProgressSubmissions = (List<Submission>) request.getAttribute("inProgressSubmissions");
            @SuppressWarnings("unchecked")
            List<Map<String, Object>> notTakenUsers = (List<Map<String, Object>>) request.getAttribute("notTakenUsers");
            int totalFailed = (timeoutSubmissions != null ? timeoutSubmissions.size() : 0) +
                             (inProgressSubmissions != null ? inProgressSubmissions.size() : 0) +
                             (notTakenUsers != null ? notTakenUsers.size() : 0);

            java.util.Set<String> failedTags = new java.util.TreeSet<>();
            if (timeoutSubmissions != null) {
                for (Submission sub : timeoutSubmissions) {
                    String tag = sub.getUserTag();
                    if (tag != null && !tag.isEmpty()) failedTags.add(tag);
                }
            }
            if (inProgressSubmissions != null) {
                for (Submission sub : inProgressSubmissions) {
                    String tag = sub.getUserTag();
                    if (tag != null && !tag.isEmpty()) failedTags.add(tag);
                }
            }
            if (notTakenUsers != null) {
                for (Map<String, Object> user : notTakenUsers) {
                    String tag = (String) user.get("userTag");
                    if (tag != null && !tag.isEmpty()) failedTags.add(tag);
                }
            }
        %>
        <% if (totalFailed > 0) { %>
        <div class="card chart-card card-danger-bg">
            <div class="card-header d-flex justify-content-between align-items-center flex-wrap gap-2 card-header-danger-transparent">
                <h6 class="mb-0 fw-bold text-white">
                    <i class="bi bi-exclamation-triangle me-2"></i>Peserta Tidak Lulus (<%= totalFailed %>)
                </h6>
                <div class="d-flex gap-2 align-items-center">
                    <select class="form-select form-select-sm" style="width: auto;" id="failedTagFilter" onchange="filterFailedParticipants()">
                        <option value="">Semua Tag</option>
                        <% for (String tag : failedTags) { %>
                        <option value="<%= esc(tag) %>"><%= esc(tag) %></option>
                        <% } %>
                    </select>
                    <button class="btn btn-sm" class="btn-white-border" type="button" data-bs-toggle="collapse" data-bs-target="#failedParticipantsContent">
                        <i class="bi bi-chevron-down"></i>
                    </button>
                </div>
            </div>
            <div class="collapse show" id="failedParticipantsContent">
                <div class="card-body p-0">
                    <!-- Timeout Submissions -->
                    <% if (timeoutSubmissions != null && !timeoutSubmissions.isEmpty()) { %>
                    <div class="alert alert-warning d-flex justify-content-between align-items-center m-3" id="timeoutAlert">
                        <div>
                            <i class="bi bi-clock-history me-2"></i>
                            <strong><span id="timeoutCount"><%= timeoutSubmissions.size() %></span></strong> peserta timeout (waktu habis)
                        </div>
                        <button type="button" class="btn btn-sm btn-white-border" onclick="resetAllTimeout()">
                            <i class="bi bi-arrow-clockwise me-1"></i>Reset Semua Timeout
                        </button>
                    </div>
                    <div class="alert alert-info d-flex justify-content-between align-items-center mx-3" id="bulkTimeoutActions" style="display: none;">
                        <div>
                            <i class="bi bi-check2-square me-2"></i>
                            <strong><span id="selectedTimeoutCount">0</span></strong> peserta dipilih
                        </div>
                        <button type="button" class="btn btn-sm btn-danger" onclick="resetSelectedTimeout()">
                            <i class="bi bi-arrow-clockwise me-1"></i>Reset yang Dipilih
                        </button>
                    </div>
                    <div class="table-responsive mb-4" style="padding: 0 1rem 1rem 1rem;">
                        <table class="table table-sm table-hover mb-0">
                            <thead class="table-light">
                                <tr>
                                    <th style="padding: 12px; width: 50px;">
                                        <input type="checkbox" class="form-check-input" id="selectAllTimeout" onchange="toggleAllTimeout(this)">
                                    </th>
                                    <th style="padding: 12px; width: 50px;">No</th>
                                    <th style="padding: 12px;">Nama</th>
                                    <th style="padding: 12px;">Email</th>
                                    <th style="padding: 12px;">Tag</th>
                                    <th style="padding: 12px;">Waktu Mulai</th>
                                    <th style="padding: 12px;">Status</th>
                                    <th style="padding: 12px;">Aksi</th>
                                </tr>
                            </thead>
                            <tbody id="timeoutTableBody">
                                <% int timeoutCounter = 1;
                                for (Submission sub : timeoutSubmissions) {
                                    String userTag = sub.getUserTag();
                                %>
                                <tr class="timeout-row"
                                     data-submission-id="<%= sub.getId() %>"
                                     data-tag="<%= userTag != null ? userTag : "" %>"
                                     data-user-name="<%= esc(sub.getUserName()) %>"
                                     data-user-email="<%= esc(sub.getUserEmail()) %>"
                                     data-start-time="<%= sub.getStartedAt() != null ? sub.getStartedAt().toString() : "" %>"
                                     data-type="timeout"
                                     style="cursor: pointer;"
                                     onclick="showFailedParticipantDetailFromRow(this)">
                                    <td style="padding: 12px; text-align: center;" onclick="event.stopPropagation()">
                                        <input type="checkbox" class="form-check-input timeout-checkbox" data-submission-id="<%= sub.getId() %>" onchange="updateSelectedTimeoutCount()">
                                    </td>
                                    <td style="padding: 12px; text-align: center;"><%= timeoutCounter %></td>
                                    <td style="padding: 12px;"><%= esc(sub.getUserName()) %></td>
                                    <td style="padding: 12px;"><%= esc(sub.getUserEmail()) %></td>
                                    <td style="padding: 12px;">
                                        <% if (userTag != null && !userTag.isEmpty()) { %>
                                            <span class="badge badge-info"><%= esc(userTag) %></span>
                                        <% } else { %>
                                            <span class="text-muted">-</span>
                                        <% } %>
                                    </td>
                                    <td style="padding: 12px;">
                                        <%= sub.getStartedAt() != null ? sub.getStartedAt().toString() : "-" %>
                                    </td>
                                    <td style="padding: 12px;"><span class="badge badge-warning">Timeout</span></td>
                                    <td style="padding: 12px;">
                                        <button class="btn btn-sm btn-primary"
                                                data-submission-id="<%= sub.getId() %>"
                                                data-user-name="<%= jsEsc(sub.getUserName()) %>"
                                                onclick="resetTimeoutFromDataset(this)">
                                            <i class="bi bi-arrow-clockwise me-1"></i>Reset
                                        </button>
                                    </td>
                                </tr>
                                <% timeoutCounter++; } %>
                            </tbody>
                        </table>
                    </div>
                    <% } %>

                    <!-- Not Taken Users -->
                    <% if (notTakenUsers != null && !notTakenUsers.isEmpty()) { %>
                    <div class="alert m-3 bg-secondary-light border-0 text-secondary" id="notTakenAlert">
                        <i class="bi bi-dash-circle me-2"></i>
                        <strong><span id="notTakenCount"><%= notTakenUsers.size() %></span></strong> peserta belum mengerjakan quiz
                    </div>
                    <div class="alert alert-info d-flex justify-content-between align-items-center mx-3" id="bulkNotTakenActions" style="display: none;">
                        <div>
                            <i class="bi bi-check2-square me-2"></i>
                            <strong><span id="selectedNotTakenCount">0</span></strong> peserta dipilih
                        </div>
                        <button type="button" class="btn btn-sm btn-primary" onclick="resetSelectedNotTaken()">
                            <i class="bi bi-arrow-clockwise me-1"></i>Izinkan Retake yang Dipilih
                        </button>
                    </div>
                    <div class="table-responsive" style="padding: 0 1rem 1rem 1rem;">
                        <table class="table table-sm table-hover mb-0">
                            <thead class="table-light">
                                <tr>
                                    <th style="padding: 12px; width: 50px;">
                                        <input type="checkbox" class="form-check-input" id="selectAllNotTaken" onchange="toggleAllNotTaken(this)">
                                    </th>
                                    <th style="padding: 12px; width: 50px;">No</th>
                                    <th style="padding: 12px;">Nama</th>
                                    <th style="padding: 12px;">Email</th>
                                    <th style="padding: 12px;">Tag</th>
                                    <th style="padding: 12px;">Status</th>
                                </tr>
                            </thead>
                            <tbody id="notTakenTableBody">
                                <% int notTakenCounter = 1;
                                for (Map<String, Object> user : notTakenUsers) {
                                    String tag = (String) user.get("userTag");
                                    Integer userId = (Integer) user.get("userId");
                                %>
                                <tr class="not-taken-row"
                                     data-tag="<%= tag != null ? tag : "" %>"
                                     data-user-id="<%= userId %>"
                                     data-user-name="<%= esc((String)user.get("userName")) %>"
                                     data-user-email="<%= esc((String)user.get("userEmail")) %>"
                                     data-type="notTaken"
                                     style="cursor: pointer;"
                                     onclick="showFailedParticipantDetailFromRow(this)">
                                    <td style="padding: 12px; text-align: center;" onclick="event.stopPropagation()">
                                        <input type="checkbox" class="form-check-input not-taken-checkbox" data-user-id="<%= userId %>" data-user-name="<%= jsEsc((String)user.get("userName")) %>" onchange="updateSelectedNotTakenCount()">
                                    </td>
                                    <td style="padding: 12px; text-align: center;"><%= notTakenCounter %></td>
                                    <td style="padding: 12px;"><%= esc((String)user.get("userName")) %></td>
                                    <td style="padding: 12px;"><%= esc((String)user.get("userEmail")) %></td>
                                    <td style="padding: 12px;">
                                        <% if (tag != null && !tag.isEmpty()) { %>
                                            <span class="badge badge-info"><%= esc(tag) %></span>
                                        <% } else { %>
                                            <span class="text-muted">-</span>
                                        <% } %>
                                    </td>
                                    <td style="padding: 12px;"><span class="badge badge-danger">Belum Mengerjakan</span></td>
                                </tr>
                                <% notTakenCounter++; } %>
                            </tbody>
                        </table>
                    </div>
                    <% } %>

                    <!-- In Progress Submissions -->
                    <% if (inProgressSubmissions != null && !inProgressSubmissions.isEmpty()) { %>
                    <div class="alert alert-info d-flex justify-content-between align-items-center m-3" id="inProgressAlert">
                        <div>
                            <i class="bi bi-hourglass-split me-2"></i>
                            <strong><span id="inProgressCount"><%= inProgressSubmissions.size() %></span></strong> peserta sedang mengerjakan
                        </div>
                        <button type="button" class="btn btn-sm btn-info" onclick="resetAllInProgress()">
                            <i class="bi bi-arrow-clockwise me-1"></i>Reset Semua In Progress
                        </button>
                    </div>
                    <div class="alert alert-warning d-flex justify-content-between align-items-center mx-3" id="bulkInProgressActions" style="display: none;">
                        <div>
                            <i class="bi bi-check2-square me-2"></i>
                            <strong><span id="selectedInProgressCount">0</span></strong> peserta dipilih
                        </div>
                        <button type="button" class="btn btn-sm btn-warning" onclick="resetSelectedInProgress()">
                            <i class="bi bi-arrow-clockwise me-1"></i>Reset yang Dipilih
                        </button>
                    </div>
                    <div class="table-responsive mb-4" style="padding: 0 1rem 1rem 1rem;">
                        <table class="table table-sm table-hover mb-0">
                            <thead class="table-light">
                                <tr>
                                    <th style="padding: 12px; width: 50px;">
                                        <input type="checkbox" class="form-check-input" id="selectAllInProgress" onchange="toggleAllInProgress(this)">
                                    </th>
                                    <th style="padding: 12px; width: 50px;">No</th>
                                    <th style="padding: 12px;">Nama</th>
                                    <th style="padding: 12px;">Email</th>
                                    <th style="padding: 12px;">Tag</th>
                                    <th style="padding: 12px;">Waktu Mulai</th>
                                    <th style="padding: 12px;">Durasi</th>
                                    <th style="padding: 12px;">Status</th>
                                    <th style="padding: 12px;">Aksi</th>
                                </tr>
                            </thead>
                            <tbody id="inProgressTableBody">
                                <% int inProgressCounter = 1;
                                for (Submission sub : inProgressSubmissions) {
                                    String userTag = sub.getUserTag();
                                %>
                                <tr class="in-progress-row"
                                     data-submission-id="<%= sub.getId() %>"
                                     data-tag="<%= userTag != null ? userTag : "" %>"
                                     data-user-name="<%= esc(sub.getUserName()) %>"
                                     data-user-email="<%= esc(sub.getUserEmail()) %>"
                                     data-start-time="<%= sub.getStartedAt() != null ? sub.getStartedAt().toString() : "" %>"
                                     data-type="inProgress"
                                     style="cursor: pointer;"
                                     onclick="showFailedParticipantDetailFromRow(this)">
                                    <td style="padding: 12px; text-align: center;" onclick="event.stopPropagation()">
                                        <input type="checkbox" class="form-check-input in-progress-checkbox" data-submission-id="<%= sub.getId() %>" onchange="updateSelectedInProgressCount()">
                                    </td>
                                    <td style="padding: 12px; text-align: center;"><%= inProgressCounter %></td>
                                    <td style="padding: 12px;"><%= esc(sub.getUserName()) %></td>
                                    <td style="padding: 12px;"><%= esc(sub.getUserEmail()) %></td>
                                    <td style="padding: 12px;">
                                        <% if (userTag != null && !userTag.isEmpty()) { %>
                                            <span class="badge badge-info"><%= esc(userTag) %></span>
                                        <% } else { %>
                                            <span class="text-muted">-</span>
                                        <% } %>
                                    </td>
                                    <td style="padding:12px;"><%= sub.getStartedAt() != null ? sub.getStartedAt().format(java.time.format.DateTimeFormatter.ofPattern("dd MMM yyyy, HH:mm")) : "-" %></td>
                                    <td style="padding:12px;">
                                        <% if (sub.getTimeSpent() != null) { %>
                                            <%= sub.getFormattedTimeSpent() %>
                                        <% } else { %>
                                            <span class="text-muted">-</span>
                                        <% } %>
                                    </td>
                                    <td style="padding: 12px;"><span class="badge bg-info text-white">Sedang Mengerjakan</span></td>
                                    <td style="padding: 12px;">
                                        <button type="button" class="btn btn-sm btn-outline-danger"
                                                onclick="resetSingleInProgress(<%= sub.getId() %>, '<%= esc(sub.getUserName()) %>')">
                                            <i class="bi bi-arrow-clockwise"></i>
                                        </button>
                                    </td>
                                </tr>
                                <% inProgressCounter++; } %>
                            </tbody>
                        </table>
                    </div>
                    <% } %>
                </div>
            </div>
        </div>
        <% } %>

        <% } else { %>
        <!-- No Quiz Selected -->
        <div class="card chart-card">
            <div class="card-body text-center py-5">
                <div class="mb-4">
                    <i class="bi bi-graph-up display-1 icon-muted" class="text-primary-blue"></i>
                </div>
                <h4 class="text-secondary mb-2">Pilih Quiz untuk Melihat Statistik</h4>
                <p class="text-muted">Pilih quiz dari dropdown di atas untuk melihat statistik dan distribusi nilai.</p>
            </div>
        </div>
        <% } %>
    </div>

    <!-- User Detail Modal -->
    <div class="modal fade" id="userDetailModal" tabindex="-1">
        <div class="modal-dialog modal-xl">
            <div class="modal-content" class="card-content-rounded">
                <div class="modal-header" class="border-bottom-custom">
                    <h5 class="modal-title fw-bold">
                        <i class="bi bi-person-check me-2" class="text-primary-blue"></i>Detail Jawaban Peserta
                    </h5>
                    <button type="button" class="btn-close" data-bs-dismiss="modal"></button>
                </div>
                <div class="modal-body" id="userDetailBody">
                    <div class="text-center py-5">
                        <div class="spinner-border" role="status" class="text-primary-blue"></div>
                        <p class="mt-3" class="text-secondary">Memuat data...</p>
                    </div>
                </div>
                <div class="modal-footer no-print" class="border-top-custom">
                    <button type="button" class="btn btn-outline-warning" id="retakeBtn" onclick="retakeQuiz()">
                        <i class="bi bi-arrow-repeat me-1"></i>Izinkan Retake
                    </button>
                    <button type="button" class="btn btn-outline-secondary" data-bs-dismiss="modal">Tutup</button>
                    <button type="button" class="btn btn-outline-success" onclick="exportDetailToTxt()">
                        <i class="bi bi-file-earmark-text me-1"></i>Export TXT
                    </button>
                    <button type="button" class="btn btn-primary" onclick="exportDetailToPdf()">
                        <i class="bi bi-file-earmark-pdf me-1"></i>Export PDF
                    </button>
                </div>
            </div>
        </div>
    </div>

    <!-- Failed User Detail Modal (for users who completed quiz but scored < 60) -->
    <div class="modal fade" id="failedUserDetailModal" tabindex="-1">
        <div class="modal-dialog modal-xl">
            <div class="modal-content" style="border-radius: 16px;">
                <div class="modal-header" style="border-bottom: 1px solid var(--border-light);">
                    <h5 class="modal-title fw-bold">
                        <i class="bi bi-exclamation-triangle me-2" style="color: var(--danger);"></i>Detail Peserta Tidak Lulus
                    </h5>
                    <button type="button" class="btn-close" data-bs-dismiss="modal"></button>
                </div>
                <div class="modal-body" id="failedUserDetailBody">
                    <div class="text-center py-5">
                        <div class="spinner-border text-danger" role="status"></div>
                        <p class="mt-3 text-muted">Memuat data...</p>
                    </div>
                </div>
                <div class="modal-footer" style="border-top: 1px solid var(--border-light);">
                    <button type="button" class="btn btn-warning" id="failedRetakeQuizBtn" onclick="retakeFailedQuiz()">
                        <i class="bi bi-arrow-repeat me-1"></i>Izinkan Retake
                    </button>
                    <button type="button" class="btn btn-outline-secondary" data-bs-dismiss="modal">Tutup</button>
                </div>
            </div>
        </div>
    </div>

    <!-- Failed Participant Detail Modal -->
    <div class="modal fade" id="failedParticipantModal" tabindex="-1">
        <div class="modal-dialog modal-lg">
            <div class="modal-content" style="border-radius: 16px;">
                <div class="modal-header" style="border-bottom: 1px solid var(--border-light);">
                    <h5 class="modal-title fw-bold">
                        <i class="bi bi-exclamation-triangle me-2" style="color: var(--danger);"></i>Detail Peserta Tidak Lulus
                    </h5>
                    <button type="button" class="btn-close" data-bs-dismiss="modal"></button>
                </div>
                <div class="modal-body" id="failedParticipantBody">
                    <div class="text-center py-5">
                        <div class="spinner-border text-primary" role="status"></div>
                        <p class="mt-3 text-muted">Memuat data...</p>
                    </div>
                </div>
                <div class="modal-footer" style="border-top: 1px solid var(--border-light);">
                    <button type="button" class="btn btn-warning" id="failedRetakeBtn" onclick="retakeFailedParticipant()">
                        <i class="bi bi-key me-1"></i>Buat Kode Retake
                    </button>
                    <button type="button" class="btn btn-outline-secondary" data-bs-dismiss="modal">Tutup</button>
                </div>
            </div>
        </div>
    </div>

    <!-- CSRF Token for AJAX -->
    <input type="hidden" id="csrfToken" value="<%= session.getAttribute("csrfToken") %>">

    <script src="https://cdn.jsdelivr.net/npm/bootstrap@5.3.0/dist/js/bootstrap.bundle.min.js"></script>
    <script src="../assets/js/html2pdf.bundle.min.js"></script>

    <script>
        // Export functions remain the same
        function exportDetailToPdf() {
            const element = document.getElementById('userDetailContent');
            if (!element) {
                alert('Data belum dimuat. Silakan tunggu hingga data selesai dimuat.');
                return;
            }

            const userName = element.getAttribute('data-user-name') || 'peserta';
            const quizTitle = element.getAttribute('data-quiz-title') || 'quiz';

            const printWindow = window.open('', '_blank', 'width=900,height=650');

            if (!printWindow) {
                alert('Popup blocker mencegah pembukaan window. Silakan izinkan popup atau gunakan Export TXT.');
                return;
            }

            const contentHtml = element.innerHTML;

            printWindow.document.write('<!DOCTYPE html><html><head>' +
                '<title>Hasil Quiz - ' + quizTitle + '</title>' +
                '<link href="https://cdn.jsdelivr.net/npm/bootstrap@5.3.0/dist/css/bootstrap.min.css" rel="stylesheet">' +
                '<link href="https://cdn.jsdelivr.net/npm/bootstrap-icons@1.10.0/font/bootstrap-icons.css" rel="stylesheet">' +
                '<style>' +
                'body { font-family: Arial, sans-serif; padding: 20px; font-size: 12px; background: #fafbfc; }' +
                '.question-item { margin-bottom: 15px; padding: 12px; border: 1px solid #e9ecef; border-radius: 8px; page-break-inside: avoid; background: white; }' +
                '.option-item { padding: 8px 12px; margin: 4px 0; border: 1px solid #e9ecef; border-radius: 6px; background: white; }' +
                '.correct-answer { background-color: #d4edda !important; border-color: #28a745 !important; color: #155724 !important; }' +
                '.wrong-answer { background-color: #f8d7da !important; border-color: #dc3545 !important; }' +
                '.selected { font-weight: 600; }' +
                '.badge { padding: 4px 8px; border-radius: 6px; font-size: 11px; }' +
                'canvas { display: none !important; }' +
                '@media print { .no-print { display: none !important; } body { padding: 0; } }' +
                '</style></head><body>' +
                '<div class="no-print" style="margin-bottom: 20px; padding: 15px; background: #e3edf7; border-radius: 8px; text-align: center;">' +
                '<h3 style="margin: 0 0 10px 0; color: #4a6fdc;">Hasil Quiz: ' + quizTitle + '</h3>' +
                '<p style="margin: 0 0 15px 0;">Peserta: <strong>' + userName + '</strong></p>' +
                '<button onclick="window.print()" style="padding: 10px 30px; font-size: 16px; cursor: pointer; background: #4a6fdc; color: white; border: none; border-radius: 8px;">Print / Save as PDF</button>' +
                '<p style="margin-top: 10px; font-size: 11px; color: #6c757d;">Klik tombol di atas, lalu pilih "Save as PDF" sebagai printer</p>' +
                '</div>' +
                '<hr class="no-print">' +
                contentHtml +
                '</body></html>');

            printWindow.document.close();
        }

        function exportDetailToTxt() {
            const element = document.getElementById('userDetailContent');
            if (!element) {
                alert('Data belum dimuat. Silakan tunggu hingga data selesai dimuat.');
                return;
            }

            const userName = element.getAttribute('data-user-name') || 'peserta';
            const quizTitle = element.getAttribute('data-quiz-title') || 'quiz';

            let text = '='.repeat(60) + '\n';
            text += 'HASIL QUIZ - EXAMORA\n';
            text += '='.repeat(60) + '\n\n';
            text += 'Quiz: ' + quizTitle + '\n';
            text += 'Peserta: ' + userName + '\n\n';

            const questions = element.querySelectorAll('.question-item');
            questions.forEach((q, index) => {
                const questionText = q.querySelector('h6 span:last-child');
                if (questionText) {
                    text += '-'.repeat(60) + '\n';
                    text += 'Soal ' + (index + 1) + ': ' + questionText.textContent.trim() + '\n';
                }

                const options = q.querySelectorAll('.option-item');
                options.forEach(opt => {
                    const isSelected = opt.classList.contains('selected');
                    const isCorrect = opt.classList.contains('correct-answer');
                    text += '  ' + opt.textContent.trim();
                    if (isSelected) text += ' [JAWABAN PESERTA]';
                    if (isCorrect) text += ' [BENAR]';
                    text += '\n';
                });

                const badge = q.querySelector('.badge');
                if (badge) {
                    text += '  Status: ' + badge.textContent.trim() + '\n';
                }
                text += '\n';
            });

            const blob = new Blob([text], { type: 'text/plain;charset=utf-8' });
            const url = URL.createObjectURL(blob);
            const a = document.createElement('a');
            a.href = url;
            a.download = 'hasil_' + quizTitle.replace(/[^a-zA-Z0-9]/g, '_') + '_' + userName.replace(/[^a-zA-Z0-9]/g, '_') + '.txt';
            document.body.appendChild(a);
            a.click();
            document.body.removeChild(a);
            URL.revokeObjectURL(url);
        }
    </script>

    <% if (statistics != null) { %>
    <script>
        // Chart Colors (Soft Palette)
        const chartColors = {
            primary: 'rgba(74, 111, 220, 0.7)',
            success: 'rgba(92, 184, 92, 0.7)',
            warning: 'rgba(240, 173, 78, 0.7)',
            danger: 'rgba(217, 83, 79, 0.7)',
            info: 'rgba(91, 192, 222, 0.7)',
            successLight: 'rgba(92, 184, 92, 0.2)',
            dangerLight: 'rgba(217, 83, 79, 0.2)'
        };

        // Score Distribution Chart
        const scoreCtx = document.getElementById('scoreDistributionChart').getContext('2d');
        new Chart(scoreCtx, {
            type: 'bar',
            data: {
                labels: ['0-40 (Sangat Kurang)', '41-60 (Kurang)', '61-75 (Cukup)', '76-85 (Baik)', '86-100 (Sangat Baik)'],
                datasets: [{
                    label: 'Jumlah Peserta',
                    data: [
                        <%= statistics.get("scoreRange0_40") != null ? statistics.get("scoreRange0_40") : 0 %>,
                        <%= statistics.get("scoreRange41_60") != null ? statistics.get("scoreRange41_60") : 0 %>,
                        <%= statistics.get("scoreRange61_75") != null ? statistics.get("scoreRange61_75") : 0 %>,
                        <%= statistics.get("scoreRange76_85") != null ? statistics.get("scoreRange76_85") : 0 %>,
                        <%= statistics.get("scoreRange86_100") != null ? statistics.get("scoreRange86_100") : 0 %>
                    ],
                    backgroundColor: [
                        'rgba(217, 83, 79, 0.6)',
                        'rgba(240, 173, 78, 0.6)',
                        'rgba(91, 192, 222, 0.6)',
                        'rgba(102, 16, 242, 0.5)',
                        'rgba(92, 184, 92, 0.6)'
                    ],
                    borderColor: [
                        'rgba(217, 83, 79, 1)',
                        'rgba(240, 173, 78, 1)',
                        'rgba(91, 192, 222, 1)',
                        'rgba(102, 16, 242, 1)',
                        'rgba(92, 184, 92, 1)'
                    ],
                    borderWidth: 2,
                    borderRadius: 8
                }]
            },
            options: {
                responsive: true,
                plugins: {
                    legend: { display: false }
                },
                scales: {
                    y: {
                        beginAtZero: true,
                        ticks: { stepSize: 1 },
                        grid: { color: 'rgba(0, 0, 0, 0.08)' }
                    },
                    x: {
                        grid: { display: false }
                    }
                }
            }
        });

        // Pass Rate Chart
        const passCtx = document.getElementById('passRateChart').getContext('2d');
        new Chart(passCtx, {
            type: 'doughnut',
            data: {
                labels: ['Lulus', 'Tidak Lulus'],
                datasets: [{
                    data: [<%= statistics.get("passedCount") != null ? statistics.get("passedCount") : 0 %>, <%= statistics.get("failedCount") != null ? statistics.get("failedCount") : 0 %>],
                    backgroundColor: [chartColors.success, chartColors.danger],
                    borderColor: ['rgba(92, 184, 92, 1)', 'rgba(217, 83, 79, 1)'],
                    borderWidth: 2
                }]
            },
            options: {
                responsive: true,
                cutout: '65%',
                plugins: { legend: { display: false } }
            }
        });

        let currentSubmissionId = null;

        function loadUserDetail(submissionId) {
            if (!submissionId) return;

            currentSubmissionId = submissionId;
            document.getElementById('retakeBtn').style.display = 'inline-block';

            const modal = new bootstrap.Modal(document.getElementById('userDetailModal'));
            document.getElementById('userDetailBody').innerHTML =
                '<div class="text-center py-5"><div class="spinner-border text-primary-blue" role="status"></div><p class="mt-3 text-secondary">Memuat data...</p></div>';
            modal.show();

            fetch('../AdminServlet?action=userDetail&submissionId=' + submissionId)
                .then(response => { if (!response.ok) throw new Error('Failed'); return response.text(); })
                .then(html => { document.getElementById('userDetailBody').innerHTML = html; initUserChart(); })
                .catch(error => {
                    document.getElementById('userDetailBody').innerHTML =
                        '<div id="userDetailContent"><div class="text-center py-5">' +
                        '<i class="bi bi-exclamation-triangle display-1" style="color: var(--danger); margin-bottom: 1rem; display: block;"></i>' +
                        '<h4 class="text-secondary">Gagal Memuat Data</h4>' +
                        '<button class="btn btn-sm mt-3" onclick="loadUserDetail(\'' + submissionId + '\')" style="background: var(--primary); color: white; border: none; border-radius: 8px;">Coba Lagi</button></div></div>';
                });
        }

        // Handle participant row click based on pass/fail status
        function handleParticipantClick(element) {
            const submissionId = element.getAttribute('data-submission-id');
            const isFailed = element.getAttribute('data-is-failed') === 'true';

            if (isFailed) {
                loadFailedUserDetail(submissionId);
            } else {
                loadUserDetail(submissionId);
            }
        }

        // Failed User Detail Modal Functions (for users who completed quiz but scored < 60)
        let currentFailedSubmissionId = null;

        function loadFailedUserDetail(submissionId) {
            if (!submissionId) return;

            currentFailedSubmissionId = submissionId;
            document.getElementById('failedRetakeQuizBtn').style.display = 'inline-block';

            const modal = new bootstrap.Modal(document.getElementById('failedUserDetailModal'));
            document.getElementById('failedUserDetailBody').innerHTML =
                '<div class="text-center py-5"><div class="spinner-border text-danger" role="status"></div><p class="mt-3 text-secondary">Memuat data...</p></div>';
            modal.show();

            fetch('../AdminServlet?action=failedUserDetail&submissionId=' + submissionId)
                .then(response => { if (!response.ok) throw new Error('Failed'); return response.text(); })
                .then(html => { document.getElementById('failedUserDetailBody').innerHTML = html; initFailedUserChart(); })
                .catch(error => {
                    document.getElementById('failedUserDetailBody').innerHTML =
                        '<div id="failedUserDetailContent"><div class="text-center py-5">' +
                        '<i class="bi bi-exclamation-triangle display-1 text-danger"></i>' +
                        '<h4 class="text-secondary mt-3">Gagal Memuat Data</h4>' +
                        '<button class="btn btn-sm mt-3" onclick="loadFailedUserDetail(\'' + submissionId + '\')">Coba Lagi</button></div></div>';
                });
        }

        function retakeFailedQuiz() {
            if (!currentFailedSubmissionId) {
                alert('Tidak ada submission yang dipilih');
                return;
            }

            const userNameEl = document.querySelector('#failedUserDetailContent');
            const userName = userNameEl ? userNameEl.getAttribute('data-user-name') : 'peserta ini';

            if (!confirm('Izinkan ' + userName + ' untuk retake quiz?\n\nData jawaban lama akan dihapus permanen.')) {
                return;
            }

            const btn = document.getElementById('failedRetakeQuizBtn');
            btn.disabled = true;
            btn.innerHTML = '<span class="spinner-border spinner-border-sm me-1"></span>Memproses...';

            const formData = new URLSearchParams();
            formData.append('action', 'retakeQuiz');
            formData.append('submissionId', currentFailedSubmissionId);
            formData.append('csrfToken', document.getElementById('csrfToken').value);

            fetch('../AdminServlet', {
                method: 'POST',
                headers: {
                    'Content-Type': 'application/x-www-form-urlencoded',
                    'X-Requested-With': 'XMLHttpRequest'
                },
                body: formData
            })
            .then(response => response.json())
            .then(data => {
                if (data.success) {
                    alert('Retake berhasil diizinkan untuk ' + userName);
                    bootstrap.Modal.getInstance(document.getElementById('failedUserDetailModal')).hide();
                    location.reload();
                } else {
                    alert('Error: ' + (data.message || data.error || 'Unknown error'));
                    btn.disabled = false;
                    btn.innerHTML = '<i class="bi bi-arrow-repeat me-1"></i>Izinkan Retake';
                }
            })
            .catch(error => {
                console.error('Error:', error);
                alert('Error: ' + error.message);
                btn.disabled = false;
                btn.innerHTML = '<i class="bi bi-arrow-repeat me-1"></i>Izinkan Retake';
            });
        }

        function initFailedUserChart() {
            const canvas = document.getElementById('failedUserPerformanceChart');
            if (!canvas) return;

            const ctx = canvas.getContext('2d');
            const correct = canvas.dataset.correct;
            const wrong = canvas.dataset.wrong;
            const unanswered = canvas.dataset.unanswered;

            new Chart(ctx, {
                type: 'doughnut',
                data: {
                    labels: ['Benar', 'Salah', 'Tidak Dijawab'],
                    datasets: [{
                        data: [correct, wrong, unanswered],
                        backgroundColor: ['#28a745', '#dc3545', '#ffc107'],
                        borderWidth: 2
                    }]
                },
                options: {
                    responsive: true,
                    cutout: '65%',
                    plugins: { legend: { position: 'bottom' } }
                }
            });
        }

        // Failed Participant Modal Functions
        let currentFailedParticipantId = null;
        let currentFailedParticipantType = null;
        let currentFailedParticipantName = null;

        function showFailedParticipantDetailFromRow(row) {
            console.log('showFailedParticipantDetailFromRow called', row);

            const type = row.getAttribute('data-type');
            const id = row.getAttribute(type === 'timeout' ? 'data-submission-id' : 'data-user-id');
            const userName = row.getAttribute('data-user-name');
            const userEmail = row.getAttribute('data-user-email');
            const userTag = row.getAttribute('data-tag') || '';
            const startTime = row.getAttribute('data-start-time') || '';
            const notTaken = type === 'notTaken';

            console.log('Data extracted:', {type, id, userName, userEmail, userTag, startTime, notTaken});

            showFailedParticipantDetail(type, id, userName, userEmail, userTag, startTime, notTaken);
        }

        function showFailedParticipantDetail(type, id, userName, userEmail, userTag, startTime, notTaken) {
            console.log('showFailedParticipantDetail called:', type, id, userName);

            currentFailedParticipantId = id;
            currentFailedParticipantType = type;
            currentFailedParticipantName = userName;

            const modalElement = document.getElementById('failedParticipantModal');
            const body = document.getElementById('failedParticipantBody');

            if (!modalElement) {
                console.error('Modal element not found!');
                alert('Modal tidak ditemukan. Silakan refresh halaman.');
                return;
            }

            // Build modal content
            const isNotTaken = notTaken === 'true';

            let html = `
                <div class="container-fluid">
                    <!-- Participant Info Card -->
                    <div class="card mb-3" style="border-radius: 12px; border: 1px solid var(--border-light);">
                        <div class="card-body">
                            <div class="row align-items-center">
                                <div class="col-md-2 text-center">
                                    <div style="width: 80px; height: 80px; border-radius: 50%; background: var(--danger); display: flex; align-items: center; justify-content: center; margin: 0 auto;">
                                        <span style="color: white; font-weight: 600; font-size: 1.8rem;">\${userName.charAt(0).toUpperCase()}</span>
                                    </div>
                                </div>
                                <div class="col-md-10">
                                    <h5 class="mb-1" style="color: var(--text-primary);">\${userName}</h5>
                                    <p class="mb-2" style="color: var(--text-secondary);">\${userEmail}</p>
                                    \${userTag ? '<span class="badge" style="background: var(--info); color: white;">\${userTag}</span>' : ''}
                                </div>
                            </div>
                        </div>
                    </div>

                    <!-- Status Cards -->
                    <div class="row mb-3">
                        <div class="col-md-6">
                            <div class="card h-100" style="border-radius: 12px; border: 1px solid var(--border-light);">
                                <div class="card-body">
                                    <div class="d-flex align-items-center mb-2">
                                        <i class="bi bi-clock-history me-2" style="color: var(--warning); font-size: 1.2rem;"></i>
                                        <h6 class="mb-0" style="color: var(--text-secondary);">Status Quiz</h6>
                                    </div>
                                    <div class="mt-2">
                                        \${isNotTaken
                                            ? '<span class="badge" style="background: var(--danger); color: white; font-size: 0.9rem; padding: 8px 16px;">Belum Mengerjakan</span>'
                                            : '<span class="badge" style="background: var(--warning); color: white; font-size: 0.9rem; padding: 8px 16px;">Timeout (Waktu Habis)</span>'
                                        }
                                    </div>
                                </div>
                            </div>
                        </div>
                        <div class="col-md-6">
                            <div class="card h-100" style="border-radius: 12px; border: 1px solid var(--border-light);">
                                <div class="card-body">
                                    <div class="d-flex align-items-center mb-2">
                                        <i class="bi bi-door-open me-2" style="color: var(--primary); font-size: 1.2rem;"></i>
                                        <h6 class="mb-0" style="color: var(--text-secondary);">Akses Quiz</h6>
                                    </div>
                                    <div class="mt-2">
                                        \${isNotTaken
                                            ? '<span class="badge" style="background: var(--bg-secondary); color: var(--text-muted); font-size: 0.9rem; padding: 8px 16px;"><i class="bi bi-x-circle me-1"></i>Tidak Pernah Akses</span>'
                                            : '<span class="badge" style="background: var(--success); color: white; font-size: 0.9rem; padding: 8px 16px;"><i class="bi bi-check-circle me-1"></i>Pernah Akses</span>'
                                        }
                                    </div>
                                    \${!isNotTaken && startTime ? `<small class="text-muted mt-2 d-block">Waktu mulai: \${startTime}</small>` : ''}
                                </div>
                            </div>
                        </div>
                    </div>

                    <!-- Information Section -->
                    <div class="card" style="border-radius: 12px; border: 1px solid var(--border-light);">
                        <div class="card-body">
                            <h6 class="mb-3" style="color: var(--text-primary);">
                                <i class="bi bi-info-circle me-2" style="color: var(--primary);"></i>Informasi
                            </h6>
                            \${isNotTaken
                                ? `<p style="color: var(--text-secondary); margin-bottom: 0;">
                                    <i class="bi bi-arrow-right me-2" style="color: var(--danger);"></i>
                                    Peserta ini <strong>belum pernah mengerjakan</strong> quiz sama sekali. Mungkin karena:
                                    <ul class="mt-2 mb-0" style="color: var(--text-secondary);">
                                        <li>Tidak membuka halaman quiz</li>
                                        <li>Lupa atau melewatkan deadline</li>
                                        <li>Kendala teknis saat mencoba mengakses</li>
                                    </ul>
                                   </p>`
                                : `<p style="color: var(--text-secondary); margin-bottom: 0;">
                                    <i class="bi bi-arrow-right me-2" style="color: var(--warning);"></i>
                                    Peserta ini <strong>pernah mengakses</strong> quiz namun <strong>waktu habis</strong> (timeout).
                                    Pengerjaan tidak selesai sebelum batas waktu berakhir.
                                   </p>`
                            }
                        </div>
                    </div>
                </div>
            `;

            body.innerHTML = html;

            // Show/hide retake button based on type
            const retakeBtn = document.getElementById('failedRetakeBtn');
            if (type === 'timeout') {
                retakeBtn.innerHTML = '<i class="bi bi-arrow-clockwise me-1"></i>Reset & Izinkan Retake';
            } else {
                retakeBtn.innerHTML = '<i class="bi bi-arrow-clockwise me-1"></i>Izinkan Retake';
            }

            // Show modal using Bootstrap
            if (typeof bootstrap !== 'undefined') {
                const modal = new bootstrap.Modal(modalElement);
                modal.show();
            } else {
                // Fallback: manually show modal
                modalElement.classList.add('show');
                modalElement.style.display = 'block';
                document.body.classList.add('modal-open');
                const backdrop = document.createElement('div');
                backdrop.className = 'modal-backdrop fade show';
                backdrop.id = 'failedParticipantModalBackdrop';
                document.body.appendChild(backdrop);
            }
        }

        function retakeFailedParticipant() {
            if (!currentFailedParticipantId || !currentFailedParticipantType) {
                alert('Tidak ada peserta yang dipilih');
                return;
            }

            const typeText = currentFailedParticipantType === 'timeout' ? 'timeout' : 'belum mengerjakan';

            if (!confirm('Buat kode retake untuk ' + currentFailedParticipantName + '?\n\nPeserta ini statusnya: ' + typeText)) {
                return;
            }

            const btn = document.getElementById('failedRetakeBtn');
            btn.disabled = true;
            btn.innerHTML = '<span class="spinner-border spinner-border-sm me-1"></span>Memproses...';

            const csrfToken = document.getElementById('csrfToken').value;
            const quizId = <%= selectedQuizId %>;

            if (!quizId) {
                alert('Quiz ID tidak ditemukan. Silakan pilih quiz terlebih dahulu.');
                btn.disabled = false;
                btn.innerHTML = '<i class="bi bi-key me-1"></i>Buat Kode Retake';
                return;
            }

            // For timeout participants, delete submission first
            if (currentFailedParticipantType === 'timeout') {
                fetch('../AdminServlet', {
                    method: 'POST',
                    headers: {
                        'Content-Type': 'application/x-www-form-urlencoded',
                    },
                    body: 'action=resetSubmission&submissionId=' + currentFailedParticipantId + '&quizId=' + quizId + '&csrfToken=' + csrfToken
                })
                .then(response => response.json())
                .then(data => {
                    if (data.success) {
                        // Now generate retake code
                        generateRetakeCodeForUser(currentFailedParticipantId, quizId, csrfToken, btn);
                    } else {
                        alert('Error: ' + (data.message || 'Terjadi kesalahan'));
                        btn.disabled = false;
                        btn.innerHTML = '<i class="bi bi-key me-1"></i>Buat Kode Retake';
                    }
                })
                .catch(error => {
                    console.error('Error:', error);
                    alert('Error: ' + error.message);
                    btn.disabled = false;
                    btn.innerHTML = '<i class="bi bi-key me-1"></i>Buat Kode Retake';
                });
            } else {
                // For not taken participants, directly generate retake code
                generateRetakeCodeForUser(currentFailedParticipantId, quizId, csrfToken, btn);
            }
        }

        function generateRetakeCodeForUser(userId, quizId, csrfToken, btn) {
            fetch('../AdminServlet', {
                method: 'POST',
                headers: {
                    'Content-Type': 'application/x-www-form-urlencoded',
                },
                body: 'action=generateRetakeCode&userId=' + userId + '&quizId=' + quizId + '&csrfToken=' + csrfToken
            })
            .then(response => response.json())
            .then(data => {
                if (data.success) {
                    // Show modal with the retake code
                    showRetakeCodeModal(data.retakeCode, currentFailedParticipantName, false);
                } else {
                    // Check if error is about existing retake code
                    const message = data.message || '';
                    if (message.includes('sudah memiliki kode retake') || message.includes('RET-')) {
                        // Extract the existing code from the message
                        const codeMatch = message.match(/RET-[A-Z0-9]{8}/i);
                        if (codeMatch) {
                            // Show modal with existing code
                            showRetakeCodeModal(codeMatch[0], currentFailedParticipantName, true);
                        } else {
                            alert('Error: ' + message);
                            btn.disabled = false;
                            btn.innerHTML = '<i class="bi bi-key me-1"></i>Buat Kode Retake';
                        }
                    } else {
                        alert('Error: ' + message);
                        btn.disabled = false;
                        btn.innerHTML = '<i class="bi bi-key me-1"></i>Buat Kode Retake';
                    }
                }
            })
            .catch(error => {
                console.error('Error:', error);
                alert('Error: ' + error.message);
                btn.disabled = false;
                btn.innerHTML = '<i class="bi bi-key me-1"></i>Buat Kode Retake';
            });
        }

        function showRetakeCodeModal(code, userName, isExisting) {
            var isEx = isExisting || false;
            var headerClass = isEx ? 'bg-info text-white' : 'bg-success text-white';
            var iconClass = isEx ? 'info-circle' : 'key';
            var titleText = isEx ? 'Kode Retake Sudah Ada' : 'Kode Retake Berhasil Dibuat';
            var escapedName = userName.replace(/'/g, "\\'");
            var escapedCode = code.replace(/'/g, "\\'");
            var messageHtml = isEx ?
                '<div class="alert alert-warning mb-3">' +
                '<i class="bi bi-exclamation-triangle me-2"></i>' +
                '<strong>' + escapedName + '</strong> sudah memiliki kode retake yang masih berlaku.' +
                '</div>' :
                '<p class="mb-3">Berikan kode retake berikut kepada <strong>' + escapedName + '</strong>:</p>';

            var modalHtml = '<div class="modal fade" id="retakeCodeModal" tabindex="-1">' +
                '<div class="modal-dialog modal-dialog-centered">' +
                '<div class="modal-content">' +
                '<div class="modal-header ' + headerClass + '">' +
                '<h5 class="modal-title">' +
                '<i class="bi bi-' + iconClass + ' me-2"></i>' +
                titleText +
                '</h5>' +
                '<button type="button" class="btn-close btn-close-white" data-bs-dismiss="modal"></button>' +
                '</div>' +
                '<div class="modal-body text-center">' +
                messageHtml +
                '<div class="input-group mb-3">' +
                '<input type="text" class="form-control form-control-lg text-center fw-bold" ' +
                'value="' + escapedCode + '" readonly id="retakeCodeDisplay">' +
                '<button class="btn btn-outline-primary" id="retakeCodeCopyBtn" onclick="copyRetakeCode(\'' + escapedCode + '\')">' +
                '<i class="bi bi-clipboard"></i> Copy' +
                '</button>' +
                '</div>' +
                '<div class="alert alert-info">' +
                '<i class="bi bi-info-circle me-2"></i>' +
                'Peserta dapat memasukkan kode ini di halaman quiz untuk mengambil quiz.' +
                '</div>' +
                '</div>' +
                '<div class="modal-footer">' +
                '<button type="button" class="btn btn-secondary" data-bs-dismiss="modal">Tutup</button>' +
                '</div>' +
                '</div>' +
                '</div>' +
                '</div>';

            // Remove existing modal if any
            var existingModal = document.getElementById('retakeCodeModal');
            if (existingModal) existingModal.remove();

            document.body.insertAdjacentHTML('beforeend', modalHtml);

            var modal = new bootstrap.Modal(document.getElementById('retakeCodeModal'));
            modal.show();

            // Reset button
            var btn = document.getElementById('failedRetakeBtn');
            btn.disabled = false;
            btn.innerHTML = '<i class="bi bi-key me-1"></i>Buat Kode Retake';

            // Reload page after modal closes
            document.getElementById('retakeCodeModal').addEventListener('hidden.bs.modal', function () {
                location.reload();
            });
        }

        function copyRetakeCode(code) {
            navigator.clipboard.writeText(code).then(function() {
                var btn = document.getElementById('retakeCodeCopyBtn');
                if (btn) {
                    var originalHtml = btn.innerHTML;
                    btn.innerHTML = '<i class="bi bi-check"></i> Copied!';
                    setTimeout(function() {
                        btn.innerHTML = originalHtml;
                    }, 2000);
                }
            }).catch(function(err) {
                alert('Gagal menyalin kode: ' + err);
            });
        }

        function retakeQuiz() {
            if (!currentSubmissionId) {
                alert('Tidak ada submission yang dipilih');
                return;
            }

            const userNameEl = document.querySelector('#userDetailContent .fw-bold');
            const userName = userNameEl ? userNameEl.textContent : 'peserta ini';

            if (!confirm('Izinkan ' + userName + ' untuk retake quiz?\n\nData jawaban lama akan dihapus permanen.')) {
                return;
            }

            const btn = document.getElementById('retakeBtn');
            btn.disabled = true;
            btn.innerHTML = '<span class="spinner-border spinner-border-sm me-1"></span>Memproses...';

            const csrfToken = document.getElementById('csrfToken').value;
            const formData = new FormData();
            formData.append('action', 'retakeQuiz');
            formData.append('submissionId', currentSubmissionId);
            formData.append('csrfToken', csrfToken);

            fetch('../AdminServlet', {
                method: 'POST',
                headers: {
                    'Content-Type': 'application/x-www-form-urlencoded',
                    'X-Requested-With': 'XMLHttpRequest'
                },
                body: formData
            })
            .then(response => response.text())
            .then(text => {
                console.log('Response:', text);
                try {
                    return JSON.parse(text);
                } catch (e) {
                    throw new Error('Server returned invalid response: ' + text.substring(0, 100));
                }
            })
            .then(data => {
                if (data.success) {
                    alert('Retake berhasil diizinkan untuk ' + userName);
                    bootstrap.Modal.getInstance(document.getElementById('userDetailModal')).hide();
                    location.reload();
                } else {
                    alert('Error: ' + (data.error || 'Unknown error'));
                }
            })
            .catch(error => {
                console.error('Error:', error);
                alert('Error: ' + error.message);
            })
            .finally(() => {
                btn.disabled = false;
                btn.innerHTML = '<i class="bi bi-arrow-repeat me-1"></i>Izinkan Retake';
            });
        }

        function initUserChart() {
            const chartCanvas = document.getElementById('userPerformanceChart');
            if (!chartCanvas) return;
            const correct = parseInt(chartCanvas.dataset.correct || 0);
            const wrong = parseInt(chartCanvas.dataset.wrong || 0);
            const unanswered = parseInt(chartCanvas.dataset.unanswered || 0);
            new Chart(chartCanvas.getContext('2d'), {
                type: 'radar',
                data: {
                    labels: ['Benar', 'Salah', 'Tidak Dijawab'],
                    datasets: [{
                        data: [correct, wrong, unanswered],
                        backgroundColor: [
                            chartColors.successLight,
                            'rgba(217, 83, 79, 0.2)',
                            'rgba(240, 173, 78, 0.2)'
                        ],
                        borderColor: [
                            'rgba(92, 184, 92, 1)',
                            'rgba(217, 83, 79, 1)',
                            'rgba(240, 173, 78, 1)'
                        ],
                        borderWidth: 2
                    }]
                },
                options: {
                    responsive: true,
                    scales: {
                        r: {
                            beginAtZero: true,
                            grid: { color: 'rgba(0, 0, 0, 0.08)' }
                        }
                    },
                    plugins: {
                        legend: { display: false }
                    }
                }
            });
        }

        function resetTimeout(submissionId, userName) {
            if (!confirm('Reset submission timeout untuk ' + userName + '?\n\nPeserta akan dapat mengerjakan quiz kembali.')) {
                return;
            }

            const btn = event.target.closest('button');
            const originalHtml = btn.innerHTML;
            btn.disabled = true;
            btn.innerHTML = '<span class="spinner-border spinner-border-sm me-1"></span>Memproses...';

            const csrfToken = document.getElementById('csrfToken').value;
            const formData = new URLSearchParams();
            formData.append('action', 'resetTimeout');
            formData.append('submissionId', submissionId.toString());
            formData.append('quizId', '<%= selectedQuizId %>');
            formData.append('csrfToken', csrfToken);

            fetch('../AdminServlet', {
                method: 'POST',
                headers: {
                    'Content-Type': 'application/x-www-form-urlencoded',
                    'X-Requested-With': 'XMLHttpRequest'
                },
                body: formData
            })
            .then(response => response.json())
            .then(data => {
                if (data.success) {
                    alert('Submission berhasil direset!');
                    location.reload();
                } else {
                    alert('Error: ' + (data.message || 'Terjadi kesalahan'));
                    btn.disabled = false;
                    btn.innerHTML = originalHtml;
                }
            })
            .catch(error => {
                console.error('Error:', error);
                alert('Error: ' + error.message);
                btn.disabled = false;
                btn.innerHTML = originalHtml;
            });
        }

        function resetTimeoutFromDataset(btn) {
            const submissionId = btn.dataset.submissionId;
            const userName = btn.dataset.userName;

            if (!confirm('Reset submission timeout untuk ' + userName + '?\n\nPeserta akan dapat mengerjakan quiz kembali.')) {
                return;
            }

            const originalHtml = btn.innerHTML;
            btn.disabled = true;
            btn.innerHTML = '<span class="spinner-border spinner-border-sm me-1"></span>Memproses...';

            const csrfToken = document.getElementById('csrfToken').value;
            const formData = new URLSearchParams();
            formData.append('action', 'resetTimeout');
            formData.append('submissionId', submissionId);
            formData.append('quizId', '<%= selectedQuizId %>');
            formData.append('csrfToken', csrfToken);

            fetch('../AdminServlet', {
                method: 'POST',
                headers: {
                    'Content-Type': 'application/x-www-form-urlencoded',
                    'X-Requested-With': 'XMLHttpRequest'
                },
                body: formData
            })
            .then(response => response.json())
            .then(data => {
                if (data.success) {
                    alert('Submission berhasil direset!');
                    location.reload();
                } else {
                    alert('Error: ' + (data.message || 'Terjadi kesalahan'));
                    btn.disabled = false;
                    btn.innerHTML = originalHtml;
                }
            })
            .catch(error => {
                console.error('Error:', error);
                alert('Error: ' + error.message);
                btn.disabled = false;
                btn.innerHTML = originalHtml;
            });
        }

        function resetSubmission(submissionId, userName, score) {
            if (!confirm('Izinkan ' + userName + ' untuk retake quiz?\n\nNilai saat ini: ' + score + '\n\nSubmission akan direset dan peserta dapat mengerjakan quiz kembali.')) {
                return;
            }

            const btn = event.target.closest('button');
            const originalHtml = btn.innerHTML;
            btn.disabled = true;
            btn.innerHTML = '<span class="spinner-border spinner-border-sm me-1"></span>Memproses...';

            const csrfToken = document.getElementById('csrfToken').value;
            const formData = new URLSearchParams();
            formData.append('action', 'resetSubmission');
            formData.append('submissionId', submissionId.toString());
            formData.append('quizId', '<%= selectedQuizId %>');
            formData.append('csrfToken', csrfToken);

            fetch('../AdminServlet', {
                method: 'POST',
                headers: {
                    'Content-Type': 'application/x-www-form-urlencoded',
                    'X-Requested-With': 'XMLHttpRequest'
                },
                body: formData
            })
            .then(response => response.json())
            .then(data => {
                if (data.success) {
                    alert('Submission berhasil direset! ' + userName + ' sekarang dapat mengerjakan quiz kembali.');
                    location.reload();
                } else {
                    alert('Error: ' + (data.message || 'Terjadi kesalahan'));
                    btn.disabled = false;
                    btn.innerHTML = originalHtml;
                }
            })
            .catch(error => {
                console.error('Error:', error);
                alert('Error: ' + error.message);
                btn.disabled = false;
                btn.innerHTML = originalHtml;
            });
        }

        function resetSubmissionFromDataset(btn) {
            const submissionId = btn.dataset.submissionId;
            const userName = btn.dataset.userName;
            const score = btn.dataset.score;

            if (!confirm('Izinkan ' + userName + ' untuk retake quiz?\n\nNilai saat ini: ' + score + '\n\nSubmission akan direset dan peserta dapat mengerjakan quiz kembali.')) {
                return;
            }

            const originalHtml = btn.innerHTML;
            btn.disabled = true;
            btn.innerHTML = '<span class="spinner-border spinner-border-sm me-1"></span>Memproses...';

            const csrfToken = document.getElementById('csrfToken').value;
            const formData = new URLSearchParams();
            formData.append('action', 'resetSubmission');
            formData.append('submissionId', submissionId);
            formData.append('quizId', '<%= selectedQuizId %>');
            formData.append('csrfToken', csrfToken);

            fetch('../AdminServlet', {
                method: 'POST',
                headers: {
                    'Content-Type': 'application/x-www-form-urlencoded',
                    'X-Requested-With': 'XMLHttpRequest'
                },
                body: formData
            })
            .then(response => response.json())
            .then(data => {
                if (data.success) {
                    alert('Submission berhasil direset! ' + userName + ' sekarang dapat mengerjakan quiz kembali.');
                    location.reload();
                } else {
                    alert('Error: ' + (data.message || 'Terjadi kesalahan'));
                    btn.disabled = false;
                    btn.innerHTML = originalHtml;
                }
            })
            .catch(error => {
                console.error('Error:', error);
                alert('Error: ' + error.message);
                btn.disabled = false;
                btn.innerHTML = originalHtml;
            });
        }

        function resetAllTimeout() {
            console.log('resetAllTimeout called');
            const timeoutRows = document.querySelectorAll('.timeout-row:not([style*="display: none"])');
            console.log('Found timeout rows:', timeoutRows.length);

            if (timeoutRows.length === 0) {
                alert('Tidak ada submission timeout untuk direset');
                return;
            }

            if (!confirm('Reset SEMUA submission timeout (' + timeoutRows.length + ' peserta)?\n\nSemua peserta timeout akan dapat mengerjakan quiz kembali.')) {
                return;
            }

            const btn = event.target.closest('button');
            const originalHtml = btn.innerHTML;
            btn.disabled = true;
            btn.innerHTML = '<span class="spinner-border spinner-border-sm me-1"></span>Memproses...';

            const csrfToken = document.getElementById('csrfToken').value;
            const formData = new URLSearchParams();
            formData.append('action', 'resetAllTimeout');
            formData.append('quizId', '<%= selectedQuizId %>');
            formData.append('csrfToken', csrfToken);

            console.log('Sending request to AdminServlet with action: resetAllTimeout');

            fetch('../AdminServlet', {
                method: 'POST',
                headers: {
                    'Content-Type': 'application/x-www-form-urlencoded',
                    'X-Requested-With': 'XMLHttpRequest'
                },
                body: formData
            })
            .then(response => {
                console.log('Response status:', response.status);
                return response.json();
            })
            .then(data => {
                console.log('Response data:', data);
                if (data.success) {
                    alert('Semua submission timeout berhasil direset! (' + data.count + ' submission)');
                    location.reload();
                } else {
                    alert('Error: ' + (data.message || 'Terjadi kesalahan'));
                    btn.disabled = false;
                    btn.innerHTML = originalHtml;
                }
            })
            .catch(error => {
                console.error('Error:', error);
                alert('Error: ' + error.message);
                btn.disabled = false;
                btn.innerHTML = originalHtml;
            });
        }

        // Checkbox functions for timeout participants
        function toggleAllTimeout(checkbox) {
            const checkboxes = document.querySelectorAll('.timeout-checkbox');
            checkboxes.forEach(cb => {
                if (!cb.closest('tr').style.display || cb.closest('tr').style.display !== 'none') {
                    cb.checked = checkbox.checked;
                }
            });
            updateSelectedTimeoutCount();
        }

        function updateSelectedTimeoutCount() {
            const checkboxes = document.querySelectorAll('.timeout-checkbox:checked');
            const count = checkboxes.length;
            document.getElementById('selectedTimeoutCount').textContent = count;

            const bulkActions = document.getElementById('bulkTimeoutActions');
            if (count > 0) {
                bulkActions.style.display = '';
            } else {
                bulkActions.style.display = 'none';
            }

            // Update select all checkbox state
            const allCheckboxes = document.querySelectorAll('.timeout-checkbox');
            const allChecked = Array.from(allCheckboxes).every(cb => cb.checked);
            document.getElementById('selectAllTimeout').checked = allChecked && allCheckboxes.length > 0;
        }

        function resetSelectedTimeout() {
            const checkboxes = document.querySelectorAll('.timeout-checkbox:checked');
            if (checkboxes.length === 0) {
                alert('Pilih minimal satu peserta untuk direset');
                return;
            }

            if (!confirm('Reset ' + checkboxes.length + ' submission timeout yang dipilih?\n\nPeserta yang dipilih akan dapat mengerjakan quiz kembali.')) {
                return;
            }

            const submissionIds = Array.from(checkboxes).map(cb => cb.getAttribute('data-submission-id'));
            const btn = event.target.closest('button');
            const originalHtml = btn.innerHTML;
            btn.disabled = true;
            btn.innerHTML = '<span class="spinner-border spinner-border-sm me-1"></span>Memproses...';

            const csrfToken = document.getElementById('csrfToken').value;

            fetch('../AdminServlet', {
                method: 'POST',
                headers: {
                    'Content-Type': 'application/x-www-form-urlencoded',
                },
                body: 'action=resetMultipleTimeout&submissionIds=' + submissionIds.join(',') + '&csrfToken=' + csrfToken
            })
            .then(response => response.json())
            .then(data => {
                if (data.success) {
                    alert(data.message || 'Reset berhasil!');
                    location.reload();
                } else {
                    alert('Error: ' + (data.message || 'Terjadi kesalahan'));
                    btn.disabled = false;
                    btn.innerHTML = originalHtml;
                }
            })
            .catch(error => {
                console.error('Error:', error);
                alert('Error: ' + error.message);
                btn.disabled = false;
                btn.innerHTML = originalHtml;
            });
        }

        // Checkbox functions for not taken participants
        function toggleAllNotTaken(checkbox) {
            const checkboxes = document.querySelectorAll('.not-taken-checkbox');
            checkboxes.forEach(cb => {
                if (!cb.closest('tr').style.display || cb.closest('tr').style.display !== 'none') {
                    cb.checked = checkbox.checked;
                }
            });
            updateSelectedNotTakenCount();
        }

        function updateSelectedNotTakenCount() {
            const checkboxes = document.querySelectorAll('.not-taken-checkbox:checked');
            const count = checkboxes.length;
            document.getElementById('selectedNotTakenCount').textContent = count;

            const bulkActions = document.getElementById('bulkNotTakenActions');
            if (count > 0) {
                bulkActions.style.display = '';
            } else {
                bulkActions.style.display = 'none';
            }

            // Update select all checkbox state
            const allCheckboxes = document.querySelectorAll('.not-taken-checkbox');
            const allChecked = Array.from(allCheckboxes).every(cb => cb.checked);
            document.getElementById('selectAllNotTaken').checked = allChecked && allCheckboxes.length > 0;
        }

        function resetSelectedNotTaken() {
            const checkboxes = document.querySelectorAll('.not-taken-checkbox:checked');
            if (checkboxes.length === 0) {
                alert('Pilih minimal satu peserta untuk diizinkan retake');
                return;
            }

            const userIds = Array.from(checkboxes).map(cb => cb.getAttribute('data-user-id'));
            const userNames = Array.from(checkboxes).map(cb => cb.getAttribute('data-user-name')).join(', ');

            if (!confirm('Izinkan retake untuk ' + checkboxes.length + ' peserta berikut:\n\n' + userNames + '\n\nPeserta ini akan dapat mengerjakan quiz kembali.')) {
                return;
            }

            const btn = event.target.closest('button');
            const originalHtml = btn.innerHTML;
            btn.disabled = true;
            btn.innerHTML = '<span class="spinner-border spinner-border-sm me-1"></span>Memproses...';

            const csrfToken = document.getElementById('csrfToken').value;

            fetch('../AdminServlet', {
                method: 'POST',
                headers: {
                    'Content-Type': 'application/x-www-form-urlencoded',
                },
                body: 'action=allowRetakeMultiple&userIds=' + userIds.join(',') + '&quizId=<%= selectedQuizId %>&csrfToken=' + csrfToken
            })
            .then(response => response.json())
            .then(data => {
                if (data.success) {
                    alert(data.message || 'Retake berhasil diizinkan!');
                    location.reload();
                } else {
                    alert('Error: ' + (data.message || 'Terjadi kesalahan'));
                    btn.disabled = false;
                    btn.innerHTML = originalHtml;
                }
            })
            .catch(error => {
                console.error('Error:', error);
                alert('Error: ' + error.message);
                btn.disabled = false;
                btn.innerHTML = originalHtml;
            });
        }

        // Checkbox functions for in-progress participants
        function toggleAllInProgress(checkbox) {
            const checkboxes = document.querySelectorAll('.in-progress-checkbox');
            checkboxes.forEach(cb => {
                if (!cb.closest('tr').style.display || cb.closest('tr').style.display !== 'none') {
                    cb.checked = checkbox.checked;
                }
            });
            updateSelectedInProgressCount();
        }

        function updateSelectedInProgressCount() {
            const checkboxes = document.querySelectorAll('.in-progress-checkbox:checked');
            const count = checkboxes.length;
            const countEl = document.getElementById('selectedInProgressCount');
            if (countEl) {
                countEl.textContent = count;
            }

            const bulkActions = document.getElementById('bulkInProgressActions');
            if (bulkActions) {
                if (count > 0) {
                    bulkActions.style.display = '';
                } else {
                    bulkActions.style.display = 'none';
                }
            }

            // Update select all checkbox state
            const allCheckboxes = document.querySelectorAll('.in-progress-checkbox');
            const allChecked = Array.from(allCheckboxes).every(cb => cb.checked);
            const selectAllEl = document.getElementById('selectAllInProgress');
            if (selectAllEl) {
                selectAllEl.checked = allChecked && allCheckboxes.length > 0;
            }
        }

        function resetSingleInProgress(submissionId, userName) {
            if (!confirm('Reset submission in-progress untuk ' + userName + '?\n\nPeserta akan dapat mengerjakan quiz kembali dari awal.')) {
                return;
            }

            const btn = event.target.closest('button');
            const originalHtml = btn.innerHTML;
            btn.disabled = true;
            btn.innerHTML = '<span class="spinner-border spinner-border-sm me-1"></span>Memproses...';

            const csrfToken = document.getElementById('csrfToken').value;
            const formData = new URLSearchParams();
            formData.append('action', 'resetSubmission');
            formData.append('submissionId', submissionId.toString());
            formData.append('quizId', '<%= selectedQuizId %>');
            formData.append('csrfToken', csrfToken);

            fetch('../AdminServlet', {
                method: 'POST',
                headers: {
                    'Content-Type': 'application/x-www-form-urlencoded',
                    'X-Requested-With': 'XMLHttpRequest'
                },
                body: formData
            })
            .then(response => response.json())
            .then(data => {
                if (data.success) {
                    alert('Submission berhasil direset! ' + userName + ' sekarang dapat mengerjakan quiz kembali.');
                    location.reload();
                } else {
                    alert('Error: ' + (data.message || 'Terjadi kesalahan'));
                    btn.disabled = false;
                    btn.innerHTML = originalHtml;
                }
            })
            .catch(error => {
                console.error('Error:', error);
                alert('Error: ' + error.message);
                btn.disabled = false;
                btn.innerHTML = originalHtml;
            });
        }

        function resetAllInProgress() {
            const inProgressRows = document.querySelectorAll('.in-progress-row:not([style*="display: none"])');

            if (inProgressRows.length === 0) {
                alert('Tidak ada submission in-progress untuk direset');
                return;
            }

            if (!confirm('Reset SEMUA submission in-progress (' + inProgressRows.length + ' peserta)?\n\nSemua peserta in-progress akan dapat mengerjakan quiz kembali dari awal.')) {
                return;
            }

            const btn = event.target.closest('button');
            const originalHtml = btn.innerHTML;
            btn.disabled = true;
            btn.innerHTML = '<span class="spinner-border spinner-border-sm me-1"></span>Memproses...';

            const submissionIds = Array.from(inProgressRows).map(row => row.getAttribute('data-submission-id'));
            const csrfToken = document.getElementById('csrfToken').value;

            fetch('../AdminServlet', {
                method: 'POST',
                headers: {
                    'Content-Type': 'application/x-www-form-urlencoded',
                },
                body: 'action=resetMultipleInProgress&submissionIds=' + submissionIds.join(',') + '&csrfToken=' + csrfToken
            })
            .then(response => response.json())
            .then(data => {
                if (data.success) {
                    alert('Semua submission in-progress berhasil direset! (' + data.count + ' submission)');
                    location.reload();
                } else {
                    alert('Error: ' + (data.message || 'Terjadi kesalahan'));
                    btn.disabled = false;
                    btn.innerHTML = originalHtml;
                }
            })
            .catch(error => {
                console.error('Error:', error);
                alert('Error: ' + error.message);
                btn.disabled = false;
                btn.innerHTML = originalHtml;
            });
        }

        function resetSelectedInProgress() {
            const checkboxes = document.querySelectorAll('.in-progress-checkbox:checked');
            if (checkboxes.length === 0) {
                alert('Pilih minimal satu peserta untuk direset');
                return;
            }

            if (!confirm('Reset ' + checkboxes.length + ' submission in-progress yang dipilih?\n\nPeserta yang dipilih akan dapat mengerjakan quiz kembali dari awal.')) {
                return;
            }

            const submissionIds = Array.from(checkboxes).map(cb => cb.getAttribute('data-submission-id'));
            const btn = event.target.closest('button');
            const originalHtml = btn.innerHTML;
            btn.disabled = true;
            btn.innerHTML = '<span class="spinner-border spinner-border-sm me-1"></span>Memproses...';

            const csrfToken = document.getElementById('csrfToken').value;

            fetch('../AdminServlet', {
                method: 'POST',
                headers: {
                    'Content-Type': 'application/x-www-form-urlencoded',
                },
                body: 'action=resetMultipleInProgress&submissionIds=' + submissionIds.join(',') + '&csrfToken=' + csrfToken
            })
            .then(response => response.json())
            .then(data => {
                if (data.success) {
                    alert(data.message || 'Reset berhasil!');
                    location.reload();
                } else {
                    alert('Error: ' + (data.message || 'Terjadi kesalahan'));
                    btn.disabled = false;
                    btn.innerHTML = originalHtml;
                }
            })
            .catch(error => {
                console.error('Error:', error);
                alert('Error: ' + error.message);
                btn.disabled = false;
                btn.innerHTML = originalHtml;
            });
        }

        function filterFailedParticipants() {
            const selectedTag = document.getElementById('failedTagFilter').value;

            const timeoutRows = document.querySelectorAll('.timeout-row');
            let visibleTimeoutCount = 0;
            timeoutRows.forEach(row => {
                const rowTag = row.getAttribute('data-tag') || '';
                if (selectedTag === '' || rowTag === selectedTag) {
                    row.style.display = '';
                    visibleTimeoutCount++;
                } else {
                    row.style.display = 'none';
                }
            });

            const timeoutCountEl = document.getElementById('timeoutCount');
            if (timeoutCountEl) {
                timeoutCountEl.textContent = visibleTimeoutCount;
            }

            const timeoutAlert = document.getElementById('timeoutAlert');
            if (timeoutAlert) {
                timeoutAlert.style.display = visibleTimeoutCount > 0 ? '' : 'none';
            }

            const inProgressRows = document.querySelectorAll('.in-progress-row');
            let visibleInProgressCount = 0;
            inProgressRows.forEach(row => {
                const rowTag = row.getAttribute('data-tag') || '';
                if (selectedTag === '' || rowTag === selectedTag) {
                    row.style.display = '';
                    visibleInProgressCount++;
                } else {
                    row.style.display = 'none';
                }
            });

            const inProgressCountEl = document.getElementById('inProgressCount');
            if (inProgressCountEl) {
                inProgressCountEl.textContent = visibleInProgressCount;
            }

            const inProgressAlert = document.getElementById('inProgressAlert');
            if (inProgressAlert) {
                inProgressAlert.style.display = visibleInProgressCount > 0 ? '' : 'none';
            }

            const notTakenRows = document.querySelectorAll('#notTakenTableBody tr');
            let visibleNotTakenCount = 0;
            notTakenRows.forEach(row => {
                const rowTag = row.getAttribute('data-tag') || '';
                if (selectedTag === '' || rowTag === selectedTag) {
                    row.style.display = '';
                    visibleNotTakenCount++;
                } else {
                    row.style.display = 'none';
                }
            });

            const notTakenCountEl = document.getElementById('notTakenCount');
            if (notTakenCountEl) {
                notTakenCountEl.textContent = visibleNotTakenCount;
            }

            const notTakenAlert = document.getElementById('notTakenAlert');
            if (notTakenAlert) {
                notTakenAlert.style.display = visibleNotTakenCount > 0 ? '' : 'none';
            }

            const totalVisible = visibleTimeoutCount + visibleInProgressCount + visibleNotTakenCount;
            const cardHeader = document.querySelector('.bg-danger.text-white h6');
            if (cardHeader) {
                cardHeader.innerHTML = '<i class="bi bi-exclamation-triangle me-2"></i>Peserta Tidak Lulus (' + totalVisible + ')';
            }
        }

        function exportAllToPdf() {
            const rows = document.querySelectorAll('.participant-row');
            if (!rows || rows.length === 0) {
                alert('Tidak ada data peserta untuk diexport');
                return;
            }

            let tableHtml = '';
            rows.forEach((row, idx) => {
                const name = row.querySelector('.participant-name');
                const tag = row.dataset.tag || '-';
                const score = parseFloat(row.dataset.score) || 0;

                const correctEl = row.querySelectorAll('.text-success.fw-bold')[0];
                const wrongEl = row.querySelectorAll('.text-danger.fw-bold')[0];
                const unansweredEl = row.querySelectorAll('.text-warning.fw-bold')[0];
                const timeText = row.querySelector('.bi-clock')?.parentElement?.textContent?.trim() || '-';

                const bgClass = idx % 2 === 0 ? 'background:#f8f9fa;' : '';
                const scoreColor = score >= 60 ? '#5cb85c' : '#d9534f';

                tableHtml += '<tr style="' + bgClass + '">';
                tableHtml += '<td style="padding:6px;border:1px solid #dee2e6;text-align:center;">' + (idx + 1) + '</td>';
                tableHtml += '<td style="padding:6px;border:1px solid #dee2e6;">' + (name ? name.textContent.trim() : '-') + '</td>';
                tableHtml += '<td style="padding:6px;border:1px solid #dee2e6;text-align:center;">' + tag + '</td>';
                tableHtml += '<td style="padding:6px;border:1px solid #dee2e6;text-align:center;color:#5cb85c;font-weight:bold;">' + (correctEl ? correctEl.textContent.trim() : '0') + '</td>';
                tableHtml += '<td style="padding:6px;border:1px solid #dee2e6;text-align:center;color:#d9534f;font-weight:bold;">' + (wrongEl ? wrongEl.textContent.trim() : '0') + '</td>';
                tableHtml += '<td style="padding:6px;border:1px solid #dee2e6;text-align:center;color:#f0ad4e;font-weight:bold;">' + (unansweredEl ? unansweredEl.textContent.trim() : '0') + '</td>';
                tableHtml += '<td style="padding:6px;border:1px solid #dee2e6;text-align:center;">' + timeText + '</td>';
                tableHtml += '<td style="padding:6px;border:1px solid #dee2e6;text-align:center;font-weight:bold;color:' + scoreColor + ';">' + score.toFixed(0) + '</td>';
                tableHtml += '</tr>';
            });

            const printWindow = window.open('', '_blank', 'width=1000,height=700');

            if (!printWindow) {
                alert('Popup blocker mencegah pembukaan window. Silakan izinkan popup atau gunakan Export TXT.');
                return;
            }

            var printDate = new Date().toLocaleString('id-ID');

            printWindow.document.write('<!DOCTYPE html><html><head>' +
                '<title>Daftar Peserta - <%= esc(selectedQuizTitle) %></title>' +
                '<style>' +
                'body { font-family: Arial, sans-serif; padding: 20px; font-size: 12px; background: #fafbfc; }' +
                'h2 { text-align: center; margin-bottom: 20px; color: #4a6fdc; }' +
                'table { width: 100%; border-collapse: collapse; font-size: 11px; }' +
                'th { padding: 10px; border: 1px solid #dee2e6; background: #4a6fdc; color: white; }' +
                'td { padding: 6px; border: 1px solid #dee2e6; }' +
                '.no-print { margin-bottom: 20px; padding: 15px; background: #e3edf7; border-radius: 8px; text-align: center; }' +
                '@media print { .no-print { display: none; } body { padding: 0; } }' +
                '</style></head><body>' +
                '<div class="no-print">' +
                '<h3 style="margin: 0 0 15px 0; color: #4a6fdc;">Daftar Peserta Quiz</h3>' +
                '<button onclick="window.print()" style="padding: 10px 30px; font-size: 16px; cursor: pointer; background: #4a6fdc; color: white; border: none; border-radius: 8px;">Print / Save as PDF</button>' +
                '<p style="margin-top: 10px; font-size: 11px; color: #6c757d;">Klik tombol di atas, lalu pilih "Save as PDF" sebagai printer</p>' +
                '</div>' +
                '<h2>Daftar Peserta - <%= esc(selectedQuizTitle) %></h2>' +
                '<table><thead><tr>' +
                '<th>No</th><th>Nama Peserta</th><th>Tag</th><th>Benar</th><th>Salah</th><th>Kosong</th><th>Waktu</th><th>Nilai</th>' +
                '</tr></thead><tbody>' + tableHtml + '</tbody></table>' +
                '<p style="text-align:center;margin-top:15px;font-size:10px;color:#6c757d;">Dicetak pada: ' + printDate + '</p>' +
                '</body></html>');

            printWindow.document.close();
        }

        function exportAllToTxt() {
            const rows = document.querySelectorAll('.participant-row');
            if (!rows || rows.length === 0) {
                alert('Tidak ada data peserta untuk diexport');
                return;
            }

            let text = '='.repeat(60) + '\n';
            text += 'DAFTAR PESERTA QUIZ\n';
            text += '='.repeat(60) + '\n\n';
            text += 'Quiz: <%= esc(selectedQuizTitle) %>\n';
            text += 'Tanggal Export: ' + new Date().toLocaleString('id-ID') + '\n\n';
            text += '-'.repeat(60) + '\n';

            rows.forEach((row, idx) => {
                const name = row.querySelector('.participant-name');
                const tag = row.dataset.tag || '-';
                const score = parseFloat(row.dataset.score) || 0;

                const correctEl = row.querySelectorAll('.text-success.fw-bold')[0];
                const wrongEl = row.querySelectorAll('.text-danger.fw-bold')[0];
                const unansweredEl = row.querySelectorAll('.text-warning.fw-bold')[0];
                const timeText = row.querySelector('.bi-clock')?.parentElement?.textContent?.trim() || '-';

                text += (idx + 1) + '. ' + (name ? name.textContent.trim() : '-') + '\n';
                text += '   Tag: ' + tag + ' | Nilai: ' + score.toFixed(0) + '\n';
                text += '   Benar: ' + (correctEl ? correctEl.textContent.trim() : '0');
                text += ' | Salah: ' + (wrongEl ? wrongEl.textContent.trim() : '0');
                text += ' | Kosong: ' + (unansweredEl ? unansweredEl.textContent.trim() : '0') + '\n';
                text += '   Waktu: ' + timeText + '\n\n';
            });

            text += '='.repeat(60) + '\n';
            text += 'Total Peserta: ' + rows.length + '\n';
            text += '='.repeat(60) + '\n';

            const blob = new Blob([text], { type: 'text/plain;charset=utf-8' });
            const url = URL.createObjectURL(blob);
            const a = document.createElement('a');
            a.href = url;
            a.download = 'statistik_<%= selectedQuizId %>_<%= java.time.LocalDate.now().toString() %>.txt';
            document.body.appendChild(a);
            a.click();
            document.body.removeChild(a);
            URL.revokeObjectURL(url);
        }

        // Filter and Pagination
        let currentPage = 1;
        let filteredRows = [];

        function filterTable() {
            const searchTerm = document.getElementById('searchInput').value.toLowerCase();
            const tagFilter = document.getElementById('tagFilter').value;
            const scoreFilter = document.getElementById('scoreFilter').value;
            const allRows = Array.from(document.querySelectorAll('.participant-row'));

            filteredRows = allRows.filter(row => {
                const name = row.dataset.name || '';
                const tag = row.dataset.tag || '';
                const score = parseFloat(row.dataset.score) || 0;
                const matchesSearch = name.includes(searchTerm);
                const matchesTag = !tagFilter || tag === tagFilter;
                let matchesScore = true;
                if (scoreFilter) {
                    switch(scoreFilter) {
                        case 'pass': matchesScore = score >= 60; break;
                        case 'fail': matchesScore = score < 60; break;
                        case 'excellent': matchesScore = score >= 86; break;
                        case 'good': matchesScore = score >= 76 && score < 86; break;
                        case 'fair': matchesScore = score >= 61 && score < 76; break;
                        case 'poor': matchesScore = score < 61; break;
                    }
                }
                return matchesSearch && matchesTag && matchesScore;
            });

            document.getElementById('totalCount').textContent = filteredRows.length + ' peserta ditemukan';
            currentPage = 1;
            renderTable();
        }

        function renderTable() {
            const allRows = Array.from(document.querySelectorAll('.participant-row'));
            const pageSize = document.getElementById('pageSize').value;

            allRows.forEach(row => row.style.display = 'none');

            let rowsToShow, totalPages;
            if (pageSize === 'all') {
                rowsToShow = filteredRows.length > 0 ? filteredRows : allRows;
                totalPages = 1;
            } else {
                const size = parseInt(pageSize);
                totalPages = Math.ceil(filteredRows.length / size) || 1;
                const startIndex = (currentPage - 1) * size;
                rowsToShow = filteredRows.slice(startIndex, startIndex + size);
            }

            rowsToShow.forEach(row => row.style.display = '');

            const pageSizeVal = pageSize === 'all' ? filteredRows.length : parseInt(pageSize);
            const startItem = filteredRows.length > 0 ? ((currentPage - 1) * pageSizeVal) + 1 : 0;
            const endItem = pageSize === 'all' ? filteredRows.length : Math.min(currentPage * pageSizeVal, filteredRows.length);
            document.getElementById('showingInfo').textContent = 'Menampilkan ' + startItem + '-' + endItem + ' dari ' + filteredRows.length + ' peserta';

            renderPagination(totalPages);
        }

        function renderPagination(totalPages) {
            const paginationList = document.getElementById('paginationList');
            paginationList.innerHTML = '';
            if (totalPages <= 1) return;

            const prevLi = document.createElement('li');
            prevLi.className = 'page-item ' + (currentPage === 1 ? 'disabled' : '');
            prevLi.innerHTML = '<a class="page-link" href="#" onclick="goToPage(' + (currentPage - 1) + ');return false;"><i class="bi bi-chevron-left"></i></a>';
            paginationList.appendChild(prevLi);

            const maxVisible = 5;
            let startPage = Math.max(1, currentPage - Math.floor(maxVisible / 2));
            let endPage = Math.min(totalPages, startPage + maxVisible - 1);
            if (endPage - startPage < maxVisible - 1) startPage = Math.max(1, endPage - maxVisible + 1);

            for (let i = startPage; i <= endPage; i++) {
                const li = document.createElement('li');
                li.className = 'page-item ' + (i === currentPage ? 'active' : '');
                li.innerHTML = '<a class="page-link" href="#" onclick="goToPage(' + i + ');return false;">' + i + '</a>';
                paginationList.appendChild(li);
            }

            const nextLi = document.createElement('li');
            nextLi.className = 'page-item ' + (currentPage === totalPages ? 'disabled' : '');
            nextLi.innerHTML = '<a class="page-link" href="#" onclick="goToPage(' + (currentPage + 1) + ');return false;"><i class="bi bi-chevron-right"></i></a>';
            paginationList.appendChild(nextLi);
        }

        function goToPage(page) {
            const pageSize = document.getElementById('pageSize').value;
            const size = pageSize === 'all' ? filteredRows.length : parseInt(pageSize);
            const totalPages = Math.ceil(filteredRows.length / size) || 1;
            if (page < 1 || page > totalPages) return;
            currentPage = page;
            renderTable();
            document.getElementById('participantsList').scrollIntoView({ behavior: 'smooth' });
        }

        function changePageSize() { currentPage = 1; filterTable(); }

        // Modal close handlers
        document.addEventListener('DOMContentLoaded', function() {
            // Setup failed participant modal close button
            const failedModalCloseBtn = document.querySelector('#failedParticipantModal .btn-close');
            if (failedModalCloseBtn) {
                failedModalCloseBtn.addEventListener('click', function() {
                    closeFailedParticipantModal();
                });
            }

            // Setup close button with data-bs-dismiss
            const closeButtons = document.querySelectorAll('#failedParticipantModal [data-bs-dismiss="modal"]');
            closeButtons.forEach(function(btn) {
                btn.addEventListener('click', function(e) {
                    e.preventDefault();
                    closeFailedParticipantModal();
                });
            });

            // Close modal when clicking backdrop
            document.addEventListener('click', function(e) {
                if (e.target.id === 'failedParticipantModalBackdrop') {
                    closeFailedParticipantModal();
                }
            });
        });

        function closeFailedParticipantModal() {
            const modalElement = document.getElementById('failedParticipantModal');
            if (modalElement) {
                modalElement.classList.remove('show');
                modalElement.style.display = 'none';
                document.body.classList.remove('modal-open');
                const backdrop = document.getElementById('failedParticipantModalBackdrop');
                if (backdrop) {
                    backdrop.remove();
                }
            }
        }

        document.addEventListener('DOMContentLoaded', function() {
            const allRows = Array.from(document.querySelectorAll('.participant-row'));
            if (allRows.length > 0) {
                filteredRows = allRows;
                renderTable();
            }
        });
    </script>
    <% } %>
</body>
</html>

<%@ page contentType="text/html;charset=UTF-8" language="java" %>
<%@ taglib prefix="c" uri="http://java.sun.com/jsp/jstl/core" %>
<%@ page import="com.examora.model.User" %>
<%@ page import="com.examora.model.Quiz" %>
<%@ page import="com.examora.dao.QuestionDAO" %>
<%@ page import="java.util.List" %>
<%@ page import="java.util.Map" %>
<%@ page import="com.examora.util.ValidationUtil" %>
<%
    User currentUser = (User) session.getAttribute("user");
    if (currentUser == null || !currentUser.isAdmin()) {
        response.sendRedirect("../LoginServlet");
        return;
    }
    Quiz quiz = (Quiz) request.getAttribute("quiz");
    String error = (String) request.getAttribute("error");

    // Get question statistics
    List<Map<String, Object>> questionStats = null;
    if (quiz != null) {
        try {
            QuestionDAO questionDAO = new QuestionDAO();
            questionStats = questionDAO.getQuestionStatistics(quiz.getId());
        } catch (Exception e) {
            e.printStackTrace();
        }
    }
%>
<!DOCTYPE html>
<html lang="id">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Analisis Soal - Exatuy</title>
    <link href="https://cdn.jsdelivr.net/npm/bootstrap@5.3.0/dist/css/bootstrap.min.css" rel="stylesheet">
    <link href="https://cdn.jsdelivr.net/npm/bootstrap-icons@1.10.0/font/bootstrap-icons.css" rel="stylesheet">
    <link href="../assets/css/style.css" rel="stylesheet">
    <link rel="icon" type="image/svg+xml" type="image/svg+xml" href="../assets/img/favicon.svg?v=3">
    <style>
        .difficulty-easy { background-color: #d4edda; color: #155724; }
        .difficulty-medium { background-color: #fff3cd; color: #856404; }
        .difficulty-hard { background-color: #f8d7da; color: #721c24; }
    </style>
<link href="../assets/css/handdrawn.css" rel="stylesheet">
</head>
<body>
    <!-- Sidebar -->
    <%@ include file="sidebar.jsp" %>

    <!-- Main Content -->
    <div class="main-content">
        <div class="d-flex justify-content-between align-items-center mb-4">
            <div>
                <h1 class="h3 mb-0">Analisis Soal</h1>
                <nav aria-label="breadcrumb">
                    <ol class="breadcrumb mb-0">
                        <li class="breadcrumb-item"><a href="../AdminServlet?action=dashboard">Dashboard</a></li>
                        <li class="breadcrumb-item"><a href="../QuizServlet?action=list">Quiz</a></li>
                        <% if (quiz != null) { %>
                        <li class="breadcrumb-item"><a href="../QuestionServlet?action=list&quizId=<%= quiz.getId() %>"><%= ValidationUtil.sanitizeHtml(quiz.getTitle()) %></a></li>
                        <% } %>
                        <li class="breadcrumb-item active">Analisis</li>
                    </ol>
                </nav>
            </div>
            <div class="d-flex gap-2">
                <% if (quiz != null) { %>
                <a href="../QuestionServlet?action=list&quizId=<%= quiz.getId() %>" class="btn btn-outline-secondary">
                    <i class="bi bi-arrow-left me-2"></i>Kembali ke Soal
                </a>
                <% } %>
            </div>
        </div>

        <% if (error != null) { %>
        <div class="alert alert-danger alert-dismissible fade show">
            <i class="bi bi-exclamation-triangle me-2"></i><%= ValidationUtil.sanitizeHtml(error) %>
            <button type="button" class="btn-close" data-bs-dismiss="alert"></button>
        </div>
        <% } %>

        <% if (quiz != null) { %>
        <!-- Quiz Info -->
        <div class="card mb-4">
            <div class="card-body">
                <div class="row">
                    <div class="col-md-8">
                        <h5><%= ValidationUtil.sanitizeHtml(quiz.getTitle()) %></h5>
                        <p class="text-muted mb-0"><%= ValidationUtil.sanitizeHtml(quiz.getDescription()) %></p>
                    </div>
                    <div class="col-md-4 text-end">
                        <span class="badge <%= quiz.getIsActive() ? "bg-success" : "bg-secondary" %>">
                            <%= quiz.getIsActive() ? "Published" : "Draft" %>
                        </span>
                    </div>
                </div>
            </div>
        </div>

        <!-- Statistics -->
        <div class="card">
            <div class="card-header">
                <h6 class="mb-0"><i class="bi bi-bar-chart me-2"></i>Statistik Soal</h6>
            </div>
            <div class="card-body">
                <% if (questionStats != null && !questionStats.isEmpty()) { %>
                <div class="table-responsive">
                    <table class="table table-hover">
                        <thead>
                            <tr>
                                <th width="50">#</th>
                                <th>Soal</th>
                                <th width="100" class="text-center">Percobaan</th>
                                <th width="100" class="text-center">Benar</th>
                                <th width="100" class="text-center">% Benar</th>
                                <th width="120" class="text-center">Tingkat Kesulitan</th>
                                <th width="120">Kategori</th>
                            </tr>
                        </thead>
                        <tbody>
                            <% for (int i = 0; i < questionStats.size(); i++) {
                                Map<String, Object> stat = questionStats.get(i);
                                int totalAttempts = stat.get("totalAttempts") != null ? (Integer) stat.get("totalAttempts") : 0;
                                int correctAttempts = stat.get("correctAttempts") != null ? (Integer) stat.get("correctAttempts") : 0;
                                double correctPercentage = stat.get("correctPercentage") != null ? (Double) stat.get("correctPercentage") : 0;
                                String difficultyLabel = stat.get("difficultyLabel") != null ? (String) stat.get("difficultyLabel") : "N/A";
                                String difficultyClass = "secondary";
                                if ("Mudah".equals(difficultyLabel)) difficultyClass = "success";
                                else if ("Sedang".equals(difficultyLabel)) difficultyClass = "warning";
                                else if ("Sulit".equals(difficultyLabel)) difficultyClass = "danger";
                            %>
                            <tr>
                                <td><%= i + 1 %></td>
                                <td>
                                    <%= ValidationUtil.sanitizeHtml(stat.get("questionText") != null ?
                                        (stat.get("questionText").toString().length() > 80 ?
                                            stat.get("questionText").toString().substring(0, 80) + "..." :
                                            stat.get("questionText").toString()) : "-") %>
                                </td>
                                <td class="text-center"><%= totalAttempts %></td>
                                <td class="text-center"><%= correctAttempts %></td>
                                <td class="text-center">
                                    <span class="badge <%= correctPercentage >= 70 ? "bg-success" : (correctPercentage >= 40 ? "bg-warning" : "bg-danger") %>">
                                        <%= String.format("%.1f", correctPercentage) %>%
                                    </span>
                                </td>
                                <td class="text-center">
                                    <span class="badge bg-<%= difficultyClass %>"><%= difficultyLabel %></span>
                                </td>
                                <td><%= ValidationUtil.sanitizeHtml(stat.get("categoryName") != null ? stat.get("categoryName").toString() : "-") %></td>
                            </tr>
                            <% } %>
                        </tbody>
                    </table>
                </div>

                <!-- Summary -->
                <div class="row mt-4">
                    <div class="col-md-4">
                        <div class="card bg-success bg-opacity-10 border-0">
                            <div class="card-body text-center">
                                <h6 class="text-success">Soal Mudah</h6>
                                <h3 class="mb-0">
                                    <% int easyCount = 0;
                                    for (Map<String, Object> s : questionStats) {
                                        if ("Mudah".equals(s.get("difficultyLabel"))) easyCount++;
                                    } %>
                                    <%= easyCount %>
                                </h3>
                                <small class="text-muted">(% benar >= 70%)</small>
                            </div>
                        </div>
                    </div>
                    <div class="col-md-4">
                        <div class="card bg-warning bg-opacity-10 border-0">
                            <div class="card-body text-center">
                                <h6 class="text-warning">Soal Sedang</h6>
                                <h3 class="mb-0">
                                    <% int mediumCount = 0;
                                    for (Map<String, Object> s : questionStats) {
                                        if ("Sedang".equals(s.get("difficultyLabel"))) mediumCount++;
                                    } %>
                                    <%= mediumCount %>
                                </h3>
                                <small class="text-muted">(% benar 40-69%)</small>
                            </div>
                        </div>
                    </div>
                    <div class="col-md-4">
                        <div class="card bg-danger bg-opacity-10 border-0">
                            <div class="card-body text-center">
                                <h6 class="text-danger">Soal Sulit</h6>
                                <h3 class="mb-0">
                                    <% int hardCount = 0;
                                    for (Map<String, Object> s : questionStats) {
                                        if ("Sulit".equals(s.get("difficultyLabel"))) hardCount++;
                                    } %>
                                    <%= hardCount %>
                                </h3>
                                <small class="text-muted">(% benar < 40%)</small>
                            </div>
                        </div>
                    </div>
                </div>

                <% } else { %>
                <div class="text-center py-5">
                    <i class="bi bi-bar-chart display-1 text-muted mb-3 d-block"></i>
                    <h5 class="text-muted">Belum ada data statistik</h5>
                    <p class="text-muted mb-0">Statistik soal akan muncul setelah peserta mengerjakan quiz ini.</p>
                </div>
                <% } %>
            </div>
        </div>

        <% } else { %>
        <div class="card">
            <div class="card-body text-center py-5">
                <i class="bi bi-question-circle display-1 text-muted mb-3 d-block"></i>
                <h5 class="text-muted">Pilih Quiz</h5>
                <p class="text-muted">Pilih quiz dari daftar untuk melihat analisis soal.</p>
                <a href="../QuizServlet?action=list" class="btn btn-primary">
                    <i class="bi bi-list me-2"></i>Lihat Daftar Quiz
                </a>
            </div>
        </div>
        <% } %>
    </div>

    <script src="https://cdn.jsdelivr.net/npm/bootstrap@5.3.0/dist/js/bootstrap.bundle.min.js"></script>
</body>
</html>

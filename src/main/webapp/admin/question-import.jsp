<%@ page contentType="text/html;charset=UTF-8" language="java" %>
<%@ taglib prefix="c" uri="http://java.sun.com/jsp/jstl/core" %>
<%@ page import="com.examora.model.User" %>
<%@ page import="com.examora.model.Quiz" %>
<%@ page import="java.util.List" %>
<%@ page import="com.examora.util.ValidationUtil" %>
<%
    User currentUser = (User) session.getAttribute("user");
    if (currentUser == null || !currentUser.isAdmin()) {
        response.sendRedirect("../LoginServlet");
        return;
    }
    Quiz quiz = (Quiz) request.getAttribute("quiz");
    String error = (String) request.getAttribute("error");
    String success = (String) request.getAttribute("success");
    List<String> warnings = (List<String>) request.getAttribute("warnings");
%>
<!DOCTYPE html>
<html lang="id">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Import Soal - Exatuy</title>
    <link href="https://cdn.jsdelivr.net/npm/bootstrap@5.3.0/dist/css/bootstrap.min.css" rel="stylesheet">
    <link href="https://cdn.jsdelivr.net/npm/bootstrap-icons@1.10.0/font/bootstrap-icons.css" rel="stylesheet">
    <link href="../assets/css/style.css" rel="stylesheet">
    <link rel="icon" type="image/svg+xml" type="image/svg+xml" href="../assets/img/favicon.svg?v=3">
<link href="../assets/css/handdrawn.css" rel="stylesheet">
</head>
<body>
    <!-- Sidebar -->
    <%@ include file="sidebar.jsp" %>

    <!-- Main Content -->
    <div class="main-content">
        <div class="d-flex justify-content-between align-items-center mb-4">
            <div>
                <h1 class="h3 mb-0">Import Soal dari CSV</h1>
                <nav aria-label="breadcrumb">
                    <ol class="breadcrumb mb-0">
                        <li class="breadcrumb-item"><a href="../AdminServlet?action=dashboard">Dashboard</a></li>
                        <li class="breadcrumb-item"><a href="../QuizServlet?action=list">Quiz</a></li>
                        <% if (quiz != null) { %>
                        <li class="breadcrumb-item"><a href="../QuestionServlet?action=list&quizId=<%= quiz.getId() %>"><%= ValidationUtil.sanitizeHtml(quiz.getTitle()) %></a></li>
                        <% } %>
                        <li class="breadcrumb-item active">Import CSV</li>
                    </ol>
                </nav>
            </div>
        </div>

        <% if (error != null) { %>
        <div class="alert alert-danger alert-dismissible fade show">
            <i class="bi bi-exclamation-triangle me-2"></i><%= ValidationUtil.sanitizeHtml(error) %>
            <button type="button" class="btn-close" data-bs-dismiss="alert"></button>
        </div>
        <% } %>

        <% if (success != null) { %>
        <div class="alert alert-success alert-dismissible fade show">
            <i class="bi bi-check-circle me-2"></i><%= ValidationUtil.sanitizeHtml(success) %>
            <button type="button" class="btn-close" data-bs-dismiss="alert"></button>
        </div>
        <% } %>

        <% if (warnings != null && !warnings.isEmpty()) { %>
        <div class="alert alert-warning alert-dismissible fade show">
            <h6 class="alert-heading"><i class="bi bi-exclamation-triangle me-2"></i>Peringatan:</h6>
            <ul class="mb-0">
                <% for (String warning : warnings) { %>
                <li><%= ValidationUtil.sanitizeHtml(warning) %></li>
                <% } %>
            </ul>
            <button type="button" class="btn-close" data-bs-dismiss="alert"></button>
        </div>
        <% } %>

        <div class="row">
            <div class="col-lg-8">
                <div class="card">
                    <div class="card-header">
                        <h6 class="mb-0"><i class="bi bi-file-earmark-spreadsheet me-2"></i>Import dari CSV</h6>
                    </div>
                    <div class="card-body">
                        <form action="../QuestionImportExportServlet" method="post" enctype="multipart/form-data">
                        <input type="hidden" name="csrfToken" value="<%= session.getAttribute("csrfToken") %>" />
                            <input type="hidden" name="action" value="import">
                            <% if (quiz != null) { %>
                            <input type="hidden" name="quizId" value="<%= quiz.getId() %>">
                            <% } %>

                            <div class="mb-3">
                                <label for="csvFile" class="form-label">File CSV <span class="text-danger">*</span></label>
                                <input type="file" class="form-control" id="csvFile" name="csvFile"
                                       accept=".csv" required>
                                <div class="form-text">Upload file CSV dengan format yang sesuai. Maks 10MB.</div>
                            </div>

                            <% if (quiz != null) { %>
                            <div class="alert alert-info">
                                <i class="bi bi-info-circle me-2"></i>
                                Soal akan diimport ke quiz: <strong><%= ValidationUtil.sanitizeHtml(quiz.getTitle()) %></strong>
                            </div>
                            <% } %>

                            <div class="d-flex gap-2">
                                <button type="submit" class="btn btn-primary">
                                    <i class="bi bi-upload me-2"></i>Import
                                </button>
                                <a href="../QuestionImportExportServlet?action=template" class="btn btn-outline-secondary">
                                    <i class="bi bi-download me-2"></i>Download Template
                                </a>
                                <% if (quiz != null) { %>
                                <a href="../QuestionServlet?action=list&quizId=<%= quiz.getId() %>" class="btn btn-outline-secondary">
                                    <i class="bi bi-x-lg me-2"></i>Batal
                                </a>
                                <% } else { %>
                                <a href="../QuizServlet?action=list" class="btn btn-outline-secondary">
                                    <i class="bi bi-x-lg me-2"></i>Batal
                                </a>
                                <% } %>
                            </div>
                        </form>
                    </div>
                </div>
            </div>

            <div class="col-lg-4">
                <div class="card">
                    <div class="card-header">
                        <h6 class="mb-0"><i class="bi bi-file-text me-2"></i>Format CSV</h6>
                    </div>
                    <div class="card-body">
                        <p class="small text-muted mb-3">File CSV harus memiliki kolom berikut:</p>
                        <table class="table table-sm small">
                            <thead>
                                <tr>
                                    <th>Kolom</th>
                                    <th>Wajib</th>
                                </tr>
                            </thead>
                            <tbody>
                                <tr>
                                    <td><code>question_text</code></td>
                                    <td><span class="badge bg-danger">Ya</span></td>
                                </tr>
                                <tr>
                                    <td><code>option_a</code></td>
                                    <td><span class="badge bg-danger">Ya</span></td>
                                </tr>
                                <tr>
                                    <td><code>option_b</code></td>
                                    <td><span class="badge bg-danger">Ya</span></td>
                                </tr>
                                <tr>
                                    <td><code>option_c</code></td>
                                    <td><span class="badge bg-danger">Ya</span></td>
                                </tr>
                                <tr>
                                    <td><code>option_d</code></td>
                                    <td><span class="badge bg-danger">Ya</span></td>
                                </tr>
                                <tr>
                                    <td><code>correct_answer</code></td>
                                    <td><span class="badge bg-danger">Ya</span></td>
                                </tr>
                                <tr>
                                    <td><code>category</code></td>
                                    <td><span class="badge bg-secondary">Tidak</span></td>
                                </tr>
                                <tr>
                                    <td><code>explanation</code></td>
                                    <td><span class="badge bg-secondary">Tidak</span></td>
                                </tr>
                            </tbody>
                        </table>
                        <div class="alert alert-warning small mb-0">
                            <i class="bi bi-lightbulb me-1"></i>
                            <strong>Tips:</strong> Gunakan UTF-8 encoding untuk karakter khusus.
                        </div>
                    </div>
                </div>

                <div class="card mt-3">
                    <div class="card-header">
                        <h6 class="mb-0"><i class="bi bi-lightbulb me-2"></i>Contoh Isi CSV</h6>
                    </div>
                    <div class="card-body">
                        <pre class="small bg-light p-2 rounded mb-0" style="white-space: pre-wrap;">question_text,option_a,option_b,option_c,option_d,correct_answer,category,explanation
"Apa ibukota Indonesia?","Jakarta","Bandung","Surabaya","Medan","A","Geografi","Jakarta adalah ibukota negara Indonesia."</pre>
                    </div>
                </div>
            </div>
        </div>
    </div>

    <script src="https://cdn.jsdelivr.net/npm/bootstrap@5.3.0/dist/js/bootstrap.bundle.min.js"></script>
</body>
</html>

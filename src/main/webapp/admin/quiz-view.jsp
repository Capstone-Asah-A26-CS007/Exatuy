<%@ page contentType="text/html;charset=UTF-8" language="java" %>
<%@ taglib prefix="c" uri="http://java.sun.com/jsp/jstl/core" %>
<%@ page import="com.examora.model.User" %>
<%@ page import="com.examora.model.Quiz" %>
<%@ page import="com.examora.model.Question" %>
<%@ page import="com.examora.util.ValidationUtil" %>
<%@ page import="java.util.List" %>
<%
    User currentUser = (User) session.getAttribute("user");
    if (currentUser == null || !currentUser.isAdmin()) {
        response.sendRedirect("../LoginServlet");
        return;
    }

    Quiz quiz = (Quiz) request.getAttribute("quiz");
    if (quiz == null) {
        response.sendRedirect("../QuizServlet?action=list");
        return;
    }

    @SuppressWarnings("unchecked")
    List<Question> questions = (List<Question>) request.getAttribute("questions");
%>
<!DOCTYPE html>
<html lang="id">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Detail Quiz - <%= ValidationUtil.sanitizeHtml(quiz.getTitle()) %></title>
    <link href="https://cdn.jsdelivr.net/npm/bootstrap@5.3.0/dist/css/bootstrap.min.css" rel="stylesheet">
    <link href="https://cdn.jsdelivr.net/npm/bootstrap-icons@1.11.0/font/bootstrap-icons.css" rel="stylesheet">
    <link href="../assets/css/style.css" rel="stylesheet">
    <style>
        :root {
            /* Text Colors - WCAG AA Compliant */
            --text-primary: #2d3748;  /* Soft dark gray (12.6:1 contrast) */
            --text-secondary: #4a5568;  /* Medium gray (7.5:1 contrast) */
            --text-muted: #718096;  /* Comfortable gray (4.7:1 contrast) */
            --text-light: #a0aec0;  /* Subtle gray (2.9:1 contrast) */

            /* Primary Colors */
            --primary: #2563eb;
            --primary-light: #dbeafe;

            /* Other Colors */
            --success: #10b981;
            --warning: #f59e0b;
            --danger: #ef4444;
            --info: #06b6d4;
        }

        body {
            color: var(--text-primary);
        }

        /* Utility Classes for Better Readability */
        .text-muted-custom { color: var(--text-muted) !important; }
        .text-secondary-custom { color: var(--text-secondary) !important; }
        .text-primary-custom { color: var(--text-primary) !important; }

        /* Badge Utility Classes with better contrast */
        .badge-primary-custom { background-color: var(--primary) !important; color: white !important; }
        .badge-success-custom { background-color: var(--success) !important; color: white !important; }
        .badge-warning-custom { background-color: var(--warning) !important; color: white !important; }
        .badge-danger-custom { background-color: var(--danger) !important; color: white !important; }
        .badge-info-custom { background-color: var(--info) !important; color: white !important; }
        .badge-secondary-custom { background-color: var(--text-secondary) !important; color: white !important; }

        /* Override Bootstrap's text-muted with better contrast */
        .text-muted { color: var(--text-muted) !important; }

        /* Icon utility */
        .icon-muted { opacity: 0.4; }

        /* Card improvements */
        .card {
            border: 1px solid #e5e7eb;
            box-shadow: 0 1px 3px rgba(0, 0, 0, 0.1);
        }

        .card-header {
            background-color: #f8fafc;
            border-bottom: 1px solid #e5e7eb;
            font-weight: 600;
        }

        /* Table improvements */
        .table thead th {
            background-color: #f8fafc;
            color: var(--text-primary);
            font-weight: 600;
            border-bottom: 2px solid #e5e7eb;
        }

        .table-hover tbody tr:hover {
            background-color: #f8fafc;
        }

        /* Breadcrumb improvements */
        .breadcrumb-item a {
            color: var(--text-secondary);
            text-decoration: none;
        }

        .breadcrumb-item a:hover {
            color: var(--primary);
        }

        .breadcrumb-item.active {
            color: var(--text-muted);
        }

        /* Empty state */
        .empty-state-icon {
            font-size: 3rem;
            color: var(--text-muted);
            opacity: 0.6;
        }
    </style>
<link href="../assets/css/handdrawn.css" rel="stylesheet">
</head>
<body>
    <%@ include file="sidebar.jsp" %>

    <div class="main-content">
        <div class="container-fluid px-4">
            <div class="d-flex justify-content-between align-items-center mb-4">
                <div>
                    <h2 class="mb-1">Detail Quiz</h2>
                    <nav aria-label="breadcrumb">
                        <ol class="breadcrumb mb-0">
                            <li class="breadcrumb-item"><a href="../AdminServlet?action=dashboard">Dashboard</a></li>
                            <li class="breadcrumb-item"><a href="../QuizServlet?action=list">Quiz</a></li>
                            <li class="breadcrumb-item active">Detail</li>
                        </ol>
                    </nav>
                </div>
                <div class="d-flex gap-2">
                    <a href="../QuizServlet?action=submissions&id=<%= quiz.getId() %>" class="btn btn-info">
                        <i class="bi bi-people me-1"></i>Lihat Submission
                    </a>
                    <a href="../QuestionServlet?action=list&quizId=<%= quiz.getId() %>" class="btn btn-primary">
                        <i class="bi bi-question-lg me-1"></i>Kelola Soal
                    </a>
                    <a href="../QuizServlet?action=edit&id=<%= quiz.getId() %>" class="btn btn-warning">
                        <i class="bi bi-pencil me-1"></i>Edit
                    </a>
                    <a href="../QuizServlet?action=list" class="btn btn-outline-secondary">
                        <i class="bi bi-arrow-left me-1"></i>Kembali
                    </a>
                </div>
            </div>

            <!-- Quiz Details Card -->
            <div class="card mb-4">
                <div class="card-header">
                    <h5 class="mb-0">Informasi Quiz</h5>
                </div>
                <div class="card-body">
                    <div class="row mb-3">
                        <div class="col-md-3 fw-bold">Judul</div>
                        <div class="col-md-9"><%= ValidationUtil.sanitizeHtml(quiz.getTitle()) %></div>
                    </div>
                    <div class="row mb-3">
                        <div class="col-md-3 fw-bold">Deskripsi</div>
                        <div class="col-md-9"><%= ValidationUtil.sanitizeHtml(quiz.getDescription() != null ? quiz.getDescription() : "-") %></div>
                    </div>
                    <div class="row mb-3">
                        <div class="col-md-3 fw-bold">Durasi</div>
                        <div class="col-md-9"><%= quiz.getDuration() %> menit</div>
                    </div>
                    <div class="row mb-3">
                        <div class="col-md-3 fw-bold">Deadline</div>
                        <div class="col-md-9"><%= quiz.getDeadline() != null ? quiz.getDeadline().toString() : "Tidak ada" %></div>
                    </div>
                    <div class="row mb-3">
                        <div class="col-md-3 fw-bold">Target Peserta</div>
                        <div class="col-md-9">
                            <% if (quiz.getTargetTag() != null && !quiz.getTargetTag().isEmpty()) { %>
                                <% String[] tags = quiz.getTargetTag().split(",");
                                   for (String tag : tags) { %>
                                    <span class="badge badge-primary-custom me-1"><%= ValidationUtil.sanitizeHtml(tag.trim()) %></span>
                                <% } %>
                            <% } else { %>
                                <span class="badge badge-secondary-custom">Semua Peserta</span>
                            <% } %>
                        </div>
                    </div>
                    <div class="row mb-3">
                        <div class="col-md-3 fw-bold">Status</div>
                        <div class="col-md-9">
                            <% if (quiz.getIsActive()) { %>
                                <span class="badge badge-success-custom">Aktif</span>
                            <% } else { %>
                                <span class="badge badge-secondary-custom">Draft</span>
                            <% } %>
                        </div>
                    </div>
                    <div class="row">
                        <div class="col-md-3 fw-bold">Jumlah Soal</div>
                        <div class="col-md-9"><%= questions != null ? questions.size() : 0 %> soal</div>
                    </div>
                </div>
            </div>

            <!-- Questions List -->
            <div class="card">
                <div class="card-header d-flex justify-content-between align-items-center">
                    <h5 class="mb-0">Daftar Soal</h5>
                    <a href="../QuestionServlet?action=create&quizId=<%= quiz.getId() %>" class="btn btn-sm btn-primary">
                        <i class="bi bi-plus-lg me-1"></i>Tambah Soal
                    </a>
                </div>
                <div class="card-body p-0">
                    <% if (questions != null && !questions.isEmpty()) { %>
                    <div class="table-responsive">
                        <table class="table table-hover mb-0">
                            <thead>
                                <tr>
                                    <th style="width: 50px;">No</th>
                                    <th>Pertanyaan</th>
                                    <th style="width: 100px;">Tipe</th>
                                    <th style="width: 100px;">Kunci</th>
                                    <th style="width: 100px;">Aksi</th>
                                </tr>
                            </thead>
                            <tbody>
                                <% int no = 1; for (Question q : questions) { %>
                                <tr>
                                    <td><%= no++ %></td>
                                    <td>
                                        <%= ValidationUtil.sanitizeHtml(q.getQuestionText() != null && q.getQuestionText().length() > 100 ?
                                            q.getQuestionText().substring(0, 100) + "..." : q.getQuestionText()) %>
                                        <% if (q.getImagePath() != null && !q.getImagePath().isEmpty()) { %>
                                            <span class="badge badge-info-custom ms-2"><i class="bi bi-image"></i></span>
                                        <% } %>
                                    </td>
                                    <td><span class="badge badge-primary-custom"><%= q.getCorrectAnswer() %></span></td>
                                    <td>
                                        <div class="btn-group btn-group-sm">
                                            <a href="../QuestionServlet?action=edit&id=<%= q.getId() %>&quizId=<%= quiz.getId() %>"
                                               class="btn btn-outline-primary" title="Edit">
                                                <i class="bi bi-pencil"></i>
                                            </a>
                                            <a href="../QuestionServlet?action=delete&id=<%= q.getId() %>&quizId=<%= quiz.getId() %>"
                                               class="btn btn-outline-danger" title="Hapus"
                                               onclick="return confirm('Hapus soal ini?')">
                                                <i class="bi bi-trash"></i>
                                            </a>
                                        </div>
                                    </td>
                                </tr>
                                <% } %>
                            </tbody>
                        </table>
                    </div>
                    <% } else { %>
                    <div class="text-center py-5">
                        <i class="bi bi-inbox empty-state-icon"></i>
                        <p class="text-muted-custom mt-3">Belum ada soal</p>
                        <a href="../QuestionServlet?action=create&quizId=<%= quiz.getId() %>" class="btn btn-primary">
                            <i class="bi bi-plus-lg me-1"></i>Tambah Soal Pertama
                        </a>
                    </div>
                    <% } %>
                </div>
            </div>
        </div>
    </div>

    <script src="https://cdn.jsdelivr.net/npm/bootstrap@5.3.0/dist/js/bootstrap.bundle.min.js"></script>
</body>
</html>

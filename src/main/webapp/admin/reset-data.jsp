<%@ page contentType="text/html;charset=UTF-8" language="java" %>
<%@ taglib prefix="c" uri="http://java.sun.com/jsp/jstl/core" %>
<%@ page import="com.examora.model.User" %>
<%
    User currentUser = (User) session.getAttribute("user");
    if (currentUser == null || !currentUser.isAdmin()) {
        response.sendRedirect("../LoginServlet");
        return;
    }

    String success = (String) request.getAttribute("success");
    String error = (String) request.getAttribute("error");
    Integer submissionCount = (Integer) request.getAttribute("submissionCount");
    Integer answerCount = (Integer) request.getAttribute("answerCount");
    Integer attendanceRecordCount = (Integer) request.getAttribute("attendanceRecordCount");
    Integer attendanceSessionCount = (Integer) request.getAttribute("attendanceSessionCount");

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
    <title>Reset Data - Exatuy Admin</title>
    <link href="https://cdn.jsdelivr.net/npm/bootstrap@5.3.0/dist/css/bootstrap.min.css" rel="stylesheet">
    <link href="https://cdn.jsdelivr.net/npm/bootstrap-icons@1.10.0/font/bootstrap-icons.css" rel="stylesheet">
    <link href="../assets/css/style.css" rel="stylesheet">
    <link rel="icon" type="image/svg+xml" type="image/svg+xml" href="../assets/img/favicon.svg?v=3">
<link href="../assets/css/handdrawn.css" rel="stylesheet">
</head>
<body class="admin-page">
    <div class="wrapper">
        <%@ include file="sidebar.jsp" %>

        <div class="main-content">
            <div class="container-fluid py-4">
                <!-- Header -->
                <div class="d-flex justify-content-between align-items-center mb-4">
                    <div>
                        <h4 class="mb-1"><i class="bi bi-arrow-repeat me-2"></i>Reset Data</h4>
                        <p class="text-muted mb-0">Reset data quiz dan absensi</p>
                    </div>
                    <nav aria-label="breadcrumb">
                        <ol class="breadcrumb mb-0">
                            <li class="breadcrumb-item"><a href="../AdminServlet?action=dashboard">Dashboard</a></li>
                            <li class="breadcrumb-item active">Reset Data</li>
                        </ol>
                    </nav>
                </div>

                <!-- Alert Messages -->
                <% if (success != null) { %>
                <div class="alert alert-success alert-dismissible fade show">
                    <i class="bi bi-check-circle me-2"></i><%= success %>
                    <button type="button" class="btn-close" data-bs-dismiss="alert"></button>
                </div>
                <% } %>

                <% if (error != null) { %>
                <div class="alert alert-danger alert-dismissible fade show">
                    <i class="bi bi-exclamation-triangle me-2"></i><%= error %>
                    <button type="button" class="btn-close" data-bs-dismiss="alert"></button>
                </div>
                <% } %>

                <!-- Warning Banner -->
                <div class="alert alert-warning d-flex align-items-start">
                    <i class="bi bi-exclamation-triangle-fill me-3 fs-4"></i>
                    <div>
                        <h6 class="alert-heading mb-1">Peringatan!</h6>
                        <p class="mb-0">
                            Fitur ini akan menghapus data secara permanen dan tidak dapat dikembalikan.
                            Pastikan Anda sudah membackup data sebelum melakukan reset.
                        </p>
                    </div>
                </div>

                <div class="row g-4">
                    <!-- Quiz Data Card -->
                    <div class="col-md-6">
                        <div class="card h-100 border-0 shadow-sm">
                            <div class="card-header bg-primary text-white">
                                <h5 class="mb-0">
                                    <i class="bi bi-journal-text me-2"></i>Data Quiz
                                </h5>
                            </div>
                            <div class="card-body">
                                <div class="row g-3 mb-4">
                                    <div class="col-6">
                                        <div class="bg-light rounded p-3 text-center">
                                            <h3 class="mb-0 text-primary"><%= submissionCount != null ? submissionCount : 0 %></h3>
                                            <small class="text-muted">Submission</small>
                                        </div>
                                    </div>
                                    <div class="col-6">
                                        <div class="bg-light rounded p-3 text-center">
                                            <h3 class="mb-0 text-primary"><%= answerCount != null ? answerCount : 0 %></h3>
                                            <small class="text-muted">Jawaban</small>
                                        </div>
                                    </div>
                                </div>

                                <p class="text-muted small mb-3">
                                    Menghapus semua data submission dan jawaban quiz. Quiz dan soal tetap tersimpan.
                                </p>

                                <div class="accordion" id="quizAccordion">
                                    <div class="accordion-item border-0">
                                        <h2 class="accordion-header">
                                            <button class="accordion-button collapsed bg-danger text-white" type="button"
                                                    data-bs-toggle="collapse" data-bs-target="#quizCollapse">
                                                <i class="bi bi-trash me-2"></i>Reset Data Quiz
                                            </button>
                                        </h2>
                                        <div id="quizCollapse" class="accordion-collapse collapse" data-bs-parent="#quizAccordion">
                                            <div class="accordion-body bg-light">
                                                <form action="../AdminServlet" method="POST" onsubmit="return confirmResetQuiz()">
                                                    <input type="hidden" name="action" value="resetQuizData">
                                                    <input type="hidden" name="csrfToken" value="<%= csrfToken %>">

                                                    <div class="alert alert-danger mb-3">
                                                        <strong>Akan menghapus:</strong>
                                                        <ul class="mb-0 mt-2">
                                                            <li>Semua submission quiz</li>
                                                            <li>Semua jawaban peserta</li>
                                                            <li>Nilai dan statistik quiz</li>
                                                        </ul>
                                                    </div>

                                                    <div class="mb-3">
                                                        <label class="form-label">
                                                            Ketik <strong>RESET QUIZ DATA</strong> untuk konfirmasi:
                                                        </label>
                                                        <input type="text" class="form-control" name="confirmation"
                                                               placeholder="RESET QUIZ DATA" required
                                                               pattern="RESET QUIZ DATA">
                                                    </div>

                                                    <button type="submit" class="btn btn-danger w-100">
                                                        <i class="bi bi-trash me-2"></i>Reset Data Quiz
                                                    </button>
                                                </form>
                                            </div>
                                        </div>
                                    </div>
                                </div>
                            </div>
                        </div>
                    </div>

                    <!-- Attendance Data Card -->
                    <div class="col-md-6">
                        <div class="card h-100 border-0 shadow-sm">
                            <div class="card-header bg-success text-white">
                                <h5 class="mb-0">
                                    <i class="bi bi-check2-square me-2"></i>Data Absensi
                                </h5>
                            </div>
                            <div class="card-body">
                                <div class="row g-3 mb-4">
                                    <div class="col-6">
                                        <div class="bg-light rounded p-3 text-center">
                                            <h3 class="mb-0 text-success"><%= attendanceSessionCount != null ? attendanceSessionCount : 0 %></h3>
                                            <small class="text-muted">Sesi Absensi</small>
                                        </div>
                                    </div>
                                    <div class="col-6">
                                        <div class="bg-light rounded p-3 text-center">
                                            <h3 class="mb-0 text-success"><%= attendanceRecordCount != null ? attendanceRecordCount : 0 %></h3>
                                            <small class="text-muted">Record Absensi</small>
                                        </div>
                                    </div>
                                </div>

                                <p class="text-muted small mb-3">
                                    Menghapus semua sesi absensi dan record kehadiran. Data user tetap tersimpan.
                                </p>

                                <div class="accordion" id="attendanceAccordion">
                                    <div class="accordion-item border-0">
                                        <h2 class="accordion-header">
                                            <button class="accordion-button collapsed bg-danger text-white" type="button"
                                                    data-bs-toggle="collapse" data-bs-target="#attendanceCollapse">
                                                <i class="bi bi-trash me-2"></i>Reset Data Absensi
                                            </button>
                                        </h2>
                                        <div id="attendanceCollapse" class="accordion-collapse collapse" data-bs-parent="#attendanceAccordion">
                                            <div class="accordion-body bg-light">
                                                <form action="../AdminServlet" method="POST" onsubmit="return confirmResetAttendance()">
                                                    <input type="hidden" name="action" value="resetAttendanceData">
                                                    <input type="hidden" name="csrfToken" value="<%= csrfToken %>">

                                                    <div class="alert alert-danger mb-3">
                                                        <strong>Akan menghapus:</strong>
                                                        <ul class="mb-0 mt-2">
                                                            <li>Semua sesi absensi</li>
                                                            <li>Semua record kehadiran</li>
                                                            <li>Riwayat absensi peserta</li>
                                                        </ul>
                                                    </div>

                                                    <div class="mb-3">
                                                        <label class="form-label">
                                                            Ketik <strong>RESET ABSENSI</strong> untuk konfirmasi:
                                                        </label>
                                                        <input type="text" class="form-control" name="confirmation"
                                                               placeholder="RESET ABSENSI" required
                                                               pattern="RESET ABSENSI">
                                                    </div>

                                                    <button type="submit" class="btn btn-danger w-100">
                                                        <i class="bi bi-trash me-2"></i>Reset Data Absensi
                                                    </button>
                                                </form>
                                            </div>
                                        </div>
                                    </div>
                                </div>
                            </div>
                        </div>
                    </div>
                </div>

                <!-- Info Card -->
                <div class="card border-0 shadow-sm mt-4">
                    <div class="card-body">
                        <h6 class="mb-3"><i class="bi bi-info-circle me-2"></i>Informasi</h6>
                        <div class="row">
                            <div class="col-md-6">
                                <h6 class="text-primary">Data yang TIDAK dihapus:</h6>
                                <ul class="small text-muted">
                                    <li>Data user (admin dan peserta)</li>
                                    <li>Quiz dan soal</li>
                                    <li>Achievement settings</li>
                                    <li>Email templates</li>
                                    <li>Audit log</li>
                                </ul>
                            </div>
                            <div class="col-md-6">
                                <h6 class="text-danger">Data yang DIHAPUS:</h6>
                                <ul class="small text-muted">
                                    <li>Semua submission quiz</li>
                                    <li>Semua jawaban peserta</li>
                                    <li>Semua sesi absensi</li>
                                    <li>Semua record kehadiran</li>
                                </ul>
                            </div>
                        </div>
                    </div>
                </div>
            </div>
        </div>
    </div>

    <script src="https://cdn.jsdelivr.net/npm/bootstrap@5.3.0/dist/js/bootstrap.bundle.min.js"></script>
    <script>
        function confirmResetQuiz() {
            return confirm('PERINGATAN! Anda yakin ingin menghapus SEMUA data quiz?\n\nTindakan ini tidak dapat dibatalkan!');
        }

        function confirmResetAttendance() {
            return confirm('PERINGATAN! Anda yakin ingin menghapus SEMUA data absensi?\n\nTindakan ini tidak dapat dibatalkan!');
        }
    </script>
</body>
</html>

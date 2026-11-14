<%@ page contentType="text/html;charset=UTF-8" language="java" %>
<%@ taglib prefix="c" uri="http://java.sun.com/jsp/jstl/core" %>
<%@ page import="com.examora.model.User" %>
<%@ page import="com.examora.model.Quiz" %>
<%@ page import="com.examora.model.Submission" %>
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
    if (quiz == null) {
        response.sendRedirect("../QuizServlet?action=list");
        return;
    }

    @SuppressWarnings("unchecked")
    List<Submission> submissions = (List<Submission>) request.getAttribute("submissions");
    @SuppressWarnings("unchecked")
    List<Submission> timeoutSubmissions = (List<Submission>) request.getAttribute("timeoutSubmissions");
    @SuppressWarnings("unchecked")
    Map<String, Integer> statusCounts = (Map<String, Integer>) request.getAttribute("statusCounts");

    int completedCount = statusCounts != null && statusCounts.containsKey("completed") ? statusCounts.get("completed") : 0;
    int timeoutCount = statusCounts != null && statusCounts.containsKey("timeout") ? statusCounts.get("timeout") : 0;
    int inProgressCount = statusCounts != null && statusCounts.containsKey("in_progress") ? statusCounts.get("in_progress") : 0;
    int retakeCount = 0;
    if (submissions != null) { for (Submission s : submissions) { if (s.getIsRetake() != null && s.getIsRetake()) retakeCount++; } }
    if (timeoutSubmissions != null) { for (Submission s : timeoutSubmissions) { if (s.getIsRetake() != null && s.getIsRetake()) retakeCount++; } }
%>
<!DOCTYPE html>
<html lang="id">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Submission Quiz - <%= ValidationUtil.sanitizeHtml(quiz.getTitle()) %></title>
    <link href="https://cdn.jsdelivr.net/npm/bootstrap@5.3.0/dist/css/bootstrap.min.css" rel="stylesheet">
    <link href="https://cdn.jsdelivr.net/npm/bootstrap-icons@1.11.0/font/bootstrap-icons.css" rel="stylesheet">
    <link href="../assets/css/style.css" rel="stylesheet">
<link href="../assets/css/handdrawn.css" rel="stylesheet">
</head>
<body>
    <%@ include file="sidebar.jsp" %>

    <div class="main-content">
        <div class="container-fluid px-4">
            <div class="d-flex justify-content-between align-items-center mb-4">
                <div>
                    <h2 class="mb-1">Submission Quiz</h2>
                    <nav aria-label="breadcrumb">
                        <ol class="breadcrumb mb-0">
                            <li class="breadcrumb-item"><a href="../AdminServlet?action=dashboard">Dashboard</a></li>
                            <li class="breadcrumb-item"><a href="../QuizServlet?action=list">Quiz</a></li>
                            <li class="breadcrumb-item active">Submission</li>
                        </ol>
                    </nav>
                </div>
                <div>
                    <a href="../QuizServlet?action=view&id=<%= quiz.getId() %>" class="btn btn-outline-primary">
                        <i class="bi bi-arrow-left me-1"></i>Kembali ke Quiz
                    </a>
                </div>
            </div>

            <!-- Quiz Info -->
            <div class="card mb-4">
                <div class="card-body">
                    <h5 class="card-title"><%= ValidationUtil.sanitizeHtml(quiz.getTitle()) %></h5>
                    <p class="text-muted mb-2"><%= ValidationUtil.sanitizeHtml(quiz.getDescription() != null ? quiz.getDescription() : "") %></p>
                    <div class="row">
                        <div class="col-md-3">
                            <small class="text-muted">Durasi</small>
                            <div><strong><%= quiz.getDuration() %> menit</strong></div>
                        </div>
                        <div class="col-md-3">
                            <small class="text-muted">Deadline</small>
                            <div><strong><%= quiz.getDeadline() != null ? quiz.getDeadline().toString() : "Tidak ada" %></strong></div>
                        </div>
                    </div>
                </div>
            </div>

            <!-- Status Summary -->
            <div class="row mb-4">
                <div class="col">
                    <div class="card bg-primary text-white">
                        <div class="card-body">
                            <h6 class="card-title mb-0">Total Peserta</h6>
                            <h2 class="mb-0"><%= completedCount + timeoutCount + inProgressCount %></h2>
                        </div>
                    </div>
                </div>
                <div class="col">
                    <div class="card bg-success text-white">
                        <div class="card-body">
                            <h6 class="card-title mb-0">Selesai</h6>
                            <h2 class="mb-0"><%= completedCount %></h2>
                        </div>
                    </div>
                </div>
                <div class="col">
                    <div class="card bg-warning text-white">
                        <div class="card-body">
                            <h6 class="card-title mb-0">Timeout</h6>
                            <h2 class="mb-0"><%= timeoutCount %></h2>
                        </div>
                    </div>
                </div>
                <div class="col">
                    <div class="card bg-info text-white">
                        <div class="card-body">
                            <h6 class="card-title mb-0">In Progress</h6>
                            <h2 class="mb-0"><%= inProgressCount %></h2>
                        </div>
                    </div>
                </div>
                <div class="col">
                    <div class="card bg-purple text-white" style="background-color: #6f42c1 !important;">
                        <div class="card-body">
                            <h6 class="card-title mb-0"><i class="bi bi-arrow-repeat me-1"></i>Retake</h6>
                            <h2 class="mb-0"><%= retakeCount %></h2>
                        </div>
                    </div>
                </div>
            </div>

            <!-- Timeout Submissions Section -->
            <% if (timeoutSubmissions != null && !timeoutSubmissions.isEmpty()) { %>
            <div class="card mb-4 border-warning">
                <div class="card-header bg-warning text-white d-flex justify-content-between align-items-center">
                    <h5 class="mb-0"><i class="bi bi-clock-history me-2"></i>Peserta Timeout (<%= timeoutSubmissions.size() %>)</h5>
                    <form method="post" action="../QuizServlet" onsubmit="return confirmResetAll();">
                        <input type="hidden" name="action" value="resetTimeout">
                        <input type="hidden" name="quizId" value="<%= quiz.getId() %>">
                        <button type="submit" class="btn btn-danger btn-sm">
                            <i class="bi bi-arrow-clockwise me-1"></i>Reset Semua Timeout
                        </button>
                    </form>
                </div>
                <div class="card-body p-0">
                    <div class="table-responsive">
                        <table class="table table-hover mb-0">
                            <thead>
                                <tr>
                                    <th>ID</th>
                                    <th>Nama</th>
                                    <th>Email</th>
                                    <th>Waktu Dikerjakan</th>
                                    <th>Waktu Submit</th>
                                    <th>Aksi</th>
                                </tr>
                            </thead>
                            <tbody>
                                <% for (Submission sub : timeoutSubmissions) { %>
                                <tr class="<%= sub.getIsRetake() != null && sub.getIsRetake() ? "table-info" : "" %>">
                                    <td>#<%= sub.getId() %></td>
                                    <td>
                                        <%= ValidationUtil.sanitizeHtml(sub.getUserName() != null ? sub.getUserName() : "-") %>
                                        <% if (sub.getIsRetake() != null && sub.getIsRetake()) { %>
                                        <span class="badge bg-purple ms-1" style="background-color: #6f42c1 !important;"><i class="bi bi-arrow-repeat"></i> Retake</span>
                                        <% } %>
                                    </td>
                                    <td><%= ValidationUtil.sanitizeHtml(sub.getUserEmail() != null ? sub.getUserEmail() : "-") %></td>
                                    <td><%= sub.getStartedAt() != null ? sub.getStartedAt().toString() : "-" %></td>
                                    <td><span class="badge bg-warning">Timeout</span></td>
                                    <td>
                                        <a href="../AdminServlet?action=editScore&submissionId=<%= sub.getId() %>"
                                           class="btn btn-sm btn-outline-primary me-1">
                                            <i class="bi bi-pencil-square"></i> Edit Nilai
                                        </a>
                                        <button class="btn btn-sm btn-outline-warning" onclick="resetSubmission(<%= sub.getId() %>, <%= quiz.getId() %>, '<%= ValidationUtil.sanitizeHtml(ValidationUtil.sanitizeJs(sub.getUserName() != null ? sub.getUserName() : "Peserta")) %>')">
                                            <i class="bi bi-arrow-clockwise me-1"></i>Reset
                                        </button>
                                    </td>
                                </tr>
                                <% } %>
                            </tbody>
                        </table>
                    </div>
                </div>
            </div>
            <% } else { %>
            <div class="alert alert-success mb-4">
                <i class="bi bi-check-circle me-2"></i>Tidak ada peserta yang timeout
            </div>
            <% } %>

            <!-- Completed Submissions -->
            <div class="card">
                <div class="card-header">
                    <h5 class="mb-0"><i class="bi bi-check2-circle me-2"></i>Peserta Selesai (<%= submissions != null ? submissions.size() : 0 %>)</h5>
                </div>
                <div class="card-body p-0">
                    <% if (submissions != null && !submissions.isEmpty()) { %>
                    <div class="table-responsive">
                        <table class="table table-hover mb-0">
                            <thead>
                                <tr>
                                    <th>Rank</th>
                                    <th>Nama</th>
                                    <th>Email</th>
                                    <th>Skor</th>
                                    <th>Benar</th>
                                    <th>Tgl Submit</th>
                                    <th>Waktu</th>
                                    <th>Status</th>
                                    <th>Aksi</th>
                                </tr>
                            </thead>
                            <tbody>
                                <% int rank = 1; for (Submission sub : submissions) { %>
                                <tr class="<%= sub.getIsRetake() != null && sub.getIsRetake() ? "table-info" : "" %>">
                                    <td><%= rank++ %></td>
                                    <td>
                                        <%= ValidationUtil.sanitizeHtml(sub.getUserName() != null ? sub.getUserName() : "-") %>
                                        <% if (sub.getIsRetake() != null && sub.getIsRetake()) { %>
                                        <span class="badge bg-purple ms-1" style="background-color: #6f42c1 !important;"><i class="bi bi-arrow-repeat"></i> Retake</span>
                                        <% } %>
                                    </td>
                                    <td><%= ValidationUtil.sanitizeHtml(sub.getUserEmail() != null ? sub.getUserEmail() : "-") %></td>
                                    <td>
                                        <span class="badge <%= sub.getScore() >= 60 ? "bg-success" : "bg-danger" %>">
                                            <%= sub.getScore() %>
                                        </span>
                                    </td>
                                    <td><%= sub.getCorrectAnswers() %>/<%= sub.getTotalQuestions() %></td>
                                    <td><%= sub.getSubmittedAt() != null ? sub.getSubmittedAt().toString() : "-" %></td>
                                    <td><%= sub.getFormattedTimeSpent() %></td>
                                    <td>
                                        <span class="badge bg-success">Selesai</span>
                                    </td>
                                    <td>
                                        <a href="../AdminServlet?action=editScore&submissionId=<%= sub.getId() %>"
                                           class="btn btn-sm btn-outline-primary me-1">
                                            <i class="bi bi-pencil-square"></i> Edit Nilai
                                        </a>
                                        <button class="btn btn-sm btn-outline-danger" onclick="resetSubmission(<%= sub.getId() %>, <%= quiz.getId() %>, '<%= ValidationUtil.sanitizeHtml(ValidationUtil.sanitizeJs(sub.getUserName() != null ? sub.getUserName() : "Peserta")) %>')">
                                            <i class="bi bi-arrow-clockwise me-1"></i>Reset
                                        </button>
                                    </td>
                                </tr>
                                <% } %>
                            </tbody>
                        </table>
                    </div>
                    <% } else { %>
                    <div class="text-center py-4">
                        <p class="text-muted mb-0">Belum ada peserta yang menyelesaikan quiz</p>
                    </div>
                    <% } %>
                </div>
            </div>

            <!-- Add to Timeout Section -->
            <div class="card mb-4 border-info">
                <div class="card-header bg-info text-white">
                    <h5 class="mb-0"><i class="bi bi-plus-circle me-2"></i>Tambah ke Timeout (Manual Control)</h5>
                </div>
                <div class="card-body">
                    <p class="text-muted mb-3">Tambahkan user ke daftar timeout. User harus di-reset manual sebelum bisa mengerjakan quiz.</p>
                    <form onsubmit="addTimeoutSubmit(event)">
                        <div class="row">
                            <div class="col-md-6">
                                <label class="form-label">User ID</label>
                                <input type="number" class="form-control" id="timeoutUserId" placeholder="Masukkan User ID" required>
                                <small class="text-muted">Cek User ID di halaman Users</small>
                            </div>
                            <div class="col-md-6 d-flex align-items-end">
                                <button type="submit" class="btn btn-info">
                                    <i class="bi bi-plus-circle me-1"></i>Tambah ke Timeout
                                </button>
                            </div>
                        </div>
                    </form>
                </div>
            </div>
        </div>
    </div>

    <script src="https://cdn.jsdelivr.net/npm/bootstrap@5.3.0/dist/js/bootstrap.bundle.min.js"></script>
    <script>
        function confirmResetAll() {
            return confirm('Apakah Anda yakin ingin mereset SEMUA submission timeout? Peserta akan dapat mengerjakan quiz kembali.');
        }

        function addTimeoutSubmit(event) {
            event.preventDefault();
            const userId = document.getElementById('timeoutUserId').value;
            const quizId = <%= quiz.getId() %>;

            if (!userId || !confirm('Tambahkan user ID ' + userId + ' ke daftar timeout?\n\nUser akan memiliki status timeout dan harus di-reset manual sebelum bisa mengerjakan quiz.')) {
                return;
            }

            fetch('../AdminServlet', {
                method: 'POST',
                headers: {
                    'Content-Type': 'application/x-www-form-urlencoded',
                },
                body: 'action=addTimeoutSubmission&userId=' + userId + '&quizId=' + quizId
            })
            .then(response => response.json())
            .then(data => {
                if (data.success) {
                    alert(data.message);
                    location.reload();
                } else {
                    alert('Gagal: ' + data.message);
                }
            })
            .catch(error => {
                alert('Terjadi kesalahan: ' + error.message);
            });
        }

        function resetSubmission(submissionId, quizId, participantName) {
            if (!confirm('Apakah Anda yakin ingin mereset submission untuk peserta "' + participantName + '"?\n\nPeserta akan dapat mengerjakan quiz kembali.')) {
                return;
            }

            fetch('../AdminServlet', {
                method: 'POST',
                headers: {
                    'Content-Type': 'application/x-www-form-urlencoded',
                },
                body: 'action=resetSubmission&submissionId=' + submissionId + '&quizId=' + quizId
            })
            .then(response => response.json())
            .then(data => {
                if (data.success) {
                    alert('Submission berhasil direset!');
                    location.reload();
                } else {
                    alert('Gagal mereset submission: ' + data.message);
                }
            })
            .catch(error => {
                alert('Terjadi kesalahan: ' + error.message);
            });
        }
    </script>
</body>
</html>

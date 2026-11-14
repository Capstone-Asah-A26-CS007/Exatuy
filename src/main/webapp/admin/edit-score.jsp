<%@ page contentType="text/html;charset=UTF-8" language="java" %>
<%@ taglib prefix="c" uri="http://java.sun.com/jsp/jstl/core" %>
<%@ page import="com.examora.model.User" %>
<%@ page import="com.examora.model.Submission" %>
<%@ page import="com.examora.util.ValidationUtil" %>
<%@ page import="java.util.Map" %>
<%@ page import="java.util.List" %>
<%@ page import="java.time.format.DateTimeFormatter" %>
<%@ page import="java.time.ZoneId" %>
<%
    // Auth check - admin only
    User currentUser = (User) session.getAttribute("user");
    if (currentUser == null || !currentUser.isAdmin()) {
        response.sendRedirect("../LoginServlet");
        return;
    }

    String csrfToken = (String) session.getAttribute("csrfToken");
    if (csrfToken == null) csrfToken = "";

    String errorMsg = (String) request.getAttribute("error");
    Map<String, Object> detail = (Map<String, Object>) request.getAttribute("detail");
    Boolean isOverriddenAttr = (Boolean) request.getAttribute("isOverridden");
    boolean isOverridden = isOverriddenAttr != null && isOverriddenAttr;
    Double expectedScoreAttr = (Double) request.getAttribute("expectedScore");
    double expectedScore = expectedScoreAttr != null ? expectedScoreAttr : 0.0;

    Submission submission = null;
    List<Map<String, Object>> questions = null;
    Integer correctCount = 0, wrongCount = 0, unansweredCount = 0;

    if (detail != null) {
        submission = (Submission) detail.get("submission");
        questions = (List<Map<String, Object>>) detail.get("questions");
        correctCount = (Integer) detail.get("correctCount");
        wrongCount = (Integer) detail.get("wrongCount");
        unansweredCount = (Integer) detail.get("unansweredCount");
        if (correctCount == null) correctCount = 0;
        if (wrongCount == null) wrongCount = 0;
        if (unansweredCount == null) unansweredCount = 0;
    }

    ZoneId jakartaZone = ZoneId.of("Asia/Jakarta");
    DateTimeFormatter dtf = DateTimeFormatter.ofPattern("dd MMMM yyyy, HH:mm").withZone(jakartaZone);

    double currentScore = submission != null ? submission.getScore() : 0.0;
    int totalQuestions = submission != null && submission.getTotalQuestions() != null ? submission.getTotalQuestions() : 0;
    int correctAnswers = submission != null && submission.getCorrectAnswers() != null ? submission.getCorrectAnswers() : 0;
    String scoreClass = currentScore >= 60 ? "success" : "danger";
%>
<!DOCTYPE html>
<html lang="id">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Edit Nilai - Exatuy Admin</title>
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
                    <h2 class="mb-1"><i class="bi bi-pencil-square me-2"></i>Edit Nilai</h2>
                    <nav aria-label="breadcrumb">
                        <ol class="breadcrumb mb-0">
                            <li class="breadcrumb-item"><a href="../AdminServlet?action=dashboard">Dashboard</a></li>
                            <li class="breadcrumb-item"><a href="../AdminServlet?action=editScoreList">Edit Nilai</a></li>
                            <li class="breadcrumb-item active">Submission #<%= submission != null ? submission.getId() : "?" %></li>
                        </ol>
                    </nav>
                </div>
                <div>
                    <a href="../AdminServlet?action=editScoreList" class="btn btn-outline-secondary">
                        <i class="bi bi-arrow-left me-1"></i>Kembali ke List
                    </a>
                </div>
            </div>

            <% if (errorMsg != null || submission == null) { %>
            <div class="card">
                <div class="card-body text-center py-5">
                    <div class="mb-3">
                        <i class="bi bi-exclamation-triangle display-1 text-warning"></i>
                    </div>
                    <h4 class="text-muted mb-3">Data Tidak Ditemukan</h4>
                    <p class="text-muted"><%= ValidationUtil.sanitizeHtml(errorMsg != null ? errorMsg : "Data tidak ditemukan") %></p>
                    <p class="small text-muted">Pastikan peserta telah menyelesaikan quiz terlebih dahulu.</p>
                    <a href="../AdminServlet?action=editScoreList" class="btn btn-primary mt-2">
                        <i class="bi bi-arrow-left me-1"></i>Kembali ke List
                    </a>
                </div>
            </div>
            <% } else { %>

            <!-- User Info Header -->
            <div class="card mb-4">
                <div class="card-body">
                    <div class="row">
                        <div class="col-md-8">
                            <div class="d-flex align-items-center mb-3">
                                <div class="bg-primary text-white rounded-circle d-flex align-items-center justify-content-center me-3"
                                     style="width: 56px; height: 56px; font-size: 22px;">
                                    <%= ValidationUtil.sanitizeHtml(submission.getUserName() != null && !submission.getUserName().isEmpty() ?
                                        submission.getUserName().substring(0, 1).toUpperCase() : "U") %>
                                </div>
                                <div>
                                    <h4 class="mb-0"><%= ValidationUtil.sanitizeHtml(submission.getUserName() != null ? submission.getUserName() : "-") %></h4>
                                    <small class="text-muted">
                                        <%= ValidationUtil.sanitizeHtml(submission.getUserEmail() != null ? submission.getUserEmail() : "-") %>
                                        <% if (submission.getUserTag() != null && !submission.getUserTag().isEmpty()) { %>
                                        | <span class="badge bg-secondary"><%= ValidationUtil.sanitizeHtml(submission.getUserTag()) %></span>
                                        <% } %>
                                    </small>
                                </div>
                            </div>
                            <table class="table table-borderless table-sm mb-0">
                                <tr>
                                    <td class="text-muted" width="160">Quiz:</td>
                                    <td><strong><%= ValidationUtil.sanitizeHtml(submission.getQuizTitle() != null ? submission.getQuizTitle() : "-") %></strong></td>
                                </tr>
                                <tr>
                                    <td class="text-muted">Waktu Submit:</td>
                                    <td><%= submission.getSubmittedAt() != null ? submission.getSubmittedAt().atZone(ZoneId.systemDefault()).withZoneSameInstant(jakartaZone).format(dtf) : "-" %></td>
                                </tr>
                                <tr>
                                    <td class="text-muted">Waktu Pengerjaan:</td>
                                    <td><%= submission.getFormattedTimeSpent() %></td>
                                </tr>
                                <tr>
                                    <td class="text-muted">Status:</td>
                                    <td>
                                        <% if ("timeout".equals(submission.getStatus())) { %>
                                        <span class="badge bg-warning">Timeout</span>
                                        <% } else { %>
                                        <span class="badge bg-success">Selesai</span>
                                        <% } %>
                                    </td>
                                </tr>
                            </table>
                        </div>
                        <div class="col-md-4">
                            <div class="card bg-<%= scoreClass %> text-white h-100">
                                <div class="card-body text-center d-flex flex-column justify-content-center">
                                    <p class="mb-1 opacity-75">NILAI</p>
                                    <h1 class="display-4 mb-1" id="scoreDisplay"><%= String.format("%.2f", currentScore) %></h1>
                                    <div class="mb-1">
                                        <span class="badge bg-<%= scoreClass %> border border-white" id="scoreBadge">
                                            <%= currentScore >= 60 ? "LULUS" : "TIDAK LULUS" %>
                                        </span>
                                    </div>
                                    <div>
                                        <span class="badge bg-warning text-dark" id="overrideBadge"
                                              style="<%= isOverridden ? "display:inline-block;" : "display:none;" %>">
                                            <i class="bi bi-exclamation-triangle-fill me-1"></i>SCORE OVERRIDDEN
                                        </span>
                                    </div>
                                    <small class="opacity-75 mt-1">
                                        Expected: <%= String.format("%.2f", expectedScore) %> |
                                        Benar: <span id="correctDisplay"><%= correctAnswers %>/<%= totalQuestions %></span>
                                    </small>
                                </div>
                            </div>
                        </div>
                    </div>
                </div>
            </div>

            <div class="row">
                <!-- Left column: Questions/Answers -->
                <div class="col-lg-8">
                    <div class="card">
                        <div class="card-header d-flex justify-content-between align-items-center">
                            <h5 class="mb-0"><i class="bi bi-list-check me-2"></i>Detail Jawaban</h5>
                            <small class="text-muted">Toggle status jawaban untuk hitung ulang skor otomatis</small>
                        </div>
                        <div class="card-body">
                            <% if (questions != null && !questions.isEmpty()) {
                                int qNo = 1;
                                for (Map<String, Object> q : questions) {
                                    Integer questionId = (Integer) q.get("questionId");
                                    String questionText = (String) q.get("questionText");
                                    String imagePath = (String) q.get("imagePath");
                                    String optionA = (String) q.get("optionA");
                                    String optionB = (String) q.get("optionB");
                                    String optionC = (String) q.get("optionC");
                                    String optionD = (String) q.get("optionD");
                                    String correctAnswer = (String) q.get("correctAnswer");
                                    String selectedAnswer = (String) q.get("selectedAnswer");
                                    Boolean isCorrect = (Boolean) q.get("isCorrect");
                                    Boolean answered = (Boolean) q.get("answered");

                                    boolean currentlyCorrect = answered != null && answered && isCorrect != null && isCorrect;
                                    boolean wasAnswered = answered != null && answered;
                            %>
                            <div class="card mb-3 <%= wasAnswered ? (currentlyCorrect ? "border-success" : "border-danger") : "border-warning" %>">
                                <div class="card-header py-2 d-flex justify-content-between align-items-center bg-light">
                                    <span class="fw-bold">
                                        <%= qNo %>. <%= ValidationUtil.sanitizeHtml(questionText) %>
                                    </span>
                                    <span class="badge <%= wasAnswered ? (currentlyCorrect ? "bg-success" : "bg-danger") : "bg-warning text-dark" %>">
                                        <%= wasAnswered ? (currentlyCorrect ? "Benar" : "Salah") : "Tidak Dijawab" %>
                                    </span>
                                </div>
                                <div class="card-body">
                                    <% if (imagePath != null && !imagePath.isEmpty()) { %>
                                    <div class="mb-3">
                                        <img src="../<%= ValidationUtil.sanitizeHtml(imagePath) %>" alt="Question Image" class="img-fluid rounded" style="max-width: 100%; max-height: 300px;">
                                    </div>
                                    <% } %>

                                    <% for (String opt : new String[]{"A", "B", "C", "D"}) {
                                        String optText = opt.equals("A") ? optionA : opt.equals("B") ? optionB :
                                                        opt.equals("C") ? optionC : optionD;
                                        if (optText == null) continue;

                                        String optClass = "p-2 mb-1 rounded border";
                                        String optIcon = "";
                                        String optBadge = "";
                                        if (opt.equals(correctAnswer)) {
                                            optClass += " border-success bg-success bg-opacity-10";
                                            optIcon = "<i class='bi bi-check-lg text-success ms-2'></i>";
                                        }
                                        if (opt.equals(selectedAnswer)) {
                                            optBadge = "<span class='badge bg-primary ms-2'>Jawaban User</span>";
                                        }
                                    %>
                                    <div class="<%= optClass %>">
                                        <strong><%= opt %>.</strong> <%= ValidationUtil.sanitizeHtml(optText) %>
                                        <%= optIcon %><%= optBadge %>
                                    </div>
                                    <% } %>

                                    <% if (wasAnswered) { %>
                                    <div class="mt-3 p-2 bg-light rounded d-flex justify-content-between align-items-center">
                                        <div>
                                            <strong>Tandai sebagai:</strong>
                                            <span class="text-muted ms-2">(akan hitung ulang skor)</span>
                                        </div>
                                        <div class="form-check form-switch">
                                            <input class="form-check-input" type="checkbox" role="switch"
                                                   id="toggle_<%= questionId %>"
                                                   data-submission-id="<%= submission.getId() %>"
                                                   data-question-id="<%= questionId %>"
                                                   <%= currentlyCorrect ? "checked" : "" %>
                                                   onchange="toggleAnswer(<%= submission.getId() %>, <%= questionId %>, this)">
                                            <label class="form-check-label" for="toggle_<%= questionId %>">Benar</label>
                                        </div>
                                    </div>
                                    <% } else { %>
                                    <div class="mt-3 p-2 bg-light rounded text-muted small">
                                        <i class="bi bi-info-circle me-1"></i>Tidak dijawab — toggle dinonaktifkan (tidak ada jawaban untuk dinilai). Gunakan Override Skor.
                                    </div>
                                    <% } %>
                                </div>
                            </div>
                            <%      qNo++;
                                }
                            } else { %>
                            <div class="text-center py-4 text-muted">
                                <i class="bi bi-inbox display-4 d-block mb-2"></i>
                                Tidak ada data pertanyaan
                            </div>
                            <% } %>
                        </div>
                    </div>
                </div>

                <!-- Right column: Override + Summary -->
                <div class="col-lg-4">
                    <!-- Score Override Card -->
                    <div class="card mb-4 border-warning">
                        <div class="card-header bg-warning text-dark">
                            <h6 class="mb-0"><i class="bi bi-pencil me-2"></i>Override Skor Akhir</h6>
                        </div>
                        <div class="card-body">
                            <p class="text-muted small mb-2">
                                Override skor akan menyimpan nilai baru tanpa mengubah status jawaban.
                                Toggle jawaban apapun akan menghitung ulang skor dari awal dan menimpa override ini.
                            </p>
                            <div class="input-group mb-3">
                                <input type="number" class="form-control" id="scoreOverrideInput"
                                       min="0" max="100" step="0.01" placeholder="0 - 100"
                                       value="<%= String.format("%.2f", currentScore) %>">
                                <span class="input-group-text">/ 100</span>
                            </div>
                            <button type="button" class="btn btn-warning w-100" onclick="overrideScore(<%= submission.getId() %>)">
                                <i class="bi bi-pencil-square me-1"></i>Override Skor
                            </button>
                        </div>
                    </div>

                    <!-- Summary Card -->
                    <div class="card">
                        <div class="card-header">
                            <h6 class="mb-0"><i class="bi bi-bar-chart me-2"></i>Ringkasan Jawaban</h6>
                        </div>
                        <div class="card-body">
                            <div class="row text-center">
                                <div class="col-4">
                                    <div class="p-2 border rounded bg-success bg-opacity-10">
                                        <h4 class="text-success mb-0" id="correctCount"><%= correctCount %></h4>
                                        <small class="text-muted">Benar</small>
                                    </div>
                                </div>
                                <div class="col-4">
                                    <div class="p-2 border rounded bg-danger bg-opacity-10">
                                        <h4 class="text-danger mb-0" id="wrongCount"><%= wrongCount %></h4>
                                        <small class="text-muted">Salah</small>
                                    </div>
                                </div>
                                <div class="col-4">
                                    <div class="p-2 border rounded bg-warning bg-opacity-10">
                                        <h4 class="text-warning mb-0" id="unansweredCount"><%= unansweredCount %></h4>
                                        <small class="text-muted">Tidak Dijawab</small>
                                    </div>
                                </div>
                            </div>
                            <div class="mt-3">
                                <div class="progress" style="height: 18px;">
                                    <div class="progress-bar bg-success" id="progressCorrect"
                                         style="width: <%= totalQuestions > 0 ? (correctCount * 100.0 / totalQuestions) : 0 %>%">
                                    </div>
                                    <div class="progress-bar bg-danger" id="progressWrong"
                                         style="width: <%= totalQuestions > 0 ? (wrongCount * 100.0 / totalQuestions) : 0 %>%">
                                    </div>
                                    <div class="progress-bar bg-warning" id="progressUnanswered"
                                         style="width: <%= totalQuestions > 0 ? (unansweredCount * 100.0 / totalQuestions) : 0 %>%">
                                    </div>
                                </div>
                                <small class="text-muted">Total: <%= totalQuestions %> soal</small>
                            </div>
                        </div>
                    </div>
                </div>
            </div>
            <% } %>
        </div>
    </div>

    <script src="https://cdn.jsdelivr.net/npm/bootstrap@5.3.0/dist/js/bootstrap.bundle.min.js"></script>
    <script>
        const csrfToken = '<%= ValidationUtil.sanitizeJs(csrfToken) %>';
        let isOverridden = <%= isOverridden %>;

        function toggleAnswer(submissionId, questionId, checkbox) {
            const isCorrect = checkbox.checked;
            if (isOverridden && !confirm('Toggle jawaban akan menghitung ulang skor dan menghapus override sebelumnya. Lanjut?')) {
                checkbox.checked = !isCorrect;
                return;
            }
            fetch('../AdminServlet', {
                method: 'POST',
                headers: {
                    'Content-Type': 'application/x-www-form-urlencoded',
                    'X-CSRF-Token': csrfToken
                },
                body: 'action=toggleAnswer&submissionId=' + submissionId +
                      '&questionId=' + questionId +
                      '&isCorrect=' + isCorrect +
                      '&csrfToken=' + encodeURIComponent(csrfToken)
            })
            .then(r => r.json())
            .then(data => {
                if (data.success) {
                    updateScoreDisplay(data.newScore, data.correctAnswers, data.totalQuestions);
                    isOverridden = false;
                    const badge = document.getElementById('overrideBadge');
                    if (badge) badge.style.display = 'none';
                } else {
                    alert('Gagal: ' + data.message);
                    checkbox.checked = !isCorrect;
                }
            })
            .catch(() => {
                alert('Terjadi kesalahan jaringan.');
                checkbox.checked = !isCorrect;
            });
        }

        function overrideScore(submissionId) {
            const val = document.getElementById('scoreOverrideInput').value;
            if (val === '' || isNaN(val) || val < 0 || val > 100) {
                alert('Skor harus berupa angka di antara 0 - 100.');
                return;
            }
            if (!confirm('Override skor ke ' + val + '?')) return;
            fetch('../AdminServlet', {
                method: 'POST',
                headers: {
                    'Content-Type': 'application/x-www-form-urlencoded',
                    'X-CSRF-Token': csrfToken
                },
                body: 'action=overrideScore&submissionId=' + submissionId +
                      '&newScore=' + val +
                      '&csrfToken=' + encodeURIComponent(csrfToken)
            })
            .then(r => r.json())
            .then(data => {
                if (data.success) {
                    updateScoreDisplay(data.newScore, null, null);
                    isOverridden = true;
                    const badge = document.getElementById('overrideBadge');
                    if (badge) badge.style.display = 'inline-block';
                } else {
                    alert('Gagal: ' + data.message);
                }
            })
            .catch(() => {
                alert('Terjadi kesalahan jaringan.');
            });
        }

        function updateScoreDisplay(score, correct, total) {
            const scoreDisplay = document.getElementById('scoreDisplay');
            if (scoreDisplay) scoreDisplay.textContent = (Math.round(score * 100) / 100).toFixed(2);

            const scoreBadge = document.getElementById('scoreBadge');
            if (scoreBadge) {
                scoreBadge.textContent = score >= 60 ? 'LULUS' : 'TIDAK LULUS';
                // Re-color the parent score card too
                const scoreCard = scoreBadge.closest('.card');
                if (scoreCard) {
                    scoreCard.classList.remove('bg-success', 'bg-danger');
                    scoreCard.classList.add(score >= 60 ? 'bg-success' : 'bg-danger');
                    scoreBadge.classList.remove('bg-success', 'bg-danger');
                    scoreBadge.classList.add('bg-' + (score >= 60 ? 'success' : 'danger'));
                }
            }

            if (correct !== null && total !== null) {
                const correctDisplay = document.getElementById('correctDisplay');
                if (correctDisplay) correctDisplay.textContent = correct + '/' + total;
            }
        }
    </script>
</body>
</html>

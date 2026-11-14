<%@ page contentType="text/html;charset=UTF-8" language="java" %>
<%@ taglib prefix="c" uri="http://java.sun.com/jsp/jstl/core" %>
<%@ page import="com.examora.model.User" %>
<%@ page import="com.examora.util.ValidationUtil" %>
<%@ page import="java.util.List" %>
<%
    User currentUser = (User) session.getAttribute("user");
    if (currentUser == null || !currentUser.isAdmin()) {
        response.sendRedirect("../LoginServlet");
        return;
    }
    String error = (String) request.getAttribute("error");
    String success = (String) request.getAttribute("success");
    List<String> warnings = (List<String>) request.getAttribute("warnings");
%>
<!DOCTYPE html>
<html lang="id">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Import Quiz - Exatuy</title>
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
                <h1 class="h3 mb-0">Import Quiz dari CSV</h1>
                <nav aria-label="breadcrumb">
                    <ol class="breadcrumb mb-0">
                        <li class="breadcrumb-item"><a href="../AdminServlet?action=dashboard">Dashboard</a></li>
                        <li class="breadcrumb-item"><a href="../QuizServlet?action=list">Quiz</a></li>
                        <li class="breadcrumb-item active">Import Quiz</li>
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
                        <h6 class="mb-0"><i class="bi bi-file-earmark-spreadsheet me-2"></i>Import Quiz dari CSV</h6>
                    </div>
                    <div class="card-body">
                        <form action="../QuizExportImportServlet" method="post" enctype="multipart/form-data">
                            <input type="hidden" name="csrfToken" value="<%= session.getAttribute("csrfToken") %>" />
                            <input type="hidden" name="action" value="importQuiz">

                            <!-- Mode selector -->
                            <div class="mb-3">
                                <label class="form-label fw-semibold">Format CSV</label>
                                <div class="form-check">
                                    <input class="form-check-input" type="radio" name="importMode" id="modeQuestions" value="questionsOnly" checked>
                                    <label class="form-check-label" for="modeQuestions">
                                        <strong>Soal saja</strong> — CSV berisi soal, metadata quiz diisi manual (direkomendasikan)
                                    </label>
                                </div>
                                <div class="form-check">
                                    <input class="form-check-input" type="radio" name="importMode" id="modeFull" value="fullQuiz">
                                    <label class="form-check-label" for="modeFull">
                                        <strong>Dengan baris #QUIZ#</strong> — CSV berisi metadata quiz + soal (dari export)
                                    </label>
                                </div>
                            </div>

                            <!-- Quiz metadata fields (shown when questionsOnly) -->
                            <div id="quizMetadataFields">
                                <div class="card bg-light mb-3">
                                    <div class="card-body">
                                        <h6 class="mb-3"><i class="bi bi-gear me-1"></i>Metadata Quiz</h6>
                                        <div class="row">
                                            <div class="col-md-8 mb-2">
                                                <label for="quizTitle" class="form-label">Judul Quiz <span class="text-danger">*</span></label>
                                                <input type="text" class="form-control" id="quizTitle" name="quizTitle" placeholder="Masukkan judul quiz" required>
                                            </div>
                                            <div class="col-md-4 mb-2">
                                                <label for="quizDuration" class="form-label">Durasi (menit) <span class="text-danger">*</span></label>
                                                <input type="number" class="form-control" id="quizDuration" name="quizDuration" value="30" min="1">
                                            </div>
                                        </div>
                                        <div class="mb-2">
                                            <label for="quizDescription" class="form-label">Deskripsi</label>
                                            <textarea class="form-control" id="quizDescription" name="quizDescription" rows="2" placeholder="Deskripsi quiz (opsional)"></textarea>
                                        </div>
                                        <div>
                                            <label for="quizTargetTag" class="form-label">Target Tag</label>
                                            <input type="text" class="form-control" id="quizTargetTag" name="quizTargetTag" placeholder="Kosongkan untuk semua user">
                                        </div>
                                    </div>
                                </div>
                            </div>

                            <div class="mb-3">
                                <label for="csvFile" class="form-label">File CSV <span class="text-danger">*</span></label>
                                <input type="file" class="form-control" id="csvFile" name="csvFile"
                                       accept=".csv" required>
                                <div class="form-text">Upload file CSV. Maks 10MB.</div>
                            </div>

                            <div class="d-flex gap-2">
                                <button type="submit" class="btn btn-primary">
                                    <i class="bi bi-upload me-2"></i>Import Quiz
                                </button>
                                <a href="../QuizExportImportServlet?action=template" class="btn btn-outline-secondary">
                                    <i class="bi bi-download me-2"></i>Download Template
                                </a>
                                <a href="../QuizServlet?action=list" class="btn btn-outline-secondary">
                                    <i class="bi bi-x-lg me-2"></i>Batal
                                </a>
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
                        <p class="small fw-semibold mb-1">Mode 1: Dengan #QUIZ#</p>
                        <p class="small text-muted mb-2">Baris pertama = metadata quiz, baris berikutnya = soal:</p>
                        <table class="table table-sm small mb-3">
                            <thead>
                                <tr><th>Kolom</th><th>Keterangan</th></tr>
                            </thead>
                            <tbody>
                                <tr><td><code>#QUIZ#</code></td><td>Penanda awal</td></tr>
                                <tr><td><code>judul</code></td><td>Judul quiz</td></tr>
                                <tr><td><code>deskripsi</code></td><td>Deskripsi quiz</td></tr>
                                <tr><td><code>durasi</code></td><td>Durasi (menit)</td></tr>
                                <tr><td><code>target_tag</code></td><td>Target tag (opsional)</td></tr>
                                <tr><td><code>shuffle</code></td><td>Acak soal (true/false)</td></tr>
                                <tr><td><code>review</code></td><td>Tampilkan review (true/false)</td></tr>
                            </tbody>
                        </table>

                        <p class="small fw-semibold mb-1">Mode 2: Tanpa #QUIZ#</p>
                        <p class="small text-muted mb-2">Langsung header soal, metadata quiz diisi di form:</p>

                        <hr>
                        <p class="small text-muted mb-1">Kolom soal (kedua mode sama):</p>
                        <table class="table table-sm small">
                            <thead>
                                <tr><th>Kolom</th><th>Wajib</th></tr>
                            </thead>
                            <tbody>
                                <tr><td><code>question_text</code></td><td><span class="badge bg-danger">Ya</span></td></tr>
                                <tr><td><code>option_a</code> s/d <code>option_d</code></td><td><span class="badge bg-danger">Ya</span></td></tr>
                                <tr><td><code>correct_answer</code></td><td><span class="badge bg-danger">Ya</span></td></tr>
                                <tr><td><code>category</code></td><td><span class="badge bg-secondary">Tidak</span></td></tr>
                                <tr><td><code>explanation</code></td><td><span class="badge bg-secondary">Tidak</span></td></tr>
                            </tbody>
                        </table>
                    </div>
                </div>

                <div class="card mt-3">
                    <div class="card-header">
                        <h6 class="mb-0"><i class="bi bi-lightbulb me-2"></i>Contoh Isi CSV</h6>
                    </div>
                    <div class="card-body">
                        <p class="small fw-semibold mb-1">Dengan #QUIZ#:</p>
                        <pre class="small bg-light p-2 rounded mb-2" style="white-space: pre-wrap; font-size: 0.7rem;">#QUIZ,"Quiz Jaringan","Deskripsi",30,,true,true
question_text,option_a,option_b,option_c,option_d,correct_answer,category,explanation
"Apa itu IP?","Fisik","Logis","Protokol","Port","B","Network","IP adalah alamat logis"</pre>

                        <p class="small fw-semibold mb-1">Tanpa #QUIZ#:</p>
                        <pre class="small bg-light p-2 rounded mb-0" style="white-space: pre-wrap; font-size: 0.7rem;">question_text,option_a,option_b,option_c,option_d,correct_answer,category,explanation
"Apa itu IP?","Fisik","Logis","Protokol","Port","B","Network","IP adalah alamat logis"
"HTTP port?","21","22","80","443","C","Network","HTTP default port 80"</pre>
                    </div>
                </div>
            </div>
        </div>
    </div>

    <script src="https://cdn.jsdelivr.net/npm/bootstrap@5.3.0/dist/js/bootstrap.bundle.min.js"></script>
    <script>
        // Toggle quiz metadata fields based on mode
        document.querySelectorAll('input[name="importMode"]').forEach(function(radio) {
            radio.addEventListener('change', function() {
                var metaFields = document.getElementById('quizMetadataFields');
                var titleInput = document.getElementById('quizTitle');
                if (this.value === 'questionsOnly') {
                    metaFields.style.display = 'block';
                    titleInput.setAttribute('required', 'required');
                } else {
                    metaFields.style.display = 'none';
                    titleInput.removeAttribute('required');
                }
            });
        });

        // Validate form before submit
        document.querySelector('form').addEventListener('submit', function(e) {
            var mode = document.querySelector('input[name="importMode"]:checked').value;
            if (mode === 'questionsOnly') {
                var title = document.getElementById('quizTitle').value.trim();
                if (!title) {
                    e.preventDefault();
                    alert('Judul quiz harus diisi untuk mode tanpa #QUIZ#');
                }
            }
        });
    </script>
</body>
</html>

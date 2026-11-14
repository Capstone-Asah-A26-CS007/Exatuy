<%@ page contentType="text/html;charset=UTF-8" language="java" %>
<%@ taglib prefix="c" uri="http://java.sun.com/jsp/jstl/core" %>
<%@ page import="com.examora.model.User" %>
<%@ page import="java.util.List" %>
<%@ page import="java.util.Map" %>
<%
    User currentUser = (User) session.getAttribute("user");
    if (currentUser == null || !currentUser.isAdmin()) {
        response.sendRedirect("../LoginServlet");
        return;
    }

    Integer submissionCount = (Integer) request.getAttribute("submissionCount");
    Integer answerCount = (Integer) request.getAttribute("answerCount");
    Integer attendanceRecordCount = (Integer) request.getAttribute("attendanceRecordCount");
    Integer attendanceSessionCount = (Integer) request.getAttribute("attendanceSessionCount");

    @SuppressWarnings("unchecked")
    Map<String, String> settingsMap = (Map<String, String>) request.getAttribute("settings");
    if (settingsMap == null) settingsMap = java.util.Collections.emptyMap();
    String leaderboardDefaultTag = settingsMap.get("leaderboard_default_tag");
    if (leaderboardDefaultTag == null) leaderboardDefaultTag = "";
    String leaderboardPublishedRaw = settingsMap.get("leaderboard_published");
    boolean leaderboardPublished = leaderboardPublishedRaw == null || "true".equalsIgnoreCase(leaderboardPublishedRaw);

    @SuppressWarnings("unchecked")
    List<String> allTags = (List<String>) request.getAttribute("allTags");
    if (allTags == null) allTags = java.util.Collections.emptyList();

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
    <title>Pengaturan - Exatuy Admin</title>
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
                <div class="d-flex justify-content-between align-items-center mb-4">
                    <div>
                        <h1 class="h3 mb-0"><i class="bi bi-gear me-2"></i>Pengaturan</h1>
                        <p class="text-muted mb-0">Kelola pengaturan aplikasi</p>
                    </div>
                </div>

                <!-- Alert Messages -->
                <c:if test="${not empty success}">
                    <div class="alert alert-success alert-dismissible fade show" role="alert">
                        <i class="bi bi-check-circle me-2"></i>${success}
                        <button type="button" class="btn-close" data-bs-dismiss="alert"></button>
                    </div>
                </c:if>
                <c:if test="${not empty error}">
                    <div class="alert alert-danger alert-dismissible fade show" role="alert">
                        <i class="bi bi-exclamation-triangle me-2"></i>${error}
                        <button type="button" class="btn-close" data-bs-dismiss="alert"></button>
                    </div>
                </c:if>

                <!-- Registration Settings -->
                <div class="card shadow-sm mb-4">
                    <div class="card-header bg-white">
                        <h5 class="mb-0">
                            <i class="bi bi-person-plus me-2"></i>Pengaturan Registrasi
                        </h5>
                    </div>
                    <div class="card-body">
                        <form action="../AdminServlet" method="post">
                            <input type="hidden" name="action" value="updateSettings">
                            <input type="hidden" name="csrfToken" value="<%= csrfToken %>">

                            <div class="form-check form-switch mb-3">
                                <input class="form-check-input" type="checkbox" id="registrationEnabled"
                                       name="registrationEnabled" value="true"
                                       ${settings['registration_enabled'] eq 'true' ? 'checked' : ''}>
                                <label class="form-check-label" for="registrationEnabled">
                                    <strong>Izinkan Registrasi Pengguna Baru</strong>
                                </label>
                                <div class="form-text">
                                    Jika dinonaktifkan, tombol dan link registrasi akan disembunyikan dari halaman landing.
                                    Pengguna baru hanya bisa ditambahkan oleh admin.
                                </div>
                            </div>

                            <hr>

                            <div class="d-flex justify-content-end">
                                <button type="submit" class="btn btn-primary">
                                    <i class="bi bi-save me-1"></i>Simpan Pengaturan
                                </button>
                            </div>
                        </form>
                    </div>
                </div>

                <!-- Chat Settings -->
                <div class="card shadow-sm mb-4">
                    <div class="card-header bg-white">
                        <h5 class="mb-0">
                            <i class="bi bi-chat-dots me-2"></i>Pengaturan Chat
                        </h5>
                    </div>
                    <div class="card-body">
                        <form action="../AdminServlet" method="post">
                            <input type="hidden" name="action" value="updateSettings">
                            <input type="hidden" name="csrfToken" value="<%= csrfToken %>">

                            <div class="form-check form-switch mb-3">
                                <input class="form-check-input" type="checkbox" id="chatEnabled"
                                       name="chatEnabled" value="true"
                                       ${settings['chat_enabled'] eq 'true' or empty settings['chat_enabled'] ? 'checked' : ''}>
                                <label class="form-check-label" for="chatEnabled">
                                    <strong>Aktifkan Fitur Chat</strong>
                                </label>
                                <div class="form-text">
                                    Jika dinonaktifkan, pengguna tidak dapat mengakses fitur chat untuk menghubungi admin.
                                    Admin tetap dapat melihat pesan yang sudah ada.
                                </div>
                            </div>

                            <hr>

                            <div class="d-flex justify-content-end">
                                <button type="submit" class="btn btn-primary">
                                    <i class="bi bi-save me-1"></i>Simpan Pengaturan
                                </button>
                            </div>
                        </form>
                    </div>
                </div>

                <!-- File Management Settings -->
                <div class="card shadow-sm mb-4">
                    <div class="card-header bg-white">
                        <h5 class="mb-0">
                            <i class="bi bi-folder me-2"></i>Pengaturan File Management
                        </h5>
                    </div>
                    <div class="card-body">
                        <form action="../AdminServlet" method="post">
                            <input type="hidden" name="action" value="updateSettings">
                            <input type="hidden" name="csrfToken" value="<%= csrfToken %>">

                            <div class="form-check form-switch mb-3">
                                <input class="form-check-input" type="checkbox" id="fileManagementEnabled"
                                       name="fileManagementEnabled" value="true"
                                       ${settings['file_management_enabled'] eq 'true' or empty settings['file_management_enabled'] ? 'checked' : ''}>
                                <label class="form-check-label" for="fileManagementEnabled">
                                    <strong>Aktifkan Fitur File Management</strong>
                                </label>
                                <div class="form-text">
                                    Jika dinonaktifkan, pengguna tidak dapat mengakses fitur upload dan download file.
                                    File yang sudah diupload tetap tersimpan dan dapat diakses setelah fitur diaktifkan kembali.
                                </div>
                            </div>

                            <hr>

                            <div class="d-flex justify-content-end">
                                <button type="submit" class="btn btn-primary">
                                    <i class="bi bi-save me-1"></i>Simpan Pengaturan
                                </button>
                            </div>
                        </form>
                    </div>
                </div>

                <!-- Transcript Branding Settings -->
                <div class="card shadow-sm mb-4">
                    <div class="card-header bg-white">
                        <h5 class="mb-0">
                            <i class="bi bi-award me-2"></i>Pengaturan Transkrip Nilai
                        </h5>
                    </div>
                    <div class="card-body">
                        <form action="../AdminServlet" method="post" enctype="multipart/form-data">
                            <input type="hidden" name="action" value="updateTranscriptSettings">
                            <input type="hidden" name="csrfToken" value="<%= csrfToken %>">

                            <div class="alert alert-info small py-2">
                                <i class="bi bi-info-circle me-1"></i>
                                Pengaturan ini tampil pada blok tanda tangan di halaman transkrip peserta.
                            </div>

                            <div class="row g-3">
                                <div class="col-md-6">
                                    <label for="transcriptOrgName" class="form-label">Nama Organisasi</label>
                                    <input type="text" class="form-control" id="transcriptOrgName" name="transcriptOrgName"
                                           value="${not empty settings['transcript_org_name'] ? settings['transcript_org_name'] : 'IDS Cyber Security'}"
                                           placeholder="IDS Cyber Security">
                                    <div class="form-text">Nama penerbit yang ditampilkan di blok tanda tangan.</div>
                                </div>
                                <div class="col-md-6">
                                    <label for="transcriptOrgUrl" class="form-label">URL Organisasi</label>
                                    <input type="text" class="form-control" id="transcriptOrgUrl" name="transcriptOrgUrl"
                                           value="${not empty settings['transcript_org_url'] ? settings['transcript_org_url'] : 'ids-cybersecurity.com'}"
                                           placeholder="ids-cybersecurity.com">
                                    <div class="form-text">URL/website organisasi (ditampilkan sebagai tautan).</div>
                                </div>
                                <div class="col-md-6">
                                    <label for="transcriptSignerName" class="form-label">Nama Penandatangan</label>
                                    <input type="text" class="form-control" id="transcriptSignerName" name="transcriptSignerName"
                                           value="${settings['transcript_signer_name']}"
                                           placeholder="Contoh: Agus Budi Dharmawan, S.Kom., M.T.">
                                    <div class="form-text">Nama yang muncul di bawah tanda tangan.</div>
                                </div>
                                <div class="col-md-6">
                                    <label for="transcriptSignerTitle" class="form-label">Jabatan Penandatangan</label>
                                    <input type="text" class="form-control" id="transcriptSignerTitle" name="transcriptSignerTitle"
                                           value="${settings['transcript_signer_title']}"
                                           placeholder="Contoh: Supervisor / Administrator">
                                    <div class="form-text">Opsional. Jabatan atau peran penandatangan.</div>
                                </div>
                            </div>

                            <hr>

                            <div class="mb-3">
                                <label for="transcriptSignature" class="form-label">Tanda Tangan (gambar)</label>
                                <input type="file" class="form-control" id="transcriptSignature" name="transcriptSignature"
                                       accept="image/png,image/jpeg,image/jpg,image/gif,image/webp">
                                <div class="form-text">Format: JPG, PNG, GIF, atau WebP. Maksimal 2MB. Transparan (PNG) disarankan.</div>
                            </div>

                            <c:if test="${not empty settings['transcript_signature_path']}">
                                <div class="d-flex align-items-center gap-3 mb-3 p-2 bg-light rounded">
                                    <img src="../${settings['transcript_signature_path']}" alt="Tanda tangan saat ini" style="max-height:60px;max-width:180px;object-fit:contain;">
                                    <div>
                                        <div class="fw-semibold small">Tanda tangan saat ini</div>
                                        <div class="form-check mt-1">
                                            <input class="form-check-input" type="checkbox" id="removeSignature" name="removeSignature" value="true">
                                            <label class="form-check-label small" for="removeSignature">Hapus tanda tangan ini</label>
                                        </div>
                                    </div>
                                </div>
                            </c:if>

                            <hr>

                            <div class="d-flex justify-content-end">
                                <button type="submit" class="btn btn-primary">
                                    <i class="bi bi-save me-1"></i>Simpan Pengaturan Transkrip
                                </button>
                            </div>
                        </form>
                    </div>
                </div>

                <!-- Leaderboard Settings -->
                <div class="card shadow-sm mb-4">
                    <div class="card-header bg-white d-flex justify-content-between align-items-center">
                        <h5 class="mb-0">
                            <i class="bi bi-trophy me-2"></i>Pengaturan Leaderboard
                        </h5>
                        <% if (leaderboardPublished) { %>
                        <span class="badge bg-success"><i class="bi bi-check-circle me-1"></i>Published</span>
                        <% } else { %>
                        <span class="badge bg-secondary"><i class="bi bi-eye-slash me-1"></i>Unpublished</span>
                        <% } %>
                    </div>
                    <div class="card-body">

                        <!-- Publish / Unpublish toggle (separate quick-action form) -->
                        <div class="<%= leaderboardPublished ? "alert alert-success" : "alert alert-warning" %> d-flex align-items-center justify-content-between flex-wrap gap-2 mb-3">
                            <div>
                                <strong><%= leaderboardPublished ? "Leaderboard sedang dipublikasi." : "Leaderboard saat ini disembunyikan." %></strong>
                                <div class="small">
                                    <%= leaderboardPublished
                                        ? "Peserta dapat melihat dan mengakses halaman leaderboard."
                                        : "Peserta tidak dapat mengakses leaderboard (melihat halaman \u201cbelum dipublikasi\u201d)." %>
                                </div>
                            </div>
                            <form action="../AdminServlet" method="post" class="m-0">
                                <input type="hidden" name="action" value="updateLeaderboardSettings">
                                <input type="hidden" name="csrfToken" value="<%= csrfToken %>">
                                <!-- Re-submit current CSV URL + tag so they aren't wiped -->
                                <input type="hidden" name="leaderboardCsvUrl" value="${not empty settings['leaderboard_csv_url'] ? settings['leaderboard_csv_url'] : 'https://docs.google.com/spreadsheets/d/1hnEJS2rQFudsxc0QWAdcPtzDE7I2ZI3mz0OYHSxmoLQ/export?format=csv&gid=278631504'}">
                                <input type="hidden" name="leaderboardDefaultTag" value="<%= leaderboardDefaultTag %>">
                                <% if (leaderboardPublished) { %>
                                <input type="hidden" name="leaderboardPublished" value="false">
                                <button type="submit" class="btn btn-outline-danger">
                                    <i class="bi bi-eye-slash me-1"></i>Unpublish
                                </button>
                                <% } else { %>
                                <input type="hidden" name="leaderboardPublished" value="true">
                                <button type="submit" class="btn btn-success">
                                    <i class="bi bi-eye me-1"></i>Publish
                                </button>
                                <% } %>
                            </form>
                        </div>

                        <form action="../AdminServlet" method="post">
                            <input type="hidden" name="action" value="updateLeaderboardSettings">
                            <input type="hidden" name="csrfToken" value="<%= csrfToken %>">
                            <!-- Preserve current publish state when editing other settings -->
                            <input type="hidden" name="leaderboardPublished" value="<%= leaderboardPublished ? "true" : "false" %>">

                            <div class="alert alert-info small py-2">
                                <i class="bi bi-info-circle me-1"></i>
                                URL CSV dari Google Sheets yang akan ditampilkan di halaman Leaderboard.
                                Pastikan sheet bersifat publik (Anyone with link can view).
                            </div>

                            <div class="mb-3">
                                <label for="leaderboardCsvUrl" class="form-label">URL Export CSV Google Sheets</label>
                                <input type="url" class="form-control" id="leaderboardCsvUrl" name="leaderboardCsvUrl"
                                       value="${not empty settings['leaderboard_csv_url'] ? settings['leaderboard_csv_url'] : 'https://docs.google.com/spreadsheets/d/1hnEJS2rQFudsxc0QWAdcPtzDE7I2ZI3mz0OYHSxmoLQ/export?format=csv&gid=278631504'}"
                                       placeholder="https://docs.google.com/spreadsheets/d/XXXXX/export?format=csv&gid=XXXXX">
                                <div class="form-text">
                                    Format: <code>https://docs.google.com/spreadsheets/d/<i>DOC_ID</i>/export?format=csv&gid=<i>TAB_ID</i></code>
                                </div>
                            </div>

                            <hr>

                            <div class="mb-3">
                                <label for="leaderboardDefaultTag" class="form-label">Filter Tag Default (Tampil Per Tag)</label>
                                <select class="form-select" id="leaderboardDefaultTag" name="leaderboardDefaultTag">
                                    <option value="all" <%= leaderboardDefaultTag.isEmpty() || "all".equalsIgnoreCase(leaderboardDefaultTag) ? "selected" : "" %>>
                                        Tampilkan Semua Tag (default)
                                    </option>
                                    <% for (String tg : allTags) { %>
                                    <option value="<%= tg %>" <%= tg.equals(leaderboardDefaultTag) ? "selected" : "" %>><%= tg %></option>
                                    <% } %>
                                </select>
                                <div class="form-text">
                                    Pilih tag jika leaderboard hanya boleh menampilkan peserta dari tag tersebut secara default.
                                    Peserta tetap bisa berpindah tag lewat tombol filter di halaman leaderboard.
                                </div>
                            </div>

                            <div class="d-flex justify-content-end">
                                <button type="submit" class="btn btn-primary">
                                    <i class="bi bi-save me-1"></i>Simpan Pengaturan Leaderboard
                                </button>
                            </div>
                        </form>
                    </div>
                </div>

                <!-- Reset Data Section -->
                <div class="card shadow-sm mb-4 border-warning">
                    <div class="card-header bg-warning text-dark">
                        <h5 class="mb-0">
                            <i class="bi bi-arrow-repeat me-2"></i>Reset Data
                        </h5>
                    </div>
                    <div class="card-body">
                        <!-- Warning Banner -->
                        <div class="alert alert-warning d-flex align-items-start mb-4">
                            <i class="bi bi-exclamation-triangle-fill me-3 fs-4"></i>
                            <div>
                                <h6 class="alert-heading mb-1">Peringatan!</h6>
                                <p class="mb-0 small">
                                    Fitur ini akan menghapus data secara permanen dan tidak dapat dikembalikan.
                                    Pastikan Anda sudah membackup data sebelum melakukan reset.
                                </p>
                            </div>
                        </div>

                        <div class="row g-4">
                            <!-- Quiz Data Card -->
                            <div class="col-md-6">
                                <div class="card h-100 border">
                                    <div class="card-header bg-primary text-white py-2">
                                        <h6 class="mb-0">
                                            <i class="bi bi-journal-text me-2"></i>Data Quiz
                                        </h6>
                                    </div>
                                    <div class="card-body">
                                        <div class="row g-2 mb-3">
                                            <div class="col-6">
                                                <div class="bg-light rounded p-2 text-center">
                                                    <h4 class="mb-0 text-primary"><%= submissionCount != null ? submissionCount : 0 %></h4>
                                                    <small class="text-muted">Submission</small>
                                                </div>
                                            </div>
                                            <div class="col-6">
                                                <div class="bg-light rounded p-2 text-center">
                                                    <h4 class="mb-0 text-primary"><%= answerCount != null ? answerCount : 0 %></h4>
                                                    <small class="text-muted">Jawaban</small>
                                                </div>
                                            </div>
                                        </div>

                                        <p class="text-muted small mb-3">
                                            Menghapus semua data submission dan jawaban quiz. Quiz dan soal tetap tersimpan.
                                        </p>

                                        <button class="btn btn-outline-danger btn-sm w-100" type="button"
                                                data-bs-toggle="collapse" data-bs-target="#quizCollapse">
                                            <i class="bi bi-trash me-1"></i>Reset Data Quiz
                                        </button>

                                        <div class="collapse mt-2" id="quizCollapse">
                                            <div class="card card-body bg-light">
                                                <form action="../AdminServlet" method="POST" onsubmit="return confirmResetQuiz()">
                                                    <input type="hidden" name="action" value="resetQuizData">
                                                    <input type="hidden" name="csrfToken" value="<%= csrfToken %>">

                                                    <div class="alert alert-danger mb-2 py-2 small">
                                                        <strong>Akan menghapus:</strong>
                                                        <ul class="mb-0 mt-1">
                                                            <li>Semua submission quiz</li>
                                                            <li>Semua jawaban peserta</li>
                                                        </ul>
                                                    </div>

                                                    <div class="mb-2">
                                                        <label class="form-label small">
                                                            Ketik <strong>RESET QUIZ DATA</strong>:
                                                        </label>
                                                        <input type="text" class="form-control form-control-sm" name="confirmation"
                                                               placeholder="RESET QUIZ DATA" required
                                                               pattern="RESET QUIZ DATA">
                                                    </div>

                                                    <button type="submit" class="btn btn-danger btn-sm w-100">
                                                        <i class="bi bi-trash me-1"></i>Reset
                                                    </button>
                                                </form>
                                            </div>
                                        </div>
                                    </div>
                                </div>
                            </div>

                            <!-- Attendance Data Card -->
                            <div class="col-md-6">
                                <div class="card h-100 border">
                                    <div class="card-header bg-success text-white py-2">
                                        <h6 class="mb-0">
                                            <i class="bi bi-check2-square me-2"></i>Data Absensi
                                        </h6>
                                    </div>
                                    <div class="card-body">
                                        <div class="row g-2 mb-3">
                                            <div class="col-6">
                                                <div class="bg-light rounded p-2 text-center">
                                                    <h4 class="mb-0 text-success"><%= attendanceSessionCount != null ? attendanceSessionCount : 0 %></h4>
                                                    <small class="text-muted">Sesi</small>
                                                </div>
                                            </div>
                                            <div class="col-6">
                                                <div class="bg-light rounded p-2 text-center">
                                                    <h4 class="mb-0 text-success"><%= attendanceRecordCount != null ? attendanceRecordCount : 0 %></h4>
                                                    <small class="text-muted">Record</small>
                                                </div>
                                            </div>
                                        </div>

                                        <p class="text-muted small mb-3">
                                            Menghapus semua sesi absensi dan record kehadiran. Data user tetap tersimpan.
                                        </p>

                                        <button class="btn btn-outline-danger btn-sm w-100" type="button"
                                                data-bs-toggle="collapse" data-bs-target="#attendanceCollapse">
                                            <i class="bi bi-trash me-1"></i>Reset Data Absensi
                                        </button>

                                        <div class="collapse mt-2" id="attendanceCollapse">
                                            <div class="card card-body bg-light">
                                                <form action="../AdminServlet" method="POST" onsubmit="return confirmResetAttendance()">
                                                    <input type="hidden" name="action" value="resetAttendanceData">
                                                    <input type="hidden" name="csrfToken" value="<%= csrfToken %>">

                                                    <div class="alert alert-danger mb-2 py-2 small">
                                                        <strong>Akan menghapus:</strong>
                                                        <ul class="mb-0 mt-1">
                                                            <li>Semua sesi absensi</li>
                                                            <li>Semua record kehadiran</li>
                                                        </ul>
                                                    </div>

                                                    <div class="mb-2">
                                                        <label class="form-label small">
                                                            Ketik <strong>RESET ABSENSI</strong>:
                                                        </label>
                                                        <input type="text" class="form-control form-control-sm" name="confirmation"
                                                               placeholder="RESET ABSENSI" required
                                                               pattern="RESET ABSENSI">
                                                    </div>

                                                    <button type="submit" class="btn btn-danger btn-sm w-100">
                                                        <i class="bi bi-trash me-1"></i>Reset
                                                    </button>
                                                </form>
                                            </div>
                                        </div>
                                    </div>
                                </div>
                            </div>
                        </div>

                        <!-- Info -->
                        <div class="mt-3 p-2 bg-light rounded small">
                            <div class="row">
                                <div class="col-6">
                                    <span class="text-success"><i class="bi bi-check-circle me-1"></i>Tetap tersimpan:</span>
                                    <span class="text-muted">User, Quiz, Soal, Audit Log</span>
                                </div>
                                <div class="col-6">
                                    <span class="text-danger"><i class="bi bi-x-circle me-1"></i>Dihapus:</span>
                                    <span class="text-muted">Submission, Jawaban, Sesi Absensi</span>
                                </div>
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

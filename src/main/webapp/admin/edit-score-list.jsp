<%@ page contentType="text/html;charset=UTF-8" language="java" %>
<%@ taglib prefix="c" uri="http://java.sun.com/jsp/jstl/core" %>
<%@ page import="com.examora.model.User" %>
<%@ page import="com.examora.util.ValidationUtil" %>
<%@ page import="java.util.List" %>
<%
    // Auth check - admin only
    User currentUser = (User) session.getAttribute("user");
    if (currentUser == null || !currentUser.isAdmin()) {
        response.sendRedirect("../LoginServlet");
        return;
    }

    @SuppressWarnings("unchecked")
    List<User> pesertaUsers = (List<User>) request.getAttribute("pesertaUsers");
    @SuppressWarnings("unchecked")
    List<String> allTags = (List<String>) request.getAttribute("allTags");
    if (allTags == null) allTags = new java.util.ArrayList<>();
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
                            <li class="breadcrumb-item active">Edit Nilai</li>
                        </ol>
                    </nav>
                </div>
            </div>

            <!-- Flash messages -->
            <% if (request.getAttribute("success") != null) { %>
            <div class="alert alert-success alert-dismissible fade show" role="alert">
                <i class="bi bi-check-circle me-2"></i><%= ValidationUtil.sanitizeHtml((String) request.getAttribute("success")) %>
                <button type="button" class="btn-close" data-bs-dismiss="alert"></button>
            </div>
            <% } %>
            <% if (request.getAttribute("error") != null) { %>
            <div class="alert alert-danger alert-dismissible fade show" role="alert">
                <i class="bi bi-exclamation-triangle me-2"></i><%= ValidationUtil.sanitizeHtml((String) request.getAttribute("error")) %>
                <button type="button" class="btn-close" data-bs-dismiss="alert"></button>
            </div>
            <% } %>

            <!-- Peserta table -->
            <div class="card">
                <div class="card-header d-flex justify-content-between align-items-center">
                    <h5 class="mb-0"><i class="bi bi-people me-2"></i>Daftar Peserta (<%= pesertaUsers != null ? pesertaUsers.size() : 0 %>)</h5>
                    <div class="d-flex gap-2">
                        <select id="tagFilter" class="form-select form-select-sm" onchange="filterUsers()">
                            <option value="">Semua Tag</option>
                            <% for (String tag : allTags) { %>
                            <option value="<%= ValidationUtil.sanitizeHtml(tag) %>"><%= ValidationUtil.sanitizeHtml(tag) %></option>
                            <% } %>
                        </select>
                        <input type="text" id="searchInput" class="form-control form-control-sm" placeholder="Cari nama/email..." oninput="filterUsers()">
                    </div>
                </div>
                <div class="card-body p-0">
                    <div class="table-responsive">
                        <table class="table table-hover mb-0 align-middle" id="usersTable">
                            <thead>
                                <tr>
                                    <th>Nama</th>
                                    <th>Email</th>
                                    <th>Tag</th>
                                    <th class="text-end">Aksi</th>
                                </tr>
                            </thead>
                            <tbody>
                            <% if (pesertaUsers != null) for (User u : pesertaUsers) { %>
                                <tr data-name="<%= ValidationUtil.sanitizeHtml((u.getName()!=null?u.getName():"").toLowerCase()) %>"
                                    data-email="<%= ValidationUtil.sanitizeHtml((u.getEmail()!=null?u.getEmail():"").toLowerCase()) %>"
                                    data-tag="<%= ValidationUtil.sanitizeHtml(u.getTag()!=null?u.getTag():"") %>">
                                    <td><%= ValidationUtil.sanitizeHtml(u.getName()) %></td>
                                    <td><%= ValidationUtil.sanitizeHtml(u.getEmail()) %></td>
                                    <td><%= u.getTag()!=null && !u.getTag().isEmpty() ? "<span class='badge bg-secondary'>"+ValidationUtil.sanitizeHtml(u.getTag())+"</span>" : "-" %></td>
                                    <td class="text-end">
                                        <button class="btn btn-sm btn-primary" onclick="openGradeModal(<%= u.getId() %>)">
                                            <i class="bi bi-pencil-square me-1"></i>Edit Nilai
                                        </button>
                                    </td>
                                </tr>
                            <% } %>
                            </tbody>
                        </table>
                    </div>
                </div>
            </div>
        </div>
    </div>

    <!-- Modal: Edit Nilai (per-user, lists all quizzes) -->
    <div class="modal fade" id="gradeModal" tabindex="-1">
      <div class="modal-dialog modal-lg">
        <div class="modal-content">
          <div class="modal-header bg-primary text-white">
            <h5 class="modal-title"><i class="bi bi-pencil-square me-2"></i>Edit Nilai &mdash; <span id="gUserName">-</span></h5>
            <button type="button" class="btn-close btn-close-white" data-bs-dismiss="modal"></button>
          </div>
          <div class="modal-body">
            <p class="text-muted small mb-3">Edit <strong>jumlah jawaban benar</strong> per quiz. Skor dihitung otomatis (benar &divide; total &times; 100). Quiz yang belum dikerjakan akan dibuatkan submission berstatus completed.</p>
            <div id="gradeContent">
              <div class="text-center py-4 text-muted"><span class="spinner-border"></span> Memuat...</div>
            </div>
          </div>
          <div class="modal-footer">
            <button type="button" class="btn btn-secondary" data-bs-dismiss="modal">Tutup</button>
          </div>
        </div>
      </div>
    </div>

    <script src="https://cdn.jsdelivr.net/npm/bootstrap@5.3.0/dist/js/bootstrap.bundle.min.js"></script>
    <script>
        const csrfToken = '<%= ValidationUtil.sanitizeJs((String) session.getAttribute("csrfToken")) %>';
        let gradeUserId = null;

        function filterUsers() {
            const q = document.getElementById('searchInput').value.toLowerCase();
            const tag = document.getElementById('tagFilter').value.toLowerCase();
            document.querySelectorAll('#usersTable tbody tr').forEach(tr => {
                const matchSearch = !q || tr.dataset.name.includes(q) || tr.dataset.email.includes(q);
                const matchTag = !tag || tr.dataset.tag.toLowerCase() === tag;
                tr.style.display = (matchSearch && matchTag) ? '' : 'none';
            });
        }

        function openGradeModal(userId) {
            gradeUserId = userId;
            document.getElementById('gradeContent').innerHTML = '<div class="text-center py-4 text-muted"><span class="spinner-border"></span> Memuat...</div>';
            document.getElementById('gUserName').textContent = '-';
            new bootstrap.Modal(document.getElementById('gradeModal')).show();
            fetch('../AdminServlet?action=getUserQuizOverview&userId=' + userId)
                .then(r => r.json())
                .then(data => {
                    if (!data.success) {
                        document.getElementById('gradeContent').innerHTML = '<p class="text-danger">' + escapeHtml(data.message) + '</p>';
                        return;
                    }
                    document.getElementById('gUserName').textContent = data.user.name + ' (' + (data.user.email || '-') + ')';
                    renderGrades(data);
                })
                .catch(() => document.getElementById('gradeContent').innerHTML = '<p class="text-danger">Gagal memuat data.</p>');
        }

        function renderGrades(data) {
            // merge taken + untaken into one list sorted by quizId
            const rows = [];
            (data.takenQuizzes || []).forEach(q => rows.push(Object.assign({}, q, { taken: true })));
            (data.untakenQuizzes || []).forEach(q => rows.push(Object.assign({}, q, { taken: false })));
            rows.sort((a, b) => (a.quizId - b.quizId));
            let html = '<div class="table-responsive"><table class="table table-sm align-middle"><thead><tr>' +
                '<th>Quiz</th><th>Status</th><th>Skor</th><th style="width:200px">Jawaban Benar</th><th></th></tr></thead><tbody>';
            if (rows.length === 0) {
                html += '<tr><td colspan="5" class="text-center text-muted py-3">Tidak ada quiz</td></tr>';
            }
            for (const r of rows) {
                const total = r.totalQuestions || r.questionCount || 0;
                const correct = r.taken ? (r.correctAnswers || 0) : 0;
                const score = r.taken ? (r.score != null ? Number(r.score).toFixed(2) : '-') : '-';
                html += '<tr data-quiz="' + r.quizId + '" data-total="' + total + '" data-taken="' + r.taken + '">' +
                    '<td>' + escapeHtml(r.quizTitle) + '</td>' +
                    '<td>' + (r.taken ? '<span class="badge bg-success">Sudah</span>' : '<span class="badge bg-warning text-dark">Belum</span>') + '</td>' +
                    '<td class="scoreCell">' + score + '</td>' +
                    '<td><div class="input-group input-group-sm"><input type="number" class="form-control correctInput" min="0" max="' + total + '" value="' + correct + '"><span class="input-group-text">/ ' + total + '</span></div></td>' +
                    '<td><button class="btn btn-sm btn-outline-primary" onclick="saveRow(this)">Simpan</button> ' +
                    (r.taken ? '<a class="btn btn-sm btn-outline-secondary" href="../AdminServlet?action=editScore&submissionId=' + r.submissionId + '">Detail</a>' : '') + '</td>' +
                    '</tr>';
            }
            html += '</tbody></table></div>';
            document.getElementById('gradeContent').innerHTML = html;
        }

        function saveRow(btn) {
            const tr = btn.closest('tr');
            const quizId = tr.dataset.quiz;
            const total = parseInt(tr.dataset.total);
            const val = tr.querySelector('.correctInput').value;
            if (val === '' || isNaN(val) || val < 0 || val > total) {
                alert('Jawaban benar harus angka 0 - ' + total);
                return;
            }
            btn.disabled = true;
            fetch('../AdminServlet', {
                method: 'POST',
                headers: { 'Content-Type': 'application/x-www-form-urlencoded', 'X-CSRF-Token': csrfToken },
                body: 'action=saveCorrectCount&userId=' + gradeUserId + '&quizId=' + quizId + '&correctCount=' + val + '&csrfToken=' + encodeURIComponent(csrfToken)
            }).then(r => r.json()).then(d => {
                btn.disabled = false;
                if (d.success) {
                    tr.dataset.taken = 'true';
                    tr.querySelector('.scoreCell').textContent = Number(d.score).toFixed(2);
                    tr.querySelector('td:nth-child(2)').innerHTML = '<span class="badge bg-success">Sudah</span>';
                    // add Detail link if row was previously untaken
                    const lastTd = tr.querySelector('td:last-child');
                    if (!lastTd.querySelector('a')) {
                        lastTd.innerHTML = '<button class="btn btn-sm btn-outline-primary" onclick="saveRow(this)">Simpan</button> <a class="btn btn-sm btn-outline-secondary" href="../AdminServlet?action=editScore&submissionId=' + d.submissionId + '">Detail</a>';
                    }
                } else {
                    alert('Gagal: ' + d.message);
                }
            }).catch(() => { btn.disabled = false; alert('Kesalahan jaringan.'); });
        }

        function escapeHtml(s) {
            return (s == null ? '' : String(s)).replace(/[&<>"']/g, c => ({ '&': '&amp;', '<': '&lt;', '>': '&gt;', '"': '&quot;', "'": '&#39;' }[c]));
        }
    </script>
</body>
</html>

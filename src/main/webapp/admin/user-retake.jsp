<%@ page contentType="text/html;charset=UTF-8" language="java" %>
<%@ page import="com.examora.model.User" %>
<%
    User currentUser = (User) session.getAttribute("user");
    if (currentUser == null || !currentUser.isAdmin()) {
        response.sendRedirect("../LoginServlet");
        return;
    }
    String csrfToken = (String) session.getAttribute("csrfToken");
%>
<!DOCTYPE html>
<html lang="id">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Retake User - Admin Exatuy</title>
    <link href="../assets/vendor/bootstrap.min.css" rel="stylesheet">
    <link href="../assets/vendor/bootstrap-icons.css" rel="stylesheet">
    <link href="../assets/css/style.css" rel="stylesheet">
    <link rel="icon" type="image/svg+xml" href="../assets/img/favicon.svg?v=3">
<link href="../assets/css/handdrawn.css" rel="stylesheet">
</head>
<body>
    <!-- Sidebar -->
    <%@ include file="sidebar.jsp" %>

    <!-- Main Content -->
    <div class="main-content">
        <div class="d-flex justify-content-between align-items-center mb-4">
            <div>
                <h1 class="h3 mb-0">Retake User</h1>
                <nav aria-label="breadcrumb">
                    <ol class="breadcrumb mb-0">
                        <li class="breadcrumb-item"><a href="../AdminServlet?action=dashboard">Dashboard</a></li>
                        <li class="breadcrumb-item active">Retake User</li>
                    </ol>
                </nav>
            </div>
        </div>

        <!-- Search Card -->
        <div class="card border-0 shadow-sm mb-4">
            <div class="card-body">
                <h6 class="card-title mb-3"><i class="bi bi-search me-2"></i>Cari User</h6>
                <div class="position-relative">
                    <input type="text" id="userSearch" class="form-control" placeholder="Cari nama atau email user..." autocomplete="off">
                    <div id="searchDropdown" class="dropdown-menu w-100 shadow-sm" style="max-height: 300px; overflow-y: auto;"></div>
                </div>
            </div>
        </div>

        <!-- User Info Card -->
        <div id="userInfoCard" class="card border-0 shadow-sm mb-4" style="display: none;">
            <div class="card-body">
                <div class="d-flex align-items-center">
                    <div class="bg-primary bg-opacity-15 rounded-circle d-flex align-items-center justify-content-center me-3"
                         style="width: 48px; height: 48px;">
                        <span id="userAvatar" class="text-primary fw-bold fs-5"></span>
                    </div>
                    <div>
                        <h6 id="userName" class="mb-0"></h6>
                        <small id="userEmail" class="text-muted"></small>
                        <span id="userTag" class="badge bg-info ms-2" style="display: none;"></span>
                    </div>
                    <button type="button" class="btn btn-sm btn-outline-secondary ms-auto" onclick="clearSelection()">
                        <i class="bi bi-x-lg"></i> Ganti User
                    </button>
                </div>
            </div>
        </div>

        <!-- Stat Cards -->
        <div id="statCards" class="row g-3 mb-4" style="display: none;">
            <div class="col-md-4">
                <div class="card border-0 shadow-sm text-center">
                    <div class="card-body">
                        <div class="text-muted small">Total Quiz</div>
                        <div id="statTotal" class="fs-4 fw-bold">0</div>
                    </div>
                </div>
            </div>
            <div class="col-md-4">
                <div class="card border-0 shadow-sm text-center">
                    <div class="card-body">
                        <div class="text-muted small">Sudah Dikerjakan</div>
                        <div id="statTaken" class="fs-4 fw-bold text-success">0</div>
                    </div>
                </div>
            </div>
            <div class="col-md-4">
                <div class="card border-0 shadow-sm text-center">
                    <div class="card-body">
                        <div class="text-muted small">Belum Dikerjakan</div>
                        <div id="statUntaken" class="fs-4 fw-bold text-warning">0</div>
                    </div>
                </div>
            </div>
        </div>

        <!-- Taken Quizzes Table -->
        <div id="takenSection" class="card border-0 shadow-sm mb-4" style="display: none;">
            <div class="card-header bg-transparent border-0 pb-0">
                <h6 class="mb-0"><i class="bi bi-check-circle me-2 text-success"></i>Sudah Dikerjakan</h6>
            </div>
            <div class="card-body">
                <div class="table-responsive">
                    <table class="table table-hover align-middle mb-0">
                        <thead class="table-light">
                            <tr>
                                <th style="width: 40px;">No</th>
                                <th>Quiz Title</th>
                                <th style="width: 100px;">Score</th>
                                <th style="width: 120px;">Status</th>
                                <th style="width: 160px;">Submitted</th>
                                <th style="width: 200px;">Actions</th>
                            </tr>
                        </thead>
                        <tbody id="takenTableBody"></tbody>
                    </table>
                </div>
            </div>
        </div>

        <!-- Untaken Quizzes Table -->
        <div id="untakenSection" class="card border-0 shadow-sm mb-4" style="display: none;">
            <div class="card-header bg-transparent border-0 pb-0">
                <h6 class="mb-0"><i class="bi bi-clock me-2 text-warning"></i>Belum Dikerjakan</h6>
            </div>
            <div class="card-body">
                <div class="table-responsive">
                    <table class="table table-hover align-middle mb-0">
                        <thead class="table-light">
                            <tr>
                                <th style="width: 40px;">No</th>
                                <th>Quiz Title</th>
                                <th style="width: 100px;">Duration</th>
                                <th style="width: 120px;">Status Quiz</th>
                                <th style="width: 160px;">Deadline</th>
                                <th style="width: 150px;">Actions</th>
                            </tr>
                        </thead>
                        <tbody id="untakenTableBody"></tbody>
                    </table>
                </div>
            </div>
        </div>
    </div>

    <!-- Reset Confirmation Modal -->
    <div class="modal fade" id="resetModal" tabindex="-1">
        <div class="modal-dialog">
            <div class="modal-content">
                <div class="modal-header">
                    <h5 class="modal-title"><i class="bi bi-exclamation-triangle text-warning me-2"></i>Konfirmasi Reset</h5>
                    <button type="button" class="btn-close" data-bs-dismiss="modal"></button>
                </div>
                <div class="modal-body">
                    <p id="resetModalText">Yakin reset submission untuk user ini?</p>
                </div>
                <div class="modal-footer">
                    <button type="button" class="btn btn-secondary" data-bs-dismiss="modal">Batal</button>
                    <button type="button" class="btn btn-warning" id="confirmResetBtn">
                        <i class="bi bi-arrow-clockwise me-1"></i>Ya, Reset
                    </button>
                </div>
            </div>
        </div>
    </div>

    <!-- Retake Code Modal -->
    <div class="modal fade" id="retakeCodeModal" tabindex="-1">
        <div class="modal-dialog">
            <div class="modal-content">
                <div class="modal-header">
                    <h5 class="modal-title"><i class="bi bi-key text-info me-2"></i>Kode Retake</h5>
                    <button type="button" class="btn-close" data-bs-dismiss="modal"></button>
                </div>
                <div class="modal-body text-center">
                    <p class="text-muted mb-2">Kode retake berhasil dibuat:</p>
                    <div class="bg-light rounded p-3 mb-3">
                        <code id="retakeCodeValue" class="fs-4 fw-bold text-primary"></code>
                    </div>
                    <p class="small text-muted">Berikan kode ini ke user agar bisa mengerjakan ulang quiz.</p>
                </div>
                <div class="modal-footer justify-content-center">
                    <button type="button" class="btn btn-primary" onclick="copyRetakeCode()">
                        <i class="bi bi-clipboard me-1"></i>Copy to Clipboard
                    </button>
                    <button type="button" class="btn btn-secondary" data-bs-dismiss="modal">Tutup</button>
                </div>
            </div>
        </div>
    </div>

    <!-- Loading Overlay -->
    <div id="loadingOverlay" class="position-fixed top-0 start-0 w-100 h-100 align-items-center justify-content-center bg-white bg-opacity-75 d-none" style="z-index: 1050;">
        <div class="text-center">
            <div class="spinner-border text-primary mb-2" role="status"></div>
            <div class="text-muted">Memuat data...</div>
        </div>
    </div>

    <script src="../assets/vendor/bootstrap.bundle.min.js"></script>
    <script>
    console.log('[Retake] Page script loaded, Bootstrap:', typeof bootstrap !== 'undefined' ? 'OK' : 'MISSING');
    const CSRF = '<%= csrfToken != null ? csrfToken : "" %>';
    let selectedUserId = null;
    let currentQuizData = null;
    let pendingResetSubmissionId = null;
    let pendingResetQuizId = null;
    let searchTimeout = null;

    const searchInput = document.getElementById('userSearch');
    const searchDropdown = document.getElementById('searchDropdown');
    console.log('[Retake] DOM elements ready, searchInput:', searchInput ? 'OK' : 'MISSING');

    // Debounced search
    searchInput.addEventListener('input', function() {
        clearTimeout(searchTimeout);
        const query = this.value.trim();
        if (query.length < 2) {
            searchDropdown.classList.remove('show');
            return;
        }
        searchTimeout = setTimeout(() => doSearch(query), 300);
    });

    // Close dropdown on outside click
    document.addEventListener('click', function(e) {
        if (!searchInput.contains(e.target) && !searchDropdown.contains(e.target)) {
            searchDropdown.classList.remove('show');
        }
    });

    async function doSearch(query) {
        console.log('[Retake] Searching:', query);
        try {
            const res = await fetch('../AdminServlet?action=searchUsers&query=' + encodeURIComponent(query));
            console.log('[Retake] Search response status:', res.status);
            const data = await res.json();
            if (data.success && data.users.length > 0) {
                let html = '';
                data.users.forEach(u => {
                    const tagBadge = u.tag ? '<span class="badge bg-info ms-2">' + escapeHtml(u.tag) + '</span>' : '';
                    html += '<button type="button" class="dropdown-item d-flex align-items-center py-2" onclick="selectUser(' + u.id + ', \'' + escapeHtml(u.name).replace(/'/g, "\\'") + '\', \'' + escapeHtml(u.email) + '\', \'' + escapeHtml(u.tag || '') + '\')">';
                    html += '<div><div class="fw-semibold">' + escapeHtml(u.name) + tagBadge + '</div>';
                    html += '<small class="text-muted">' + escapeHtml(u.email) + '</small></div>';
                    html += '</button>';
                });
                searchDropdown.innerHTML = html;
                searchDropdown.classList.add('show');
            } else {
                searchDropdown.innerHTML = '<span class="dropdown-item text-muted">Tidak ada user ditemukan</span>';
                searchDropdown.classList.add('show');
            }
        } catch (e) {
            console.error('Search error:', e);
        }
    }

    async function selectUser(id, name, email, tag) {
        selectedUserId = id;
        searchDropdown.classList.remove('show');
        searchInput.value = '';
        searchInput.disabled = false;
        searchInput.focus();

        document.getElementById('userAvatar').textContent = name.charAt(0).toUpperCase();
        document.getElementById('userName').textContent = name;
        document.getElementById('userEmail').textContent = email;
        const tagEl = document.getElementById('userTag');
        if (tag) {
            tagEl.textContent = tag;
            tagEl.style.display = '';
        } else {
            tagEl.style.display = 'none';
        }
        document.getElementById('userInfoCard').style.display = '';

        await loadQuizOverview();
    }

    async function loadQuizOverview() {
        console.log('[Retake] loadQuizOverview called, userId:', selectedUserId);
        showLoading(true);
        try {
            const res = await fetch('../AdminServlet?action=getUserQuizOverview&userId=' + selectedUserId);
            console.log('[Retake] Overview response status:', res.status);
            const data = await res.json();
            console.log('[Retake] Overview data success:', data.success, 'taken:', data.takenQuizzes?.length, 'untaken:', data.untakenQuizzes?.length);
            if (!data.success) {
                alert(data.message || 'Gagal memuat data');
                return;
            }
            currentQuizData = data;
            renderOverview(data);
        } catch (e) {
            alert('Error: ' + e.message);
        } finally {
            showLoading(false);
        }
    }

    function renderOverview(data) {
        document.getElementById('statTotal').textContent = data.takenQuizzes.length + data.untakenQuizzes.length;
        document.getElementById('statTaken').textContent = data.takenQuizzes.length;
        document.getElementById('statUntaken').textContent = data.untakenQuizzes.length;
        document.getElementById('statCards').style.display = '';

        // Taken quizzes table
        const takenBody = document.getElementById('takenTableBody');
        if (data.takenQuizzes.length > 0) {
            let html = '';
            data.takenQuizzes.forEach((q, i) => {
                const score = q.score != null ? Math.round(q.score) : 0;
                const scoreBadge = score >= 60
                    ? '<span class="badge bg-success">' + score + '%</span>'
                    : '<span class="badge bg-danger">' + score + '%</span>';
                const statusMap = {
                    'completed': '<span class="badge bg-success">Completed</span>',
                    'timeout': '<span class="badge bg-warning text-dark">Timeout</span>',
                    'in_progress': '<span class="badge bg-info">In Progress</span>'
                };
                const statusBadge = statusMap[q.status] || '<span class="badge bg-secondary">' + escapeHtml(q.status) + '</span>';
                const retakeIcon = q.isRetake ? ' <i class="bi bi-arrow-repeat text-info" title="Retake"></i>' : '';

                html += '<tr>';
                html += '<td>' + (i + 1) + '</td>';
                html += '<td>' + escapeHtml(q.quizTitle) + retakeIcon + '</td>';
                html += '<td>' + scoreBadge + '</td>';
                html += '<td>' + statusBadge + '</td>';
                html += '<td><small>' + escapeHtml(q.submittedAt) + '</small></td>';
                html += '<td>';
                html += '<button class="btn btn-sm btn-outline-warning me-1" onclick="showResetModal(' + q.submissionId + ', ' + q.quizId + ', \'' + escapeHtml(q.quizTitle).replace(/'/g, "\\'") + '\')"><i class="bi bi-arrow-clockwise"></i> Reset</button>';
                html += '<button class="btn btn-sm btn-outline-info" onclick="doGenerateRetakeCode(' + q.quizId + ')"><i class="bi bi-key"></i> Kode Retake</button>';
                html += '</td>';
                html += '</tr>';
            });
            takenBody.innerHTML = html;
            document.getElementById('takenSection').style.display = '';
        } else {
            takenBody.innerHTML = '<tr><td colspan="6" class="text-center text-muted py-3">Belum ada quiz yang dikerjakan</td></tr>';
            document.getElementById('takenSection').style.display = '';
        }

        // Untaken quizzes table
        const untakenBody = document.getElementById('untakenTableBody');
        if (data.untakenQuizzes.length > 0) {
            let html = '';
            data.untakenQuizzes.forEach((q, i) => {
                const activeBadge = q.isActive
                    ? '<span class="badge bg-success">Active</span>'
                    : '<span class="badge bg-secondary">Inactive</span>';

                html += '<tr>';
                html += '<td>' + (i + 1) + '</td>';
                html += '<td>' + escapeHtml(q.quizTitle) + '</td>';
                html += '<td>' + q.duration + ' min</td>';
                html += '<td>' + activeBadge + '</td>';
                html += '<td><small>' + escapeHtml(q.deadline) + '</small></td>';
                html += '<td>';
                html += '<button class="btn btn-sm btn-outline-info" onclick="doGenerateRetakeCode(' + q.quizId + ')"><i class="bi bi-key"></i> Kode Retake</button>';
                html += '</td>';
                html += '</tr>';
            });
            untakenBody.innerHTML = html;
            document.getElementById('untakenSection').style.display = '';
        } else {
            untakenBody.innerHTML = '<tr><td colspan="6" class="text-center text-muted py-3">Semua quiz sudah dikerjakan</td></tr>';
            document.getElementById('untakenSection').style.display = '';
        }
    }

    function clearSelection() {
        selectedUserId = null;
        currentQuizData = null;
        searchInput.value = '';
        searchInput.disabled = false;
        searchInput.focus();
        document.getElementById('userInfoCard').style.display = 'none';
        document.getElementById('statCards').style.display = 'none';
        document.getElementById('takenSection').style.display = 'none';
        document.getElementById('untakenSection').style.display = 'none';
    }

    // Reset submission
    function showResetModal(submissionId, quizId, quizTitle) {
        const userName = document.getElementById('userName').textContent;
        document.getElementById('resetModalText').textContent =
            'Yakin reset submission "' + quizTitle + '" untuk ' + userName + '?';
        pendingResetSubmissionId = submissionId;
        pendingResetQuizId = quizId;
        new bootstrap.Modal(document.getElementById('resetModal')).show();
    }

    document.getElementById('confirmResetBtn').addEventListener('click', async function() {
        if (!pendingResetSubmissionId || !pendingResetQuizId) return;
        const btn = this;
        btn.disabled = true;
        btn.innerHTML = '<span class="spinner-border spinner-border-sm me-1"></span>Mereset...';

        try {
            const formData = new FormData();
            formData.append('action', 'resetSubmission');
            formData.append('submissionId', pendingResetSubmissionId);
            formData.append('quizId', pendingResetQuizId);
            formData.append('csrfToken', CSRF);

            const res = await fetch('../AdminServlet', { method: 'POST', body: formData });
            const data = await res.json();

            if (data.success) {
                bootstrap.Modal.getInstance(document.getElementById('resetModal')).hide();
                await loadQuizOverview();
                showToast(data.message, 'success');
            } else {
                alert(data.message || 'Gagal mereset submission');
            }
        } catch (e) {
            alert('Error: ' + e.message);
        } finally {
            btn.disabled = false;
            btn.innerHTML = '<i class="bi bi-arrow-clockwise me-1"></i>Ya, Reset';
        }
    });

    // Generate retake code
    async function doGenerateRetakeCode(quizId) {
        if (!selectedUserId) return;
        try {
            const formData = new FormData();
            formData.append('action', 'generateRetakeCode');
            formData.append('userId', selectedUserId);
            formData.append('quizId', quizId);
            formData.append('csrfToken', CSRF);

            const res = await fetch('../AdminServlet', { method: 'POST', body: formData });
            const data = await res.json();

            if (data.success) {
                document.getElementById('retakeCodeValue').textContent = data.retakeCode;
                new bootstrap.Modal(document.getElementById('retakeCodeModal')).show();
            } else {
                alert(data.message || 'Gagal membuat kode retake');
            }
        } catch (e) {
            alert('Error: ' + e.message);
        }
    }

    function copyRetakeCode() {
        const code = document.getElementById('retakeCodeValue').textContent;
        navigator.clipboard.writeText(code).then(() => {
            showToast('Kode berhasil disalin ke clipboard', 'success');
        }).catch(() => {
            // Fallback
            const textarea = document.createElement('textarea');
            textarea.value = code;
            document.body.appendChild(textarea);
            textarea.select();
            document.execCommand('copy');
            document.body.removeChild(textarea);
            showToast('Kode berhasil disalin ke clipboard', 'success');
        });
    }

    function showLoading(show) {
        console.log('[Retake] showLoading:', show);
        const overlay = document.getElementById('loadingOverlay');
        if (show) {
            overlay.classList.remove('d-none');
            overlay.classList.add('d-flex');
        } else {
            overlay.classList.remove('d-flex');
            overlay.classList.add('d-none');
        }
    }

    function showToast(message, type) {
        const icon = type === 'success' ? 'check-circle' : 'exclamation-circle';
        const bgClass = type === 'success' ? 'text-success' : 'text-danger';
        const toastHtml = '<div class="position-fixed bottom-0 end-0 p-3" style="z-index: 9999;">' +
            '<div class="toast show" role="alert">' +
            '<div class="toast-body"><i class="bi bi-' + icon + ' ' + bgClass + ' me-2"></i>' + escapeHtml(message) + '</div>' +
            '</div></div>';
        const wrapper = document.createElement('div');
        wrapper.innerHTML = toastHtml;
        document.body.appendChild(wrapper.firstElementChild);
        setTimeout(() => {
            const toasts = document.querySelectorAll('.toast');
            toasts.forEach(t => { if (t.parentElement) t.parentElement.remove(); });
        }, 3000);
    }

    function escapeHtml(str) {
        if (!str) return '';
        const div = document.createElement('div');
        div.textContent = str;
        return div.innerHTML;
    }
    </script>
</body>
</html>

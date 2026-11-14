<%@ page contentType="text/html;charset=UTF-8" language="java" %>
<%@ taglib prefix="c" uri="http://java.sun.com/jsp/jstl/core" %>
<%@ page import="com.examora.model.User" %>
<%@ page import="com.examora.model.AttendanceSession" %>
<%@ page import="com.examora.util.ValidationUtil" %>
<%@ page import="java.util.List" %>
<%@ page import="java.util.TimeZone" %>
<%
    User currentUser = (User) session.getAttribute("user");
    if (currentUser == null || !currentUser.isAdmin()) {
        response.sendRedirect("../LoginServlet");
        return;
    }

    List<AttendanceSession> sessions = (List<AttendanceSession>) request.getAttribute("sessions");
    List<String> tags = (List<String>) request.getAttribute("tags");
    String success = (String) request.getAttribute("success");
    String error = (String) request.getAttribute("error");

    String csrfToken = (String) session.getAttribute("csrfToken");
    if (csrfToken == null) {
        csrfToken = java.util.UUID.randomUUID().toString();
        session.setAttribute("csrfToken", csrfToken);
    }

    // Date formatters with Jakarta timezone
    java.text.SimpleDateFormat dateFormat = new java.text.SimpleDateFormat("dd MMM yyyy");
    java.text.SimpleDateFormat timeFormat = new java.text.SimpleDateFormat("HH:mm");
    dateFormat.setTimeZone(TimeZone.getTimeZone("Asia/Jakarta"));
    timeFormat.setTimeZone(TimeZone.getTimeZone("Asia/Jakarta"));
%>
<!DOCTYPE html>
<html lang="id">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Kelola Absensi - Exatuy</title>
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
        <!-- Header -->
        <div class="d-flex justify-content-between align-items-center mb-4">
            <div>
                <h1 class="h3 mb-0">Kelola Absensi</h1>
                <p class="text-muted mb-0">Buat dan kelola sesi absensi</p>
            </div>
            <div>
                <button type="button" class="btn btn-primary" data-bs-toggle="modal" data-bs-target="#createSessionModal">
                    <i class="bi bi-plus-lg me-2"></i>Buat Sesi Absensi
                </button>
            </div>
        </div>

        <% if (success != null) { %>
        <div class="alert alert-success alert-dismissible fade show" role="alert">
            <i class="bi bi-check-circle me-2"></i><%= ValidationUtil.sanitizeHtml(success) %>
            <button type="button" class="btn-close" data-bs-dismiss="alert"></button>
        </div>
        <% } %>

        <% if (error != null) { %>
        <div class="alert alert-danger alert-dismissible fade show" role="alert">
            <i class="bi bi-exclamation-triangle me-2"></i><%= ValidationUtil.sanitizeHtml(error) %>
            <button type="button" class="btn-close" data-bs-dismiss="alert"></button>
        </div>
        <% } %>

        <!-- Sessions Table -->
        <div class="card">
            <div class="card-header">
                <h5 class="mb-0"><i class="bi bi-list-ul me-2"></i>Daftar Sesi Absensi</h5>
            </div>
            <div class="card-body">
                <% if (sessions != null && !sessions.isEmpty()) { %>
                <div class="table-responsive">
                    <table class="table table-hover">
                        <thead>
                            <tr>
                                <th>Nama Sesi</th>
                                <th>Kode</th>
                                <th>Tanggal</th>
                                <th>Waktu</th>
                                <th>Target Tag</th>
                                <th>Status</th>
                                <th>Aksi</th>
                            </tr>
                        </thead>
                        <tbody>
                            <% for (AttendanceSession attSession : sessions) { %>
                            <tr>
                                <td><%= ValidationUtil.sanitizeHtml(attSession.getSessionName()) %></td>
                                <td>
                                    <span class="badge bg-dark font-monospace"><%= ValidationUtil.sanitizeHtml(attSession.getSessionCode()) %></span>
                                </td>
                                <td><%= dateFormat.format(attSession.getSessionDate()) %></td>
                                <td>
                                    <%= timeFormat.format(attSession.getStartTime()) %> -
                                    <%= timeFormat.format(attSession.getEndTime()) %>
                                </td>
                                <td>
                                    <% if (attSession.getTargetTag() != null && !attSession.getTargetTag().isEmpty()) { %>
                                    <span class="badge bg-info"><%= ValidationUtil.sanitizeHtml(attSession.getTargetTag()) %></span>
                                    <% } else { %>
                                    <span class="text-muted">Semua</span>
                                    <% } %>
                                </td>
                                <td>
                                    <span class="badge <%= ValidationUtil.sanitizeHtml(attSession.getStatusBadgeClass()) %>"><%= ValidationUtil.sanitizeHtml(attSession.getStatusLabel()) %></span>
                                    <% if ("scheduled".equals(attSession.getStatus())) { %>
                                    <div class="text-muted small mt-1"><i class="bi bi-clock"></i> Otomatis aktif saat waktunya</div>
                                    <% } %>
                                </td>
                                <td>
                                    <% if ("scheduled".equals(attSession.getStatus())) { %>
                                    <button class="btn btn-sm btn-success activate-btn"
                                            data-session-id="<%= attSession.getId() %>" title="Aktifkan">
                                        <i class="bi bi-play-fill"></i>
                                    </button>
                                    <% } %>
                                    <% if ("active".equals(attSession.getStatus())) { %>
                                    <button class="btn btn-sm btn-warning close-btn"
                                            data-session-id="<%= attSession.getId() %>" title="Tutup">
                                        <i class="bi bi-stop-fill"></i>
                                    </button>
                                    <% } %>
                                    <button class="btn btn-sm btn-outline-primary edit-btn"
                                            data-session-id="<%= attSession.getId() %>" title="Edit">
                                        <i class="bi bi-pencil"></i>
                                    </button>
                                    <a href="AttendanceServlet?action=view&sessionId=<%= attSession.getId() %>"
                                       class="btn btn-sm btn-info" title="Lihat Records">
                                        <i class="bi bi-people"></i>
                                    </a>
                                    <button class="btn btn-sm btn-outline-danger delete-btn"
                                            data-session-id="<%= attSession.getId() %>" title="Hapus">
                                        <i class="bi bi-trash"></i>
                                    </button>
                                </td>
                            </tr>
                            <% } %>
                        </tbody>
                    </table>
                </div>
                <% } else { %>
                <div class="text-center py-4 text-muted">
                    <i class="bi bi-calendar-x display-4 d-block mb-2"></i>
                    Belum ada sesi absensi. Klik tombol "Buat Sesi Absensi" untuk membuat sesi baru.
                </div>
                <% } %>
            </div>
        </div>
    </div>

    <!-- Create Session Modal -->
    <div class="modal fade" id="createSessionModal" tabindex="-1">
        <div class="modal-dialog">
            <div class="modal-content">
                <div class="modal-header">
                    <h5 class="modal-title"><i class="bi bi-plus-circle me-2"></i>Buat Sesi Absensi Baru</h5>
                    <button type="button" class="btn-close" data-bs-dismiss="modal"></button>
                </div>
                <div class="modal-body">
                    <form id="createSessionForm">
                        <div class="mb-3">
                            <label class="form-label">Nama Sesi <span class="text-danger">*</span></label>
                            <input type="text" class="form-control" name="sessionName" required
                                   placeholder="Contoh: Absensi Kuliah Pertemuan 1">
                        </div>
                        <div class="mb-3">
                            <label class="form-label">Tanggal <span class="text-danger">*</span></label>
                            <input type="date" class="form-control" name="sessionDate" required>
                        </div>
                        <div class="mb-3">
                            <label class="form-label">Waktu Mulai <span class="text-danger">*</span></label>
                            <div class="d-flex gap-2">
                                <select class="form-select" name="startHour" required style="max-width: 100px;">
                                    <option value="">Jam</option>
                                    <% for (int h = 1; h <= 24; h++) { %>
                                        <option value="<%= h %>"><%= String.format("%02d", h) %></option>
                                    <% } %>
                                </select>
                                <select class="form-select" name="startMinute" required style="max-width: 100px;">
                                    <option value="">Menit</option>
                                    <option value="0">00</option>
                                    <option value="15">15</option>
                                    <option value="30">30</option>
                                    <option value="45">45</option>
                                </select>
                                <span class="align-self-center text-muted small">WIB (01-24)</span>
                            </div>
                        </div>
                        <div class="mb-3">
                            <label class="form-label">Waktu Selesai <span class="text-danger">*</span></label>
                            <div class="d-flex gap-2">
                                <select class="form-select" name="endHour" required style="max-width: 100px;">
                                    <option value="">Jam</option>
                                    <% for (int h = 1; h <= 24; h++) { %>
                                        <option value="<%= h %>"><%= String.format("%02d", h) %></option>
                                    <% } %>
                                </select>
                                <select class="form-select" name="endMinute" required style="max-width: 100px;">
                                    <option value="">Menit</option>
                                    <option value="0">00</option>
                                    <option value="15">15</option>
                                    <option value="30">30</option>
                                    <option value="45">45</option>
                                </select>
                                <span class="align-self-center text-muted small">WIB (01-24)</span>
                            </div>
                        </div>
                        <div class="mb-3">
                            <label class="form-label">Target Tag (Opsional)</label>
                            <select class="form-select" name="targetTag">
                                <option value="">-- Semua Peserta --</option>
                                <% if (tags != null) { %>
                                    <% for (String tag : tags) { %>
                                        <% if (tag != null && !tag.isEmpty()) { %>
                                        <option value="<%= ValidationUtil.sanitizeHtml(tag) %>"><%= ValidationUtil.sanitizeHtml(tag) %></option>
                                        <% } %>
                                    <% } %>
                                <% } %>
                            </select>
                            <div class="form-text">Hanya peserta dengan tag ini yang bisa absen</div>
                        </div>
                        <div class="mb-3">
                            <label class="form-label">Batas Terlambat (menit)</label>
                            <input type="number" class="form-control" name="lateThreshold" value="15" min="0">
                            <div class="form-text">Setelah waktu ini, status absensi akan "Terlambat"</div>
                        </div>
                    </form>
                </div>
                <div class="modal-footer">
                    <button type="button" class="btn btn-secondary" data-bs-dismiss="modal">Batal</button>
                    <button type="button" class="btn btn-primary" id="createSessionBtn">
                        <i class="bi bi-check-lg me-2"></i>Buat Sesi
                    </button>
                </div>
            </div>
        </div>
    </div>

    <!-- Success Modal -->
    <div class="modal fade" id="successModal" tabindex="-1">
        <div class="modal-dialog">
            <div class="modal-content">
                <div class="modal-header bg-success text-white">
                    <h5 class="modal-title"><i class="bi bi-check-circle me-2"></i>Sesi Berhasil Dibuat!</h5>
                    <button type="button" class="btn-close btn-close-white" data-bs-dismiss="modal"></button>
                </div>
                <div class="modal-body text-center">
                    <p class="mb-2">Kode Sesi:</p>
                    <h2 class="text-primary font-monospace mb-3" id="generatedCode"></h2>
                    <p class="text-muted">Share kode ini ke peserta untuk melakukan absensi</p>
                </div>
                <div class="modal-footer">
                    <button type="button" class="btn btn-secondary" data-bs-dismiss="modal">Tutup</button>
                    <button type="button" class="btn btn-primary" id="copyCodeBtn">
                        <i class="bi bi-clipboard me-2"></i>Salin Kode
                    </button>
                </div>
            </div>
        </div>
    </div>

    <!-- Edit Session Modal -->
    <div class="modal fade" id="editSessionModal" tabindex="-1">
        <div class="modal-dialog">
            <div class="modal-content">
                <div class="modal-header">
                    <h5 class="modal-title"><i class="bi bi-pencil me-2"></i>Edit Sesi Absensi</h5>
                    <button type="button" class="btn-close" data-bs-dismiss="modal"></button>
                </div>
                <div class="modal-body">
                    <form id="editSessionForm">
                        <input type="hidden" name="sessionId" id="editSessionId">
                        <div class="mb-3">
                            <label class="form-label">Nama Sesi <span class="text-danger">*</span></label>
                            <input type="text" class="form-control" name="sessionName" id="editSessionName" required
                                   placeholder="Contoh: Absensi Kuliah Pertemuan 1">
                        </div>
                        <div class="mb-3">
                            <label class="form-label">Tanggal <span class="text-danger">*</span></label>
                            <input type="date" class="form-control" name="sessionDate" id="editSessionDate" required>
                        </div>
                        <div class="mb-3">
                            <label class="form-label">Waktu Mulai <span class="text-danger">*</span></label>
                            <div class="d-flex gap-2">
                                <select class="form-select" name="editStartHour" id="editStartHour" required style="max-width: 100px;">
                                    <option value="">Jam</option>
                                    <% for (int h = 1; h <= 24; h++) { %>
                                        <option value="<%= h %>"><%= String.format("%02d", h) %></option>
                                    <% } %>
                                </select>
                                <select class="form-select" name="editStartMinute" id="editStartMinute" required style="max-width: 100px;">
                                    <option value="">Menit</option>
                                    <option value="0">00</option>
                                    <option value="15">15</option>
                                    <option value="30">30</option>
                                    <option value="45">45</option>
                                </select>
                                <span class="align-self-center text-muted small">WIB (01-24)</span>
                            </div>
                        </div>
                        <div class="mb-3">
                            <label class="form-label">Waktu Selesai <span class="text-danger">*</span></label>
                            <div class="d-flex gap-2">
                                <select class="form-select" name="editEndHour" id="editEndHour" required style="max-width: 100px;">
                                    <option value="">Jam</option>
                                    <% for (int h = 1; h <= 24; h++) { %>
                                        <option value="<%= h %>"><%= String.format("%02d", h) %></option>
                                    <% } %>
                                </select>
                                <select class="form-select" name="editEndMinute" id="editEndMinute" required style="max-width: 100px;">
                                    <option value="">Menit</option>
                                    <option value="0">00</option>
                                    <option value="15">15</option>
                                    <option value="30">30</option>
                                    <option value="45">45</option>
                                </select>
                                <span class="align-self-center text-muted small">WIB (01-24)</span>
                            </div>
                        </div>
                        <div class="mb-3">
                            <label class="form-label">Target Tag (Opsional)</label>
                            <select class="form-select" name="targetTag" id="editTargetTag">
                                <option value="">-- Semua Peserta --</option>
                                <% if (tags != null) { %>
                                    <% for (String tag : tags) { %>
                                        <% if (tag != null && !tag.isEmpty()) { %>
                                        <option value="<%= ValidationUtil.sanitizeHtml(tag) %>"><%= ValidationUtil.sanitizeHtml(tag) %></option>
                                        <% } %>
                                    <% } %>
                                <% } %>
                            </select>
                            <div class="form-text">Hanya peserta dengan tag ini yang bisa absen</div>
                        </div>
                        <div class="mb-3">
                            <label class="form-label">Batas Terlambat (menit)</label>
                            <input type="number" class="form-control" name="lateThreshold" id="editLateThreshold" value="15" min="0">
                            <div class="form-text">Setelah waktu ini, status absensi akan "Terlambat"</div>
                        </div>
                    </form>
                </div>
                <div class="modal-footer">
                    <button type="button" class="btn btn-secondary" data-bs-dismiss="modal">Batal</button>
                    <button type="button" class="btn btn-primary" id="updateSessionBtn">
                        <i class="bi bi-check-lg me-2"></i>Simpan Perubahan
                    </button>
                </div>
            </div>
        </div>
    </div>

    <script src="https://cdn.jsdelivr.net/npm/bootstrap@5.3.0/dist/js/bootstrap.bundle.min.js"></script>
    <script>
        const csrfToken = '<%= csrfToken %>';

        // Set default date to today
        document.addEventListener('DOMContentLoaded', function() {
            const dateInput = document.querySelector('input[name="sessionDate"]');
            if (dateInput) {
                dateInput.valueAsDate = new Date();
            }
        });

        // Convert 01-24 format to 00-23 format for backend
        function convertTo24Hour(hour, minute) {
            // If hour is 24, convert to 00
            if (hour === '24') {
                return '00:' + minute.padStart(2, '0');
            }
            return hour.padStart(2, '0') + ':' + minute.padStart(2, '0');
        }

        // Create session
        document.getElementById('createSessionBtn').addEventListener('click', function() {
            const form = document.getElementById('createSessionForm');
            const formData = new FormData(form);
            const params = new URLSearchParams();
            params.append('action', 'create');
            params.append('csrfToken', csrfToken);

            // Get time values and convert
            const startHour = formData.get('startHour');
            const startMinute = formData.get('startMinute');
            const endHour = formData.get('endHour');
            const endMinute = formData.get('endMinute');

            // Validate time selection
            if (!startHour || !startMinute || !endHour || !endMinute) {
                alert('Silakan pilih waktu mulai dan selesai');
                return;
            }

            // Convert to 00-23 format
            const startTime = convertTo24Hour(startHour, startMinute);
            const endTime = convertTo24Hour(endHour, endMinute);

            // Append form data (excluding the separate hour/minute fields)
            for (let [key, value] of formData.entries()) {
                if (key !== 'startHour' && key !== 'startMinute' && key !== 'endHour' && key !== 'endMinute') {
                    params.append(key, value);
                }
            }

            // Append converted time values
            params.append('startTime', startTime);
            params.append('endTime', endTime);

            fetch('AttendanceServlet', {
                method: 'POST',
                headers: {
                    'Content-Type': 'application/x-www-form-urlencoded',
                    'Accept': 'application/json'
                },
                body: params
            })
            .then(response => {
                if (!response.ok) {
                    return response.text().then(text => {
                        throw new Error('HTTP ' + response.status + ': ' + text);
                    });
                }
                return response.json();
            })
            .then(data => {
                if (data.success) {
                    const createModal = bootstrap.Modal.getInstance(document.getElementById('createSessionModal'));
                    createModal.hide();
                    form.reset();
                    const dateInput = document.querySelector('input[name="sessionDate"]');
                    if (dateInput) {
                        dateInput.valueAsDate = new Date();
                    }
                    // Reset dropdowns
                    document.querySelectorAll('select[name="startHour"], select[name="startMinute"], select[name="endHour"], select[name="endMinute"]').forEach(sel => sel.value = '');

                    document.getElementById('generatedCode').textContent = data.sessionCode;
                    const successModal = new bootstrap.Modal(document.getElementById('successModal'));
                    successModal.show();

                    setTimeout(() => location.reload(), 2000);
                } else {
                    alert('Error: ' + (data.message || 'Terjadi kesalahan'));
                }
            })
            .catch(error => {
                console.error('Error:', error);
                alert('Error: ' + error.message);
            });
        });

        // Copy code
        document.getElementById('copyCodeBtn').addEventListener('click', function() {
            const code = document.getElementById('generatedCode').textContent;
            navigator.clipboard.writeText(code).then(() => {
                this.innerHTML = '<i class="bi bi-check me-2"></i>Tersalin!';
                setTimeout(() => {
                    this.innerHTML = '<i class="bi bi-clipboard me-2"></i>Salin Kode';
                }, 2000);
            });
        });

        // Activate session
        document.querySelectorAll('.activate-btn').forEach(btn => {
            btn.addEventListener('click', function() {
                if (confirm('Aktifkan sesi ini?')) {
                    const sessionId = this.dataset.sessionId;
                    const params = new URLSearchParams();
                    params.append('action', 'activate');
                    params.append('sessionId', sessionId);
                    params.append('csrfToken', csrfToken);

                    fetch('AttendanceServlet', {
                        method: 'POST',
                        headers: {
                            'Content-Type': 'application/x-www-form-urlencoded'
                        },
                        body: params
                    })
                    .then(response => response.json())
                    .then(data => {
                        if (data.success) {
                            location.reload();
                        } else {
                            alert('Error: ' + (data.message || 'Terjadi kesalahan'));
                        }
                    });
                }
            });
        });

        // Close session
        document.querySelectorAll('.close-btn').forEach(btn => {
            btn.addEventListener('click', function() {
                if (confirm('Tutup sesi ini?')) {
                    const sessionId = this.dataset.sessionId;
                    const params = new URLSearchParams();
                    params.append('action', 'close');
                    params.append('sessionId', sessionId);
                    params.append('csrfToken', csrfToken);

                    fetch('AttendanceServlet', {
                        method: 'POST',
                        headers: {
                            'Content-Type': 'application/x-www-form-urlencoded'
                        },
                        body: params
                    })
                    .then(response => response.json())
                    .then(data => {
                        if (data.success) {
                            location.reload();
                        } else {
                            alert('Error: ' + (data.message || 'Terjadi kesalahan'));
                        }
                    });
                }
            });
        });

        // Edit session button click - wrapped in DOMContentLoaded
        document.addEventListener('DOMContentLoaded', function() {
            document.querySelectorAll('.edit-btn').forEach(btn => {
                btn.addEventListener('click', function() {
                    const sessionId = this.dataset.sessionId;
                    console.log('Edit button clicked, sessionId:', sessionId);

                    // Fetch session data
                    fetch('AttendanceServlet?action=edit&sessionId=' + sessionId, {
                        headers: {
                            'Accept': 'application/json'
                        }
                    })
                    .then(response => {
                        console.log('Response status:', response.status);
                        if (!response.ok) {
                            throw new Error('HTTP ' + response.status);
                        }
                        return response.json();
                    })
                    .then(data => {
                        console.log('Edit session data:', data);
                        if (data.success) {
                            // Populate edit form
                            document.getElementById('editSessionId').value = data.id;
                            document.getElementById('editSessionName').value = data.sessionName || '';
                            document.getElementById('editSessionDate').value = data.sessionDate || '';
                            document.getElementById('editTargetTag').value = data.targetTag || '';
                            document.getElementById('editLateThreshold').value = data.lateThreshold || 15;

                            // Set start time
                            document.getElementById('editStartHour').value = data.displayStartHour || data.startTime?.split(':')[0] || '';
                            document.getElementById('editStartMinute').value = data.startMinute || data.startTime?.split(':')[1] || '00';

                            // Set end time
                            document.getElementById('editEndHour').value = data.displayEndHour || data.endTime?.split(':')[0] || '';
                            document.getElementById('editEndMinute').value = data.endMinute || data.endTime?.split(':')[1] || '00';

                            console.log('Opening edit modal...');
                            const modal = new bootstrap.Modal(document.getElementById('editSessionModal'));
                            modal.show();
                        } else {
                            alert('Error: ' + (data.message || 'Gagal memuat data sesi'));
                        }
                    })
                    .catch(error => {
                        console.error('Error:', error);
                        alert('Error: ' + error.message);
                    });
                });
            });

            // Update session button listener
            document.getElementById('updateSessionBtn').addEventListener('click', function() {
                const form = document.getElementById('editSessionForm');
                const params = new URLSearchParams();
                params.append('action', 'edit');
                params.append('csrfToken', csrfToken);

                // Get form data
                params.append('sessionId', document.getElementById('editSessionId').value);
                params.append('sessionName', document.getElementById('editSessionName').value);
                params.append('sessionDate', document.getElementById('editSessionDate').value);
                params.append('targetTag', document.getElementById('editTargetTag').value);
                params.append('lateThreshold', document.getElementById('editLateThreshold').value);

                // Get time values and convert
                const startHour = document.getElementById('editStartHour').value;
                const startMinute = document.getElementById('editStartMinute').value;
                const endHour = document.getElementById('editEndHour').value;
                const endMinute = document.getElementById('editEndMinute').value;

                // Validate time selection
                if (!startHour || !startMinute || !endHour || !endMinute) {
                    alert('Silakan pilih waktu mulai dan selesai');
                    return;
                }

                // Convert to 00-23 format
                const startTime = convertTo24Hour(startHour, startMinute);
                const endTime = convertTo24Hour(endHour, endMinute);

                params.append('startTime', startTime);
                params.append('endTime', endTime);

                fetch('AttendanceServlet', {
                    method: 'POST',
                    headers: {
                        'Content-Type': 'application/x-www-form-urlencoded',
                        'Accept': 'application/json'
                    },
                    body: params
                })
                .then(response => {
                    if (!response.ok) {
                        return response.text().then(text => {
                            throw new Error('HTTP ' + response.status + ': ' + text);
                        });
                    }
                    return response.json();
                })
                .then(data => {
                    if (data.success) {
                        const modal = bootstrap.Modal.getInstance(document.getElementById('editSessionModal'));
                        modal.hide();
                        location.reload();
                    } else {
                        alert('Error: ' + (data.message || 'Gagal mengupdate sesi'));
                    }
                })
                .catch(error => {
                    console.error('Error:', error);
                    alert('Error: ' + error.message);
                });
            });

            // Delete session button listeners
            document.querySelectorAll('.delete-btn').forEach(btn => {
                btn.addEventListener('click', function() {
                    if (confirm('Hapus sesi ini?')) {
                        const sessionId = this.dataset.sessionId;
                        const params = new URLSearchParams();
                        params.append('action', 'delete');
                        params.append('sessionId', sessionId);
                        params.append('csrfToken', csrfToken);

                        fetch('AttendanceServlet', {
                            method: 'POST',
                            headers: {
                                'Content-Type': 'application/x-www-form-urlencoded'
                            },
                            body: params
                        })
                        .then(response => response.json())
                        .then(data => {
                            if (data.success) {
                                location.reload();
                            } else {
                                alert('Error: ' + (data.message || 'Gagal menghapus sesi'));
                            }
                        });
                    }
                });
            });
        });
    </script>
</body>
</html>

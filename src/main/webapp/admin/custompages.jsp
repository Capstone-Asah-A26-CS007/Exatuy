<%@ page contentType="text/html;charset=UTF-8" language="java" %>
<%@ page import="com.examora.model.User" %>
<%@ page import="com.examora.model.CustomPage" %>
<%@ page import="com.examora.util.ValidationUtil" %>
<%@ page import="java.util.List" %>
<%
    User currentUser = (User) session.getAttribute("user");
    if (currentUser == null || !currentUser.isAdmin()) {
        response.sendRedirect("../LoginServlet");
        return;
    }

    List<CustomPage> customPages = (List<CustomPage>) request.getAttribute("customPages");
    if (customPages == null) customPages = List.of();

    @SuppressWarnings("unchecked")
    List<String> allTags = (List<String>) request.getAttribute("allTags");
    if (allTags == null) allTags = java.util.List.of();

    String success = (String) request.getAttribute("success");
    String error = (String) request.getAttribute("error");
%>
<!DOCTYPE html>
<html lang="id">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Kelola Menu - Admin Exatuy</title>
    <link href="https://cdn.jsdelivr.net/npm/bootstrap@5.3.0/dist/css/bootstrap.min.css" rel="stylesheet">
    <link href="https://cdn.jsdelivr.net/npm/bootstrap-icons@1.10.0/font/bootstrap-icons.css" rel="stylesheet">
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
                <h1 class="h3 mb-0">Kelola Menu</h1>
                <nav aria-label="breadcrumb">
                    <ol class="breadcrumb mb-0">
                        <li class="breadcrumb-item"><a href="../AdminServlet?action=dashboard">Dashboard</a></li>
                        <li class="breadcrumb-item active">Kelola Menu</li>
                    </ol>
                </nav>
            </div>
            <button class="btn btn-primary" data-bs-toggle="modal" data-bs-target="#createModal">
                <i class="bi bi-plus-lg me-2"></i>Tambah Menu
            </button>
        </div>

        <% if (success != null) { %>
        <div class="alert alert-success alert-dismissible fade show">
            <i class="bi bi-check-circle me-2"></i><%= ValidationUtil.sanitizeHtml(success) %>
            <button type="button" class="btn-close" data-bs-dismiss="alert"></button>
        </div>
        <% } %>

        <% if (error != null) { %>
        <div class="alert alert-danger alert-dismissible fade show">
            <i class="bi bi-exclamation-triangle me-2"></i><%= ValidationUtil.sanitizeHtml(error) %>
            <button type="button" class="btn-close" data-bs-dismiss="alert"></button>
        </div>
        <% } %>

        <!-- Stats -->
        <div class="row mb-4">
            <div class="col-md-4">
                <div class="card border-primary">
                    <div class="card-body">
                        <div class="d-flex align-items-center">
                            <div class="fs-1 text-primary me-3">
                                <i class="bi bi-link-45deg"></i>
                            </div>
                            <div>
                                <h6 class="text-muted mb-0">Total Menu</h6>
                                <h3 class="mb-0"><%= customPages.size() %></h3>
                            </div>
                        </div>
                    </div>
                </div>
            </div>
            <div class="col-md-4">
                <div class="card border-success">
                    <div class="card-body">
                        <div class="d-flex align-items-center">
                            <div class="fs-1 text-success me-3">
                                <i class="bi bi-check-circle-fill"></i>
                            </div>
                            <div>
                                <h6 class="text-muted mb-0">Aktif</h6>
                                <h3 class="mb-0"><%= customPages.stream().filter(CustomPage::getIsActive).count() %></h3>
                            </div>
                        </div>
                    </div>
                </div>
            </div>
            <div class="col-md-4">
                <div class="card border-secondary">
                    <div class="card-body">
                        <div class="d-flex align-items-center">
                            <div class="fs-1 text-secondary me-3">
                                <i class="bi bi-x-circle-fill"></i>
                            </div>
                            <div>
                                <h6 class="text-muted mb-0">Tidak Aktif</h6>
                                <h3 class="mb-0"><%= customPages.stream().filter(p -> !p.getIsActive()).count() %></h3>
                            </div>
                        </div>
                    </div>
                </div>
            </div>
        </div>

        <!-- Table -->
        <div class="card">
            <div class="card-header">
                <div class="row align-items-center">
                    <div class="col">
                        <h5 class="mb-0">Daftar Menu</h5>
                    </div>
                    <div class="col-auto">
                        <input type="text" class="form-control form-control-sm" id="searchMenu" placeholder="Cari menu..." style="width: 200px;">
                    </div>
                </div>
            </div>
            <div class="card-body">
                <% if (customPages.isEmpty()) { %>
                <div class="text-center py-5">
                    <i class="bi bi-link-45deg display-4 text-muted"></i>
                    <p class="text-muted mt-3">Belum ada menu yang ditambahkan</p>
                    <button class="btn btn-primary" data-bs-toggle="modal" data-bs-target="#createModal">
                        <i class="bi bi-plus-lg me-2"></i>Tambah Menu Pertama
                    </button>
                </div>
                <% } else { %>
                <div class="table-responsive">
                    <table class="table table-hover" id="menuTable">
                        <thead>
                            <tr>
                                <th width="40">Urutan</th>
                                <th>Icon</th>
                                <th>Nama Menu</th>
                                <th>Link</th>
                                <th>Tag Peserta</th>
                                <th>Komentar Admin</th>
                                <th>Status</th>
                                <th>Dibuat</th>
                                <th width="160">Aksi</th>
                            </tr>
                        </thead>
                        <tbody>
                            <% for (CustomPage cp : customPages) { %>
                            <tr data-name="<%= ValidationUtil.sanitizeHtml(cp.getMenuName().toLowerCase()) %>">
                                <td><span class="badge bg-primary"><%= cp.getSortOrder() != null ? cp.getSortOrder() : 0 %></span></td>
                                <td><i class="bi <%= ValidationUtil.sanitizeHtml(cp.getIconClass()) %> fs-5"></i></td>
                                <td><strong><%= ValidationUtil.sanitizeHtml(cp.getMenuName()) %></strong></td>
                                <td>
                                    <a href="<%= ValidationUtil.sanitizeHtml(cp.getMenuLink()) %>" target="_blank" class="text-truncate d-inline-block" style="max-width: 250px;">
                                        <%= ValidationUtil.sanitizeHtml(cp.getMenuLink()) %>
                                        <i class="bi bi-box-arrow-upright small"></i>
                                    </a>
                                </td>
                                <td>
                                    <% if (cp.getTargetTag() != null && !cp.getTargetTag().trim().isEmpty()) { %>
                                        <span class="badge bg-info text-dark"><%= ValidationUtil.sanitizeHtml(cp.getTargetTag()) %></span>
                                    <% } else { %>
                                        <span class="badge bg-secondary">Semua</span>
                                    <% } %>
                                </td>
                                <td>
                                    <% if (cp.getAdminComment() != null && !cp.getAdminComment().trim().isEmpty()) { %>
                                        <span class="text-muted small" title="<%= ValidationUtil.sanitizeHtml(cp.getAdminComment()) %>">
                                            <i class="bi bi-sticky-note-fill me-1 text-warning"></i>
                                            <%= ValidationUtil.sanitizeHtml(cp.getAdminComment().length() > 60 ? cp.getAdminComment().substring(0, 60) + "..." : cp.getAdminComment()) %>
                                        </span>
                                    <% } else { %>
                                        <span class="text-muted">&ndash;</span>
                                    <% } %>
                                </td>
                                <td><%= cp.getStatusBadge() %></td>
                                <td><%= cp.getFormattedCreatedAt() %></td>
                                <td>
                                    <div class="btn-group btn-group-sm">
                                        <button class="btn btn-outline-primary" onclick="editPage(<%= cp.getId() %>)" title="Edit">
                                            <i class="bi bi-pencil"></i>
                                        </button>
                                        <button class="btn btn-outline-warning" onclick="toggleStatus(<%= cp.getId() %>)" title="<%= cp.getIsActive() ? "Nonaktifkan" : "Aktifkan" %>">
                                            <i class="bi bi-<%= cp.getIsActive() ? "eye-slash" : "eye" %>"></i>
                                        </button>
                                        <button class="btn btn-outline-danger" onclick="deletePage(<%= cp.getId() %>, '<%= ValidationUtil.sanitizeHtml(ValidationUtil.sanitizeJs(cp.getMenuName())) %>')" title="Hapus">
                                            <i class="bi bi-trash"></i>
                                        </button>
                                    </div>
                                </td>
                            </tr>
                            <% } %>
                        </tbody>
                    </table>
                </div>
                <% } %>
            </div>
        </div>
    </div>

    <!-- Create Modal -->
    <div class="modal fade" id="createModal" tabindex="-1">
        <div class="modal-dialog">
            <div class="modal-content">
                <div class="modal-header">
                    <h5 class="modal-title"><i class="bi bi-plus-circle me-2"></i>Tambah Menu Baru</h5>
                    <button type="button" class="btn-close" data-bs-dismiss="modal"></button>
                </div>
                <form action="../CustomPageServlet" method="post">
                    <div class="modal-body">
                        <input type="hidden" name="action" value="create">
                        <input type="hidden" name="csrfToken" value="<%= session.getAttribute("csrfToken") != null ? session.getAttribute("csrfToken") : "" %>">
                        <div class="mb-3">
                            <label class="form-label">Nama Menu *</label>
                            <input type="text" class="form-control" name="menuName" required
                                   placeholder="Contoh: Google Classroom">
                        </div>
                        <div class="mb-3">
                            <label class="form-label">Link URL *</label>
                            <input type="url" class="form-control" name="menuLink" required
                                   placeholder="https://example.com">
                        </div>
                        <div class="mb-3">
                            <label class="form-label">Icon <span class="text-muted">(opsional)</span></label>
                            <input type="text" class="form-control" name="icon"
                                   placeholder="bi-link-45deg" value="bi-link-45deg">
                            <div class="form-text">Bootstrap icon class, contoh: bi-google, bi-book, bi-globe</div>
                        </div>
                        <div class="mb-3">
                            <label class="form-label">Urutan <span class="text-muted">(opsional)</span></label>
                            <input type="number" class="form-control" name="sortOrder" value="0" min="0">
                            <div class="form-text">Angka lebih kecil ditampilkan lebih dulu</div>
                        </div>
                        <div class="mb-3">
                            <label class="form-label">Tag Peserta <span class="text-muted">(opsional)</span></label>
                            <select class="form-select" name="targetTag">
                                <option value="">Semua Tag (tampil ke semua peserta)</option>
                                <% for (String tag : allTags) { %>
                                <option value="<%= ValidationUtil.sanitizeHtml(tag) %>"><%= ValidationUtil.sanitizeHtml(tag) %></option>
                                <% } %>
                            </select>
                            <div class="form-text">Menu hanya akan tampil ke peserta dengan tag terpilih</div>
                        </div>
                        <div class="mb-3">
                            <label class="form-label">Komentar Admin <span class="text-muted badge bg-warning text-dark ms-1">admin-only</span></label>
                            <textarea class="form-control" name="adminComment" rows="2" placeholder="Catatan internal, tidak terlihat oleh peserta..."></textarea>
                            <div class="form-text">Hanya tampil di halaman admin ini, tidak pernah dilihat peserta</div>
                        </div>
                    </div>
                    <div class="modal-footer">
                        <button type="button" class="btn btn-secondary" data-bs-dismiss="modal">Batal</button>
                        <button type="submit" class="btn btn-primary">
                            <i class="bi bi-plus-lg me-2"></i>Tambah Menu
                        </button>
                    </div>
                </form>
            </div>
        </div>
    </div>

    <!-- Edit Modal -->
    <div class="modal fade" id="editModal" tabindex="-1">
        <div class="modal-dialog">
            <div class="modal-content">
                <div class="modal-header">
                    <h5 class="modal-title"><i class="bi bi-pencil me-2"></i>Edit Menu</h5>
                    <button type="button" class="btn-close" data-bs-dismiss="modal"></button>
                </div>
                <form action="../CustomPageServlet" method="post">
                    <div class="modal-body">
                        <input type="hidden" name="action" value="update">
                        <input type="hidden" name="id" id="editId">
                        <input type="hidden" name="csrfToken" value="<%= session.getAttribute("csrfToken") != null ? session.getAttribute("csrfToken") : "" %>">
                        <div class="mb-3">
                            <label class="form-label">Nama Menu *</label>
                            <input type="text" class="form-control" name="menuName" id="editMenuName" required>
                        </div>
                        <div class="mb-3">
                            <label class="form-label">Link URL *</label>
                            <input type="url" class="form-control" name="menuLink" id="editMenuLink" required>
                        </div>
                        <div class="mb-3">
                            <label class="form-label">Icon <span class="text-muted">(opsional)</span></label>
                            <input type="text" class="form-control" name="icon" id="editIcon">
                            <div class="form-text">Bootstrap icon class, contoh: bi-google, bi-book, bi-globe</div>
                        </div>
                        <div class="mb-3">
                            <label class="form-label">Urutan <span class="text-muted">(opsional)</span></label>
                            <input type="number" class="form-control" name="sortOrder" id="editSortOrder" min="0">
                        </div>
                        <div class="mb-3">
                            <label class="form-label">Tag Peserta <span class="text-muted">(opsional)</span></label>
                            <select class="form-select" name="targetTag" id="editTargetTag">
                                <option value="">Semua Tag (tampil ke semua peserta)</option>
                                <% for (String tag : allTags) { %>
                                <option value="<%= ValidationUtil.sanitizeHtml(tag) %>"><%= ValidationUtil.sanitizeHtml(tag) %></option>
                                <% } %>
                            </select>
                            <div class="form-text">Menu hanya akan tampil ke peserta dengan tag terpilih</div>
                        </div>
                        <div class="mb-3">
                            <label class="form-label">Komentar Admin <span class="text-muted badge bg-warning text-dark ms-1">admin-only</span></label>
                            <textarea class="form-control" name="adminComment" id="editAdminComment" rows="2" placeholder="Catatan internal, tidak terlihat oleh peserta..."></textarea>
                            <div class="form-text">Hanya tampil di halaman admin ini, tidak pernah dilihat peserta</div>
                        </div>
                    </div>
                    <div class="modal-footer">
                        <button type="button" class="btn btn-secondary" data-bs-dismiss="modal">Batal</button>
                        <button type="submit" class="btn btn-primary">
                            <i class="bi bi-check-lg me-2"></i>Simpan
                        </button>
                    </div>
                </form>
            </div>
        </div>
    </div>

    <script src="https://cdn.jsdelivr.net/npm/bootstrap@5.3.0/dist/js/bootstrap.bundle.min.js"></script>
    <script>
        document.getElementById('searchMenu').addEventListener('input', function() {
            const search = this.value.toLowerCase();
            document.querySelectorAll('#menuTable tbody tr').forEach(row => {
                const name = row.dataset.name;
                row.style.display = name.includes(search) ? '' : 'none';
            });
        });

        function editPage(id) {
            fetch('../CustomPageServlet?action=getDetail&id=' + id)
                .then(response => response.json())
                .then(data => {
                    if (!data || data.error) {
                        alert('Gagal memuat data: ' + (data.error || 'Unknown error'));
                        return;
                    }
                    document.getElementById('editId').value = data.id;
                    document.getElementById('editMenuName').value = data.menuName || '';
                    document.getElementById('editMenuLink').value = data.menuLink || '';
                    document.getElementById('editIcon').value = data.icon || '';
                    document.getElementById('editSortOrder').value = data.sortOrder || 0;
                    document.getElementById('editTargetTag').value = data.targetTag || '';
                    document.getElementById('editAdminComment').value = data.adminComment || '';
                    var modal = new bootstrap.Modal(document.getElementById('editModal'));
                    modal.show();
                })
                .catch(error => {
                    alert('Gagal memuat data: ' + error.message);
                });
        }

        function toggleStatus(id) {
            if (confirm('Ubah status menu ini?')) {
                var form = document.createElement('form');
                form.method = 'POST';
                form.action = '../CustomPageServlet';
                var csrfToken = '<%= session.getAttribute("csrfToken") != null ? session.getAttribute("csrfToken") : "" %>';
                form.innerHTML = '<input type="hidden" name="action" value="toggleStatus">' +
                                 '<input type="hidden" name="id" value="' + id + '">' +
                                 '<input type="hidden" name="csrfToken" value="' + csrfToken + '">';
                document.body.appendChild(form);
                form.submit();
            }
        }

        function deletePage(id, name) {
            if (confirm('Hapus menu "' + name + '"?')) {
                var form = document.createElement('form');
                form.method = 'POST';
                form.action = '../CustomPageServlet';
                var csrfToken = '<%= session.getAttribute("csrfToken") != null ? session.getAttribute("csrfToken") : "" %>';
                form.innerHTML = '<input type="hidden" name="action" value="delete">' +
                                 '<input type="hidden" name="id" value="' + id + '">' +
                                 '<input type="hidden" name="csrfToken" value="' + csrfToken + '">';
                document.body.appendChild(form);
                form.submit();
            }
        }
    </script>
</body>
</html>

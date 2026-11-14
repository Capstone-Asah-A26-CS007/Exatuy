<%@ page contentType="text/html;charset=UTF-8" language="java" %>
<%@ taglib prefix="c" uri="http://java.sun.com/jsp/jstl/core" %>
<%@ page import="com.examora.model.User" %>
<%@ page import="com.examora.model.Material" %>
<%@ page import="com.examora.model.MaterialCategory" %>
<%@ page import="java.util.List" %>
<%
    User currentUser = (User) session.getAttribute("user");
    if (currentUser == null) { response.sendRedirect("../LoginServlet"); return; }
    boolean isPriv = currentUser.isAdmin() || "owner".equals(currentUser.getRole()) || "pengajar".equals(currentUser.getRole());
    if (!isPriv) { response.sendRedirect("../MateriServlet"); return; }

    List<Material> materials = (List<Material>) request.getAttribute("materials");
    List<MaterialCategory> categories = (List<MaterialCategory>) request.getAttribute("categories");
    String success = (String) session.getAttribute("flashSuccess");
    String error = (String) session.getAttribute("flashError");
    if (success != null) session.removeAttribute("flashSuccess");
    if (error != null) session.removeAttribute("flashError");
%>
<!DOCTYPE html>
<html lang="id">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Materi &amp; Silabus - Exatuy</title>
    <link href="https://cdn.jsdelivr.net/npm/bootstrap@5.3.2/dist/css/bootstrap.min.css" rel="stylesheet">
    <link href="https://cdn.jsdelivr.net/npm/bootstrap-icons@1.11.1/font/bootstrap-icons.css" rel="stylesheet">
    <link href="../assets/css/style.css" rel="stylesheet">
    <link rel="icon" type="image/svg+xml" href="../assets/img/favicon.svg?v=4">
<link href="../assets/css/handdrawn.css" rel="stylesheet">
</head>
<body>
    <%@ include file="sidebar.jsp" %>

    <div class="main-content">
        <div class="d-flex justify-content-between align-items-center mb-4">
            <div>
                <h1 class="h3 mb-0">Materi &amp; Silabus</h1>
                <p class="text-muted mb-0">Kelola repositori modul belajar per jenjang dan mata pelajaran</p>
            </div>
            <div class="d-flex gap-2">
                <button class="btn btn-outline-primary" data-bs-toggle="modal" data-bs-target="#generateModal">
                    <i class="bi bi-magic me-2"></i>Generate Silabus
                </button>
                <button class="btn btn-primary" data-bs-toggle="modal" data-bs-target="#uploadModal">
                    <i class="bi bi-cloud-upload me-2"></i>Upload Materi
                </button>
            </div>
        </div>

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

        <!-- Categories summary -->
        <div class="row g-3 mb-4">
            <% if (categories != null) { for (MaterialCategory cat : categories) {
                 int count = 0;
                 if (materials != null) for (Material m : materials) if (m.getCategoryId() != null && m.getCategoryId().equals(cat.getId())) count++;
            %>
            <div class="col-lg-3 col-md-4 col-sm-6">
                <div class="card h-100">
                    <div class="card-body">
                        <div class="d-flex justify-content-between align-items-start mb-2">
                            <span class="badge badge-primary"><%= cat.getJenjang() %></span>
                            <span class="badge bg-secondary"><%= count %> materi</span>
                        </div>
                        <h6 class="fw-bold mb-1"><%= cat.getNama() %></h6>
                        <p class="small text-muted mb-0"><%= cat.getMataPelajaran() != null ? cat.getMataPelajaran() : "Umum" %></p>
                    </div>
                </div>
            </div>
            <% } } %>
        </div>

        <!-- Materials table -->
        <div class="card">
            <div class="card-header">
                <h6 class="mb-0"><i class="bi bi-folder2-open me-2"></i>Daftar Materi (<%= materials != null ? materials.size() : 0 %>)</h6>
            </div>
            <div class="card-body p-0">
                <% if (materials == null || materials.isEmpty()) { %>
                <div class="empty-state">
                    <i class="bi bi-folder-x"></i>
                    <h3>Belum ada materi</h3>
                    <p>Upload materi atau generate silabus untuk memulai.</p>
                </div>
                <% } else { %>
                <div class="table-responsive">
                    <table class="table table-hover mb-0">
                        <thead>
                            <tr>
                                <th>Judul</th>
                                <th>Kategori</th>
                                <th>Tipe</th>
                                <th>Target Tag</th>
                                <th>Views</th>
                                <th>Aksi</th>
                            </tr>
                        </thead>
                        <tbody>
                        <% for (Material m : materials) { %>
                            <tr>
                                <td>
                                    <a href="../MateriServlet?action=view&id=<%= m.getId() %>" class="fw-semibold text-decoration-none">
                                        <%= m.getTitle() %>
                                    </a>
                                    <% if (m.getIsGenerated() != null && m.getIsGenerated()) { %>
                                    <span class="badge bg-info ms-1">auto</span>
                                    <% } %>
                                </td>
                                <td><%= m.getCategoryName() != null ? m.getCategoryName() : "-" %></td>
                                <td><span class="badge bg-secondary"><%= m.getFileType() != null ? m.getFileType() : "text" %></span></td>
                                <td>
                                    <% if (m.getTargetTags() == null || m.getTargetTags().trim().isEmpty()) { %>
                                    <span class="badge badge-success">Semua</span>
                                    <% } else { %>
                                    <span class="badge badge-warning"><%= m.getTargetTags() %></span>
                                    <% } %>
                                </td>
                                <td><%= m.getViewCount() != null ? m.getViewCount() : 0 %></td>
                                <td>
                                    <form action="../MateriServlet" method="post" class="d-inline"
                                          onsubmit="return confirm('Hapus materi ini?');">
                                        <input type="hidden" name="csrfToken" value="<%= session.getAttribute("csrfToken") %>">
                                        <input type="hidden" name="action" value="delete">
                                        <input type="hidden" name="id" value="<%= m.getId() %>">
                                        <button type="submit" class="btn btn-sm btn-outline-danger">
                                            <i class="bi bi-trash"></i>
                                        </button>
                                    </form>
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

    <!-- Upload Modal -->
    <div class="modal fade" id="uploadModal" tabindex="-1">
        <div class="modal-dialog modal-lg">
            <div class="modal-content">
                <form action="../MateriServlet" method="post" enctype="multipart/form-data">
                    <input type="hidden" name="csrfToken" value="<%= session.getAttribute("csrfToken") %>">
                    <input type="hidden" name="action" value="create">
                    <div class="modal-header">
                        <h6 class="modal-title"><i class="bi bi-cloud-upload me-2"></i>Upload Materi Baru</h6>
                        <button type="button" class="btn-close" data-bs-dismiss="modal"></button>
                    </div>
                    <div class="modal-body">
                        <div class="mb-3">
                            <label class="form-label">Kategori <span class="text-danger">*</span></label>
                            <select class="form-select" name="category_id" required>
                                <option value="">-- Pilih Kategori --</option>
                                <% if (categories != null) { for (MaterialCategory cat : categories) { %>
                                <option value="<%= cat.getId() %>"><%= cat.getNama() %> (<%= cat.getJenjang() %>)</option>
                                <% } } %>
                            </select>
                        </div>
                        <div class="mb-3">
                            <label class="form-label">Judul Materi <span class="text-danger">*</span></label>
                            <input type="text" class="form-control" name="title" required
                                   placeholder="Contoh: Modul Matematika Bab 1 - Bilangan Bulat">
                        </div>
                        <div class="mb-3">
                            <label class="form-label">Target Tag / Kelas</label>
                            <input type="text" class="form-control" name="target_tags"
                                   placeholder="Contoh: SD, Kelas A (pisahkan dengan koma)">
                            <div class="form-text">Kosongkan jika materi berlaku untuk semua siswa</div>
                        </div>
                        <div class="mb-3">
                            <label class="form-label">Tipe File</label>
                            <select class="form-select" name="file_type">
                                <option value="pdf">PDF</option>
                                <option value="doc">DOC</option>
                                <option value="docx">DOCX</option>
                                <option value="link">Link Eksternal</option>
                                <option value="text">Teks / Artikel</option>
                                <option value="image">Gambar</option>
                            </select>
                        </div>
                        <div class="mb-3">
                            <label class="form-label">Ringkasan</label>
                            <textarea class="form-control" name="summary" rows="2"
                                      placeholder="Deskripsi singkat materi"></textarea>
                        </div>
                        <div class="mb-3">
                            <label class="form-label">Konten / Artikel Bacaan</label>
                            <textarea class="form-control" name="content" rows="6"
                                      placeholder="Tulis artikel bacaan atau isi materi di sini (opsional jika upload file)"></textarea>
                        </div>
                        <div class="mb-3">
                            <label class="form-label">File (opsional)</label>
                            <input type="file" class="form-control" name="file"
                                   accept=".pdf,.doc,.docx,.jpg,.png">
                            <div class="form-text">Maksimal 50 MB</div>
                        </div>
                    </div>
                    <div class="modal-footer">
                        <button type="button" class="btn btn-secondary" data-bs-dismiss="modal">Batal</button>
                        <button type="submit" class="btn btn-primary">
                            <i class="bi bi-check-lg me-2"></i>Simpan Materi
                        </button>
                    </div>
                </form>
            </div>
        </div>
    </div>

    <!-- Generate Modal -->
    <div class="modal fade" id="generateModal" tabindex="-1">
        <div class="modal-dialog">
            <div class="modal-content">
                <form action="../MateriServlet" method="post">
                    <input type="hidden" name="csrfToken" value="<%= session.getAttribute("csrfToken") %>">
                    <input type="hidden" name="action" value="generate">
                    <div class="modal-header">
                        <h6 class="modal-title"><i class="bi bi-magic me-2"></i>Generate Silabus Otomatis</h6>
                        <button type="button" class="btn-close" data-bs-dismiss="modal"></button>
                    </div>
                    <div class="modal-body">
                        <div class="alert alert-info py-2">
                            <small><i class="bi bi-info-circle me-1"></i>
                            Sistem akan membuat template silabus lengkap otomatis berdasarkan kategori yang dipilih.</small>
                        </div>
                        <div class="mb-3">
                            <label class="form-label">Kategori Silabus <span class="text-danger">*</span></label>
                            <select class="form-select" name="category_id" id="genCategory" required>
                                <option value="">-- Pilih Kategori --</option>
                                <% if (categories != null) { for (MaterialCategory cat : categories) { %>
                                <option value="<%= cat.getId() %>"
                                        data-jenjang="<%= cat.getJenjang() %>"
                                        data-mapel="<%= cat.getMataPelajaran() != null ? cat.getMataPelajaran() : "Umum" %>">
                                    <%= cat.getNama() %>
                                </option>
                                <% } } %>
                            </select>
                        </div>
                        <input type="hidden" name="jenjang" id="genJenjang">
                        <input type="hidden" name="mata_pelajaran" id="genMapel">
                    </div>
                    <div class="modal-footer">
                        <button type="button" class="btn btn-secondary" data-bs-dismiss="modal">Batal</button>
                        <button type="submit" class="btn btn-primary">
                            <i class="bi bi-magic me-2"></i>Generate Sekarang
                        </button>
                    </div>
                </form>
            </div>
        </div>
    </div>

    <script src="https://cdn.jsdelivr.net/npm/bootstrap@5.3.2/dist/js/bootstrap.bundle.min.js"></script>
    <script>
        var genCat = document.getElementById('genCategory');
        if (genCat) {
            genCat.addEventListener('change', function() {
                var opt = this.options[this.selectedIndex];
                document.getElementById('genJenjang').value = opt.getAttribute('data-jenjang') || '';
                document.getElementById('genMapel').value = opt.getAttribute('data-mapel') || '';
            });
        }
    </script>
</body>
</html>

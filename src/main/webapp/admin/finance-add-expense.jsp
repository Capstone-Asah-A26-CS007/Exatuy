<%@ page contentType="text/html;charset=UTF-8" language="java" %>
<%@ page import="com.examora.model.User" %>
<%
    User currentUser = (User) session.getAttribute("user");
    if (currentUser == null || (!currentUser.isAdmin() && !"owner".equals(currentUser.getRole()))) {
        response.sendRedirect("../LoginServlet");
        return;
    }
%>
<!DOCTYPE html>
<html lang="id">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Catat Pengeluaran - Exatuy</title>
    <link href="https://cdn.jsdelivr.net/npm/bootstrap@5.3.2/dist/css/bootstrap.min.css" rel="stylesheet">
    <link href="https://cdn.jsdelivr.net/npm/bootstrap-icons@1.11.1/font/bootstrap-icons.css" rel="stylesheet">
    <link href="../assets/css/style.css" rel="stylesheet">
    <link rel="icon" type="image/svg+xml" href="../assets/img/favicon.svg?v=4">
<link href="../assets/css/handdrawn.css" rel="stylesheet">
</head>
<body>
    <%@ include file="sidebar.jsp" %>

    <div class="main-content">
        <div class="mb-4">
            <h1 class="h3 mb-0">Catat Pengeluaran</h1>
            <nav aria-label="breadcrumb">
                <ol class="breadcrumb mb-0">
                    <li class="breadcrumb-item"><a href="../FinanceServlet?action=summary">Keuangan</a></li>
                    <li class="breadcrumb-item active">Catat</li>
                </ol>
            </nav>
        </div>

        <div class="row">
            <div class="col-lg-7">
                <div class="card">
                    <div class="card-body">
                        <form action="../FinanceServlet" method="post">
                            <input type="hidden" name="csrfToken" value="<%= session.getAttribute("csrfToken") %>">
                            <input type="hidden" name="action" value="saveExpense">

                            <div class="mb-3">
                                <label class="form-label">Kategori <span class="text-danger">*</span></label>
                                <select class="form-select" name="kategori" required>
                                    <option value="">-- Pilih Kategori --</option>
                                    <option value="Gaji Guru">Gaji Guru / Tutor</option>
                                    <option value="Modul/ATK">Modul / Alat Tulis</option>
                                    <option value="Sewa Tempat">Sewa Tempat</option>
                                    <option value="Listrik/Air">Listrik / Air / Internet</option>
                                    <option value="Lainnya">Lainnya</option>
                                </select>
                            </div>

                            <div class="mb-3">
                                <label class="form-label">Nominal (Rp) <span class="text-danger">*</span></label>
                                <input type="number" class="form-control" name="nominal" min="0" step="1000"
                                       required placeholder="Contoh: 500000">
                                <div class="form-text">Masukkan angka tanpa titik atau koma</div>
                            </div>

                            <div class="mb-3">
                                <label class="form-label">Tanggal <span class="text-danger">*</span></label>
                                <input type="date" class="form-control" name="tanggal" required>
                            </div>

                            <div class="mb-3">
                                <label class="form-label">Deskripsi</label>
                                <textarea class="form-control" name="deskripsi" rows="3"
                                          placeholder="Keterangan pengeluaran (opsional)"></textarea>
                            </div>

                            <div class="d-flex gap-2">
                                <button type="submit" class="btn btn-primary">
                                    <i class="bi bi-check-lg me-2"></i>Simpan
                                </button>
                                <a href="../FinanceServlet?action=summary" class="btn btn-outline-secondary">
                                    <i class="bi bi-x-lg me-2"></i>Batal
                                </a>
                            </div>
                        </form>
                    </div>
                </div>
            </div>

            <div class="col-lg-5">
                <div class="card">
                    <div class="card-header">
                        <h6 class="mb-0"><i class="bi bi-info-circle me-2"></i>Kategori Umum</h6>
                    </div>
                    <div class="card-body">
                        <div class="mb-3">
                            <span class="expense-tag gaji"><i class="bi bi-person-badge"></i> Gaji Guru</span>
                            <p class="small text-muted mt-1 mb-0">Honor pengajar/tutor per sesi atau per bulan</p>
                        </div>
                        <div class="mb-3">
                            <span class="expense-tag modul"><i class="bi bi-book"></i> Modul / ATK</span>
                            <p class="small text-muted mt-1 mb-0">Cetak modul, spidol, kertas, alat tulis</p>
                        </div>
                        <div class="mb-3">
                            <span class="expense-tag sewa"><i class="bi bi-building"></i> Sewa Tempat</span>
                            <p class="small text-muted mt-1 mb-0">Sewa ruang kelas atau gedung</p>
                        </div>
                    </div>
                </div>
            </div>
        </div>
    </div>

    <script src="https://cdn.jsdelivr.net/npm/bootstrap@5.3.2/dist/js/bootstrap.bundle.min.js"></script>
</body>
</html>

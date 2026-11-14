<%@ page contentType="text/html;charset=UTF-8" language="java" %>
<%@ taglib prefix="c" uri="http://java.sun.com/jsp/jstl/core" %>
<%@ page import="com.examora.model.User" %>
<%@ page import="com.examora.model.SessionPackage" %>
<%@ page import="com.examora.model.Invoice" %>
<%@ page import="java.util.List" %>
<%@ page import="java.math.BigDecimal" %>
<%
    User currentUser = (User) session.getAttribute("user");
    if (currentUser == null || (!currentUser.isAdmin() && !"owner".equals(currentUser.getRole()))) {
        response.sendRedirect("../LoginServlet");
        return;
    }
    List<User> siswaList = (List<User>) request.getAttribute("siswaList");
    List<SessionPackage> packages = (List<SessionPackage>) request.getAttribute("packages");
%>
<!DOCTYPE html>
<html lang="id">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Buat Invoice - Exatuy</title>
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
            <h1 class="h3 mb-0">Buat Invoice Baru</h1>
            <nav aria-label="breadcrumb">
                <ol class="breadcrumb mb-0">
                    <li class="breadcrumb-item"><a href="../AdminServlet?action=dashboard">Dashboard</a></li>
                    <li class="breadcrumb-item"><a href="../BillingServlet?action=list">Tagihan</a></li>
                    <li class="breadcrumb-item active">Buat</li>
                </ol>
            </nav>
        </div>

        <div class="row">
            <div class="col-lg-8">
                <div class="card">
                    <div class="card-body">
                        <form action="../BillingServlet" method="post">
                            <input type="hidden" name="csrfToken" value="<%= session.getAttribute("csrfToken") %>">
                            <input type="hidden" name="action" value="create">

                            <div class="mb-3">
                                <label class="form-label">Siswa <span class="text-danger">*</span></label>
                                <select class="form-select" name="student_id" required>
                                    <option value="">-- Pilih Siswa --</option>
                                    <% if (siswaList != null) { for (User s : siswaList) { %>
                                    <option value="<%= s.getId() %>"><%= s.getName() %> (<%= s.getEmail() %>)</option>
                                    <% } } %>
                                </select>
                            </div>

                            <div class="mb-3">
                                <label class="form-label">Paket Sesi Belajar <span class="text-danger">*</span></label>
                                <select class="form-select" name="package_id" id="packageSelect" required>
                                    <option value="">-- Pilih Paket --</option>
                                    <% if (packages != null) { for (SessionPackage p : packages) {
                                         String pre = (String) request.getAttribute("preselectedPackageId");
                                         boolean sel = pre != null && pre.equals(String.valueOf(p.getId()));
                                    %>
                                    <option value="<%= p.getId() %>" data-harga="<%= p.getHarga() %>" <%= sel ? "selected" : "" %>>
                                        <%= p.getNamaPaket() %> — <%= p.getJumlahSesi() %> sesi — Rp <%= String.format("%,.0f", p.getHarga()) %>
                                    </option>
                                    <% } } %>
                                </select>
                            </div>

                            <div class="mb-3">
                                <label class="form-label">Jatuh Tempo <span class="text-danger">*</span></label>
                                <input type="date" class="form-control" name="due_date" required>
                                <div class="form-text">Batas waktu pembayaran tagihan</div>
                            </div>

                            <div class="mb-3">
                                <label class="form-label">Catatan</label>
                                <textarea class="form-control" name="notes" rows="3" placeholder="Catatan tambahan (opsional)"></textarea>
                            </div>

                            <div class="d-flex gap-2">
                                <button type="submit" class="btn btn-primary">
                                    <i class="bi bi-check-lg me-2"></i>Simpan Invoice
                                </button>
                                <a href="../BillingServlet?action=list" class="btn btn-outline-secondary">
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
                        <h6 class="mb-0"><i class="bi bi-lightbulb me-2"></i>Panduan</h6>
                    </div>
                    <div class="card-body">
                        <ul class="list-unstyled mb-0">
                            <li class="mb-2"><i class="bi bi-check text-success me-2"></i>Pilih siswa yang akan ditagih</li>
                            <li class="mb-2"><i class="bi bi-check text-success me-2"></i>Pilih paket sesi sesuai kebutuhan</li>
                            <li class="mb-2"><i class="bi bi-check text-success me-2"></i>Set jatuh tempo pembayaran</li>
                            <li class="mb-2"><i class="bi bi-check text-success me-2"></i>Invoice akan berstatus "Belum Lunas"</li>
                            <li class="mb-2"><i class="bi bi-check text-success me-2"></i>Tandai lunas setelah pembayaran diterima</li>
                        </ul>
                    </div>
                </div>
            </div>
        </div>
    </div>

    <script src="https://cdn.jsdelivr.net/npm/bootstrap@5.3.2/dist/js/bootstrap.bundle.min.js"></script>
</body>
</html>

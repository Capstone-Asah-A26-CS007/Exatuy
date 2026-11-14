<%@ page contentType="text/html;charset=UTF-8" language="java" %>
<%@ taglib prefix="c" uri="http://java.sun.com/jsp/jstl/core" %>
<%@ taglib prefix="fmt" uri="http://java.sun.com/jsp/jstl/fmt" %>
<%@ page import="com.examora.model.User" %>
<%@ page import="com.examora.model.Invoice" %>
<%@ page import="java.util.List" %>
<%@ page import="java.math.BigDecimal" %>
<%
    User currentUser = (User) session.getAttribute("user");
    if (currentUser == null || (!currentUser.isAdmin() && !"owner".equals(currentUser.getRole()))) {
        response.sendRedirect("../LoginServlet");
        return;
    }
    List<Invoice> invoices = (List<Invoice>) request.getAttribute("invoices");
    List<Invoice> belumLunas = (List<Invoice>) request.getAttribute("belumLunas");
    List<Invoice> menunggu = (List<Invoice>) request.getAttribute("menunggu");
    List<Invoice> lunas = (List<Invoice>) request.getAttribute("lunas");
    BigDecimal totalBelum = (BigDecimal) request.getAttribute("totalBelumLunasAmount");
    BigDecimal totalLunasAmt = (BigDecimal) request.getAttribute("totalLunasAmount");
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
    <title>Tagihan - Exatuy</title>
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
                <h1 class="h3 mb-0">Tagihan &amp; Invoice</h1>
                <p class="text-muted mb-0">Kelola tagihan SPP dan paket sesi belajar</p>
            </div>
            <a href="../BillingServlet?action=create" class="btn btn-primary">
                <i class="bi bi-plus-lg me-2"></i>Buat Invoice
            </a>
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

        <!-- Stats -->
        <div class="row g-4 mb-4">
            <div class="col-lg-3 col-md-6">
                <div class="card stat-card stat-card-warning h-100">
                    <div class="card-body">
                        <div class="stat-label">Belum Lunas</div>
                        <div class="stat-value"><%= belumLunas != null ? belumLunas.size() : 0 %></div>
                    </div>
                </div>
            </div>
            <div class="col-lg-3 col-md-6">
                <div class="card stat-card stat-card-primary h-100">
                    <div class="card-body">
                        <div class="stat-label">Menunggu Verifikasi</div>
                        <div class="stat-value"><%= menunggu != null ? menunggu.size() : 0 %></div>
                    </div>
                </div>
            </div>
            <div class="col-lg-3 col-md-6">
                <div class="card stat-card stat-card-success h-100">
                    <div class="card-body">
                        <div class="stat-label">Lunas</div>
                        <div class="stat-value"><%= lunas != null ? lunas.size() : 0 %></div>
                    </div>
                </div>
            </div>
            <div class="col-lg-3 col-md-6">
                <div class="card stat-card stat-card-info h-100">
                    <div class="card-body">
                        <div class="stat-label">Total Lunas</div>
                        <div class="stat-value" style="font-size:1.4rem;">
                            Rp <%= totalLunasAmt != null ? String.format("%,.0f", totalLunasAmt) : "0" %>
                        </div>
                    </div>
                </div>
            </div>
        </div>

        <!-- Table -->
        <div class="card">
            <div class="card-header d-flex justify-content-between align-items-center">
                <h6 class="mb-0"><i class="bi bi-receipt me-2"></i>Daftar Invoice</h6>
            </div>
            <div class="card-body p-0">
                <% if (invoices == null || invoices.isEmpty()) { %>
                <div class="empty-state">
                    <i class="bi bi-receipt"></i>
                    <h3>Belum ada invoice</h3>
                    <p>Klik "Buat Invoice" untuk mulai mencatat tagihan siswa.</p>
                </div>
                <% } else { %>
                <div class="table-responsive">
                    <table class="table table-hover mb-0">
                        <thead>
                            <tr>
                                <th>No. Invoice</th>
                                <th>Siswa</th>
                                <th>Paket</th>
                                <th>Total</th>
                                <th>Jatuh Tempo</th>
                                <th>Status</th>
                                <th>Aksi</th>
                            </tr>
                        </thead>
                        <tbody>
                        <% for (Invoice inv : invoices) { %>
                            <tr>
                                <td><span class="invoice-id"><%= inv.getInvoiceNumber() %></span></td>
                                <td>
                                    <div class="student-quick-info">
                                        <div class="avatar-sm"><%= inv.getStudentName() != null && !inv.getStudentName().isEmpty() ? inv.getStudentName().substring(0,1).toUpperCase() : "?" %></div>
                                        <div class="info-text">
                                            <div class="info-name"><%= inv.getStudentName() != null ? inv.getStudentName() : "-" %></div>
                                            <div class="info-meta"><%= inv.getStudentEmail() != null ? inv.getStudentEmail() : "" %></div>
                                        </div>
                                    </div>
                                </td>
                                <td><%= inv.getPackageName() != null ? inv.getPackageName() : "-" %></td>
                                <td class="fw-bold">Rp <%= inv.getTotal() != null ? String.format("%,.0f", inv.getTotal()) : "0" %></td>
                                <td><%= inv.getDueDate() != null ? inv.getDueDate() : "-" %></td>
                                <td>
                                    <% String st = inv.getStatus() != null ? inv.getStatus() : "belum_lunas";
                                       String cls = st.equals("lunas") ? "lunas" : (st.equals("menunggu_verifikasi") ? "menunggu-verifikasi" : "belum-lunas");
                                       String label = st.equals("lunas") ? "Lunas" : (st.equals("menunggu_verifikasi") ? "Menunggu" : "Belum Lunas"); %>
                                    <span class="invoice-status <%= cls %>"><%= label %></span>
                                </td>
                                <td>
                                    <% if (!inv.isLunas()) { %>
                                    <form action="../BillingServlet" method="post" class="d-inline">
                                        <input type="hidden" name="csrfToken" value="<%= session.getAttribute("csrfToken") %>">
                                        <input type="hidden" name="action" value="markPaid">
                                        <input type="hidden" name="id" value="<%= inv.getId() %>">
                                        <input type="hidden" name="payment_method" value="transfer">
                                        <button type="submit" class="btn btn-sm btn-success" title="Tandai Lunas">
                                            <i class="bi bi-check-lg"></i>
                                        </button>
                                    </form>
                                    <% } %>
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

    <script src="https://cdn.jsdelivr.net/npm/bootstrap@5.3.2/dist/js/bootstrap.bundle.min.js"></script>
</body>
</html>

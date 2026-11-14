<%@ page contentType="text/html;charset=UTF-8" language="java" %>
<%@ page import="com.examora.model.User" %>
<%@ page import="com.examora.model.Invoice" %>
<%
    User currentUser = (User) session.getAttribute("user");
    if (currentUser == null || (!currentUser.isAdmin() && !"owner".equals(currentUser.getRole()))) {
        response.sendRedirect("../LoginServlet");
        return;
    }
    Invoice invoice = (Invoice) request.getAttribute("invoice");
    if (invoice == null) { response.sendRedirect("../BillingServlet?action=list"); return; }
%>
<!DOCTYPE html>
<html lang="id">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Invoice <%= invoice.getInvoiceNumber() %> - Exatuy</title>
    <link href="https://cdn.jsdelivr.net/npm/bootstrap@5.3.2/dist/css/bootstrap.min.css" rel="stylesheet">
    <link href="https://cdn.jsdelivr.net/npm/bootstrap-icons@1.11.1/font/bootstrap-icons.css" rel="stylesheet">
    <link href="../assets/css/style.css" rel="stylesheet">
<link href="../assets/css/handdrawn.css" rel="stylesheet">
</head>
<body>
    <%@ include file="sidebar.jsp" %>

    <div class="main-content">
        <div class="mb-4">
            <h1 class="h3 mb-0">Detail Invoice</h1>
            <nav aria-label="breadcrumb">
                <ol class="breadcrumb mb-0">
                    <li class="breadcrumb-item"><a href="../BillingServlet?action=list">Tagihan</a></li>
                    <li class="breadcrumb-item active"><%= invoice.getInvoiceNumber() %></li>
                </ol>
            </nav>
        </div>

        <div class="row">
            <div class="col-lg-8">
                <div class="card">
                    <div class="card-header invoice-summary">
                        <div class="label">Total Tagihan</div>
                        <div class="amount">Rp <%= invoice.getTotal() != null ? String.format("%,.0f", invoice.getTotal()) : "0" %></div>
                    </div>
                    <div class="card-body">
                        <table class="table table-borderless mb-0">
                            <tr><th width="35%">No. Invoice</th><td><%= invoice.getInvoiceNumber() %></td></tr>
                            <tr><th>Siswa</th><td><%= invoice.getStudentName() != null ? invoice.getStudentName() : "-" %></td></tr>
                            <tr><th>Email</th><td><%= invoice.getStudentEmail() != null ? invoice.getStudentEmail() : "-" %></td></tr>
                            <tr><th>Paket</th><td><%= invoice.getPackageName() != null ? invoice.getPackageName() : "-" %></td></tr>
                            <tr><th>Jatuh Tempo</th><td><%= invoice.getDueDate() != null ? invoice.getDueDate() : "-" %></td></tr>
                            <tr><th>Tanggal Bayar</th><td><%= invoice.getPaidAt() != null ? invoice.getPaidAt() : "Belum dibayar" %></td></tr>
                            <tr><th>Metode</th><td><%= invoice.getPaymentMethod() != null ? invoice.getPaymentMethod() : "-" %></td></tr>
                            <tr><th>Status</th><td>
                                <% String st = invoice.getStatus() != null ? invoice.getStatus() : "belum_lunas";
                                   String cls = st.equals("lunas") ? "lunas" : (st.equals("menunggu_verifikasi") ? "menunggu-verifikasi" : "belum-lunas");
                                   String label = st.equals("lunas") ? "Lunas" : (st.equals("menunggu_verifikasi") ? "Menunggu Verifikasi" : "Belum Lunas"); %>
                                <span class="invoice-status <%= cls %>"><%= label %></span>
                            </td></tr>
                            <% if (invoice.getNotes() != null && !invoice.getNotes().isEmpty()) { %>
                            <tr><th>Catatan</th><td><%= invoice.getNotes() %></td></tr>
                            <% } %>
                        </table>
                    </div>
                </div>

                <div class="d-flex gap-2 mt-3">
                    <a href="../BillingServlet?action=list" class="btn btn-outline-secondary">
                        <i class="bi bi-arrow-left me-2"></i>Kembali
                    </a>
                    <% if (!invoice.isLunas()) { %>
                    <form action="../BillingServlet" method="post">
                        <input type="hidden" name="csrfToken" value="<%= session.getAttribute("csrfToken") %>">
                        <input type="hidden" name="action" value="markPaid">
                        <input type="hidden" name="id" value="<%= invoice.getId() %>">
                        <input type="hidden" name="payment_method" value="transfer">
                        <button type="submit" class="btn btn-success">
                            <i class="bi bi-check-lg me-2"></i>Tandai Lunas
                        </button>
                    </form>
                    <% } %>
                </div>
            </div>
        </div>
    </div>

    <script src="https://cdn.jsdelivr.net/npm/bootstrap@5.3.2/dist/js/bootstrap.bundle.min.js"></script>
</body>
</html>

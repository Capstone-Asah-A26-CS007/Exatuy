<%@ page contentType="text/html;charset=UTF-8" language="java" %>
<%@ page import="com.examora.model.User" %>
<%@ page import="com.examora.model.Expense" %>
<%@ page import="java.util.List" %>
<%
    User currentUser = (User) session.getAttribute("user");
    if (currentUser == null || (!currentUser.isAdmin() && !"owner".equals(currentUser.getRole()))) {
        response.sendRedirect("../LoginServlet");
        return;
    }
    List<Expense> expenses = (List<Expense>) request.getAttribute("expenses");
    Integer year = (Integer) request.getAttribute("year");
    Integer month = (Integer) request.getAttribute("month");
    if (year == null) year = 2026;
    if (month == null) month = 1;
%>
<!DOCTYPE html>
<html lang="id">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Detail Pengeluaran - Exatuy</title>
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
                <h1 class="h3 mb-0">Detail Pengeluaran</h1>
                <nav aria-label="breadcrumb">
                    <ol class="breadcrumb mb-0">
                        <li class="breadcrumb-item"><a href="../FinanceServlet?action=summary">Keuangan</a></li>
                        <li class="breadcrumb-item active">Detail</li>
                    </ol>
                </nav>
            </div>
            <a href="../FinanceServlet?action=addExpense" class="btn btn-primary">
                <i class="bi bi-plus-lg me-2"></i>Catat Pengeluaran
            </a>
        </div>

        <div class="card">
            <div class="card-header">
                <h6 class="mb-0"><i class="bi bi-wallet2 me-2"></i>Pengeluaran <%= month %>/<%= year %></h6>
            </div>
            <div class="card-body p-0">
                <% if (expenses == null || expenses.isEmpty()) { %>
                <div class="empty-state">
                    <i class="bi bi-inbox"></i>
                    <h3>Belum ada pengeluaran</h3>
                    <p>Catat pengeluaran operasional untuk melihat rekap di sini.</p>
                </div>
                <% } else { %>
                <div class="table-responsive">
                    <table class="table table-hover mb-0">
                        <thead>
                            <tr>
                                <th>Tanggal</th>
                                <th>Kategori</th>
                                <th>Deskripsi</th>
                                <th>Nominal</th>
                                <th>Aksi</th>
                            </tr>
                        </thead>
                        <tbody>
                        <% for (Expense ex : expenses) {
                             String kat = ex.getKategori() != null ? ex.getKategori() : "Lainnya";
                             String tagCls = kat.toLowerCase().contains("gaji") ? "gaji"
                                 : kat.toLowerCase().contains("modul") ? "modul"
                                 : kat.toLowerCase().contains("sewa") ? "sewa" : ""; %>
                            <tr>
                                <td><%= ex.getTanggal() %></td>
                                <td><span class="expense-tag <%= tagCls %>"><%= kat %></span></td>
                                <td><%= ex.getDeskripsi() != null ? ex.getDeskripsi() : "-" %></td>
                                <td class="fw-bold">Rp <%= String.format("%,.0f", ex.getNominal()) %></td>
                                <td>
                                    <form action="../FinanceServlet" method="post" class="d-inline"
                                          onsubmit="return confirm('Hapus pengeluaran ini?');">
                                        <input type="hidden" name="csrfToken" value="<%= session.getAttribute("csrfToken") %>">
                                        <input type="hidden" name="action" value="deleteExpense">
                                        <input type="hidden" name="id" value="<%= ex.getId() %>">
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

    <script src="https://cdn.jsdelivr.net/npm/bootstrap@5.3.2/dist/js/bootstrap.bundle.min.js"></script>
</body>
</html>

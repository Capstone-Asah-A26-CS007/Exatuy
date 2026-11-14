<%@ page contentType="text/html;charset=UTF-8" language="java" %>
<%@ page import="com.examora.model.User" %>
<%@ page import="java.math.BigDecimal" %>
<%@ page import="java.util.Map" %>
<%@ page import="java.time.Month" %>
<%@ page import="java.time.format.TextStyle" %>
<%@ page import="java.util.Locale" %>
<%
    User currentUser = (User) session.getAttribute("user");
    if (currentUser == null || (!currentUser.isAdmin() && !"owner".equals(currentUser.getRole()))) {
        response.sendRedirect("../LoginServlet");
        return;
    }
    Integer year = (Integer) request.getAttribute("year");
    Integer month = (Integer) request.getAttribute("month");
    BigDecimal income = (BigDecimal) request.getAttribute("income");
    BigDecimal expense = (BigDecimal) request.getAttribute("expense");
    BigDecimal balance = (BigDecimal) request.getAttribute("balance");
    Map<String, BigDecimal> byCategory = (Map<String, BigDecimal>) request.getAttribute("expenseByCategory");
    Map<Integer, BigDecimal> incomeTrend = (Map<Integer, BigDecimal>) request.getAttribute("incomeTrend");
    Map<Integer, BigDecimal> expenseTrend = (Map<Integer, BigDecimal>) request.getAttribute("expenseTrend");
    String success = (String) session.getAttribute("flashSuccess");
    String error = (String) session.getAttribute("flashError");
    if (success != null) session.removeAttribute("flashSuccess");
    if (error != null) session.removeAttribute("flashError");

    if (year == null) year = 2026;
    if (month == null) month = 1;
    if (income == null) income = BigDecimal.ZERO;
    if (expense == null) expense = BigDecimal.ZERO;
    if (balance == null) balance = BigDecimal.ZERO;

    String monthName = Month.of(month).getDisplayName(TextStyle.FULL, new Locale("id", "ID"));
%>
<!DOCTYPE html>
<html lang="id">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Keuangan - Exatuy</title>
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
                <h1 class="h3 mb-0">Laporan Keuangan</h1>
                <p class="text-muted mb-0">Arus kas &mdash; <%= monthName %> <%= year %></p>
            </div>
            <div class="d-flex gap-2">
                <a href="../FinanceServlet?action=addExpense" class="btn btn-primary">
                    <i class="bi bi-plus-lg me-2"></i>Catat Pengeluaran
                </a>
                <a href="../FinanceServlet?action=expenses" class="btn btn-outline-primary">
                    <i class="bi bi-list-ul me-2"></i>Detail
                </a>
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

        <!-- Summary -->
        <div class="row g-4 mb-4">
            <div class="col-lg-4">
                <div class="card stat-card stat-card-success h-100">
                    <div class="card-body">
                        <div class="stat-label">Pemasukan</div>
                        <div class="stat-value" style="font-size:1.6rem;">Rp <%= String.format("%,.0f", income) %></div>
                    </div>
                </div>
            </div>
            <div class="col-lg-4">
                <div class="card stat-card stat-card-warning h-100">
                    <div class="card-body">
                        <div class="stat-label">Pengeluaran</div>
                        <div class="stat-value" style="font-size:1.6rem;">Rp <%= String.format("%,.0f", expense) %></div>
                    </div>
                </div>
            </div>
            <div class="col-lg-4">
                <div class="card stat-card <%= balance.compareTo(BigDecimal.ZERO) >= 0 ? "stat-card-primary" : "stat-card-warning" %> h-100">
                    <div class="card-body">
                        <div class="stat-label">Saldo Bersih</div>
                        <div class="stat-value" style="font-size:1.6rem;">Rp <%= String.format("%,.0f", balance) %></div>
                    </div>
                </div>
            </div>
        </div>

        <div class="row g-4">
            <!-- Expense breakdown -->
            <div class="col-lg-6">
                <div class="card h-100">
                    <div class="card-header">
                        <h6 class="mb-0"><i class="bi bi-pie-chart me-2"></i>Pengeluaran per Kategori</h6>
                    </div>
                    <div class="card-body">
                        <% if (byCategory == null || byCategory.isEmpty()) { %>
                        <div class="empty-state">
                            <i class="bi bi-inbox"></i>
                            <p class="mb-0">Belum ada pengeluaran bulan ini</p>
                        </div>
                        <% } else { for (Map.Entry<String, BigDecimal> e : byCategory.entrySet()) {
                             double pct = expense.compareTo(BigDecimal.ZERO) > 0
                                 ? e.getValue().doubleValue() / expense.doubleValue() * 100 : 0; %>
                        <div class="mb-3">
                            <div class="d-flex justify-content-between mb-1">
                                <span class="fw-semibold"><%= e.getKey() %></span>
                                <span class="fw-bold">Rp <%= String.format("%,.0f", e.getValue()) %></span>
                            </div>
                            <div class="progress">
                                <div class="progress-bar" style="width: <%= String.format("%.1f", pct) %>%"></div>
                            </div>
                        </div>
                        <% } } %>
                    </div>
                </div>
            </div>

            <!-- Trend -->
            <div class="col-lg-6">
                <div class="card h-100">
                    <div class="card-header">
                        <h6 class="mb-0"><i class="bi bi-graph-up me-2"></i>Tren 6 Bulan Terakhir</h6>
                    </div>
                    <div class="card-body">
                        <% if (incomeTrend == null || incomeTrend.isEmpty()) { %>
                        <div class="empty-state">
                            <i class="bi bi-graph-up"></i>
                            <p class="mb-0">Belum ada data tren</p>
                        </div>
                        <% } else {
                             BigDecimal maxVal = BigDecimal.ONE;
                             for (Integer m : incomeTrend.keySet()) {
                                 BigDecimal iv = incomeTrend.get(m);
                                 BigDecimal ev = expenseTrend != null ? expenseTrend.get(m) : BigDecimal.ZERO;
                                 if (iv != null && iv.compareTo(maxVal) > 0) maxVal = iv;
                                 if (ev != null && ev.compareTo(maxVal) > 0) maxVal = ev;
                             }
                             for (Map.Entry<Integer, BigDecimal> e : incomeTrend.entrySet()) {
                                 BigDecimal iv = e.getValue() != null ? e.getValue() : BigDecimal.ZERO;
                                 BigDecimal ev = (expenseTrend != null && expenseTrend.get(e.getKey()) != null) ? expenseTrend.get(e.getKey()) : BigDecimal.ZERO;
                                 double ipct = iv.doubleValue() / maxVal.doubleValue() * 100;
                                 double epct = ev.doubleValue() / maxVal.doubleValue() * 100;
                                 String mn = Month.of(e.getKey()).getDisplayName(TextStyle.SHORT, new Locale("id","ID"));
                        %>
                        <div class="mb-3">
                            <div class="fw-semibold mb-1"><%= mn %></div>
                            <div class="progress mb-1" style="height:8px;">
                                <div class="progress-bar bg-success" style="width: <%= String.format("%.1f", ipct) %>%"></div>
                            </div>
                            <div class="progress" style="height:8px;">
                                <div class="progress-bar bg-warning" style="width: <%= String.format("%.1f", epct) %>%"></div>
                            </div>
                            <small class="text-muted">Masuk Rp <%= String.format("%,.0f", iv) %> &middot; Keluar Rp <%= String.format("%,.0f", ev) %></small>
                        </div>
                        <% } } %>
                    </div>
                </div>
            </div>
        </div>
    </div>

    <script src="https://cdn.jsdelivr.net/npm/bootstrap@5.3.2/dist/js/bootstrap.bundle.min.js"></script>
</body>
</html>

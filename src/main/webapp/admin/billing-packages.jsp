<%@ page contentType="text/html;charset=UTF-8" language="java" %>
<%@ taglib prefix="c" uri="http://java.sun.com/jsp/jstl/core" %>
<%@ page import="com.examora.model.User" %>
<%@ page import="com.examora.model.SessionPackage" %>
<%@ page import="java.util.List" %>
<%@ page import="java.util.Map" %>
<%@ page import="java.math.BigDecimal" %>
<%
    User currentUser = (User) session.getAttribute("user");
    if (currentUser == null || (!currentUser.isAdmin() && !"owner".equals(currentUser.getRole()))) {
        response.sendRedirect("../LoginServlet");
        return;
    }
    List<SessionPackage> packages = (List<SessionPackage>) request.getAttribute("packages");
    Map<Integer, Integer> packageUsage = (Map<Integer, Integer>) request.getAttribute("packageUsage");
    if (packageUsage == null) packageUsage = new java.util.HashMap<>();

    String success = (String) session.getAttribute("flashSuccess");
    String error = (String) session.getAttribute("flashError");
    if (success != null) session.removeAttribute("flashSuccess");
    if (error != null) session.removeAttribute("flashError");

    // Warna kartu bergilir
    String[] accents = {"hd-blue", "hd-green", "hd-orange", "hd-purple"};
%>
<!DOCTYPE html>
<html lang="id">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Paket Kuota Belajar - Exatuy</title>
    <link href="https://cdn.jsdelivr.net/npm/bootstrap@5.3.2/dist/css/bootstrap.min.css" rel="stylesheet">
    <link href="https://cdn.jsdelivr.net/npm/bootstrap-icons@1.11.1/font/bootstrap-icons.css" rel="stylesheet">
    <link href="../assets/css/style.css" rel="stylesheet">
    <link href="../assets/css/handdrawn.css" rel="stylesheet">
    <link rel="icon" type="image/svg+xml" href="../assets/img/favicon.svg?v=4">
    <style>
        .pkg-card {
            position: relative;
            background: #fffef9;
            border: 2.5px solid #2b2b2b;
            border-radius: var(--hd-r1, 255px 15px 225px 15px / 15px 225px 15px 255px);
            box-shadow: 5px 5px 0 rgba(43,43,43,.18);
            padding: 1.5rem;
            height: 100%;
            transition: transform .18s ease, box-shadow .18s ease;
        }
        .pkg-card:hover {
            transform: translate(-3px,-4px) rotate(-.7deg);
            box-shadow: 9px 10px 0 rgba(43,43,43,.20);
        }
        .pkg-card:nth-of-type(even) {
            border-radius: var(--hd-r2, 15px 225px 15px 255px / 255px 15px 225px 15px);
        }
        .pkg-ribbon {
            position: absolute;
            top: -14px;
            right: 18px;
            background: #f5a623;
            color: #2b2b2b;
            border: 2px solid #2b2b2b;
            border-radius: 20px;
            padding: .2rem .8rem;
            font-size: .75rem;
            font-weight: 700;
            transform: rotate(3deg);
            box-shadow: 2px 2px 0 rgba(43,43,43,.2);
        }
        .pkg-sesi {
            font-family: 'Architects Daughter', cursive;
            font-size: 3rem;
            font-weight: 700;
            line-height: 1;
            color: #2b2b2b;
        }
        .pkg-sesi small {
            font-family: 'Patrick Hand', cursive;
            font-size: 1rem;
            display: block;
            color: #4a4a4a;
        }
        .pkg-harga {
            font-family: 'Architects Daughter', cursive;
            font-size: 1.6rem;
            font-weight: 700;
            color: #3d7ebd;
            margin: .75rem 0 .25rem;
        }
        .pkg-per-sesi {
            font-size: .85rem;
            color: #4a4a4a;
            font-style: italic;
        }
        .pkg-nama {
            font-family: 'Architects Daughter', cursive;
            font-weight: 700;
            font-size: 1.15rem;
            margin-bottom: .35rem;
        }
        .pkg-desc {
            font-size: .9rem;
            color: #4a4a4a;
            min-height: 2.6rem;
        }
        .pkg-kuota-bar {
            height: 14px;
            border: 2px solid #2b2b2b;
            border-radius: 20px;
            background: #fffef9;
            overflow: hidden;
            margin: .5rem 0 .25rem;
        }
        .pkg-kuota-fill {
            height: 100%;
            background: #5ea86a;
            border-radius: 20px;
        }
        .pkg-total {
            background: #fffef9;
            border: 2.5px solid #2b2b2b;
            border-radius: var(--hd-r1, 255px 15px 225px 15px / 15px 225px 15px 255px);
            box-shadow: 5px 5px 0 rgba(43,43,43,.18);
            padding: 1.25rem;
        }
    </style>
</head>
<body>
    <%@ include file="sidebar.jsp" %>

    <div class="main-content">
        <div class="d-flex justify-content-between align-items-center mb-4">
            <div>
                <h1 class="h3 mb-0">Paket Kuota Belajar</h1>
                <p class="text-muted mb-0">Pilih paket sesi belajar untuk siswa — kuota otomatis terpotong tiap kehadiran</p>
            </div>
            <div class="d-flex gap-2">
                <a href="../BillingServlet?action=list" class="btn btn-outline-secondary">
                    <i class="bi bi-receipt me-2"></i>Tagihan
                </a>
                <a href="../BillingServlet?action=create" class="btn btn-primary">
                    <i class="bi bi-plus-lg me-2"></i>Buat Invoice
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

        <!-- Ringkasan total -->
        <div class="row g-3 mb-4">
            <div class="col-lg-3 col-6">
                <div class="pkg-total">
                    <div class="text-muted small">Jumlah Paket</div>
                    <div class="fs-3 fw-bold"><%= packages != null ? packages.size() : 0 %></div>
                </div>
            </div>
            <div class="col-lg-3 col-6">
                <div class="pkg-total">
                    <div class="text-muted small">Paket Terjual</div>
                    <div class="fs-3 fw-bold">
                        <% int totalSold = 0; for (Integer v : packageUsage.values()) totalSold += v; %>
                        <%= totalSold %>
                    </div>
                </div>
            </div>
            <div class="col-lg-3 col-6">
                <div class="pkg-total">
                    <div class="text-muted small">Rentang Sesi</div>
                    <div class="fs-3 fw-bold">
                        <% int minS = 0, maxS = 0;
                           if (packages != null && !packages.isEmpty()) {
                               minS = packages.get(0).getJumlahSesi();
                               maxS = minS;
                               for (SessionPackage p : packages) {
                                   if (p.getJumlahSesi() < minS) minS = p.getJumlahSesi();
                                   if (p.getJumlahSesi() > maxS) maxS = p.getJumlahSesi();
                               }
                           } %>
                        <%= minS %>–<%= maxS %>
                    </div>
                </div>
            </div>
            <div class="col-lg-3 col-6">
                <div class="pkg-total">
                    <div class="text-muted small">Rata-rata / Sesi</div>
                    <div class="fs-4 fw-bold">
                        <%
                            long avg = 0; int cnt = 0;
                            if (packages != null) {
                                for (SessionPackage p : packages) {
                                    if (p.getJumlahSesi() > 0 && p.getHarga() != null) {
                                        avg += p.getHarga().longValue() / p.getJumlahSesi();
                                        cnt++;
                                    }
                                }
                            }
                            if (cnt > 0) avg = avg / cnt;
                        %>
                        Rp <%= String.format("%,d", avg) %>
                    </div>
                </div>
            </div>
        </div>

        <!-- Kartu paket -->
        <% if (packages == null || packages.isEmpty()) { %>
        <div class="card">
            <div class="card-body">
                <div class="empty-state">
                    <i class="bi bi-box-seam"></i>
                    <h3>Belum ada paket</h3>
                    <p class="mb-0">Tambahkan paket sesi belajar terlebih dahulu.</p>
                </div>
            </div>
        </div>
        <% } else { %>
        <div class="row g-4">
            <% int idx = 0;
               for (SessionPackage p : packages) {
                   int sold = packageUsage.getOrDefault(p.getId(), 0);
                   long perSesi = (p.getJumlahSesi() > 0 && p.getHarga() != null)
                       ? p.getHarga().longValue() / p.getJumlahSesi() : 0;
                   // Persentase bar visual: paket terlaris = 100%
                   int pct = 0;
                   if (totalSold > 0) pct = Math.max(6, (int) Math.round(sold * 100.0 / totalSold));
                   boolean populer = sold > 0 && pct == 100;
            %>
            <div class="col-lg-3 col-md-6">
                <div class="pkg-card">
                    <% if (populer) { %>
                    <div class="pkg-ribbon"><i class="bi bi-star-fill me-1"></i>Terlaris</div>
                    <% } %>

                    <div class="pkg-nama"><%= p.getNamaPaket() %></div>

                    <div class="pkg-sesi">
                        <%= p.getJumlahSesi() %>
                        <small>pertemuan</small>
                    </div>

                    <div class="pkg-harga">
                        Rp <%= p.getHarga() != null ? String.format("%,.0f", p.getHarga()) : "0" %>
                    </div>
                    <div class="pkg-per-sesi">≈ Rp <%= String.format("%,d", perSesi) %> per sesi</div>

                    <div class="pkg-desc mt-2">
                        <%= p.getDeskripsi() != null ? p.getDeskripsi() : "-" %>
                    </div>

                    <hr class="hd-divider my-3">

                    <div class="d-flex justify-content-between small">
                        <span><i class="bi bi-calendar3 me-1"></i><%= p.getDurasiBulan() != null ? p.getDurasiBulan() : "-" %> bulan</span>
                        <span><i class="bi bi-bag-check me-1"></i><%= sold %> terjual</span>
                    </div>

                    <div class="pkg-kuota-bar">
                        <div class="pkg-kuota-fill" style="width: <%= pct %>%; background: <%= idx % 2 == 0 ? "#5ea86a" : "#3d7ebd" %>;"></div>
                    </div>
                    <div class="text-end small text-muted mb-3"><%= pct %>% dari penjualan</div>

                    <a href="../BillingServlet?action=create&package_id=<%= p.getId() %>" class="btn btn-primary w-100 btn-sm">
                        <i class="bi bi-cart-plus me-2"></i>Tagih Paket Ini
                    </a>
                </div>
            </div>
            <% idx++; } %>
        </div>
        <% } %>

        <!-- Tabel ringkas -->
        <div class="card mt-4">
            <div class="card-header">
                <h6 class="mb-0"><i class="bi bi-table me-2"></i>Rincian Paket</h6>
            </div>
            <div class="card-body p-0">
                <div class="table-responsive">
                    <table class="table table-hover mb-0">
                        <thead>
                            <tr>
                                <th>Nama Paket</th>
                                <th>Sesi</th>
                                <th>Harga</th>
                                <th>/ Sesi</th>
                                <th>Durasi</th>
                                <th>Terjual</th>
                                <th>Status</th>
                            </tr>
                        </thead>
                        <tbody>
                        <% if (packages != null) { for (SessionPackage p : packages) {
                             long perSesi = (p.getJumlahSesi() > 0 && p.getHarga() != null)
                                 ? p.getHarga().longValue() / p.getJumlahSesi() : 0;
                             int sold = packageUsage.getOrDefault(p.getId(), 0);
                             boolean aktif = p.getIsActive() == null || p.getIsActive();
                        %>
                            <tr>
                                <td class="fw-semibold"><%= p.getNamaPaket() %></td>
                                <td><span class="badge badge-primary"><%= p.getJumlahSesi() %> sesi</span></td>
                                <td class="fw-bold">Rp <%= p.getHarga() != null ? String.format("%,.0f", p.getHarga()) : "0" %></td>
                                <td>Rp <%= String.format("%,d", perSesi) %></td>
                                <td><%= p.getDurasiBulan() != null ? p.getDurasiBulan() + " bln" : "-" %></td>
                                <td><%= sold %></td>
                                <td>
                                    <% if (aktif) { %>
                                    <span class="badge badge-success">Aktif</span>
                                    <% } else { %>
                                    <span class="badge badge-danger">Nonaktif</span>
                                    <% } %>
                                </td>
                            </tr>
                        <% } } %>
                        </tbody>
                    </table>
                </div>
            </div>
        </div>
    </div>

    <script src="https://cdn.jsdelivr.net/npm/bootstrap@5.3.2/dist/js/bootstrap.bundle.min.js"></script>
</body>
</html>

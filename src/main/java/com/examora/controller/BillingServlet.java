package com.examora.controller;

import com.examora.dao.InvoiceDAO;
import com.examora.dao.UserDAO;
import com.examora.model.Invoice;
import com.examora.model.SessionPackage;
import com.examora.model.User;
import com.examora.util.ValidationUtil;

import jakarta.servlet.ServletException;
import jakarta.servlet.annotation.WebServlet;
import jakarta.servlet.http.HttpServlet;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;
import jakarta.servlet.http.HttpSession;

import java.io.IOException;
import java.math.BigDecimal;
import java.sql.SQLException;
import java.time.LocalDate;
import java.time.format.DateTimeFormatter;
import java.util.List;
import java.util.UUID;

@WebServlet("/BillingServlet")
public class BillingServlet extends HttpServlet {
    private InvoiceDAO invoiceDAO;
    private UserDAO userDAO;

    @Override
    public void init() throws ServletException {
        invoiceDAO = new InvoiceDAO();
        userDAO = new UserDAO();
    }

    @Override
    protected void doGet(HttpServletRequest request, HttpServletResponse response)
            throws ServletException, IOException {
        String action = request.getParameter("action");
        HttpSession session = request.getSession(false);
        User currentUser = session != null ? (User) session.getAttribute("user") : null;

        if (currentUser == null || !"admin".equals(currentUser.getRole()) && !"owner".equals(currentUser.getRole())) {
            response.sendRedirect("../LoginServlet");
            return;
        }

        try {
            if ("list".equals(action) || action == null) {
                showList(request, response);
            } else if ("packages".equals(action)) {
                showPackages(request, response);
            } else if ("create".equals(action)) {
                showCreateForm(request, response);
            } else if ("view".equals(action)) {
                int id = Integer.parseInt(request.getParameter("id"));
                Invoice inv = invoiceDAO.findById(id);
                request.setAttribute("invoice", inv);
                request.getRequestDispatcher("/admin/billing-view.jsp").forward(request, response);
            } else {
                showList(request, response);
            }
        } catch (Exception e) {
            request.setAttribute("error", "Error: " + e.getMessage());
            showList(request, response);
        }
    }

    @Override
    protected void doPost(HttpServletRequest request, HttpServletResponse response)
            throws ServletException, IOException {
        HttpSession session = request.getSession(false);
        User currentUser = session != null ? (User) session.getAttribute("user") : null;

        if (currentUser == null) {
            response.sendRedirect("../LoginServlet");
            return;
        }

        String action = request.getParameter("action");
        try {
            if ("create".equals(action)) {
                createInvoice(request, response);
            } else if ("verify".equals(action)) {
                verifyInvoice(request, response);
            } else if ("markPaid".equals(action)) {
                markPaid(request, response);
            } else {
                response.sendRedirect("../BillingServlet?action=list");
            }
        } catch (Exception e) {
            request.getSession().setAttribute("flashError", "Error: " + e.getMessage());
            response.sendRedirect("../BillingServlet?action=" + action);
        }
    }

    private void showList(HttpServletRequest request, HttpServletResponse response)
            throws ServletException, IOException {
        try {
            List<Invoice> invoices = invoiceDAO.findAll();
            List<Invoice> belumLunas = invoiceDAO.findByStatus("belum_lunas");
            List<Invoice> menunggu = invoiceDAO.findByStatus("menunggu_verifikasi");
            List<Invoice> lunas = invoiceDAO.findByStatus("lunas");

            request.setAttribute("invoices", invoices);
            request.setAttribute("belumLunas", belumLunas);
            request.setAttribute("menunggu", menunggu);
            request.setAttribute("lunas", lunas);
            request.setAttribute("totalBelumLunas", belumLunas.size());
            request.setAttribute("totalMenunggu", menunggu.size());
            request.setAttribute("totalLunas", lunas.size());

            // Calculate totals
            BigDecimal totalBelum = belumLunas.stream()
                .map(Invoice::getTotal).reduce(BigDecimal.ZERO, BigDecimal::add);
            BigDecimal totalLunas = lunas.stream()
                .map(Invoice::getTotal).reduce(BigDecimal.ZERO, BigDecimal::add);
            request.setAttribute("totalBelumLunasAmount", totalBelum);
            request.setAttribute("totalLunasAmount", totalLunas);

            request.getRequestDispatcher("/admin/billing-list.jsp").forward(request, response);
        } catch (SQLException e) {
            throw new ServletException(e);
        }
    }

    private void showPackages(HttpServletRequest request, HttpServletResponse response)
            throws ServletException, IOException {
        try {
            List<SessionPackage> packages = invoiceDAO.getAllPackages();

            // Statistik pemakaian paket dari invoice
            java.util.Map<Integer, Integer> packageUsage = new java.util.HashMap<>();
            for (Invoice inv : invoiceDAO.findAll()) {
                Integer pid = inv.getPackageId();
                if (pid != null) {
                    packageUsage.merge(pid, 1, Integer::sum);
                }
            }

            request.setAttribute("packages", packages);
            request.setAttribute("packageUsage", packageUsage);
            request.getRequestDispatcher("/admin/billing-packages.jsp").forward(request, response);
        } catch (SQLException e) {
            throw new ServletException(e);
        }
    }

    private void showCreateForm(HttpServletRequest request, HttpServletResponse response)
            throws ServletException, IOException {
        try {
            List<User> siswaList = userDAO.findByRole("peserta");
            List<SessionPackage> packages = invoiceDAO.getAllPackages();
            request.setAttribute("siswaList", siswaList);
            request.setAttribute("packages", packages);
            // Pra-pilih paket bila datang dari halaman Paket Kuota
            String preId = request.getParameter("package_id");
            if (preId != null && !preId.isEmpty()) {
                request.setAttribute("preselectedPackageId", preId);
            }
            request.getRequestDispatcher("/admin/billing-create.jsp").forward(request, response);
        } catch (SQLException e) {
            throw new ServletException(e);
        }
    }

    private void createInvoice(HttpServletRequest request, HttpServletResponse response)
            throws IOException, ServletException, SQLException {
        int studentId = Integer.parseInt(request.getParameter("student_id"));
        int packageId = Integer.parseInt(request.getParameter("package_id"));
        String dueDateStr = request.getParameter("due_date");
        String notes = request.getParameter("notes");

        LocalDate dueDate = dueDateStr != null && !dueDateStr.isEmpty()
            ? LocalDate.parse(dueDateStr) : LocalDate.now().plusMonths(1);

        Invoice invoice = new Invoice();
        invoice.setInvoiceNumber("INV-" + UUID.randomUUID().toString().substring(0, 8).toUpperCase());
        invoice.setStudentId(studentId);
        invoice.setPackageId(packageId);

        // Look up the package price so the invoice carries the real amount
        BigDecimal harga = BigDecimal.ZERO;
        Integer jumlahSesi = null;
        String namaPaket = null;
        for (SessionPackage p : invoiceDAO.getAllPackages()) {
            if (p.getId() != null && p.getId() == packageId) {
                harga = p.getHarga() != null ? p.getHarga() : BigDecimal.ZERO;
                jumlahSesi = p.getJumlahSesi();
                namaPaket = p.getNamaPaket();
                break;
            }
        }
        invoice.setAmount(harga);
        invoice.setDiscount(BigDecimal.ZERO);
        invoice.setTotal(harga);
        invoice.setStatus("belum_lunas");
        invoice.setDueDate(dueDate);
        invoice.setNotes(notes);

        invoiceDAO.create(invoice);
        request.getSession().setAttribute("flashSuccess", "Invoice berhasil dibuat");
        response.sendRedirect("../BillingServlet?action=list");
    }

    private void verifyInvoice(HttpServletRequest request, HttpServletResponse response)
            throws IOException, ServletException, SQLException {
        int id = Integer.parseInt(request.getParameter("id"));
        int verifiedById = Integer.parseInt(request.getParameter("verified_by"));
        invoiceDAO.updateStatus(id, "menunggu_verifikasi", verifiedById);
        request.getSession().setAttribute("flashSuccess", "Invoice diverifikasi");
        response.sendRedirect("../BillingServlet?action=list");
    }

    private void markPaid(HttpServletRequest request, HttpServletResponse response)
            throws IOException, ServletException, SQLException {
        int id = Integer.parseInt(request.getParameter("id"));
        String paymentMethod = request.getParameter("payment_method");
        HttpSession session = request.getSession(false);
        User currentUser = session != null ? (User) session.getAttribute("user") : null;

        invoiceDAO.markLunas(id, paymentMethod, currentUser != null ? currentUser.getId() : null);
        request.getSession().setAttribute("flashSuccess", "Pembayaran berhasil dicatat sebagai Lunas");
        response.sendRedirect("../BillingServlet?action=list");
    }
}

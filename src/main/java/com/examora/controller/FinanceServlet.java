package com.examora.controller;

import com.examora.dao.ExpenseDAO;
import com.examora.dao.InvoiceDAO;
import com.examora.model.Expense;
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
import java.time.YearMonth;
import java.time.format.DateTimeFormatter;
import java.util.HashMap;
import java.util.List;
import java.util.Map;

@WebServlet("/FinanceServlet")
public class FinanceServlet extends HttpServlet {
    private ExpenseDAO expenseDAO;
    private InvoiceDAO invoiceDAO;

    @Override
    public void init() throws ServletException {
        expenseDAO = new ExpenseDAO();
        invoiceDAO = new InvoiceDAO();
    }

    @Override
    protected void doGet(HttpServletRequest request, HttpServletResponse response)
            throws ServletException, IOException {
        HttpSession session = request.getSession(false);
        User currentUser = session != null ? (User) session.getAttribute("user") : null;

        if (currentUser == null || !"admin".equals(currentUser.getRole()) && !"owner".equals(currentUser.getRole())) {
            response.sendRedirect("../LoginServlet");
            return;
        }

        String action = request.getParameter("action");
        String yearStr = request.getParameter("year");
        String monthStr = request.getParameter("month");

        int year = yearStr != null && !yearStr.isEmpty() ? Integer.parseInt(yearStr) : LocalDate.now().getYear();
        int month = monthStr != null && !monthStr.isEmpty() ? Integer.parseInt(monthStr) : LocalDate.now().getMonthValue();

        try {
            if ("summary".equals(action) || action == null) {
                showSummary(request, response, year, month);
            } else if ("expenses".equals(action)) {
                showExpenses(request, response, year, month);
            } else if ("addExpense".equals(action)) {
                showAddExpenseForm(request, response);
            } else {
                showSummary(request, response, year, month);
            }
        } catch (Exception e) {
            request.setAttribute("error", "Error: " + e.getMessage());
            try {
                showSummary(request, response, year, month);
            } catch (Exception ex) {
                throw new ServletException(ex);
            }
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
            if ("saveExpense".equals(action)) {
                saveExpense(request, response, currentUser);
            } else if ("deleteExpense".equals(action)) {
                int id = Integer.parseInt(request.getParameter("id"));
                expenseDAO.delete(id);
                request.getSession().setAttribute("flashSuccess", "Pengeluaran dihapus");
                response.sendRedirect("../FinanceServlet?action=expenses");
            } else {
                response.sendRedirect("../FinanceServlet?action=summary");
            }
        } catch (Exception e) {
            request.getSession().setAttribute("flashError", "Error: " + e.getMessage());
            response.sendRedirect("../FinanceServlet?action=summary");
        }
    }

    private void showSummary(HttpServletRequest request, HttpServletResponse response, int year, int month)
            throws ServletException, IOException, SQLException {
        BigDecimal income = invoiceDAO.sumByMonth(year, month);
        BigDecimal expense = expenseDAO.sumByMonth(year, month);
        BigDecimal balance = income.subtract(expense);

        // Category breakdown for expenses
        Map<String, BigDecimal> expenseByCategory = new HashMap<>();
        List<String> categories = List.of("Gaji Guru", "Modul/ATK", "Sewa Tempat", "Listrik/Air", "Lainnya");
        for (String cat : categories) {
            BigDecimal sum = expenseDAO.sumByCategory(cat, year, month);
            if (sum.compareTo(BigDecimal.ZERO) > 0) {
                expenseByCategory.put(cat, sum);
            }
        }

        // Last 6 months trend
        Map<Integer, BigDecimal> incomeTrend = new HashMap<>();
        Map<Integer, BigDecimal> expenseTrend = new HashMap<>();
        for (int i = 0; i < 6; i++) {
            int m = month - i;
            int y = year;
            if (m <= 0) { m += 12; y--; }
            incomeTrend.put(m, invoiceDAO.sumByMonth(y, m));
            expenseTrend.put(m, expenseDAO.sumByMonth(y, m));
        }

        request.setAttribute("year", year);
        request.setAttribute("month", month);
        request.setAttribute("income", income);
        request.setAttribute("expense", expense);
        request.setAttribute("balance", balance);
        request.setAttribute("expenseByCategory", expenseByCategory);
        request.setAttribute("incomeTrend", incomeTrend);
        request.setAttribute("expenseTrend", expenseTrend);

        request.getRequestDispatcher("/admin/finance-summary.jsp").forward(request, response);
    }

    private void showExpenses(HttpServletRequest request, HttpServletResponse response, int year, int month)
            throws ServletException, IOException, SQLException {
        List<Expense> expenses = expenseDAO.findByMonth(year, month);
        request.setAttribute("expenses", expenses);
        request.setAttribute("year", year);
        request.setAttribute("month", month);
        request.getRequestDispatcher("/admin/finance-expenses.jsp").forward(request, response);
    }

    private void showAddExpenseForm(HttpServletRequest request, HttpServletResponse response)
            throws ServletException, IOException {
        request.getRequestDispatcher("/admin/finance-add-expense.jsp").forward(request, response);
    }

    private void saveExpense(HttpServletRequest request, HttpServletResponse response, User user)
            throws IOException, SQLException {
        String kategori = request.getParameter("kategori");
        String nominalStr = request.getParameter("nominal");
        String tanggalStr = request.getParameter("tanggal");
        String deskripsi = request.getParameter("deskripsi");

        BigDecimal nominal = new BigDecimal(nominalStr.replace(".", "").replace(",", "."));
        LocalDate tanggal = tanggalStr != null && !tanggalStr.isEmpty()
            ? LocalDate.parse(tanggalStr) : LocalDate.now();

        Expense expense = new Expense();
        expense.setKategori(kategori);
        expense.setNominal(nominal);
        expense.setTanggal(tanggal);
        expense.setDeskripsi(deskripsi);
        expense.setCreatedBy(user.getId());

        expenseDAO.create(expense);
        request.getSession().setAttribute("flashSuccess", "Pengeluaran berhasil dicatat");
        response.sendRedirect("../FinanceServlet?action=summary");
    }
}

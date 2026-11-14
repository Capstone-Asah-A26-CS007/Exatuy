package com.examora.dao;

import com.examora.model.Invoice;
import com.examora.model.SessionPackage;
import com.examora.util.DBUtil;

import java.math.BigDecimal;
import java.sql.*;
import java.time.LocalDate;
import java.util.ArrayList;
import java.util.List;

public class InvoiceDAO {

    public List<Invoice> findAll() throws SQLException {
        List<Invoice> list = new ArrayList<>();
        String sql = "SELECT i.*, u.name as student_name, u.email as student_email, " +
                     "sp.nama_paket FROM invoices i " +
                     "LEFT JOIN users u ON i.student_id = u.id " +
                     "LEFT JOIN session_packages sp ON i.package_id = sp.id " +
                     "ORDER BY i.created_at DESC";
        try (Connection conn = DBUtil.getConnection();
             PreparedStatement stmt = conn.prepareStatement(sql);
             ResultSet rs = stmt.executeQuery()) {
            while (rs.next()) list.add(mapRow(rs));
        }
        return list;
    }

    public List<Invoice> findByStatus(String status) throws SQLException {
        List<Invoice> list = new ArrayList<>();
        String sql = "SELECT i.*, u.name as student_name, u.email as student_email, " +
                     "sp.nama_paket FROM invoices i " +
                     "LEFT JOIN users u ON i.student_id = u.id " +
                     "LEFT JOIN session_packages sp ON i.package_id = sp.id " +
                     "WHERE i.status = ? ORDER BY i.due_date ASC";
        try (Connection conn = DBUtil.getConnection();
             PreparedStatement stmt = conn.prepareStatement(sql)) {
            stmt.setString(1, status);
            try (ResultSet rs = stmt.executeQuery()) {
                while (rs.next()) list.add(mapRow(rs));
            }
        }
        return list;
    }

    public Invoice findById(int id) throws SQLException {
        String sql = "SELECT i.*, u.name as student_name, u.email as student_email, " +
                     "sp.nama_paket FROM invoices i " +
                     "LEFT JOIN users u ON i.student_id = u.id " +
                     "LEFT JOIN session_packages sp ON i.package_id = sp.id " +
                     "WHERE i.id = ?";
        try (Connection conn = DBUtil.getConnection();
             PreparedStatement stmt = conn.prepareStatement(sql)) {
            stmt.setInt(1, id);
            try (ResultSet rs = stmt.executeQuery()) {
                return rs.next() ? mapRow(rs) : null;
            }
        }
    }

    public void create(Invoice invoice) throws SQLException {
        String sql = "INSERT INTO invoices (invoice_number, student_id, package_id, amount, discount, total, " +
                     "status, due_date, paid_with, notes, verified_by) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)";
        try (Connection conn = DBUtil.getConnection();
             PreparedStatement stmt = conn.prepareStatement(sql)) {
            stmt.setString(1, invoice.getInvoiceNumber());
            stmt.setInt(2, invoice.getStudentId());
            stmt.setInt(3, invoice.getPackageId());
            stmt.setBigDecimal(4, invoice.getAmount());
            stmt.setBigDecimal(5, invoice.getDiscount() != null ? invoice.getDiscount() : BigDecimal.ZERO);
            stmt.setBigDecimal(6, invoice.getTotal());
            stmt.setString(7, invoice.getStatus());
            stmt.setDate(8, Date.valueOf(invoice.getDueDate()));
            stmt.setString(9, invoice.getPaymentMethod());
            stmt.setString(10, invoice.getNotes());
            stmt.setNull(11, Types.INTEGER);
            stmt.executeUpdate();
        }
    }

    public void updateStatus(int id, String status, Integer verifiedBy) throws SQLException {
        String sql = "UPDATE invoices SET status = ?, paid_at = CASE WHEN ? = 'lunas' THEN CURDATE() ELSE paid_at END WHERE id = ?";
        try (Connection conn = DBUtil.getConnection();
             PreparedStatement stmt = conn.prepareStatement(sql)) {
            stmt.setString(1, status);
            stmt.setString(2, status);
            stmt.setInt(3, id);
            stmt.executeUpdate();
        }
        if ("lunas".equals(status) && verifiedBy != null) {
            String sql2 = "UPDATE invoices SET verified_by = ? WHERE id = ?";
            try (Connection conn = DBUtil.getConnection();
                 PreparedStatement stmt = conn.prepareStatement(sql2)) {
                stmt.setInt(1, verifiedBy);
                stmt.setInt(2, id);
                stmt.executeUpdate();
            }
        }
    }

    public void markLunas(int id, String paymentMethod, Integer verifiedBy) throws SQLException {
        String sql = "UPDATE invoices SET status = 'lunas', paid_at = CURDATE(), paid_with = ?, verified_by = ? WHERE id = ?";
        try (Connection conn = DBUtil.getConnection();
             PreparedStatement stmt = conn.prepareStatement(sql)) {
            stmt.setString(1, paymentMethod);
            stmt.setInt(2, verifiedBy != null ? verifiedBy : 0);
            stmt.setInt(3, id);
            stmt.executeUpdate();
        }
    }

    public BigDecimal sumByMonth(int year, int month) throws SQLException {
        String sql = "SELECT COALESCE(SUM(total), 0) FROM invoices WHERE status = 'lunas' " +
                     "AND YEAR(paid_at) = ? AND MONTH(paid_at) = ?";
        try (Connection conn = DBUtil.getConnection();
             PreparedStatement stmt = conn.prepareStatement(sql)) {
            stmt.setInt(1, year);
            stmt.setInt(2, month);
            try (ResultSet rs = stmt.executeQuery()) {
                return rs.next() ? rs.getBigDecimal(1) : BigDecimal.ZERO;
            }
        }
    }

    public BigDecimal countByStatus(String status) throws SQLException {
        String sql = "SELECT COUNT(*) FROM invoices WHERE status = ?";
        try (Connection conn = DBUtil.getConnection();
             PreparedStatement stmt = conn.prepareStatement(sql)) {
            stmt.setString(1, status);
            try (ResultSet rs = stmt.executeQuery()) {
                return rs.next() ? new BigDecimal(rs.getInt(1)) : BigDecimal.ZERO;
            }
        }
    }

    public List<SessionPackage> getAllPackages() throws SQLException {
        List<SessionPackage> list = new ArrayList<>();
        String sql = "SELECT * FROM session_packages WHERE is_active = TRUE ORDER BY harga ASC";
        try (Connection conn = DBUtil.getConnection();
             PreparedStatement stmt = conn.prepareStatement(sql);
             ResultSet rs = stmt.executeQuery()) {
            while (rs.next()) {
                SessionPackage p = new SessionPackage();
                p.setId(rs.getInt("id"));
                p.setNamaPaket(rs.getString("nama_paket"));
                p.setJumlahSesi(rs.getInt("jumlah_sesi"));
                p.setHarga(rs.getBigDecimal("harga"));
                p.setDurasiBulan(rs.getInt("durasi_bulan"));
                p.setDeskripsi(rs.getString("deskripsi"));
                p.setIsActive(rs.getBoolean("is_active"));
                list.add(p);
            }
        }
        return list;
    }

    private Invoice mapRow(ResultSet rs) throws SQLException {
        Invoice inv = new Invoice();
        inv.setId(rs.getInt("id"));
        inv.setInvoiceNumber(rs.getString("invoice_number"));
        inv.setStudentId(rs.getInt("student_id"));
        inv.setStudentName(rs.getString("student_name"));
        inv.setStudentEmail(rs.getString("student_email"));
        inv.setPackageId(rs.getInt("package_id"));
        inv.setPackageName(rs.getString("nama_paket"));
        inv.setAmount(rs.getBigDecimal("amount"));
        inv.setDiscount(rs.getBigDecimal("discount"));
        inv.setTotal(rs.getBigDecimal("total"));
        inv.setStatus(rs.getString("status"));
        inv.setDueDate(rs.getDate("due_date") != null ? rs.getDate("due_date").toLocalDate() : null);
        inv.setPaidAt(rs.getDate("paid_at") != null ? rs.getDate("paid_at").toLocalDate() : null);
        inv.setPaymentMethod(rs.getString("paid_with"));
        inv.setVerifiedById(rs.getInt("verified_by"));
        inv.setVerifiedByName(rs.getString("verified_by"));
        inv.setNotes(rs.getString("notes"));
        inv.setCreatedAt(rs.getTimestamp("created_at") != null ? rs.getTimestamp("created_at").toLocalDateTime() : null);
        return inv;
    }
}

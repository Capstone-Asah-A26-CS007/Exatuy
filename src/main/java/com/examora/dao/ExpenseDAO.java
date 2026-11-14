package com.examora.dao;

import com.examora.model.Expense;
import com.examora.util.DBUtil;

import java.math.BigDecimal;
import java.sql.*;
import java.time.LocalDate;
import java.util.ArrayList;
import java.util.List;

public class ExpenseDAO {

    public List<Expense> findAll() throws SQLException {
        List<Expense> list = new ArrayList<>();
        String sql = "SELECT * FROM expenses ORDER BY tanggal DESC";
        try (Connection conn = DBUtil.getConnection();
             PreparedStatement stmt = conn.prepareStatement(sql);
             ResultSet rs = stmt.executeQuery()) {
            while (rs.next()) list.add(mapRow(rs));
        }
        return list;
    }

    public List<Expense> findByMonth(int year, int month) throws SQLException {
        List<Expense> list = new ArrayList<>();
        String sql = "SELECT * FROM expenses WHERE YEAR(tanggal) = ? AND MONTH(tanggal) = ? ORDER BY tanggal DESC";
        try (Connection conn = DBUtil.getConnection();
             PreparedStatement stmt = conn.prepareStatement(sql)) {
            stmt.setInt(1, year);
            stmt.setInt(2, month);
            try (ResultSet rs = stmt.executeQuery()) {
                while (rs.next()) list.add(mapRow(rs));
            }
        }
        return list;
    }

    public BigDecimal sumByMonth(int year, int month) throws SQLException {
        String sql = "SELECT COALESCE(SUM(nominal), 0) FROM expenses WHERE YEAR(tanggal) = ? AND MONTH(tanggal) = ?";
        try (Connection conn = DBUtil.getConnection();
             PreparedStatement stmt = conn.prepareStatement(sql)) {
            stmt.setInt(1, year);
            stmt.setInt(2, month);
            try (ResultSet rs = stmt.executeQuery()) {
                return rs.next() ? rs.getBigDecimal(1) : BigDecimal.ZERO;
            }
        }
    }

    public BigDecimal sumByCategory(String kategori, int year, int month) throws SQLException {
        String sql = "SELECT COALESCE(SUM(nominal), 0) FROM expenses WHERE kategori = ? AND YEAR(tanggal) = ? AND MONTH(tanggal) = ?";
        try (Connection conn = DBUtil.getConnection();
             PreparedStatement stmt = conn.prepareStatement(sql)) {
            stmt.setString(1, kategori);
            stmt.setInt(2, year);
            stmt.setInt(3, month);
            try (ResultSet rs = stmt.executeQuery()) {
                return rs.next() ? rs.getBigDecimal(1) : BigDecimal.ZERO;
            }
        }
    }

    public void create(Expense expense) throws SQLException {
        String sql = "INSERT INTO expenses (kategori, nominal, tanggal, deskripsi, bukti, created_by) VALUES (?, ?, ?, ?, ?, ?)";
        try (Connection conn = DBUtil.getConnection();
             PreparedStatement stmt = conn.prepareStatement(sql)) {
            stmt.setString(1, expense.getKategori());
            stmt.setBigDecimal(2, expense.getNominal());
            stmt.setDate(3, Date.valueOf(expense.getTanggal()));
            stmt.setString(4, expense.getDeskripsi());
            stmt.setString(5, expense.getBukti());
            stmt.setInt(6, expense.getCreatedBy());
            stmt.executeUpdate();
        }
    }

    public void delete(int id) throws SQLException {
        String sql = "DELETE FROM expenses WHERE id = ?";
        try (Connection conn = DBUtil.getConnection();
             PreparedStatement stmt = conn.prepareStatement(sql)) {
            stmt.setInt(1, id);
            stmt.executeUpdate();
        }
    }

    private Expense mapRow(ResultSet rs) throws SQLException {
        Expense e = new Expense();
        e.setId(rs.getInt("id"));
        e.setKategori(rs.getString("kategori"));
        e.setNominal(rs.getBigDecimal("nominal"));
        e.setTanggal(rs.getDate("tanggal") != null ? rs.getDate("tanggal").toLocalDate() : LocalDate.now());
        e.setDeskripsi(rs.getString("deskripsi"));
        e.setBukti(rs.getString("bukti"));
        e.setCreatedBy(rs.getInt("created_by"));
        e.setCreatedAt(rs.getTimestamp("created_at") != null ? rs.getTimestamp("created_at").toLocalDateTime() : null);
        return e;
    }
}

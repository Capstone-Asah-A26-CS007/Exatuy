package com.examora.dao;

import com.examora.model.MaterialCategory;
import com.examora.util.DBUtil;

import java.sql.*;
import java.util.ArrayList;
import java.util.List;

public class MaterialCategoryDAO {

    public List<MaterialCategory> findAll() throws SQLException {
        List<MaterialCategory> list = new ArrayList<>();
        String sql = "SELECT * FROM material_categories ORDER BY jenjang, mata_pelajaran, nama";
        try (Connection conn = DBUtil.getConnection();
             PreparedStatement stmt = conn.prepareStatement(sql);
             ResultSet rs = stmt.executeQuery()) {
            while (rs.next()) list.add(mapRow(rs));
        }
        return list;
    }

    public List<MaterialCategory> findByJenjang(String jenjang) throws SQLException {
        List<MaterialCategory> list = new ArrayList<>();
        String sql = "SELECT * FROM material_categories WHERE jenjang = ? AND is_active = TRUE ORDER BY mata_pelajaran, nama";
        try (Connection conn = DBUtil.getConnection();
             PreparedStatement stmt = conn.prepareStatement(sql)) {
            stmt.setString(1, jenjang);
            try (ResultSet rs = stmt.executeQuery()) {
                while (rs.next()) list.add(mapRow(rs));
            }
        }
        return list;
    }

    public MaterialCategory findById(int id) throws SQLException {
        String sql = "SELECT * FROM material_categories WHERE id = ?";
        try (Connection conn = DBUtil.getConnection();
             PreparedStatement stmt = conn.prepareStatement(sql)) {
            stmt.setInt(1, id);
            try (ResultSet rs = stmt.executeQuery()) {
                return rs.next() ? mapRow(rs) : null;
            }
        }
    }

    public void create(MaterialCategory cat) throws SQLException {
        String sql = "INSERT INTO material_categories (nama, deskripsi, jenjang, mata_pelajaran, created_by) VALUES (?, ?, ?, ?, ?)";
        try (Connection conn = DBUtil.getConnection();
             PreparedStatement stmt = conn.prepareStatement(sql)) {
            stmt.setString(1, cat.getNama());
            stmt.setString(2, cat.getDeskripsi());
            stmt.setString(3, cat.getJenjang());
            stmt.setString(4, cat.getMataPelajaran());
            stmt.setInt(5, cat.getCreatedBy());
            stmt.executeUpdate();
        }
    }

    public void update(MaterialCategory cat) throws SQLException {
        String sql = "UPDATE material_categories SET nama=?, deskripsi=?, jenjang=?, mata_pelajaran=? WHERE id=?";
        try (Connection conn = DBUtil.getConnection();
             PreparedStatement stmt = conn.prepareStatement(sql)) {
            stmt.setString(1, cat.getNama());
            stmt.setString(2, cat.getDeskripsi());
            stmt.setString(3, cat.getJenjang());
            stmt.setString(4, cat.getMataPelajaran());
            stmt.setInt(5, cat.getId());
            stmt.executeUpdate();
        }
    }

    public void delete(int id) throws SQLException {
        String sql = "UPDATE material_categories SET is_active = FALSE WHERE id = ?";
        try (Connection conn = DBUtil.getConnection();
             PreparedStatement stmt = conn.prepareStatement(sql)) {
            stmt.setInt(1, id);
            stmt.executeUpdate();
        }
    }

    private MaterialCategory mapRow(ResultSet rs) throws SQLException {
        MaterialCategory cat = new MaterialCategory();
        cat.setId(rs.getInt("id"));
        cat.setNama(rs.getString("nama"));
        cat.setDeskripsi(rs.getString("deskripsi"));
        cat.setJenjang(rs.getString("jenjang"));
        cat.setMataPelajaran(rs.getString("mata_pelajaran"));
        cat.setCreatedBy(rs.getInt("created_by"));
        cat.setIsActive(rs.getBoolean("is_active"));
        cat.setCreatedAt(rs.getTimestamp("created_at") != null ? rs.getTimestamp("created_at").toLocalDateTime() : null);
        return cat;
    }
}

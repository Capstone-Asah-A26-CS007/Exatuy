package com.examora.model;

import java.math.BigDecimal;
import java.time.LocalDate;
import java.time.LocalDateTime;

/**
 * Expense Model - Pencatatan Pengeluaran Operasional
 */
public class Expense {
    private Integer id;
    private String kategori;
    private BigDecimal nominal;
    private LocalDate tanggal;
    private String deskripsi;
    private String bukti;
    private Integer createdBy;
    private LocalDateTime createdAt;

    public Expense() {}

    public Integer getId() { return id; }
    public void setId(Integer id) { this.id = id; }

    public String getKategori() { return kategori; }
    public void setKategori(String kategori) { this.kategori = kategori; }

    public BigDecimal getNominal() { return nominal; }
    public void setNominal(BigDecimal nominal) { this.nominal = nominal; }

    public LocalDate getTanggal() { return tanggal; }
    public void setTanggal(LocalDate tanggal) { this.tanggal = tanggal; }

    public String getDeskripsi() { return deskripsi; }
    public void setDeskripsi(String deskripsi) { this.deskripsi = deskripsi; }

    public String getBukti() { return bukti; }
    public void setBukti(String bukti) { this.bukti = bukti; }

    public Integer getCreatedBy() { return createdBy; }
    public void setCreatedBy(Integer createdBy) { this.createdBy = createdBy; }

    public LocalDateTime getCreatedAt() { return createdAt; }
    public void setCreatedAt(LocalDateTime createdAt) { this.createdAt = createdAt; }
}

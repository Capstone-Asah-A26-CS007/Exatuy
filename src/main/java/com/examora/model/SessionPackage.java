package com.examora.model;

import java.math.BigDecimal;
import java.time.LocalDate;

/**
 * Session Package Model - Paket Sesi Belajar
 */
public class SessionPackage {
    private Integer id;
    private String namaPaket;
    private Integer jumlahSesi;
    private BigDecimal harga;
    private Integer durasiBulan;
    private String deskripsi;
    private Boolean isActive;

    public SessionPackage() {}

    public Integer getId() { return id; }
    public void setId(Integer id) { this.id = id; }

    public String getNamaPaket() { return namaPaket; }
    public void setNamaPaket(String namaPaket) { this.namaPaket = namaPaket; }

    public Integer getJumlahSesi() { return jumlahSesi; }
    public void setJumlahSesi(Integer jumlahSesi) { this.jumlahSesi = jumlahSesi; }

    public BigDecimal getHarga() { return harga; }
    public void setHarga(BigDecimal harga) { this.harga = harga; }

    public Integer getDurasiBulan() { return durasiBulan; }
    public void setDurasiBulan(Integer durasiBulan) { this.durasiBulan = durasiBulan; }

    public String getDeskripsi() { return deskripsi; }
    public void setDeskripsi(String deskripsi) { this.deskripsi = deskripsi; }

    public Boolean getIsActive() { return isActive; }
    public void setIsActive(Boolean isActive) { this.isActive = isActive; }
}

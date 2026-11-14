package com.examora.model;

import java.time.LocalDateTime;

/**
 * Material Category Model - Kategori Silabus/Materi
 */
public class MaterialCategory {
    private Integer id;
    private String nama;
    private String deskripsi;
    private String jenjang; // SD, SMP, SMA, UMUM
    private String mataPelajaran;
    private Integer createdBy;
    private Boolean isActive;
    private LocalDateTime createdAt;

    public MaterialCategory() {}

    public Integer getId() { return id; }
    public void setId(Integer id) { this.id = id; }

    public String getNama() { return nama; }
    public void setNama(String nama) { this.nama = nama; }

    public String getDeskripsi() { return deskripsi; }
    public void setDeskripsi(String deskripsi) { this.deskripsi = deskripsi; }

    public String getJenjang() { return jenjang; }
    public void setJenjang(String jenjang) { this.jenjang = jenjang; }

    public String getMataPelajaran() { return mataPelajaran; }
    public void setMataPelajaran(String mataPelajaran) { this.mataPelajaran = mataPelajaran; }

    public Integer getCreatedBy() { return createdBy; }
    public void setCreatedBy(Integer createdBy) { this.createdBy = createdBy; }

    public Boolean getIsActive() { return isActive; }
    public void setIsActive(Boolean isActive) { this.isActive = isActive; }

    public LocalDateTime getCreatedAt() { return createdAt; }
    public void setCreatedAt(LocalDateTime createdAt) { this.createdAt = createdAt; }
}

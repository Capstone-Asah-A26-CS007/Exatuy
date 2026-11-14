package com.examora.model;

import java.time.LocalDate;

/**
 * Quota Tracker Model - Pelacak sisa kuota siswa
 */
public class QuotaTracker {
    private Integer id;
    private Integer studentId;
    private String studentName;
    private String studentEmail;
    private String studentTag;
    private Integer sessionPackageId;
    private String packageName;
    private Integer totalSesi;
    private Integer sisaSesi;
    private Integer usedSesi;
    private LocalDate lastSessionDate;
    private Boolean isWarning;

    public QuotaTracker() {
        this.isWarning = false;
    }

    public Integer getId() { return id; }
    public void setId(Integer id) { this.id = id; }

    public Integer getStudentId() { return studentId; }
    public void setStudentId(Integer studentId) { this.studentId = studentId; }

    public String getStudentName() { return studentName; }
    public void setStudentName(String studentName) { this.studentName = studentName; }

    public String getStudentEmail() { return studentEmail; }
    public void setStudentEmail(String studentEmail) { this.studentEmail = studentEmail; }

    public String getStudentTag() { return studentTag; }
    public void setStudentTag(String studentTag) { this.studentTag = studentTag; }

    public Integer getSessionPackageId() { return sessionPackageId; }
    public void setSessionPackageId(Integer sessionPackageId) { this.sessionPackageId = sessionPackageId; }

    public String getPackageName() { return packageName; }
    public void setPackageName(String packageName) { this.packageName = packageName; }

    public Integer getTotalSesi() { return totalSesi; }
    public void setTotalSesi(Integer totalSesi) { this.totalSesi = totalSesi; }

    public Integer getSisaSesi() { return sisaSesi; }
    public void setSisaSesi(Integer sisaSesi) { this.sisaSesi = sisaSesi; }

    public Integer getUsedSesi() { return usedSesi; }
    public void setUsedSesi(Integer usedSesi) { this.usedSesi = usedSesi; }

    public LocalDate getLastSessionDate() { return lastSessionDate; }
    public void setLastSessionDate(LocalDate lastSessionDate) { this.lastSessionDate = lastSessionDate; }

    public Boolean getIsWarning() { return isWarning; }
    public void setIsWarning(Boolean isWarning) { this.isWarning = isWarning; }

    public int getProgressPercent() {
        if (totalSesi == null || totalSesi == 0) return 0;
        return (int) ((double) usedSesi / totalSesi * 100);
    }
}

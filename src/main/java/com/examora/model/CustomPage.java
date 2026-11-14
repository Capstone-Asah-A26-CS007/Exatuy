package com.examora.model;

import java.time.LocalDateTime;
import java.time.ZoneId;
import java.time.ZonedDateTime;
import java.time.format.DateTimeFormatter;

/**
 * CustomPage Model - Represents custom menu links managed by admin
 */
public class CustomPage {
    private Integer id;
    private String menuName;
    private String menuLink;
    private String icon;
    private Boolean isActive;
    private Integer sortOrder;
    private String targetTag;
    private String adminComment;
    private LocalDateTime createdAt;
    private LocalDateTime updatedAt;

    // Constructors
    public CustomPage() {}

    public CustomPage(String menuName, String menuLink) {
        this.menuName = menuName;
        this.menuLink = menuLink;
        this.isActive = true;
        this.sortOrder = 0;
    }

    // Getters and Setters
    public Integer getId() { return id; }
    public void setId(Integer id) { this.id = id; }

    public String getMenuName() { return menuName; }
    public void setMenuName(String menuName) { this.menuName = menuName; }

    public String getMenuLink() { return menuLink; }
    public void setMenuLink(String menuLink) { this.menuLink = menuLink; }

    public String getIcon() { return icon; }
    public void setIcon(String icon) { this.icon = icon; }

    public Boolean getIsActive() { return isActive; }
    public void setIsActive(Boolean isActive) { this.isActive = isActive; }

    public Integer getSortOrder() { return sortOrder; }
    public void setSortOrder(Integer sortOrder) { this.sortOrder = sortOrder; }

    public String getTargetTag() { return targetTag; }
    public void setTargetTag(String targetTag) { this.targetTag = targetTag; }

    public String getAdminComment() { return adminComment; }
    public void setAdminComment(String adminComment) { this.adminComment = adminComment; }

    public LocalDateTime getCreatedAt() { return createdAt; }
    public void setCreatedAt(LocalDateTime createdAt) { this.createdAt = createdAt; }

    public LocalDateTime getUpdatedAt() { return updatedAt; }
    public void setUpdatedAt(LocalDateTime updatedAt) { this.updatedAt = updatedAt; }

    // Utility methods
    public String getFormattedCreatedAt() {
        if (createdAt == null) return "-";
        ZonedDateTime wibTime = createdAt.atZone(ZoneId.of("Asia/Jakarta"));
        DateTimeFormatter formatter = DateTimeFormatter.ofPattern("dd MMM yyyy, HH:mm");
        return wibTime.format(formatter) + " WIB";
    }

    public String getIconClass() {
        if (icon != null && !icon.trim().isEmpty()) {
            return icon;
        }
        return "bi-link-45deg";
    }

    public String getStatusBadge() {
        if (isActive != null && isActive) {
            return "<span class=\"badge bg-success\"><i class=\"bi bi-check-circle me-1\"></i>Aktif</span>";
        }
        return "<span class=\"badge bg-secondary\"><i class=\"bi bi-x-circle me-1\"></i>Tidak Aktif</span>";
    }
}

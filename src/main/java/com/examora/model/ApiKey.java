package com.examora.model;

import java.time.LocalDateTime;
import java.time.ZoneId;
import java.time.ZonedDateTime;
import java.time.format.DateTimeFormatter;

/**
 * ApiKey Model - Represents API keys for external integrations
 */
public class ApiKey {
    private Integer id;
    private String keyName;
    private String keyValue;  // Note: This should be encrypted in production
    private String keyType;   // custom, openai, google, etc.
    private String description;
    private Integer createdBy;
    private LocalDateTime lastUsedAt;
    private LocalDateTime expiresAt;
    private Boolean isActive;
    private LocalDateTime createdAt;
    private LocalDateTime updatedAt;

    // Display fields
    private String creatorName;

    // Constructors
    public ApiKey() {}

    public ApiKey(String keyName, String keyValue, String keyType, Integer createdBy) {
        this.keyName = keyName;
        this.keyValue = keyValue;
        this.keyType = keyType;
        this.createdBy = createdBy;
        this.isActive = true;
    }

    // Getters and Setters
    public Integer getId() { return id; }
    public void setId(Integer id) { this.id = id; }

    public String getKeyName() { return keyName; }
    public void setKeyName(String keyName) { this.keyName = keyName; }

    public String getKeyValue() { return keyValue; }
    public void setKeyValue(String keyValue) { this.keyValue = keyValue; }

    public String getKeyType() { return keyType; }
    public void setKeyType(String keyType) { this.keyType = keyType; }

    public String getDescription() { return description; }
    public void setDescription(String description) { this.description = description; }

    public Integer getCreatedBy() { return createdBy; }
    public void setCreatedBy(Integer createdBy) { this.createdBy = createdBy; }

    public LocalDateTime getLastUsedAt() { return lastUsedAt; }
    public void setLastUsedAt(LocalDateTime lastUsedAt) { this.lastUsedAt = lastUsedAt; }

    public LocalDateTime getExpiresAt() { return expiresAt; }
    public void setExpiresAt(LocalDateTime expiresAt) { this.expiresAt = expiresAt; }

    public Boolean getIsActive() { return isActive; }
    public void setIsActive(Boolean isActive) { this.isActive = isActive; }

    public LocalDateTime getCreatedAt() { return createdAt; }
    public void setCreatedAt(LocalDateTime createdAt) { this.createdAt = createdAt; }

    public LocalDateTime getUpdatedAt() { return updatedAt; }
    public void setUpdatedAt(LocalDateTime updatedAt) { this.updatedAt = updatedAt; }

    public String getCreatorName() { return creatorName; }
    public void setCreatorName(String creatorName) { this.creatorName = creatorName; }

    // Utility methods
    public String getFormattedCreatedAt() {
        if (createdAt == null) return "-";
        ZonedDateTime wibTime = createdAt.atZone(ZoneId.of("Asia/Jakarta"));
        DateTimeFormatter formatter = DateTimeFormatter.ofPattern("dd MMM yyyy, HH:mm");
        return wibTime.format(formatter) + " WIB";
    }

    public String getFormattedExpiresAt() {
        if (expiresAt == null) return "Never";
        ZonedDateTime wibTime = expiresAt.atZone(ZoneId.of("Asia/Jakarta"));
        DateTimeFormatter formatter = DateTimeFormatter.ofPattern("dd MMM yyyy, HH:mm");
        return wibTime.format(formatter) + " WIB";
    }

    public boolean isExpired() {
        if (expiresAt == null) return false;
        return LocalDateTime.now().isAfter(expiresAt);
    }

    public String getStatusBadge() {
        if (!getIsActive()) {
            return "<span class=\"badge bg-secondary\">Inactive</span>";
        }
        if (isExpired()) {
            return "<span class=\"badge bg-danger\">Expired</span>";
        }
        return "<span class=\"badge bg-success\">Active</span>";
    }

    public String getMaskedKey() {
        if (keyValue == null || keyValue.length() < 8) {
            return "****";
        }
        return keyValue.substring(0, 4) + "..." + keyValue.substring(keyValue.length() - 4);
    }
}

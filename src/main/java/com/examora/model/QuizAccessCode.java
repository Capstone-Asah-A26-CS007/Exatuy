package com.examora.model;

import java.time.LocalDateTime;

/**
 * Quiz Access Code - Control quiz access with codes
 */
public class QuizAccessCode {
    private Integer id;
    private Integer quizId;
    private String accessCode;
    private String codeName;
    private Integer maxUses;
    private Integer usedCount;
    private Boolean isActive;
    private LocalDateTime createdAt;
    private LocalDateTime expiresAt;
    private Integer createdBy;

    // Constructors
    public QuizAccessCode() {}

    public QuizAccessCode(Integer quizId, String accessCode, Integer createdBy) {
        this.quizId = quizId;
        this.accessCode = accessCode;
        this.createdBy = createdBy;
        this.isActive = true;
        this.usedCount = 0;
    }

    // Check if code is valid (not expired and active)
    public boolean isValid() {
        if (isActive == null || !isActive) {
            return false;
        }
        if (expiresAt != null) {
            return LocalDateTime.now().isBefore(expiresAt);
        }
        if (maxUses != null && usedCount != null && usedCount >= maxUses) {
            return false;
        }
        return true;
    }

    // Check if code has unlimited uses
    public boolean hasUnlimitedUses() {
        return maxUses == null;
    }

    // Check if code can still be used
    public boolean canBeUsed() {
        return isValid() && (hasUnlimitedUses() || (usedCount != null && maxUses != null && usedCount < maxUses));
    }

    // Getters and Setters
    public Integer getId() { return id; }
    public void setId(Integer id) { this.id = id; }

    public Integer getQuizId() { return quizId; }
    public void setQuizId(Integer quizId) { this.quizId = quizId; }

    public String getAccessCode() { return accessCode; }
    public void setAccessCode(String accessCode) { this.accessCode = accessCode; }

    public String getCodeName() { return codeName; }
    public void setCodeName(String codeName) { this.codeName = codeName; }

    public Integer getMaxUses() { return maxUses; }
    public void setMaxUses(Integer maxUses) { this.maxUses = maxUses; }

    public Integer getUsedCount() { return usedCount; }
    public void setUsedCount(Integer usedCount) { this.usedCount = usedCount; }

    public Boolean getIsActive() { return isActive; }
    public void setIsActive(Boolean isActive) { this.isActive = isActive; }

    public LocalDateTime getCreatedAt() { return createdAt; }
    public void setCreatedAt(LocalDateTime createdAt) { this.createdAt = createdAt; }

    public LocalDateTime getExpiresAt() { return expiresAt; }
    public void setExpiresAt(LocalDateTime expiresAt) { this.expiresAt = expiresAt; }

    public Integer getCreatedBy() { return createdBy; }
    public void setCreatedBy(Integer createdBy) { this.createdBy = createdBy; }

    public String getFormattedExpiresAt() {
        if (expiresAt == null) return "Unlimited";
        return expiresAt.format(java.time.format.DateTimeFormatter.ofPattern("dd MMM yyyy, HH:mm"));
    }
}

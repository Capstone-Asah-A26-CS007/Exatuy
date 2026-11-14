package com.examora.model;

import java.time.LocalDateTime;

/**
 * Model class for retake codes that allow users to take quizzes after deadline
 */
public class RetakeCode {
    private Integer id;
    private Integer quizId;
    private Integer userId;
    private String retakeCode;
    private Boolean isUsed;
    private LocalDateTime createdAt;
    private LocalDateTime expiresAt;
    private LocalDateTime usedAt;
    private Integer createdBy;

    // Default constructor
    public RetakeCode() {}

    // Constructor for creating new retake code
    public RetakeCode(Integer quizId, Integer userId, String retakeCode, Integer createdBy) {
        this.quizId = quizId;
        this.userId = userId;
        this.retakeCode = retakeCode;
        this.createdBy = createdBy;
        this.isUsed = false;
    }

    // Check if code is valid (not used and not expired)
    public boolean isValid() {
        if (isUsed != null && isUsed) {
            return false;
        }
        if (expiresAt != null) {
            return LocalDateTime.now().isBefore(expiresAt);
        }
        return true;
    }

    // Getters and Setters
    public Integer getId() {
        return id;
    }

    public void setId(Integer id) {
        this.id = id;
    }

    public Integer getQuizId() {
        return quizId;
    }

    public void setQuizId(Integer quizId) {
        this.quizId = quizId;
    }

    public Integer getUserId() {
        return userId;
    }

    public void setUserId(Integer userId) {
        this.userId = userId;
    }

    public String getRetakeCode() {
        return retakeCode;
    }

    public void setRetakeCode(String retakeCode) {
        this.retakeCode = retakeCode;
    }

    public Boolean getIsUsed() {
        return isUsed;
    }

    public void setIsUsed(Boolean isUsed) {
        this.isUsed = isUsed;
    }

    public LocalDateTime getCreatedAt() {
        return createdAt;
    }

    public void setCreatedAt(LocalDateTime createdAt) {
        this.createdAt = createdAt;
    }

    public LocalDateTime getExpiresAt() {
        return expiresAt;
    }

    public void setExpiresAt(LocalDateTime expiresAt) {
        this.expiresAt = expiresAt;
    }

    public LocalDateTime getUsedAt() {
        return usedAt;
    }

    public void setUsedAt(LocalDateTime usedAt) {
        this.usedAt = usedAt;
    }

    public Integer getCreatedBy() {
        return createdBy;
    }

    public void setCreatedBy(Integer createdBy) {
        this.createdBy = createdBy;
    }

    @Override
    public String toString() {
        return "RetakeCode{" +
                "id=" + id +
                ", quizId=" + quizId +
                ", userId=" + userId +
                ", retakeCode='" + retakeCode + '\'' +
                ", isUsed=" + isUsed +
                ", createdAt=" + createdAt +
                ", expiresAt=" + expiresAt +
                ", usedAt=" + usedAt +
                ", createdBy=" + createdBy +
                '}';
    }
}

package com.examora.model;

import java.time.LocalDateTime;
import java.time.ZoneId;
import java.time.ZonedDateTime;
import java.time.format.DateTimeFormatter;

/**
 * PointTransaction Model - Represents point transactions history
 */
public class PointTransaction {
    private Integer id;
    private Integer userId;
    private Integer points;  // Can be positive (earned) or negative (spent)
    private String transactionType;  // quiz_complete, achievement, daily_login, etc.
    private String sourceType;  // quiz, achievement, admin, etc.
    private Integer sourceId;
    private String description;
    private LocalDateTime createdAt;

    // Display fields
    private String userName;
    private String sourceName;

    // Constructors
    public PointTransaction() {}

    public PointTransaction(Integer userId, Integer points, String transactionType,
                          String sourceType, Integer sourceId, String description) {
        this.userId = userId;
        this.points = points;
        this.transactionType = transactionType;
        this.sourceType = sourceType;
        this.sourceId = sourceId;
        this.description = description;
    }

    // Getters and Setters
    public Integer getId() { return id; }
    public void setId(Integer id) { this.id = id; }

    public Integer getUserId() { return userId; }
    public void setUserId(Integer userId) { this.userId = userId; }

    public Integer getPoints() { return points; }
    public void setPoints(Integer points) { this.points = points; }

    public String getTransactionType() { return transactionType; }
    public void setTransactionType(String transactionType) { this.transactionType = transactionType; }

    public String getSourceType() { return sourceType; }
    public void setSourceType(String sourceType) { this.sourceType = sourceType; }

    public Integer getSourceId() { return sourceId; }
    public void setSourceId(Integer sourceId) { this.sourceId = sourceId; }

    public String getDescription() { return description; }
    public void setDescription(String description) { this.description = description; }

    public LocalDateTime getCreatedAt() { return createdAt; }
    public void setCreatedAt(LocalDateTime createdAt) { this.createdAt = createdAt; }

    public String getUserName() { return userName; }
    public void setUserName(String userName) { this.userName = userName; }

    public String getSourceName() { return sourceName; }
    public void setSourceName(String sourceName) { this.sourceName = sourceName; }

    // Utility methods
    public String getFormattedCreatedAt() {
        if (createdAt == null) return "-";
        ZonedDateTime wibTime = createdAt.atZone(ZoneId.of("Asia/Jakarta"));
        DateTimeFormatter formatter = DateTimeFormatter.ofPattern("dd MMM yyyy, HH:mm");
        return wibTime.format(formatter) + " WIB";
    }

    public String getPointsDisplay() {
        if (points == null) return "0";
        if (points > 0) {
            return "<span class=\"text-success\">+" + points + "</span>";
        } else if (points < 0) {
            return "<span class=\"text-danger\">" + points + "</span>";
        }
        return "0";
    }

    public String getTransactionTypeBadge() {
        switch (transactionType != null ? transactionType : "") {
            case "quiz_complete":
                return "<span class=\"badge bg-success\">Quiz</span>";
            case "achievement":
                return "<span class=\"badge bg-warning\">Achievement</span>";
            case "daily_login":
                return "<span class=\"badge bg-info\">Login Harian</span>";
            case "admin_bonus":
                return "<span class=\"badge bg-primary\">Bonus Admin</span>";
            case "perfect_score":
                return "<span class=\"badge bg-danger\">Perfect Score</span>";
            case "points_spent":
                return "<span class=\"badge bg-secondary\">Ditukarkan</span>";
            default:
                return "<span class=\"badge bg-secondary\">" + transactionType + "</span>";
        }
    }
}

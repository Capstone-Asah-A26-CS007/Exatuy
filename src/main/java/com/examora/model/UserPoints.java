package com.examora.model;

import java.time.LocalDateTime;
import java.time.ZoneId;
import java.time.ZonedDateTime;
import java.time.format.DateTimeFormatter;

/**
 * UserPoints Model - Represents user points and level in gamification system
 */
public class UserPoints {
    private Integer id;
    private Integer userId;
    private Integer totalPoints;
    private Integer level;
    private Integer experiencePoints;
    private LocalDateTime createdAt;
    private LocalDateTime updatedAt;

    // Display fields
    private String userName;
    private String rank;
    private Integer nextLevel;
    private Integer nextLevelExp;
    private Integer currentLevelExp;
    private Integer progressToNext;

    // Constructors
    public UserPoints() {}

    public UserPoints(Integer userId) {
        this.userId = userId;
        this.totalPoints = 0;
        this.level = 1;
        this.experiencePoints = 0;
    }

    // Getters and Setters
    public Integer getId() { return id; }
    public void setId(Integer id) { this.id = id; }

    public Integer getUserId() { return userId; }
    public void setUserId(Integer userId) { this.userId = userId; }

    public Integer getTotalPoints() { return totalPoints; }
    public void setTotalPoints(Integer totalPoints) { this.totalPoints = totalPoints; }

    public Integer getLevel() { return level; }
    public void setLevel(Integer level) { this.level = level; }

    public Integer getExperiencePoints() { return experiencePoints; }
    public void setExperiencePoints(Integer experiencePoints) { this.experiencePoints = experiencePoints; }

    public LocalDateTime getCreatedAt() { return createdAt; }
    public void setCreatedAt(LocalDateTime createdAt) { this.createdAt = createdAt; }

    public LocalDateTime getUpdatedAt() { return updatedAt; }
    public void setUpdatedAt(LocalDateTime updatedAt) { this.updatedAt = updatedAt; }

    public String getUserName() { return userName; }
    public void setUserName(String userName) { this.userName = userName; }

    public String getRank() { return rank; }
    public void setRank(String rank) { this.rank = rank; }

    public Integer getNextLevel() { return nextLevel; }
    public void setNextLevel(Integer nextLevel) { this.nextLevel = nextLevel; }

    public Integer getNextLevelExp() { return nextLevelExp; }
    public void setNextLevelExp(Integer nextLevelExp) { this.nextLevelExp = nextLevelExp; }

    public Integer getCurrentLevelExp() { return currentLevelExp; }
    public void setCurrentLevelExp(Integer currentLevelExp) { this.currentLevelExp = currentLevelExp; }

    public Integer getProgressToNext() { return progressToNext; }
    public void setProgressToNext(Integer progressToNext) { this.progressToNext = progressToNext; }

    // Utility methods
    public String getFormattedUpdatedAt() {
        if (updatedAt == null) return "-";
        ZonedDateTime wibTime = updatedAt.atZone(ZoneId.of("Asia/Jakarta"));
        DateTimeFormatter formatter = DateTimeFormatter.ofPattern("dd MMM yyyy, HH:mm");
        return wibTime.format(formatter) + " WIB";
    }

    public String getLevelBadge() {
        String[] badgeColors = {"bg-secondary", "bg-primary", "bg-info", "bg-success", "bg-warning", "bg-danger", "bg-gradient"};
        String[] badgeNames = {"Beginner", "Novice", "Learner", "Scholar", "Expert", "Master", "Grandmaster"};
        int badgeIndex = Math.min(level - 1, badgeColors.length - 1);
        return "<span class=\"badge " + badgeColors[badgeIndex] + "\">" + badgeNames[badgeIndex] + "</span>";
    }

    public String getLevelTitle() {
        String[] badgeNames = {"Beginner", "Novice", "Intermediate", "Advanced", "Expert", "Master", "Grandmaster"};
        int badgeIndex = Math.min(level - 1, badgeNames.length - 1);
        return badgeNames[badgeIndex];
    }

    public Integer getUserRank() {
        // This should be set from the DAO when fetching leaderboard
        // Default to 0 if not set
        return rank != null ? Integer.valueOf(rank) : 0;
    }

    public int progressToNext() {
        if (progressToNext == null) return 0;
        return Math.max(0, Math.min(100, progressToNext));
    }
}

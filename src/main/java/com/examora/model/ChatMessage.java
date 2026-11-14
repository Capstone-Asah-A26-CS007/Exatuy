package com.examora.model;

import java.time.Duration;
import java.time.LocalDateTime;

/**
 * ChatMessage Model - Represents a chat message between user and admin
 */
public class ChatMessage {
    private Integer id;
    private Integer userId;
    private String senderType; // "user" or "admin"
    private Integer adminId;
    private String messageText;
    private Boolean isRead;
    private LocalDateTime createdAt;

    // Display fields (joined from users table)
    private String senderName;
    private String senderPhoto;

    // Constructors
    public ChatMessage() {}

    public ChatMessage(Integer userId, String senderType, String messageText) {
        this.userId = userId;
        this.senderType = senderType;
        this.messageText = messageText;
        this.isRead = false;
        this.createdAt = LocalDateTime.now();
    }

    public ChatMessage(Integer userId, String senderType, Integer adminId, String messageText) {
        this.userId = userId;
        this.senderType = senderType;
        this.adminId = adminId;
        this.messageText = messageText;
        this.isRead = false;
        this.createdAt = LocalDateTime.now();
    }

    // Getters and Setters
    public Integer getId() {
        return id;
    }

    public void setId(Integer id) {
        this.id = id;
    }

    public Integer getUserId() {
        return userId;
    }

    public void setUserId(Integer userId) {
        this.userId = userId;
    }

    public String getSenderType() {
        return senderType;
    }

    public void setSenderType(String senderType) {
        this.senderType = senderType;
    }

    public Integer getAdminId() {
        return adminId;
    }

    public void setAdminId(Integer adminId) {
        this.adminId = adminId;
    }

    public String getMessageText() {
        return messageText;
    }

    public void setMessageText(String messageText) {
        this.messageText = messageText;
    }

    public Boolean getIsRead() {
        return isRead;
    }

    public void setIsRead(Boolean isRead) {
        this.isRead = isRead;
    }

    public LocalDateTime getCreatedAt() {
        return createdAt;
    }

    public void setCreatedAt(LocalDateTime createdAt) {
        this.createdAt = createdAt;
    }

    public String getSenderName() {
        return senderName;
    }

    public void setSenderName(String senderName) {
        this.senderName = senderName;
    }

    public String getSenderPhoto() {
        return senderPhoto;
    }

    public void setSenderPhoto(String senderPhoto) {
        this.senderPhoto = senderPhoto;
    }

    // Helper methods
    public boolean isFromUser() {
        return "user".equals(senderType);
    }

    public boolean isFromAdmin() {
        return "admin".equals(senderType);
    }

    /**
     * Get time ago string (e.g., "2 menit lalu", "1 jam lalu")
     */
    public String getTimeAgo() {
        if (createdAt == null) {
            return "";
        }

        Duration duration = Duration.between(createdAt, LocalDateTime.now());
        long seconds = duration.getSeconds();

        if (seconds < 60) {
            return "Baru saja";
        } else if (seconds < 3600) {
            long minutes = seconds / 60;
            return minutes + " menit lalu";
        } else if (seconds < 86400) {
            long hours = seconds / 3600;
            return hours + " jam lalu";
        } else if (seconds < 604800) {
            long days = seconds / 86400;
            return days + " hari lalu";
        } else {
            long weeks = seconds / 604800;
            return weeks + " minggu lalu";
        }
    }

    /**
     * Get formatted time (HH:mm)
     */
    public String getFormattedTime() {
        if (createdAt == null) {
            return "";
        }
        return String.format("%02d:%02d", createdAt.getHour(), createdAt.getMinute());
    }

    /**
     * Get formatted date and time (dd MMM yyyy HH:mm)
     */
    public String getFormattedDateTime() {
        if (createdAt == null) {
            return "";
        }
        String[] months = {"", "Jan", "Feb", "Mar", "Apr", "Mei", "Jun", "Jul", "Agu", "Sep", "Okt", "Nov", "Des"};
        return String.format("%d %s %d %02d:%02d",
                createdAt.getDayOfMonth(),
                months[createdAt.getMonthValue()],
                createdAt.getYear(),
                createdAt.getHour(),
                createdAt.getMinute());
    }

    @Override
    public String toString() {
        return "ChatMessage{" +
                "id=" + id +
                ", userId=" + userId +
                ", senderType='" + senderType + '\'' +
                ", adminId=" + adminId +
                ", isRead=" + isRead +
                ", createdAt=" + createdAt +
                '}';
    }
}

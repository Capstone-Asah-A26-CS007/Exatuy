package com.examora.model;

import java.time.LocalDateTime;

/**
 * QuizExemption Model - Represents a user exemption from a quiz
 * Users who are exempted automatically get perfect scores without taking the quiz
 */
public class QuizExemption {
    private Integer id;
    private Integer quizId;
    private Integer userId;
    private Integer exemptedBy;
    private LocalDateTime createdAt;
    private String notes;

    // Related data for display
    private String userName;
    private String userEmail;
    private String userTag;
    private String exemptedByName;
    private String quizTitle;

    // Constructors
    public QuizExemption() {}

    public QuizExemption(Integer quizId, Integer userId, Integer exemptedBy) {
        this.quizId = quizId;
        this.userId = userId;
        this.exemptedBy = exemptedBy;
    }

    public QuizExemption(Integer quizId, Integer userId, Integer exemptedBy, String notes) {
        this.quizId = quizId;
        this.userId = userId;
        this.exemptedBy = exemptedBy;
        this.notes = notes;
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

    public Integer getExemptedBy() {
        return exemptedBy;
    }

    public void setExemptedBy(Integer exemptedBy) {
        this.exemptedBy = exemptedBy;
    }

    public LocalDateTime getCreatedAt() {
        return createdAt;
    }

    public void setCreatedAt(LocalDateTime createdAt) {
        this.createdAt = createdAt;
    }

    public String getNotes() {
        return notes;
    }

    public void setNotes(String notes) {
        this.notes = notes;
    }

    public String getUserName() {
        return userName;
    }

    public void setUserName(String userName) {
        this.userName = userName;
    }

    public String getUserEmail() {
        return userEmail;
    }

    public void setUserEmail(String userEmail) {
        this.userEmail = userEmail;
    }

    public String getUserTag() {
        return userTag;
    }

    public void setUserTag(String userTag) {
        this.userTag = userTag;
    }

    public String getExemptedByName() {
        return exemptedByName;
    }

    public void setExemptedByName(String exemptedByName) {
        this.exemptedByName = exemptedByName;
    }

    public String getQuizTitle() {
        return quizTitle;
    }

    public void setQuizTitle(String quizTitle) {
        this.quizTitle = quizTitle;
    }

    @Override
    public String toString() {
        return "QuizExemption{" +
                "id=" + id +
                ", quizId=" + quizId +
                ", userId=" + userId +
                ", exemptedBy=" + exemptedBy +
                ", notes='" + notes + '\'' +
                '}';
    }
}

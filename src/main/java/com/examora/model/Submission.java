package com.examora.model;

import java.time.LocalDateTime;
import java.util.List;

/**
 * Submission Model - Represents a quiz submission
 */
public class Submission {
    private Integer id;
    private Integer quizId;
    private Integer userId;
    private Double score;
    private Integer totalQuestions;
    private Integer correctAnswers;
    private LocalDateTime startedAt;
    private LocalDateTime submittedAt;
    private Integer timeSpent; // in seconds
    private String questionOrder; // comma-separated question IDs (shuffled order)
    private String status; // in_progress, completed, timeout
    private Boolean isRetake; // true if this submission used a retake code
    private Integer accumulatedPauseSeconds; // total seconds paused (offline/tab hidden)
    private LocalDateTime lastActivityAt; // last time user was active

    // Related data
    private String userName;
    private String userEmail;
    private String userTag;
    private String quizTitle;
    private List<Answer> answers;

    // Constructors
    public Submission() {}

    public Submission(Integer quizId, Integer userId) {
        this.quizId = quizId;
        this.userId = userId;
        this.score = 0.0;
        this.totalQuestions = 0;
        this.correctAnswers = 0;
        this.startedAt = LocalDateTime.now();
        this.status = "in_progress";
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

    public Double getScore() {
        return score;
    }

    public void setScore(Double score) {
        this.score = score;
    }

    public Integer getTotalQuestions() {
        return totalQuestions;
    }

    public void setTotalQuestions(Integer totalQuestions) {
        this.totalQuestions = totalQuestions;
    }

    public Integer getCorrectAnswers() {
        return correctAnswers;
    }

    public void setCorrectAnswers(Integer correctAnswers) {
        this.correctAnswers = correctAnswers;
    }

    public LocalDateTime getStartedAt() {
        return startedAt;
    }

    public void setStartedAt(LocalDateTime startedAt) {
        this.startedAt = startedAt;
    }

    public LocalDateTime getSubmittedAt() {
        return submittedAt;
    }

    public void setSubmittedAt(LocalDateTime submittedAt) {
        this.submittedAt = submittedAt;
    }

    public Integer getTimeSpent() {
        return timeSpent;
    }

    public void setTimeSpent(Integer timeSpent) {
        this.timeSpent = timeSpent;
    }

    public String getQuestionOrder() {
        return questionOrder;
    }

    public void setQuestionOrder(String questionOrder) {
        this.questionOrder = questionOrder;
    }

    public String getStatus() {
        return status;
    }

    public void setStatus(String status) {
        this.status = status;
    }

    public Boolean getIsRetake() {
        return isRetake;
    }

    public void setIsRetake(Boolean isRetake) {
        this.isRetake = isRetake;
    }

    public Integer getAccumulatedPauseSeconds() {
        return accumulatedPauseSeconds;
    }

    public void setAccumulatedPauseSeconds(Integer accumulatedPauseSeconds) {
        this.accumulatedPauseSeconds = accumulatedPauseSeconds;
    }

    public LocalDateTime getLastActivityAt() {
        return lastActivityAt;
    }

    public void setLastActivityAt(LocalDateTime lastActivityAt) {
        this.lastActivityAt = lastActivityAt;
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

    public String getQuizTitle() {
        return quizTitle;
    }

    public void setQuizTitle(String quizTitle) {
        this.quizTitle = quizTitle;
    }

    public List<Answer> getAnswers() {
        return answers;
    }

    public void setAnswers(List<Answer> answers) {
        this.answers = answers;
    }

    // Helper methods
    public boolean isCompleted() {
        return "completed".equals(status) || "timeout".equals(status);
    }

    public boolean isTimeout() {
        return "timeout".equals(status);
    }

    public boolean isInProgress() {
        return "in_progress".equals(status);
    }

    public String getFormattedTimeSpent() {
        if (timeSpent == null) return "N/A";
        int minutes = timeSpent / 60;
        int seconds = timeSpent % 60;
        return String.format("%02d:%02d", minutes, seconds);
    }

    @Override
    public String toString() {
        return "Submission{" +
                "id=" + id +
                ", quizId=" + quizId +
                ", userId=" + userId +
                ", score=" + score +
                ", status='" + status + '\'' +
                '}';
    }
}

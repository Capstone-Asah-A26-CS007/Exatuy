package com.examora.model;

import java.time.LocalDateTime;

/**
 * Question Model - Represents a multiple choice question
 */
public class Question {
    private Integer id;
    private Integer quizId;
    private String questionText;
    private String imagePath; // Path to question image (optional)
    private String optionA;
    private String optionB;
    private String optionC;
    private String optionD;
    private String correctAnswer; // A, B, C, or D
    private Integer questionOrder;
    private LocalDateTime createdAt;

    // Question Bank fields
    private Integer categoryId;

    // For user answers
    private String selectedAnswer;
    private Boolean isCorrect;

    // Quiz enhancement fields
    private String explanation; // explanation for the correct answer
    private Integer totalAttempts; // number of times this question was answered
    private Integer correctAttempts; // number of times answered correctly
    private Double difficultyIndex; // calculated difficulty (0.0 = easy, 1.0 = hard)

    // Constructors
    public Question() {}

    public Question(Integer quizId, String questionText, String optionA, String optionB,
                    String optionC, String optionD, String correctAnswer) {
        this.quizId = quizId;
        this.questionText = questionText;
        this.optionA = optionA;
        this.optionB = optionB;
        this.optionC = optionC;
        this.optionD = optionD;
        this.correctAnswer = correctAnswer;
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

    public String getQuestionText() {
        return questionText;
    }

    public void setQuestionText(String questionText) {
        this.questionText = questionText;
    }

    public String getImagePath() {
        return imagePath;
    }

    public void setImagePath(String imagePath) {
        this.imagePath = imagePath;
    }

    public String getOptionA() {
        return optionA;
    }

    public void setOptionA(String optionA) {
        this.optionA = optionA;
    }

    public String getOptionB() {
        return optionB;
    }

    public void setOptionB(String optionB) {
        this.optionB = optionB;
    }

    public String getOptionC() {
        return optionC;
    }

    public void setOptionC(String optionC) {
        this.optionC = optionC;
    }

    public String getOptionD() {
        return optionD;
    }

    public void setOptionD(String optionD) {
        this.optionD = optionD;
    }

    public String getCorrectAnswer() {
        return correctAnswer;
    }

    public void setCorrectAnswer(String correctAnswer) {
        this.correctAnswer = correctAnswer;
    }

    public Integer getQuestionOrder() {
        return questionOrder;
    }

    public void setQuestionOrder(Integer questionOrder) {
        this.questionOrder = questionOrder;
    }

    public LocalDateTime getCreatedAt() {
        return createdAt;
    }

    public void setCreatedAt(LocalDateTime createdAt) {
        this.createdAt = createdAt;
    }

    public String getSelectedAnswer() {
        return selectedAnswer;
    }

    public void setSelectedAnswer(String selectedAnswer) {
        this.selectedAnswer = selectedAnswer;
    }

    public Boolean getIsCorrect() {
        return isCorrect;
    }

    public void setIsCorrect(Boolean isCorrect) {
        this.isCorrect = isCorrect;
    }

    public Integer getCategoryId() {
        return categoryId;
    }

    public void setCategoryId(Integer categoryId) {
        this.categoryId = categoryId;
    }

    public String getExplanation() {
        return explanation;
    }

    public void setExplanation(String explanation) {
        this.explanation = explanation;
    }

    public Integer getTotalAttempts() {
        return totalAttempts;
    }

    public void setTotalAttempts(Integer totalAttempts) {
        this.totalAttempts = totalAttempts;
    }

    public Integer getCorrectAttempts() {
        return correctAttempts;
    }

    public void setCorrectAttempts(Integer correctAttempts) {
        this.correctAttempts = correctAttempts;
    }

    public Double getDifficultyIndex() {
        return difficultyIndex;
    }

    public void setDifficultyIndex(Double difficultyIndex) {
        this.difficultyIndex = difficultyIndex;
    }

    // Helper method to get option by letter
    public String getOptionByLetter(String letter) {
        switch (letter.toUpperCase()) {
            case "A": return optionA;
            case "B": return optionB;
            case "C": return optionC;
            case "D": return optionD;
            default: return null;
        }
    }

    // Helper method to get correct percentage
    public double getCorrectPercentage() {
        if (totalAttempts == null || totalAttempts == 0) {
            return 0.0;
        }
        return (correctAttempts != null ? correctAttempts : 0) * 100.0 / totalAttempts;
    }

    // Helper method to get difficulty label
    public String getDifficultyLabel() {
        if (difficultyIndex == null) {
            return "N/A";
        }
        double pct = getCorrectPercentage();
        if (pct >= 70) return "Mudah";
        if (pct >= 40) return "Sedang";
        return "Sulit";
    }

    @Override
    public String toString() {
        return "Question{" +
                "id=" + id +
                ", quizId=" + quizId +
                ", questionText='" + questionText + '\'' +
                ", correctAnswer='" + correctAnswer + '\'' +
                '}';
    }
}

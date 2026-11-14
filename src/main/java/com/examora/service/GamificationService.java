package com.examora.service;

import com.examora.dao.ApiKeyDAO;
import com.examora.dao.PointTransactionDAO;
import com.examora.dao.UserPointsDAO;
import com.examora.dao.InformationBoardDAO;
import com.examora.model.*;

import java.security.SecureRandom;
import java.sql.SQLException;
import java.util.Base64;
import java.util.List;

/**
 * GamificationService - Handles points, levels, leaderboards, and achievements
 */
public class GamificationService {
    private UserPointsDAO userPointsDAO;
    private PointTransactionDAO pointTransactionDAO;

    // Point values for different actions
    private static final int POINTS_QUIZ_COMPLETE = 100;
    private static final int POINTS_PERFECT_SCORE = 50;
    private static final int POINTS_ACHIEVEMENT = 25;
    private static final int POINTS_DAILY_LOGIN = 10;
    private static final int POINTS_HELPFUL = 5;

    // Speed bonus points
    private static final int SPEED_BONUS_VERY_FAST = 100;  // < 30% of time
    private static final int SPEED_BONUS_FAST = 50;        // 30-50% of time
    private static final int SPEED_BONUS_MODERATE = 25;    // 50-75% of time
    private static final int SPEED_BONUS_SLOW = 10;        // 75-100% of time

    // Level requirements (experience points needed)
    private static final int[] LEVEL_REQUIREMENTS = {0, 100, 500, 1500, 3500, 7500, 15000};

    public GamificationService() {
        this.userPointsDAO = new UserPointsDAO();
        this.pointTransactionDAO = new PointTransactionDAO();
    }

    // ==================== USER POINTS ====================

    /**
     * Get user points record
     */
    public UserPoints getUserPoints(Integer userId) throws ServiceException {
        try {
            return userPointsDAO.getOrCreate(userId);
        } catch (SQLException e) {
            throw new ServiceException("Gagal mengambil data points: " + e.getMessage(), e);
        }
    }

    /**
     * Add points to user
     */
    public void addPoints(Integer userId, Integer points, String transactionType,
                        String sourceType, Integer sourceId, String description) throws ServiceException {
        try {
            // Create transaction record
            PointTransaction transaction = new PointTransaction(
                userId, points, transactionType, sourceType, sourceId, description
            );
            pointTransactionDAO.create(transaction);

            // Update user points
            UserPoints userPoints = userPointsDAO.getOrCreate(userId);
            userPoints.setTotalPoints(userPoints.getTotalPoints() + points);
            userPointsDAO.update(userPoints);

            // Check for level up
            checkLevelUp(userPoints);
        } catch (SQLException e) {
            throw new ServiceException("Gagal menambah points: " + e.getMessage(), e);
        }
    }

    /**
     * Check and perform level up
     */
    private void checkLevelUp(UserPoints userPoints) throws SQLException {
        int currentExp = userPoints.getExperiencePoints();
        int newLevel = calculateLevel(currentExp);

        if (newLevel > userPoints.getLevel()) {
            userPoints.setLevel(newLevel);
            userPointsDAO.update(userPoints);
            // Could trigger notification here
        }
    }

    /**
     * Calculate level based on experience points
     */
    public int calculateLevel(int experiencePoints) {
        int level = 1;
        for (int i = 0; i < LEVEL_REQUIREMENTS.length; i++) {
            if (experiencePoints >= LEVEL_REQUIREMENTS[i]) {
                level = i + 1;
            }
        }
        return Math.min(level, 7); // Max level is 7 (Grandmaster)
    }

    /**
     * Calculate experience points needed for next level
     */
    public int getExpForNextLevel(int currentLevel) {
        if (currentLevel >= 7) return LEVEL_REQUIREMENTS[6];
        return LEVEL_REQUIREMENTS[currentLevel];
    }

    /**
     * Award points for quiz completion
     */
    public void awardQuizPoints(Integer userId, Integer quizId, Integer score, Integer maxScore) throws ServiceException {
        awardQuizPoints(userId, quizId, score, maxScore, null, null);
    }

    /**
     * Award points for quiz completion with speed bonus
     */
    public void awardQuizPoints(Integer userId, Integer quizId, Integer score, Integer maxScore,
                               Integer timeSpentSeconds, Integer durationMinutes) throws ServiceException {
        int points = POINTS_QUIZ_COMPLETE;

        // Bonus points for high scores
        if (score != null && maxScore != null && score.equals(maxScore)) {
            points += POINTS_PERFECT_SCORE;
        }

        // Calculate speed bonus if time information is available
        int speedBonus = 0;
        if (timeSpentSeconds != null && durationMinutes != null && durationMinutes > 0) {
            speedBonus = calculateSpeedBonus(timeSpentSeconds, durationMinutes);
            if (speedBonus > 0) {
                points += speedBonus;
            }
        }

        // Build description
        String description = "Penyelesaian quiz";
        if (score != null && maxScore != null && score.equals(maxScore)) {
            description += " (Perfect Score!";
            if (speedBonus > 0) {
                description += ", Speed Bonus: +" + speedBonus;
            }
            description += ")";
        } else if (speedBonus > 0) {
            description += " (Speed Bonus: +" + speedBonus + ")";
        }

        addPoints(userId, points, "quiz_complete", "quiz", quizId, description);
    }

    /**
     * Calculate speed bonus based on time spent vs time limit
     * @param timeSpentSeconds Time spent in seconds
     * @param durationMinutes Quiz duration in minutes
     * @return Bonus points based on speed
     */
    public int calculateSpeedBonus(Integer timeSpentSeconds, Integer durationMinutes) {
        if (timeSpentSeconds == null || durationMinutes == null || durationMinutes <= 0) {
            return 0;
        }

        // Convert duration to seconds
        int timeLimitSeconds = durationMinutes * 60;

        // Calculate percentage of time used
        double timePercentage = (double) timeSpentSeconds / timeLimitSeconds * 100;

        // Award bonus based on speed
        if (timePercentage < 30) {
            return SPEED_BONUS_VERY_FAST;  // Very fast - 100 points
        } else if (timePercentage < 50) {
            return SPEED_BONUS_FAST;        // Fast - 50 points
        } else if (timePercentage < 75) {
            return SPEED_BONUS_MODERATE;    // Moderate - 25 points
        } else if (timePercentage <= 100) {
            return SPEED_BONUS_SLOW;        // Slow - 10 points
        } else {
            return 0;  // Overtime - no bonus
        }
    }

    /**
     * Award points for achievement
     */
    public void awardAchievementPoints(Integer userId, Integer achievementId, String achievementName) throws ServiceException {
        addPoints(userId, POINTS_ACHIEVEMENT, "achievement", "achievement", achievementId,
                "Achievement: " + achievementName);
    }

    /**
     * Award daily login points (once per day)
     */
    public boolean awardDailyLoginPoints(Integer userId) throws ServiceException {
        // Check if already logged in today
        // This is a simplified version - in production, you'd check last login date
        addPoints(userId, POINTS_DAILY_LOGIN, "daily_login", "system", null,
                "Login harian");
        return true;
    }

    /**
     * Get leaderboard
     */
    public List<UserPoints> getLeaderboard(int limit, String periodType) throws ServiceException {
        try {
            return userPointsDAO.getLeaderboard(limit, periodType);
        } catch (SQLException e) {
            throw new ServiceException("Gagal mengambil leaderboard: " + e.getMessage(), e);
        }
    }

    /**
     * Get user rank
     */
    public int getUserRank(Integer userId) throws ServiceException {
        try {
            return userPointsDAO.getUserRank(userId);
        } catch (SQLException e) {
            throw new ServiceException("Gagal mengambil rank: " + e.getMessage(), e);
        }
    }

    /**
     * Get point transaction history
     */
    public List<PointTransaction> getTransactionHistory(Integer userId) throws ServiceException {
        try {
            return pointTransactionDAO.findByUserId(userId);
        } catch (SQLException e) {
            throw new ServiceException("Gagal mengambil riwayat transaksi: " + e.getMessage(), e);
        }
    }

    /**
     * Get recent transactions (admin)
     */
    public List<PointTransaction> getRecentTransactions(int limit) throws ServiceException {
        try {
            return pointTransactionDAO.findRecent(limit);
        } catch (SQLException e) {
            throw new ServiceException("Gagal mengambil transaksi terbaru: " + e.getMessage(), e);
        }
    }

    /**
     * Service Exception
     */
    public static class ServiceException extends Exception {
        public ServiceException(String message) {
            super(message);
        }

        public ServiceException(String message, Throwable cause) {
            super(message, cause);
        }
    }
}

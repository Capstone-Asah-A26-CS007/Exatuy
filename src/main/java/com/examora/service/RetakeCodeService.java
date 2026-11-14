package com.examora.service;

import com.examora.dao.RetakeCodeDAO;
import com.examora.model.RetakeCode;

import java.sql.SQLException;
import java.time.LocalDateTime;
import java.util.List;

/**
 * Service class for retake codes
 */
public class RetakeCodeService {

    private RetakeCodeDAO retakeCodeDAO = new RetakeCodeDAO();

    /**
     * Generate a new retake code for a user and quiz
     */
    public RetakeCode generateRetakeCode(Integer quizId, Integer userId, Integer createdBy,
                                         Integer validityHours) throws ServiceException {
        try {
            // Check if existing valid code exists
            RetakeCode existing = retakeCodeDAO.getByQuizAndUser(quizId, userId);
            if (existing != null && existing.isValid()) {
                throw new ServiceException("User ini sudah memiliki kode retake yang masih berlaku: " +
                    existing.getRetakeCode());
            }

            RetakeCode newCode = new RetakeCode(quizId, userId,
                RetakeCodeDAO.generateCode(), createdBy);

            if (validityHours != null && validityHours > 0) {
                newCode.setExpiresAt(LocalDateTime.now().plusHours(validityHours));
            }

            return retakeCodeDAO.create(newCode);
        } catch (SQLException e) {
            throw new ServiceException("Gagal membuat kode retake: " + e.getMessage(), e);
        }
    }

    /**
     * Validate a retake code WITHOUT marking it as used
     * This allows users to re-enter if they exit accidentally
     */
    public RetakeCode validateCode(String code, Integer userId) throws ServiceException {
        try {
            RetakeCode retakeCode = retakeCodeDAO.validateCode(code);
            if (retakeCode == null) {
                throw new ServiceException("Kode retake tidak valid");
            }

            if (!retakeCode.getUserId().equals(userId)) {
                throw new ServiceException("Kode retake tidak untuk user ini");
            }

            if (!retakeCode.isValid()) {
                if (retakeCode.getIsUsed() != null && retakeCode.getIsUsed()) {
                    throw new ServiceException("Kode retake sudah digunakan");
                }
                if (retakeCode.getExpiresAt() != null &&
                    LocalDateTime.now().isAfter(retakeCode.getExpiresAt())) {
                    throw new ServiceException("Kode retake sudah kadaluarsa");
                }
            }

            // DO NOT mark as used yet - only mark when quiz is submitted
            return retakeCode;
        } catch (SQLException e) {
            throw new ServiceException("Gagal memvalidasi kode: " + e.getMessage(), e);
        }
    }

    /**
     * Mark a retake code as used (called when quiz is submitted)
     */
    public void markCodeAsUsed(Integer quizId, Integer userId) throws ServiceException {
        try {
            RetakeCode retakeCode = retakeCodeDAO.getByQuizAndUser(quizId, userId);
            if (retakeCode != null && !retakeCode.getIsUsed()) {
                retakeCodeDAO.markAsUsed(retakeCode.getId(), userId);
                System.out.println("Marked retake code as used: quizId=" + quizId + ", userId=" + userId);
            }
        } catch (SQLException e) {
            System.err.println("Error marking retake code as used: " + e.getMessage());
            // Don't throw exception - this is not critical
        }
    }

    /**
     * Validate and use a retake code (kept for backward compatibility)
     * @deprecated Use validateCode() instead
     */
    @Deprecated
    public RetakeCode validateAndUseCode(String code, Integer userId) throws ServiceException {
        return validateCode(code, userId);
    }

    /**
     * Get all retake codes for a quiz
     */
    public List<RetakeCodeDAO.RetakeCodeInfo> getQuizRetakeCodes(Integer quizId) throws ServiceException {
        try {
            return retakeCodeDAO.getByQuiz(quizId);
        } catch (SQLException e) {
            throw new ServiceException("Gagal mengambil kode retake: " + e.getMessage(), e);
        }
    }

    /**
     * Delete a retake code
     */
    public boolean deleteCode(Integer codeId) throws ServiceException {
        try {
            return retakeCodeDAO.delete(codeId);
        } catch (SQLException e) {
            throw new ServiceException("Gagal menghapus kode: " + e.getMessage(), e);
        }
    }

    /**
     * Custom exception for service errors
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

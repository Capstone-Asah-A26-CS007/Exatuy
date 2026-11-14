package com.examora.service;

import com.examora.dao.QuizAccessCodeDAO;
import com.examora.model.QuizAccessCode;

import java.sql.SQLException;
import java.time.LocalDateTime;
import java.util.List;

/**
 * Quiz Access Code Service
 */
public class QuizAccessCodeService {

    private QuizAccessCodeDAO accessCodeDAO = new QuizAccessCodeDAO();

    /**
     * Generate new access code for a quiz
     */
    public QuizAccessCode generateAccessCode(Integer quizId, Integer createdBy, String codeName,
                                              Integer maxUses, Integer validityHours) throws ServiceException {
        try {
            QuizAccessCode newCode = new QuizAccessCode(quizId,
                QuizAccessCodeDAO.generateCode(), createdBy);
            newCode.setCodeName(codeName);
            newCode.setMaxUses(maxUses);

            if (validityHours != null && validityHours > 0) {
                newCode.setExpiresAt(LocalDateTime.now().plusHours(validityHours));
            }

            return accessCodeDAO.create(newCode);
        } catch (SQLException e) {
            throw new ServiceException("Gagal membuat kode akses: " + e.getMessage(), e);
        }
    }

    /**
     * Validate and use an access code
     */
    public QuizAccessCode validateAndUseCode(String code, Integer userId) throws ServiceException {
        try {
            QuizAccessCode accessCode = accessCodeDAO.validateCode(code);
            if (accessCode == null) {
                throw new ServiceException("Kode akses tidak valid");
            }

            if (!accessCode.isValid()) {
                if (accessCode.getIsActive() != null && !accessCode.getIsActive()) {
                    throw new ServiceException("Kode akses tidak aktif");
                }
                if (accessCode.getMaxUses() != null && accessCode.getUsedCount() != null &&
                    accessCode.getUsedCount() >= accessCode.getMaxUses()) {
                    throw new ServiceException("Kode akses sudah mencapai batas penggunaan");
                }
                if (accessCode.getExpiresAt() != null &&
                    LocalDateTime.now().isAfter(accessCode.getExpiresAt())) {
                    throw new ServiceException("Kode akses sudah kadaluarsa (" +
                        accessCode.getFormattedExpiresAt() + ")");
                }
            }

            // Record that user has accessed this quiz with this code
            accessCodeDAO.recordUserAccess(accessCode.getQuizId(), userId, accessCode.getId());

            // Increment used count
            accessCodeDAO.incrementUsedCount(accessCode.getId());

            return accessCode;
        } catch (SQLException e) {
            throw new ServiceException("Gagal memvalidasi kode: " + e.getMessage(), e);
        }
    }

    /**
     * Check if user has access to a quiz (via access code)
     */
    public boolean hasUserAccess(Integer quizId, Integer userId) throws ServiceException {
        try {
            return accessCodeDAO.hasUserUsedCode(quizId, userId);
        } catch (SQLException e) {
            throw new ServiceException("Gagal mengecek akses: " + e.getMessage(), e);
        }
    }

    /**
     * Get access codes for a quiz
     */
    public List<QuizAccessCode> getQuizAccessCodes(Integer quizId) throws ServiceException {
        try {
            return accessCodeDAO.getByQuizId(quizId);
        } catch (SQLException e) {
            throw new ServiceException("Gagal mengambil kode akses: " + e.getMessage(), e);
        }
    }

    /**
     * Get all access codes with quiz info
     */
    public List<QuizAccessCodeDAO.AccessCodeInfo> getAllAccessCodes() throws ServiceException {
        try {
            return accessCodeDAO.getAccessCodesWithQuizInfo();
        } catch (SQLException e) {
            throw new ServiceException("Gagal mengambil kode akses: " + e.getMessage(), e);
        }
    }

    /**
     * Delete access code
     */
    public boolean deleteCode(Integer codeId) throws ServiceException {
        try {
            return accessCodeDAO.delete(codeId);
        } catch (SQLException e) {
            throw new ServiceException("Gagal menghapus kode: " + e.getMessage(), e);
        }
    }

    /**
     * Update access code
     */
    public boolean updateCode(QuizAccessCode accessCode) throws ServiceException {
        try {
            return accessCodeDAO.update(accessCode);
        } catch (SQLException e) {
            throw new ServiceException("Gagal mengupdate kode: " + e.getMessage(), e);
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

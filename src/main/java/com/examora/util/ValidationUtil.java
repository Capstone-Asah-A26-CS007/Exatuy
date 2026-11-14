package com.examora.util;

import java.util.regex.Pattern;

/**
 * Validation Utility Class - Handles input validation and sanitization
 */
public class ValidationUtil {

    private static final Pattern EMAIL_PATTERN =
            Pattern.compile("^[A-Za-z0-9!#$%&'*+/=?^_`{|}~.-]+@[A-Za-z0-9](?:[A-Za-z0-9-]*[A-Za-z0-9])?(?:\\.[A-Za-z0-9](?:[A-Za-z0-9-]*[A-Za-z0-9])?)*\\.[A-Za-z]{2,}$");

    private static final Pattern ALPHANUMERIC_PATTERN =
            Pattern.compile("^[a-zA-Z0-9\\s]+$");

    private static final Pattern SAFE_STRING =
            Pattern.compile("^[a-zA-Z0-9\\s.,!?@#$%&*()\\-_+=:;\"']+$");

    private static final Pattern SQL_INJECTION_PATTERN =
            Pattern.compile("(?i)('|(--)|(;)|(\\|\\|)|(\\*/)|(\\/\\*)|(xp_)|(sp_)|(exec\\s)|(execute\\s)|(union\\s)|(select\\s)|(insert\\s)|(delete\\s)|(update\\s)|(drop\\s)|(create\\s)|(alter\\s)|(truncate\\s))", Pattern.CASE_INSENSITIVE);

    private static final Pattern XSS_PATTERN =
            Pattern.compile("(?i)(<script|</script|javascript:|on\\w+\\s*=|<iframe|<object|<embed|<link|<style|eval\\(|expression\\()", Pattern.CASE_INSENSITIVE);

    private static final int MIN_PASSWORD_LENGTH = 6;
    private static final int MAX_PASSWORD_LENGTH = 100;
    private static final int MAX_NAME_LENGTH = 100;
    private static final int MAX_EMAIL_LENGTH = 255;
    private static final int MAX_GENERAL_TEXT_LENGTH = 5000;
    private static final int MAX_QUIZ_TITLE_LENGTH = 200;
    private static final int MAX_QUESTION_LENGTH = 1000;
    private static final int MAX_OPTION_LENGTH = 500;

    // ==================== EMAIL VALIDATION ====================

    /**
     * Normalize an email address: strip all whitespace, trailing dots, and lowercase it.
     * Returns null when the input is null.
     */
    public static String normalizeEmail(String email) {
        if (email == null) {
            return null;
        }
        String normalized = email.replaceAll("\\s+", "");
        while (normalized.endsWith(".")) {
            normalized = normalized.substring(0, normalized.length() - 1);
        }
        return normalized.toLowerCase(java.util.Locale.ROOT);
    }

    /**
     * Validate email format
     */
    public static boolean isValidEmail(String email) {
        String trimmed = normalizeEmail(email);
        if (trimmed == null || trimmed.isEmpty()) {
            return false;
        }
        if (trimmed.length() > MAX_EMAIL_LENGTH) {
            return false;
        }
        return EMAIL_PATTERN.matcher(trimmed).matches();
    }

    // ==================== PASSWORD VALIDATION ====================

    /**
     * Validate password strength
     */
    public static boolean isValidPassword(String password) {
        if (password == null) {
            return false;
        }
        // Check for whitespace only
        if (password.trim().isEmpty()) {
            return false;
        }
        return password.length() >= MIN_PASSWORD_LENGTH &&
               password.length() <= MAX_PASSWORD_LENGTH;
    }

    /**
     * Validate password strength with requirements
     */
    public static PasswordStrength checkPasswordStrength(String password) {
        if (password == null || password.isEmpty()) {
            return new PasswordStrength(false, "Password tidak boleh kosong", 0);
        }
        if (password.length() < MIN_PASSWORD_LENGTH) {
            return new PasswordStrength(false, "Password minimal " + MIN_PASSWORD_LENGTH + " karakter", 1);
        }
        if (password.length() > MAX_PASSWORD_LENGTH) {
            return new PasswordStrength(false, "Password maksimal " + MAX_PASSWORD_LENGTH + " karakter", 0);
        }

        int score = 0;
        StringBuilder feedback = new StringBuilder();

        if (password.length() >= 8) score++;
        if (password.length() >= 12) score++;
        if (password.matches(".*[a-z].*")) score++;
        if (password.matches(".*[A-Z].*")) score++;
        if (password.matches(".*[0-9].*")) score++;
        if (password.matches(".*[!@#$%^&*()_+\\-=\\[\\]{};':\"\\\\|,.<>\\/?].*")) score++;

        if (score < 3) {
            feedback.append("Password lemah. ");
        } else if (score < 5) {
            feedback.append("Password sedang. ");
        } else {
            feedback.append("Password kuat. ");
        }

        if (!password.matches(".*[a-z].*") || !password.matches(".*[A-Z].*")) {
            feedback.append("Tambahkan huruf besar dan kecil. ");
        }
        if (!password.matches(".*[0-9].*")) {
            feedback.append("Tambahkan angka. ");
        }
        if (!password.matches(".*[!@#$%^&*()_+\\-=\\[\\]{};':\"\\\\|,.<>\\/?].*")) {
            feedback.append("Tambahkan karakter khusus. ");
        }

        return new PasswordStrength(true, feedback.toString().trim(), score);
    }

    // ==================== NAME VALIDATION ====================

    /**
     * Validate name (non-empty, reasonable length)
     */
    public static boolean isValidName(String name) {
        if (name == null || name.trim().isEmpty()) {
            return false;
        }
        String trimmed = name.trim();
        if (trimmed.length() > MAX_NAME_LENGTH) {
            return false;
        }
        // Allow letters, spaces, and common name characters
        return trimmed.matches("^[a-zA-Z\\s.'\\-]+$") || trimmed.matches("^[\\p{L}\\s.'\\-]+$");
    }

    // ==================== TEXT VALIDATION ====================

    /**
     * Validate general text input
     */
    public static boolean isValidText(String text, int maxLength) {
        if (text == null) {
            return false;
        }
        return text.length() <= maxLength;
    }

    /**
     * Validate quiz title
     */
    public static boolean isValidQuizTitle(String title) {
        if (title == null || title.trim().isEmpty()) {
            return false;
        }
        String trimmed = title.trim();
        return trimmed.length() >= 3 && trimmed.length() <= MAX_QUIZ_TITLE_LENGTH;
    }

    /**
     * Validate question text
     */
    public static boolean isValidQuestion(String question) {
        if (question == null || question.trim().isEmpty()) {
            return false;
        }
        String trimmed = question.trim();
        return trimmed.length() >= 5 && trimmed.length() <= MAX_QUESTION_LENGTH;
    }

    /**
     * Validate option text
     */
    public static boolean isValidOption(String option) {
        if (option == null || option.trim().isEmpty()) {
            return false;
        }
        String trimmed = option.trim();
        return trimmed.length() >= 1 && trimmed.length() <= MAX_OPTION_LENGTH;
    }

    /**
     * Validate chat message
     */
    public static boolean isValidChatMessage(String message) {
        if (message == null || message.trim().isEmpty()) {
            return false;
        }
        String trimmed = message.trim();
        return trimmed.length() >= 1 && trimmed.length() <= MAX_GENERAL_TEXT_LENGTH;
    }

    // ==================== ANSWER VALIDATION ====================

    /**
     * Validate quiz answer (A, B, C, or D)
     */
    public static boolean isValidAnswer(String answer) {
        return answer != null && answer.matches("[ABCD]");
    }

    /**
     * Validate multiple answers for arena
     */
    public static boolean isValidAnswers(String[] answers, int expectedCount) {
        if (answers == null || answers.length != expectedCount) {
            return false;
        }
        for (String answer : answers) {
            if (!isValidAnswer(answer)) {
                return false;
            }
        }
        return true;
    }

    // ==================== NUMERIC VALIDATION ====================

    /**
     * Validate positive integer
     */
    public static boolean isPositiveInteger(Integer value) {
        return value != null && value > 0;
    }

    /**
     * Validate positive integer with max
     */
    public static boolean isPositiveInteger(Integer value, int max) {
        return value != null && value > 0 && value <= max;
    }

    /**
     * Parse integer safely
     */
    public static Integer parseIntegerSafe(String value, Integer defaultValue) {
        if (value == null || value.trim().isEmpty()) {
            return defaultValue;
        }
        try {
            return Integer.parseInt(value.trim());
        } catch (NumberFormatException e) {
            return defaultValue;
        }
    }

    /**
     * Validate score (0-100)
     */
    public static boolean isValidScore(Double score) {
        return score != null && score >= 0 && score <= 100;
    }

    // ==================== STRING UTILITIES ====================

    /**
     * Check if string is not null and not empty
     */
    public static boolean isNotEmpty(String str) {
        return str != null && !str.trim().isEmpty();
    }

    /**
     * Check if string is null or empty
     */
    public static boolean isEmpty(String str) {
        return str == null || str.trim().isEmpty();
    }

    /**
     * Trim string safely
     */
    public static String trim(String str) {
        return str == null ? null : str.trim();
    }

    /**
     * Get string or default
     */
    public static String getOrDefault(String str, String defaultValue) {
        return isEmpty(str) ? defaultValue : str.trim();
    }

    // ==================== SANITIZATION ====================

    /**
     * Sanitize string input (basic XSS prevention)
     */
    public static String sanitize(String input) {
        if (input == null) return null;

        return input
                .replace("&", "&amp;")
                .replace("<", "&lt;")
                .replace(">", "&gt;")
                .replace("\"", "&quot;")
                .replace("'", "&#x27;");
    }

    /**
     * Sanitize for HTML output
     */
    public static String sanitizeHtml(String input) {
        if (input == null) return "";
        return sanitize(input);
    }

    /**
     * Sanitize for JavaScript output
     */
    public static String sanitizeJs(String input) {
        if (input == null) return "";
        return input
                .replace("\\", "\\\\")
                .replace("\"", "\\\"")
                .replace("'", "\\'")
                .replace("\n", "\\n")
                .replace("\r", "\\r")
                .replace("<", "\\x3c")
                .replace(">", "\\x3e");
    }

    /**
     * Sanitize for URL
     */
    public static String sanitizeUrl(String input) {
        if (input == null) return "";
        // Remove dangerous protocols
        return input.replaceAll("(?i)^javascript:.*$", "")
                    .replaceAll("(?i)^data:.*$", "")
                    .replaceAll("(?i)^vbscript:.*$", "");
    }

    /**
     * Sanitize filename
     */
    public static String sanitizeFilename(String filename) {
        if (filename == null || filename.isEmpty()) {
            return "file";
        }
        // Remove path traversal and dangerous characters
        return filename.replaceAll("[^a-zA-Z0-9._-]", "_")
                       .replaceAll("\\.{2,}", ".")
                       .replaceAll("^[.]+", "");
    }

    // ==================== SECURITY CHECKS ====================

    /**
     * Check for potential SQL injection
     */
    public static boolean containsSqlInjection(String input) {
        if (input == null) return false;
        return SQL_INJECTION_PATTERN.matcher(input).find();
    }

    /**
     * Check for potential XSS
     */
    public static boolean containsXss(String input) {
        if (input == null) return false;
        return XSS_PATTERN.matcher(input).find();
    }

    /**
     * Validate input is safe (no SQL injection or XSS)
     */
    public static ValidationResult validateSafeInput(String input, String fieldName, int maxLength) {
        if (input == null || input.trim().isEmpty()) {
            return new ValidationResult(false, fieldName + " tidak boleh kosong");
        }

        String trimmed = input.trim();

        if (trimmed.length() > maxLength) {
            return new ValidationResult(false, fieldName + " terlalu panjang (maks " + maxLength + " karakter)");
        }

        if (containsSqlInjection(trimmed)) {
            return new ValidationResult(false, fieldName + " mengandung karakter yang tidak diizinkan");
        }

        if (containsXss(trimmed)) {
            return new ValidationResult(false, fieldName + " mengandung konten yang tidak diizinkan");
        }

        return new ValidationResult(true, null);
    }

    /**
     * Validate ID parameter
     */
    public static Integer validateId(String idStr) {
        if (idStr == null || idStr.isEmpty()) {
            return null;
        }
        try {
            int id = Integer.parseInt(idStr.trim());
            return id > 0 ? id : null;
        } catch (NumberFormatException e) {
            return null;
        }
    }

    /**
     * Validate role
     */
    public static boolean isValidRole(String role) {
        return role != null && (role.equals("admin") || role.equals("peserta"));
    }

    // ==================== RESULT CLASSES ====================

    /**
     * Password strength result
     */
    public static class PasswordStrength {
        private final boolean valid;
        private final String feedback;
        private final int score; // 0-6

        public PasswordStrength(boolean valid, String feedback, int score) {
            this.valid = valid;
            this.feedback = feedback;
            this.score = score;
        }

        public boolean isValid() { return valid; }
        public String getFeedback() { return feedback; }
        public int getScore() { return score; }
        public String getStrengthLevel() {
            if (score < 3) return "lemah";
            if (score < 5) return "sedang";
            return "kuat";
        }
    }

    /**
     * Validation result
     */
    public static class ValidationResult {
        private final boolean valid;
        private final String errorMessage;

        public ValidationResult(boolean valid, String errorMessage) {
            this.valid = valid;
            this.errorMessage = errorMessage;
        }

        public boolean isValid() { return valid; }
        public String getErrorMessage() { return errorMessage; }
    }
}

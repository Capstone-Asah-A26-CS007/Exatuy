-- Quiz Access Codes Table
-- This table stores access codes for quizzes, allowing controlled access
CREATE TABLE IF NOT EXISTS quiz_access_codes (
    id INT AUTO_INCREMENT PRIMARY KEY,
    quiz_id INT NOT NULL,
    access_code VARCHAR(20) NOT NULL UNIQUE,
    code_name VARCHAR(100) DEFAULT NULL,
    max_uses INT DEFAULT NULL COMMENT 'NULL = unlimited uses',
    used_count INT DEFAULT 0,
    is_active BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    expires_at TIMESTAMP NULL COMMENT 'NULL = no expiration',
    created_by INT NOT NULL,
    FOREIGN KEY (quiz_id) REFERENCES quiz(id) ON DELETE CASCADE,
    FOREIGN KEY (created_by) REFERENCES users(id),
    INDEX idx_code (access_code),
    INDEX idx_quiz_id (quiz_id),
    INDEX idx_expires_at (expires_at)
) ENGINE=InnoDB;

-- Add column to quiz table to mark if quiz requires access code
ALTER TABLE quiz ADD COLUMN requires_access_code BOOLEAN DEFAULT FALSE AFTER show_review;

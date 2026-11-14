-- User Quiz Access Table
-- Tracks which users have used access codes for which quizzes
CREATE TABLE IF NOT EXISTS user_quiz_access (
    id INT AUTO_INCREMENT PRIMARY KEY,
    quiz_id INT NOT NULL,
    user_id INT NOT NULL,
    access_code_id INT NOT NULL,
    access_count INT DEFAULT 1,
    accessed_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (quiz_id) REFERENCES quiz(id) ON DELETE CASCADE,
    FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE,
    FOREIGN KEY (access_code_id) REFERENCES quiz_access_codes(id) ON DELETE CASCADE,
    UNIQUE KEY uk_quiz_user (quiz_id, user_id),
    INDEX idx_user_id (user_id)
) ENGINE=InnoDB;

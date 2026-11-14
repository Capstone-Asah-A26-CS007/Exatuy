-- Quiz Exemptions Table
-- Track users who are exempted from taking a quiz and automatically get perfect scores

CREATE TABLE IF NOT EXISTS quiz_exemptions (
    id INT AUTO_INCREMENT PRIMARY KEY,
    quiz_id INT NOT NULL,
    user_id INT NOT NULL,
    exempted_by INT NOT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    notes TEXT DEFAULT NULL COMMENT 'Optional notes for exemption reason',
    FOREIGN KEY (quiz_id) REFERENCES quiz(id) ON DELETE CASCADE,
    FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE,
    FOREIGN KEY (exempted_by) REFERENCES users(id),
    UNIQUE KEY unique_quiz_user (quiz_id, user_id),
    INDEX idx_quiz_id (quiz_id),
    INDEX idx_user_id (user_id)
) ENGINE=InnoDB;

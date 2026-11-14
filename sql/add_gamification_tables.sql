-- Examora - Gamification System Tables
-- Migration Script for user_points and point_transactions tables

USE examora_db;

-- User Points Table
-- Stores user points, level, and experience for the gamification system
CREATE TABLE IF NOT EXISTS user_points (
    id INT AUTO_INCREMENT PRIMARY KEY,
    user_id INT NOT NULL UNIQUE,
    total_points INT DEFAULT 0 COMMENT 'Total accumulated points',
    level INT DEFAULT 1 COMMENT 'User level (1-7)',
    experience_points INT DEFAULT 0 COMMENT 'Experience points for leveling',
    created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
    updated_at DATETIME DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE,
    INDEX idx_user_id (user_id),
    INDEX idx_total_points (total_points),
    INDEX idx_level (level)
) ENGINE=InnoDB;

-- Point Transactions Table
-- Records all point transactions (earnings and spendings) with full history
CREATE TABLE IF NOT EXISTS point_transactions (
    id INT AUTO_INCREMENT PRIMARY KEY,
    user_id INT NOT NULL,
    points INT NOT NULL COMMENT 'Positive for earned, negative for spent',
    transaction_type VARCHAR(50) NOT NULL COMMENT 'quiz_complete, achievement, daily_login, admin_bonus, points_spent',
    source_type VARCHAR(50) NOT NULL COMMENT 'quiz, achievement, admin, system, etc.',
    source_id INT NULL COMMENT 'ID of the source (quiz_id, achievement_id, etc.)',
    description TEXT COMMENT 'Human-readable description',
    created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE,
    INDEX idx_user_id (user_id),
    INDEX idx_transaction_type (transaction_type),
    INDEX idx_source (source_type, source_id),
    INDEX idx_created_at (created_at)
) ENGINE=InnoDB;

-- Initialize user_points for existing users
INSERT IGNORE INTO user_points (user_id, total_points, level, experience_points)
SELECT id, total_points, 1, 0
FROM users
WHERE id NOT IN (SELECT user_id FROM user_points);

-- Add helpful view for leaderboard with user details
CREATE OR REPLACE VIEW v_leaderboard AS
SELECT
    up.user_id,
    u.name AS user_name,
    u.email AS user_email,
    up.total_points,
    up.level,
    up.experience_points,
    up.created_at AS joined_at,
    RANK() OVER (ORDER BY up.total_points DESC) AS rank_position
FROM user_points up
JOIN users u ON up.user_id = u.id
ORDER BY up.total_points DESC;

-- Add helpful view for transaction history with user details
CREATE OR REPLACE VIEW v_point_transactions AS
SELECT
    pt.id,
    pt.user_id,
    u.name AS user_name,
    pt.points,
    pt.transaction_type,
    pt.source_type,
    pt.source_id,
    pt.description,
    pt.created_at
FROM point_transactions pt
JOIN users u ON pt.user_id = u.id
ORDER BY pt.created_at DESC;

-- Success message
SELECT 'Gamification tables created successfully!' AS message;

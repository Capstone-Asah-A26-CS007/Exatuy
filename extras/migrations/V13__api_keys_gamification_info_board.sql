-- API Keys Management, Gamification, and Information Board
-- This migration adds tables for API keys, gamification system, and information board

-- =============================================
-- API KEYS MANAGEMENT
-- =============================================

CREATE TABLE IF NOT EXISTS api_keys (
    id INT PRIMARY KEY AUTO_INCREMENT,
    key_name VARCHAR(255) NOT NULL,
    key_value VARCHAR(500) NOT NULL,
    key_type VARCHAR(50) NOT NULL DEFAULT 'custom',
    description TEXT,
    created_by INT NOT NULL,
    last_used_at TIMESTAMP NULL,
    expires_at TIMESTAMP NULL,
    is_active BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    FOREIGN KEY (created_by) REFERENCES users(id) ON DELETE CASCADE
);

CREATE INDEX IF NOT EXISTS idx_api_keys_created_by ON api_keys(created_by);
CREATE INDEX IF NOT EXISTS idx_api_keys_type ON api_keys(key_type);
CREATE INDEX IF NOT EXISTS idx_api_keys_active ON api_keys(is_active);

-- =============================================
-- GAMIFICATION SYSTEM
-- =============================================

-- User Points Table
CREATE TABLE IF NOT EXISTS user_points (
    id INT PRIMARY KEY AUTO_INCREMENT,
    user_id INT NOT NULL UNIQUE,
    total_points INT DEFAULT 0,
    level INT DEFAULT 1,
    experience_points INT DEFAULT 0,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE
);

CREATE INDEX IF NOT EXISTS idx_user_points_user ON user_points(user_id);
CREATE INDEX IF NOT EXISTS idx_user_points_total ON user_points(total_points DESC);

-- Point Transactions History
CREATE TABLE IF NOT EXISTS point_transactions (
    id INT PRIMARY KEY AUTO_INCREMENT,
    user_id INT NOT NULL,
    points INT NOT NULL,
    transaction_type VARCHAR(50) NOT NULL,
    source_type VARCHAR(50) NOT NULL,
    source_id INT,
    description TEXT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE
);

CREATE INDEX IF NOT EXISTS idx_point_trans_user ON point_transactions(user_id);
CREATE INDEX IF NOT EXISTS idx_point_trans_created ON point_transactions(created_at);

-- User Badges
CREATE TABLE IF NOT EXISTS user_badges (
    id INT PRIMARY KEY AUTO_INCREMENT,
    user_id INT NOT NULL,
    achievement_id INT NOT NULL,
    earned_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE,
    FOREIGN KEY (achievement_id) REFERENCES achievements(id) ON DELETE CASCADE,
    UNIQUE KEY unique_user_achievement (user_id, achievement_id)
);

CREATE INDEX IF NOT EXISTS idx_user_badges_user ON user_badges(user_id);
CREATE INDEX IF NOT EXISTS idx_user_badges_achievement ON user_badges(achievement_id);

-- Leaderboard (can be cached/rebuilt)
CREATE TABLE IF NOT EXISTS leaderboard (
    id INT PRIMARY KEY AUTO_INCREMENT,
    user_id INT NOT NULL,
    total_points INT NOT NULL,
    level INT NOT NULL,
    rank_position INT NOT NULL,
    period_type ENUM('daily', 'weekly', 'monthly', 'all_time') NOT NULL,
    period_start TIMESTAMP NULL,
    period_end TIMESTAMP NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE
);

CREATE INDEX IF NOT EXISTS idx_leaderboard_period ON leaderboard(period_type, period_start);
CREATE INDEX IF NOT EXISTS idx_leaderboard_points ON leaderboard(total_points DESC);
CREATE UNIQUE KEY unique_leaderboard_period_user ON leaderboard(period_type, period_start, user_id);

-- Level Definitions
CREATE TABLE IF NOT EXISTS level_definitions (
    id INT PRIMARY KEY AUTO_INCREMENT,
    level INT NOT NULL UNIQUE,
    level_name VARCHAR(100) NOT NULL,
    min_experience INT NOT NULL,
    max_experience INT NOT NULL,
    badge_icon VARCHAR(255),
    rewards TEXT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Insert default levels
INSERT INTO level_definitions (level, level_name, min_experience, max_experience, badge_icon) VALUES
(1, 'Beginner', 0, 99, 'bi-1-circle'),
(2, 'Novice', 100, 499, 'bi-2-circle'),
(3, 'Learner', 500, 1499, 'bi-3-circle'),
(4, 'Scholar', 1500, 3499, 'bi-4-circle'),
(5, 'Expert', 3500, 7499, 'bi-5-circle'),
(6, 'Master', 7500, 14999, 'bi-6-circle'),
(7, 'Grandmaster', 15000, 999999, 'bi-trophy') ON DUPLICATE KEY UPDATE level_name=VALUES(level_name);

-- =============================================
-- INFORMATION BOARD (ANNOUNCEMENTS)
-- =============================================

CREATE TABLE IF NOT EXISTS information_board (
    id INT PRIMARY KEY AUTO_INCREMENT,
    title VARCHAR(255) NOT NULL,
    content TEXT NOT NULL,
    info_type ENUM('announcement', 'info', 'warning', 'success') NOT NULL DEFAULT 'info',
    priority ENUM('low', 'normal', 'high', 'urgent') NOT NULL DEFAULT 'normal',
    target_audience ENUM('all', 'participants', 'admins') NOT NULL DEFAULT 'all',
    is_active BOOLEAN DEFAULT TRUE,
    show_until TIMESTAMP NULL,
    created_by INT NOT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    FOREIGN KEY (created_by) REFERENCES users(id) ON DELETE CASCADE
);

CREATE INDEX IF NOT EXISTS idx_info_board_type ON information_board(info_type);
CREATE INDEX IF NOT EXISTS idx_info_board_active ON information_board(is_active);
CREATE INDEX IF NOT EXISTS idx_info_board_target ON information_board(target_audience);
CREATE INDEX IF NOT EXISTS idx_info_board_priority ON information_board(priority, created_at);

-- Information Read Receipts (optional, to track who has read)
CREATE TABLE IF NOT EXISTS information_read (
    id INT PRIMARY KEY AUTO_INCREMENT,
    information_id INT NOT NULL,
    user_id INT NOT NULL,
    read_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (information_id) REFERENCES information_board(id) ON DELETE CASCADE,
    FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE,
    UNIQUE KEY unique_info_user_read (information_id, user_id)
);

CREATE INDEX IF NOT EXISTS idx_info_read_user ON information_read(user_id);

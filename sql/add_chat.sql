-- Add Chat Messages Table
-- Run this script if chat feature returns 500 error

-- Chat Messages Table
CREATE TABLE IF NOT EXISTS chat_messages (
    id INT AUTO_INCREMENT PRIMARY KEY,
    user_id INT NOT NULL COMMENT 'User yang mengirim/menerima pesan',
    sender_type ENUM('user', 'admin') NOT NULL COMMENT 'Pengirim: user atau admin',
    admin_id INT DEFAULT NULL COMMENT 'ID admin yang membalas (jika sender_type=admin)',
    message_text TEXT NOT NULL,
    is_read BOOLEAN DEFAULT FALSE,
    created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE,
    FOREIGN KEY (admin_id) REFERENCES users(id) ON DELETE SET NULL,
    INDEX idx_user_id (user_id),
    INDEX idx_sender_type (sender_type),
    INDEX idx_is_read (is_read),
    INDEX idx_created_at (created_at)
) ENGINE=InnoDB;

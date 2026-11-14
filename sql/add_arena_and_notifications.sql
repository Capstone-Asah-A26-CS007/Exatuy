-- Combined post-dump migration (verbatim concat of sql/arena_schema.sql + sql/add_notifications.sql).
-- Applied after backups/examora_db_full_20260617_141639.sql on first DB init.

-- Examora Arena Schema
-- Real-time Competitive Quiz Feature

-- Arena Sessions (rooms)
CREATE TABLE IF NOT EXISTS arena_sessions (
    id INT AUTO_INCREMENT PRIMARY KEY,
    code VARCHAR(10) NOT NULL UNIQUE,           -- Kode unik untuk join (AR-XXXXX)
    quiz_id INT NOT NULL,                        -- Reference ke quiz yang ada
    host_id INT NOT NULL,                        -- User yang membuat session
    status ENUM('waiting', 'active', 'paused', 'completed') DEFAULT 'waiting',
    current_question INT DEFAULT 0,              -- Index soal saat ini
    question_time INT DEFAULT 30,                -- Waktu per soal (detik)
    started_at DATETIME,
    ended_at DATETIME,
    created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (quiz_id) REFERENCES quiz(id) ON DELETE CASCADE,
    FOREIGN KEY (host_id) REFERENCES users(id) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Arena Participants
CREATE TABLE IF NOT EXISTS arena_participants (
    id INT AUTO_INCREMENT PRIMARY KEY,
    session_id INT NOT NULL,
    user_id INT NOT NULL,
    score INT DEFAULT 0,
    joined_at DATETIME DEFAULT CURRENT_TIMESTAMP,
    is_connected BOOLEAN DEFAULT TRUE,
    FOREIGN KEY (session_id) REFERENCES arena_sessions(id) ON DELETE CASCADE,
    FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE,
    UNIQUE KEY unique_session_user (session_id, user_id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Arena Answers
CREATE TABLE IF NOT EXISTS arena_answers (
    id INT AUTO_INCREMENT PRIMARY KEY,
    session_id INT NOT NULL,
    participant_id INT NOT NULL,
    question_id INT NOT NULL,
    selected_answer CHAR(1),
    time_taken INT DEFAULT 0,                    -- Waktu untuk menjawab (ms)
    score_earned INT DEFAULT 0,
    answered_at DATETIME DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (session_id) REFERENCES arena_sessions(id) ON DELETE CASCADE,
    FOREIGN KEY (participant_id) REFERENCES arena_participants(id) ON DELETE CASCADE,
    FOREIGN KEY (question_id) REFERENCES questions(id) ON DELETE CASCADE,
    UNIQUE KEY unique_participant_question (participant_id, question_id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Index for faster lookups
CREATE INDEX idx_arena_sessions_code ON arena_sessions(code);
CREATE INDEX idx_arena_sessions_status ON arena_sessions(status);
CREATE INDEX idx_arena_participants_session ON arena_participants(session_id);
CREATE INDEX idx_arena_participants_user ON arena_participants(user_id);
CREATE INDEX idx_arena_answers_session ON arena_answers(session_id);
CREATE INDEX idx_arena_answers_participant ON arena_answers(participant_id);


-- Examora - Email Notifications Feature
-- Migration Script

USE examora_db;

-- Notification Templates Table
CREATE TABLE IF NOT EXISTS notification_templates (
    id INT AUTO_INCREMENT PRIMARY KEY,
    name VARCHAR(100) NOT NULL,
    subject VARCHAR(255) NOT NULL,
    body TEXT NOT NULL,
    type ENUM('new_quiz', 'deadline_reminder', 'result', 'achievement', 'general') NOT NULL,
    is_active BOOLEAN DEFAULT TRUE,
    created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
    updated_at DATETIME DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    INDEX idx_type (type),
    INDEX idx_is_active (is_active)
) ENGINE=InnoDB;

-- Notification Queue Table
CREATE TABLE IF NOT EXISTS notification_queue (
    id INT AUTO_INCREMENT PRIMARY KEY,
    user_id INT NOT NULL,
    subject VARCHAR(255) NOT NULL,
    body TEXT NOT NULL,
    status ENUM('pending', 'sent', 'failed') DEFAULT 'pending',
    error_message TEXT DEFAULT NULL,
    sent_at DATETIME DEFAULT NULL,
    created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE,
    INDEX idx_status (status),
    INDEX idx_user_id (user_id),
    INDEX idx_created_at (created_at)
) ENGINE=InnoDB;

-- User Notification Settings (optional - for future use)
CREATE TABLE IF NOT EXISTS user_notification_settings (
    id INT AUTO_INCREMENT PRIMARY KEY,
    user_id INT NOT NULL,
    notify_new_quiz BOOLEAN DEFAULT TRUE,
    notify_deadline BOOLEAN DEFAULT TRUE,
    notify_result BOOLEAN DEFAULT TRUE,
    notify_achievement BOOLEAN DEFAULT TRUE,
    FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE,
    UNIQUE KEY unique_user_settings (user_id)
) ENGINE=InnoDB;

-- Insert default notification templates
INSERT INTO notification_templates (name, subject, body, type, is_active) VALUES
('New Quiz Available', 'Quiz Baru Tersedia: {{quiz_title}}', 'Halo {{user_name}},\n\nQuiz baru "{{quiz_title}}" telah tersedia untuk Anda.\n\nDetail Quiz:\n- Durasi: {{duration}} menit\n- Jumlah Soal: {{question_count}} soal\n- Deadline: {{deadline}}\n\nSilakan login ke Examora untuk mengerjakan quiz.\n\nTerima kasih,\nTim Examora', 'new_quiz', TRUE),
('Deadline Reminder', 'Pengingat: Quiz {{quiz_title}} akan segera berakhir', 'Halo {{user_name}},\n\nIni adalah pengingat bahwa quiz "{{quiz_title}}" akan berakhir dalam {{time_remaining}}.\n\nJika Anda belum mengerjakan quiz ini, segera login ke Examora.\n\nTerima kasih,\nTim Examora', 'deadline_reminder', TRUE),
('Quiz Result', 'Hasil Quiz: {{quiz_title}}', 'Halo {{user_name}},\n\nSelamat! Anda telah menyelesaikan quiz "{{quiz_title}}".\n\nHasil Anda:\n- Nilai: {{score}}\n- Jawaban Benar: {{correct_answers}}/{{total_questions}}\n- Waktu Pengerjaan: {{time_spent}}\n\nLogin ke Examora untuk melihat detail hasil.\n\nTerima kasih,\nTim Examora', 'result', TRUE),
('Achievement Earned', 'Selamat! Anda mendapatkan Achievement baru!', 'Halo {{user_name}},\n\nSelamat! Anda telah mendapatkan achievement baru!\n\n{{achievement_name}}\n{{achievement_description}}\n\nPoin yang didapat: +{{points}} poin\n\nTerus tingkatkan kemampuan Anda!\n\nTerima kasih,\nTim Examora', 'achievement', TRUE);

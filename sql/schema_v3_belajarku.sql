-- ============================================
-- BELAJARKU - Database Schema v3.0
-- Platform Belajar & Ujian Online untuk Semua Kalangan
-- ============================================

CREATE DATABASE IF NOT EXISTS belajarku_db CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
USE belajarku_db;

-- ============================================
-- USERS - Tabel Pengguna
-- ============================================
CREATE TABLE IF NOT EXISTS users (
    id INT AUTO_INCREMENT PRIMARY KEY,
    name VARCHAR(100) NOT NULL,
    email VARCHAR(100) NOT NULL UNIQUE,
    password VARCHAR(255) NOT NULL,
    role ENUM('owner', 'pengajar', 'siswa', 'orang_tua') NOT NULL DEFAULT 'siswa',
    phone VARCHAR(20) DEFAULT NULL COMMENT 'No HP/WA',
    tag VARCHAR(50) DEFAULT NULL COMMENT 'Kelas/Kelompok (contoh: Kelas A, Matematika)'),
    photo VARCHAR(255) DEFAULT NULL COMMENT 'Foto profil',
    gdrive_link VARCHAR(500) DEFAULT NULL COMMENT 'Link Google Drive',
    is_active BOOLEAN DEFAULT TRUE,
    last_login DATETIME DEFAULT NULL,
    created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
    updated_at DATETIME DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    INDEX idx_email (email),
    INDEX idx_role (role),
    INDEX idx_tag (tag),
    INDEX idx_is_active (is_active)
);

-- ============================================
-- SESSION_PACKAGES - Paket Sesi Belajar
-- ============================================
CREATE TABLE IF NOT EXISTS session_packages (
    id INT AUTO_INCREMENT PRIMARY KEY,
    nama_paket VARCHAR(100) NOT NULL,
    jumlah_sesi INT NOT NULL DEFAULT 12 COMMENT 'Jumlah pertemuan dalam paket',
    harga DECIMAL(10,2) NOT NULL COMMENT 'Harga paket dalam Rupiah',
    durasi_bulan INT DEFAULT 3 COMMENT 'Periode paket dalam bulan',
    deskripsi TEXT DEFAULT NULL,
    is_active BOOLEAN DEFAULT TRUE,
    created_at DATETIME DEFAULT CURRENT_TIMESTAMP
);

-- ============================================
-- STUDENT_PACKAGES - Pendaftaran Siswa ke Paket
-- ============================================
CREATE TABLE IF NOT EXISTS student_packages (
    id INT AUTO_INCREMENT PRIMARY KEY,
    student_id INT NOT NULL,
    package_id INT NOT NULL,
    total_sesi INT NOT NULL,
    sisa_sesi INT NOT NULL,
    mulai_date DATE NOT NULL,
    berakhir_date DATE NOT NULL,
    status ENUM('aktif', 'habis', 'cuti', 'lunas', 'hutang') DEFAULT 'aktif',
    dibayar_tanggal DATE DEFAULT NULL,
    metode_pembayaran ENUM('tunai', 'transfer', 'qris') DEFAULT NULL,
    catatan TEXT DEFAULT NULL,
    created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (student_id) REFERENCES users(id) ON DELETE CASCADE,
    FOREIGN KEY (package_id) REFERENCES session_packages(id) ON DELETE RESTRICT
);

-- ============================================
-- INVOICES - Tagihan / Invoice
-- ============================================
CREATE TABLE IF NOT EXISTS invoices (
    id INT AUTO_INCREMENT PRIMARY KEY,
    invoice_number VARCHAR(20) NOT NULL UNIQUE,
    student_id INT NOT NULL,
    package_id INT NOT NULL,
    amount DECIMAL(10,2) NOT NULL,
    discount DECIMAL(10,2) DEFAULT 0,
    total DECIMAL(10,2) NOT NULL,
    status ENUM('belum_lunas', 'menunggu_verifikasi', 'lunas', 'batal') DEFAULT 'belum_lunas',
    due_date DATE NOT NULL COMMENT 'Jatuh tempo pembayaran',
    paid_at DATE DEFAULT NULL COMMENT 'Tanggal pembayaran',
    paid_with ENUM('tunai', 'transfer', 'qris') DEFAULT NULL,
    verified_by INT DEFAULT NULL COMMENT 'Admin yang verifikasi',
    notes TEXT DEFAULT NULL,
    created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
    updated_at DATETIME DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    FOREIGN KEY (student_id) REFERENCES users(id) ON DELETE CASCADE,
    FOREIGN KEY (package_id) REFERENCES session_packages(id) ON DELETE RESTRICT,
    FOREIGN KEY (verified_by) REFERENCES users(id) ON DELETE SET NULL,
    INDEX idx_status (status),
    INDEX idx_due_date (due_date),
    INDEX idx_student (student_id)
);

-- ============================================
-- QUOTA_TRACKER - Pelacak Sisa Kuota
-- ============================================
CREATE TABLE IF NOT EXISTS quota_tracker (
    id INT AUTO_INCREMENT PRIMARY KEY,
    student_id INT NOT NULL,
    session_package_id INT NOT NULL,
    total_sesi INT NOT NULL,
    sisa_sesi INT NOT NULL,
    used_sesi INT NOT NULL DEFAULT 0,
    warning_threshold INT DEFAULT 2 COMMENT 'Berapa sisa minimal untuk trigger peringatan',
    last_session_date DATE DEFAULT NULL,
    created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
    updated_at DATETIME DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    FOREIGN KEY (student_id) REFERENCES users(id) ON DELETE CASCADE,
    FOREIGN KEY (session_package_id) REFERENCES student_packages(id) ON DELETE CASCADE,
    UNIQUE KEY uq_student_package (student_id, session_package_id),
    INDEX idx_sisa_sesi (sisa_sesi),
    INDEX idx_warning (sisa_sesi, warning_threshold)
);

-- ============================================
-- ATTENDANCE_SESSIONS - Sesi Presensi
-- ============================================
CREATE TABLE IF NOT EXISTS attendance_sessions (
    id INT AUTO_INCREMENT PRIMARY KEY,
    session_code VARCHAR(10) NOT NULL UNIQUE COMMENT 'Kode absensi 6 karakter',
    subject VARCHAR(100) DEFAULT NULL,
    class_group VARCHAR(50) DEFAULT NULL,
    schedule_date DATE NOT NULL,
    start_time TIME DEFAULT NULL,
    end_time TIME DEFAULT NULL,
    max_participants INT DEFAULT NULL,
    status ENUM('scheduled', 'active', 'finished', 'cancelled') DEFAULT 'scheduled',
    created_by INT NOT NULL,
    late_threshold_minutes INT DEFAULT 10 COMMENT 'Batas toleransi terlambat',
    created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (created_by) REFERENCES users(id) ON DELETE CASCADE,
    INDEX idx_code (session_code),
    INDEX idx_date (schedule_date),
    INDEX idx_status (status)
);

-- ============================================
-- ATTENDANCE_RECORDS - Rekap Presensi
-- ============================================
CREATE TABLE IF NOT EXISTS attendance_records (
    id INT AUTO_INCREMENT PRIMARY KEY,
    session_id INT NOT NULL,
    student_id INT NOT NULL,
    status ENUM('hadir', 'izin', 'sakit', 'alpa') NOT NULL,
    check_in_time TIME DEFAULT NULL,
    check_out_time TIME DEFAULT NULL,
    notes TEXT DEFAULT NULL,
    recorded_by INT DEFAULT NULL,
    created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (session_id) REFERENCES attendance_sessions(id) ON DELETE CASCADE,
    FOREIGN KEY (student_id) REFERENCES users(id) ON DELETE CASCADE,
    FOREIGN KEY (recorded_by) REFERENCES users(id) ON DELETE SET NULL,
    UNIQUE KEY uq_session_student (session_id, student_id),
    INDEX idx_student (student_id),
    INDEX idx_session (session_id)
);

-- ============================================
-- QUIZ - Quiz / Ujian
-- ============================================
CREATE TABLE IF NOT EXISTS quiz (
    id INT AUTO_INCREMENT PRIMARY KEY,
    title VARCHAR(200) NOT NULL,
    description TEXT DEFAULT NULL,
    quiz_type ENUM('regular', 'pre_test', 'post_test', 'utbk', 'ujian_harian', 'ujian_akhir') DEFAULT 'regular',
    subject VARCHAR(100) DEFAULT NULL COMMENT 'Mata pelajaran',
    grade_level VARCHAR(20) DEFAULT NULL COMMENT 'Jenjang: SD1-6, SMP1-3',
    duration INT NOT NULL DEFAULT 30 COMMENT 'Durasi dalam menit',
    total_questions INT DEFAULT 0,
    passing_score INT DEFAULT 70,
    is_active BOOLEAN DEFAULT FALSE,
    publish_date DATETIME DEFAULT NULL,
    deadline DATETIME DEFAULT NULL,
    target_tag VARCHAR(50) DEFAULT NULL COMMENT 'Target kelas/kelompok',
    shuffle_questions BOOLEAN DEFAULT FALSE,
    show_review BOOLEAN DEFAULT TRUE,
    created_by INT NOT NULL,
    created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
    updated_at DATETIME DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    FOREIGN KEY (created_by) REFERENCES users(id) ON DELETE CASCADE,
    INDEX idx_active (is_active),
    INDEX idx_type (quiz_type),
    INDEX idx_subject (subject),
    INDEX idx_deadline (deadline),
    INDEX idx_target_tag (target_tag)
);

-- ============================================
-- QUESTIONS - Soal
-- ============================================
CREATE TABLE IF NOT EXISTS questions (
    id INT AUTO_INCREMENT PRIMARY KEY,
    quiz_id INT NOT NULL,
    question_text TEXT NOT NULL,
    question_image VARCHAR(255) DEFAULT NULL,
    question_type ENUM('pilihan_ganda', 'esai_singkat') DEFAULT 'pilihan_ganda',
    options JSON DEFAULT NULL COMMENT 'Opsi jawaban A, B, C, D, E',
    correct_answer VARCHAR(10) NOT NULL COMMENT 'A, B, C, D, atau E',
    explanation TEXT DEFAULT NULL COMMENT 'Pembahasan',
    points INT DEFAULT 100,
    difficulty ENUM('mudah', 'sedang', 'sulit') DEFAULT 'sedang',
    keywords VARCHAR(500) DEFAULT NULL COMMENT 'Keyword untuk grading esai',
    created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (quiz_id) REFERENCES quiz(id) ON DELETE CASCADE,
    INDEX idx_quiz (quiz_id)
);

-- ============================================
-- QUESTION_CATEGORIES - Kategori Soal
-- ============================================
CREATE TABLE IF NOT EXISTS question_categories (
    id INT AUTO_INCREMENT PRIMARY KEY,
    name VARCHAR(100) NOT NULL,
    subject VARCHAR(100) DEFAULT NULL,
    grade_level VARCHAR(20) DEFAULT NULL,
    description TEXT DEFAULT NULL,
    created_by INT NOT NULL,
    created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (created_by) REFERENCES users(id) ON DELETE CASCADE
);

-- ============================================
-- SUBMISSIONS - Jawaban Siswa
-- ============================================
CREATE TABLE IF NOT EXISTS submissions (
    id INT AUTO_INCREMENT PRIMARY KEY,
    quiz_id INT NOT NULL,
    student_id INT NOT NULL,
    score INT DEFAULT NULL,
    total_questions INT DEFAULT 0,
    correct_count INT DEFAULT 0,
    submitted_at DATETIME DEFAULT CURRENT_TIMESTAMP,
    finished_at DATETIME DEFAULT NULL,
    time_spent_minutes INT DEFAULT NULL,
    is_timeout BOOLEAN DEFAULT FALSE,
    status ENUM('in_progress', 'submitted', 'graded') DEFAULT 'in_progress',
    FOREIGN KEY (quiz_id) REFERENCES quiz(id) ON DELETE CASCADE,
    FOREIGN KEY (student_id) REFERENCES users(id) ON DELETE CASCADE,
    INDEX idx_student (student_id),
    INDEX idx_quiz (quiz_id),
    INDEX idx_submitted (submitted_at)
);

-- ============================================
-- ANSWERS - Jawaban Per Soal
-- ============================================
CREATE TABLE IF NOT EXISTS answers (
    id INT AUTO_INCREMENT PRIMARY KEY,
    submission_id INT NOT NULL,
    question_id INT NOT NULL,
    selected_option VARCHAR(10) DEFAULT NULL,
    essay_answer TEXT DEFAULT NULL,
    is_correct BOOLEAN DEFAULT NULL,
    points_earned INT DEFAULT 0,
    created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (submission_id) REFERENCES submissions(id) ON DELETE CASCADE,
    FOREIGN KEY (question_id) REFERENCES questions(id) ON DELETE CASCADE,
    UNIQUE KEY uq_submission_question (submission_id, question_id)
);

-- ============================================
-- QUIZ_PARTICIPANTS - Peserta Quiz
-- ============================================
CREATE TABLE IF NOT EXISTS quiz_participants (
    id INT AUTO_INCREMENT PRIMARY KEY,
    quiz_id INT NOT NULL,
    participant_id INT NOT NULL,
    status ENUM('registered', 'started', 'completed', 'exempt') DEFAULT 'registered',
    registered_at DATETIME DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (quiz_id) REFERENCES quiz(id) ON DELETE CASCADE,
    FOREIGN KEY (participant_id) REFERENCES users(id) ON DELETE CASCADE,
    UNIQUE KEY uq_quiz_participant (quiz_id, participant_id)
);

-- ============================================
-- QUIZ_EXEMPTIONS - Pembebasan Quiz
-- ============================================
CREATE TABLE IF NOT EXISTS quiz_exemptions (
    id INT AUTO_INCREMENT PRIMARY KEY,
    quiz_id INT NOT NULL,
    user_id INT NOT NULL,
    reason TEXT DEFAULT NULL,
    exempted_by INT DEFAULT NULL,
    exempted_at DATETIME DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (quiz_id) REFERENCES quiz(id) ON DELETE CASCADE,
    FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE,
    FOREIGN KEY (exempted_by) REFERENCES users(id) ON DELETE SET NULL
);

-- ============================================
-- QUIZ_QUESTIONS - Mapel Quiz ke Soal
-- ============================================
CREATE TABLE IF NOT EXISTS quiz_questions (
    id INT AUTO_INCREMENT PRIMARY KEY,
    quiz_id INT NOT NULL,
    question_id INT NOT NULL,
    question_order INT NOT NULL,
    FOREIGN KEY (quiz_id) REFERENCES quiz(id) ON DELETE CASCADE,
    FOREIGN KEY (question_id) REFERENCES questions(id) ON DELETE CASCADE,
    UNIQUE KEY uq_quiz_question (quiz_id, question_id)
);

-- ============================================
-- ACHIEVEMENTS - Badge Pencapaian
-- ============================================
CREATE TABLE IF NOT EXISTS achievements (
    id INT AUTO_INCREMENT PRIMARY KEY,
    name VARCHAR(100) NOT NULL,
    description TEXT DEFAULT NULL,
    icon VARCHAR(50) NOT NULL DEFAULT 'bi-trophy',
    color VARCHAR(20) NOT NULL DEFAULT 'bg-warning',
    category ENUM('score', 'speed', 'quantity', 'streak', 'special') NOT NULL,
    condition_type VARCHAR(50) NOT NULL,
    condition_value INT NOT NULL,
    points INT DEFAULT 10,
    created_at DATETIME DEFAULT CURRENT_TIMESTAMP
);

-- ============================================
-- USER_ACHIEVEMENTS - Pencapaian Per User
-- ============================================
CREATE TABLE IF NOT EXISTS user_achievements (
    id INT AUTO_INCREMENT PRIMARY KEY,
    user_id INT NOT NULL,
    achievement_id INT NOT NULL,
    earned_at DATETIME DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE,
    FOREIGN KEY (achievement_id) REFERENCES achievements(id) ON DELETE CASCADE,
    UNIQUE KEY uq_user_achievement (user_id, achievement_id)
);

-- ============================================
-- USER_POINTS - Poin Pengguna
-- ============================================
CREATE TABLE IF NOT EXISTS user_points (
    id INT AUTO_INCREMENT PRIMARY KEY,
    user_id INT NOT NULL,
    total_points INT DEFAULT 0,
    perfect_scores INT DEFAULT 0,
    quick_thinks INT DEFAULT 0,
    quizzes_completed INT DEFAULT 0,
    streak_days INT DEFAULT 0,
    updated_at DATETIME DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE,
    UNIQUE KEY uq_user_points (user_id)
);

-- ============================================
-- POINT_TRANSACTIONS - Riwayat Poin
-- ============================================
CREATE TABLE IF NOT EXISTS point_transactions (
    id INT AUTO_INCREMENT PRIMARY KEY,
    user_id INT NOT NULL,
    points INT NOT NULL COMMENT 'Positif = dapat, Negatif = pakai',
    reason VARCHAR(100) NOT NULL,
    reference_id INT DEFAULT NULL,
    created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE
);

-- ============================================
-- NOTIFICATION_TEMPLATES - Template Notifikasi
-- ============================================
CREATE TABLE IF NOT EXISTS notification_templates (
    id INT AUTO_INCREMENT PRIMARY KEY,
    name VARCHAR(100) NOT NULL,
    subject_template TEXT NOT NULL,
    body_template TEXT NOT NULL,
    trigger_event VARCHAR(50) NOT NULL COMMENT 'quiz_new, deadline_reminder, quota_low, payment_received, etc',
    target_role ENUM('all', 'siswa', 'orang_tua', 'pengajar', 'owner') NOT NULL DEFAULT 'all',
    is_active BOOLEAN DEFAULT TRUE,
    created_at DATETIME DEFAULT CURRENT_TIMESTAMP
);

-- ============================================
-- NOTIFICATION_QUEUE - Antrian Notifikasi
-- ============================================
CREATE TABLE IF NOT EXISTS notification_queue (
    id INT AUTO_INCREMENT PRIMARY KEY,
    template_id INT DEFAULT NULL,
    recipient_id INT NOT NULL,
    sender_id INT DEFAULT NULL,
    subject VARCHAR(200) NOT NULL,
    body TEXT NOT NULL,
    channel ENUM('email', 'whatsapp', 'in_app') DEFAULT 'in_app',
    status ENUM('pending', 'sent', 'failed') DEFAULT 'pending',
    sent_at DATETIME DEFAULT NULL,
    error_message TEXT DEFAULT NULL,
    created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (template_id) REFERENCES notification_templates(id) ON DELETE SET NULL,
    FOREIGN KEY (recipient_id) REFERENCES users(id) ON DELETE CASCADE,
    FOREIGN KEY (sender_id) REFERENCES users(id) ON DELETE SET NULL,
    INDEX idx_status (status),
    INDEX idx_recipient (recipient_id)
);

-- ============================================
-- CHAT_MESSAGES - Pesan Chat
-- ============================================
CREATE TABLE IF NOT EXISTS chat_messages (
    id INT AUTO_INCREMENT PRIMARY KEY,
    sender_id INT NOT NULL,
    recipient_id INT NOT NULL,
    message TEXT NOT NULL,
    is_read BOOLEAN DEFAULT FALSE,
    created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (sender_id) REFERENCES users(id) ON DELETE CASCADE,
    FOREIGN KEY (recipient_id) REFERENCES users(id) ON DELETE CASCADE,
    INDEX idx_conversation (sender_id, recipient_id, created_at)
);

-- ============================================
-- AUDIT_LOG - Log Aktivitas
-- ============================================
CREATE TABLE IF NOT EXISTS audit_log (
    id INT AUTO_INCREMENT PRIMARY KEY,
    action_type VARCHAR(50) NOT NULL,
    entity_type VARCHAR(50) DEFAULT NULL,
    entity_id INT DEFAULT NULL,
    entity_name VARCHAR(255) DEFAULT NULL,
    action_data TEXT DEFAULT NULL COMMENT 'JSON data',
    user_id INT NOT NULL,
    user_name VARCHAR(100) NOT NULL,
    ip_address VARCHAR(45) DEFAULT NULL,
    user_agent VARCHAR(500) DEFAULT NULL,
    status ENUM('success', 'failed') DEFAULT 'success',
    created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
    INDEX idx_user (user_id),
    INDEX idx_action (action_type),
    INDEX idx_created (created_at)
);

-- ============================================
-- APP_SETTINGS - Pengaturan Aplikasi
-- ============================================
CREATE TABLE IF NOT EXISTS app_settings (
    id INT AUTO_INCREMENT PRIMARY KEY,
    setting_key VARCHAR(100) NOT NULL UNIQUE,
    setting_value TEXT DEFAULT NULL,
    setting_label VARCHAR(200) DEFAULT NULL,
    setting_type ENUM('boolean', 'text', 'number', 'email', 'json') DEFAULT 'text',
    updated_at DATETIME DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
);

-- ============================================
-- CUSTOM_PAGES - Halaman Kustom
-- ============================================
CREATE TABLE IF NOT EXISTS custom_pages (
    id INT AUTO_INCREMENT PRIMARY KEY,
    slug VARCHAR(100) NOT NULL UNIQUE,
    title VARCHAR(200) NOT NULL,
    content TEXT DEFAULT NULL,
    page_type ENUM('about', 'contact', 'terms', 'faq', 'custom') DEFAULT 'custom',
    is_active BOOLEAN DEFAULT TRUE,
    created_at DATETIME DEFAULT CURRENT_TIMESTAMP
);

-- ============================================
-- ERROR_LOG - Log Error
-- ============================================
CREATE TABLE IF NOT EXISTS error_log (
    id INT AUTO_INCREMENT PRIMARY KEY,
    error_type VARCHAR(100) NOT NULL,
    error_message TEXT NOT NULL,
    stack_trace TEXT DEFAULT NULL,
    request_url VARCHAR(500) DEFAULT NULL,
    user_id INT DEFAULT NULL,
    ip_address VARCHAR(45) DEFAULT NULL,
    created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
    INDEX idx_error_type (error_type),
    INDEX idx_created (created_at)
);

-- ============================================
-- FILES - File Uploads
-- ============================================
CREATE TABLE IF NOT EXISTS files (
    id INT AUTO_INCREMENT PRIMARY KEY,
    file_name VARCHAR(255) NOT NULL,
    original_name VARCHAR(255) NOT NULL,
    file_path VARCHAR(500) NOT NULL,
    file_size BIGINT NOT NULL,
    file_type VARCHAR(100) NOT NULL,
    mime_type VARCHAR(100) NOT NULL,
    uploader_id INT NOT NULL,
    folder_id INT DEFAULT NULL,
    quiz_id INT DEFAULT NULL,
    description TEXT DEFAULT NULL,
    download_count INT DEFAULT 0,
    is_public BOOLEAN DEFAULT FALSE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    FOREIGN KEY (uploader_id) REFERENCES users(id) ON DELETE CASCADE,
    FOREIGN KEY (folder_id) REFERENCES file_folders(id) ON DELETE SET NULL,
    INDEX idx_uploader (uploader_id),
    INDEX idx_quiz (quiz_id)
);

CREATE TABLE IF NOT EXISTS file_folders (
    id INT AUTO_INCREMENT PRIMARY KEY,
    name VARCHAR(100) NOT NULL,
    parent_id INT DEFAULT NULL,
    created_by INT NOT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (parent_id) REFERENCES file_folders(id) ON DELETE SET NULL,
    FOREIGN KEY (created_by) REFERENCES users(id) ON DELETE CASCADE
);

CREATE TABLE IF NOT EXISTS file_downloads (
    id INT AUTO_INCREMENT PRIMARY KEY,
    file_id INT NOT NULL,
    downloader_id INT DEFAULT NULL,
    downloaded_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (file_id) REFERENCES files(id) ON DELETE CASCADE,
    FOREIGN KEY (downloader_id) REFERENCES users(id) ON DELETE SET NULL
);

CREATE TABLE IF NOT EXISTS file_permissions (
    id INT AUTO_INCREMENT PRIMARY KEY,
    file_id INT NOT NULL,
    user_id INT NOT NULL,
    permission ENUM('view', 'download', 'full') DEFAULT 'view',
    granted_by INT DEFAULT NULL,
    granted_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (file_id) REFERENCES files(id) ON DELETE CASCADE,
    FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE,
    FOREIGN KEY (granted_by) REFERENCES users(id) ON DELETE SET NULL,
    UNIQUE KEY uq_file_user (file_id, user_id)
);

-- ============================================
-- INFORMATION_BOARD - Papan Informasi
-- ============================================
CREATE TABLE IF NOT EXISTS information_board (
    id INT AUTO_INCREMENT PRIMARY KEY,
    title VARCHAR(200) NOT NULL,
    content TEXT NOT NULL,
    board_type ENUM('announcement', 'reminder', 'event', 'notice') DEFAULT 'announcement',
    priority ENUM('low', 'medium', 'high', 'urgent') DEFAULT 'medium',
    target_role ENUM('all', 'siswa', 'pengajar', 'orang_tua') DEFAULT 'all',
    target_tag VARCHAR(50) DEFAULT NULL,
    publish_from DATETIME DEFAULT NULL,
    publish_to DATETIME DEFAULT NULL,
    is_active BOOLEAN DEFAULT TRUE,
    created_by INT NOT NULL,
    created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (created_by) REFERENCES users(id) ON DELETE CASCADE,
    INDEX idx_priority (priority),
    INDEX idx_publish (publish_from, publish_to)
);

-- ============================================
-- ARENA SESSIONS (Live Quiz)
-- ============================================
CREATE TABLE IF NOT EXISTS arena_sessions (
    id INT AUTO_INCREMENT PRIMARY KEY,
    session_code VARCHAR(20) NOT NULL UNIQUE,
    host_id INT NOT NULL,
    quiz_id INT NOT NULL,
    status ENUM('waiting', 'active', 'paused', 'finished') DEFAULT 'waiting',
    current_question_index INT DEFAULT 0,
    started_at DATETIME DEFAULT NULL,
    ended_at DATETIME DEFAULT NULL,
    created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (host_id) REFERENCES users(id) ON DELETE CASCADE,
    FOREIGN KEY (quiz_id) REFERENCES quiz(id) ON DELETE CASCADE,
    INDEX idx_session_code (session_code),
    INDEX idx_host (host_id)
);

CREATE TABLE IF NOT EXISTS arena_participants (
    id INT AUTO_INCREMENT PRIMARY KEY,
    session_id INT NOT NULL,
    user_id INT DEFAULT NULL,
    nickname VARCHAR(100) NOT NULL,
    total_score INT DEFAULT 0,
    correct_count INT DEFAULT 0,
    joined_at DATETIME DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (session_id) REFERENCES arena_sessions(id) ON DELETE CASCADE,
    FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE SET NULL,
    UNIQUE KEY uq_session_nickname (session_id, nickname),
    INDEX idx_session (session_id)
);

CREATE TABLE IF NOT EXISTS arena_answers (
    id INT AUTO_INCREMENT PRIMARY KEY,
    session_id INT NOT NULL,
    participant_id INT NOT NULL,
    question_id INT NOT NULL,
    selected_option VARCHAR(10) DEFAULT NULL,
    is_correct BOOLEAN DEFAULT FALSE,
    score INT DEFAULT 0,
    answered_at DATETIME DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (session_id) REFERENCES arena_sessions(id) ON DELETE CASCADE,
    FOREIGN KEY (participant_id) REFERENCES arena_participants(id) ON DELETE CASCADE,
    FOREIGN KEY (question_id) REFERENCES questions(id) ON DELETE CASCADE,
    UNIQUE KEY uq_participant_question (participant_id, question_id),
    INDEX idx_session_q (session_id, question_id)
);

-- ============================================
-- RETAKE CODES
-- ============================================
CREATE TABLE IF NOT EXISTS retake_codes (
    id INT AUTO_INCREMENT PRIMARY KEY,
    code VARCHAR(20) NOT NULL UNIQUE,
    quiz_id INT NOT NULL,
    used_by INT DEFAULT NULL,
    max_uses INT DEFAULT 1,
    use_count INT DEFAULT 0,
    expires_at DATETIME DEFAULT NULL,
    is_active BOOLEAN DEFAULT TRUE,
    created_by INT NOT NULL,
    created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (quiz_id) REFERENCES quiz(id) ON DELETE CASCADE,
    FOREIGN KEY (used_by) REFERENCES users(id) ON DELETE SET NULL,
    FOREIGN KEY (created_by) REFERENCES users(id) ON DELETE CASCADE
);

-- ============================================
-- USER QUIZ ACCESS
-- ============================================
CREATE TABLE IF NOT EXISTS user_quiz_access (
    id INT AUTO_INCREMENT PRIMARY KEY,
    quiz_id INT NOT NULL,
    user_id INT NOT NULL,
    access_type ENUM('override', 'exemption', 'extra_time') DEFAULT 'override',
    extra_minutes INT DEFAULT 0,
    granted_by INT DEFAULT NULL,
    granted_at DATETIME DEFAULT CURRENT_TIMESTAMP,
    expires_at DATETIME DEFAULT NULL,
    FOREIGN KEY (quiz_id) REFERENCES quiz(id) ON DELETE CASCADE,
    FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE,
    FOREIGN KEY (granted_by) REFERENCES users(id) ON DELETE SET NULL,
    UNIQUE KEY uq_quiz_user (quiz_id, user_id)
);

-- ============================================
-- QUIZ ACCESS CODES
-- ============================================
CREATE TABLE IF NOT EXISTS quiz_access_codes (
    id INT AUTO_INCREMENT PRIMARY KEY,
    quiz_id INT NOT NULL,
    code VARCHAR(20) NOT NULL UNIQUE,
    max_uses INT DEFAULT NULL,
    use_count INT DEFAULT 0,
    expires_at DATETIME DEFAULT NULL,
    created_by INT NOT NULL,
    created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (quiz_id) REFERENCES quiz(id) ON DELETE CASCADE,
    FOREIGN KEY (created_by) REFERENCES users(id) ON DELETE CASCADE
);

-- ============================================
-- GAMIFICATION LEADERBOARD VIEWS
-- ============================================
CREATE OR REPLACE VIEW v_leaderboard AS
SELECT 
    u.id as user_id,
    u.name as user_name,
    u.email,
    u.tag as class_group,
    up.total_points,
    up.quizzes_completed,
    up.perfect_scores,
    up.streak_days
FROM users u
JOIN user_points up ON u.id = up.user_id
WHERE u.role = 'siswa' AND u.is_active = TRUE
ORDER BY up.total_points DESC, up.quizzes_completed ASC;

CREATE OR REPLACE VIEW v_point_transactions_summary AS
SELECT 
    user_id,
    SUM(points) as net_points,
    COUNT(*) as transaction_count,
    MIN(created_at) as first_transaction,
    MAX(created_at) as last_transaction
FROM point_transactions
GROUP BY user_id;

-- ============================================
-- API KEYS (Optional)
-- ============================================
CREATE TABLE IF NOT EXISTS api_keys (
    id INT AUTO_INCREMENT PRIMARY KEY,
    key_name VARCHAR(255) NOT NULL,
    key_value VARCHAR(500) NOT NULL UNIQUE,
    key_type ENUM('public', 'secret', 'read_only', 'admin') DEFAULT 'public',
    description TEXT DEFAULT NULL,
    created_by INT NOT NULL,
    last_used_at TIMESTAMP NULL,
    expires_at TIMESTAMP NULL,
    is_active BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (created_by) REFERENCES users(id) ON DELETE CASCADE,
    INDEX idx_key_value (key_value(100)),
    INDEX idx_active (is_active)
);

-- ============================================
-- FILE MANAGEMENT (Migration V11)
-- ============================================
CREATE TABLE IF NOT EXISTS file_downloads_count (
    id INT AUTO_INCREMENT PRIMARY KEY,
    file_id INT NOT NULL UNIQUE,
    download_count INT DEFAULT 0,
    last_downloaded_at DATETIME DEFAULT NULL,
    FOREIGN KEY (file_id) REFERENCES files(id) ON DELETE CASCADE
);

-- ============================================
-- SEED DATA
-- ============================================

-- Session Packages
INSERT INTO session_packages (nama_paket, jumlah_sesi, harga, durasi_bulan, deskripsi) VALUES
('Paket Hemat', 8, 400000, 2, '8 pertemuan - cocok untuk tambahan/mengikuti materi'),
('Paket Reguler', 12, 600000, 3, '12 pertemuan - paket standar per semester'),
('Paket Intensif', 24, 1100000, 6, '24 pertemuan - pembelajaran intensif'),
('Paket Ujian', 6, 350000, 1, '6 pertemuan - persiapan khusus ujian');

-- Default Owner Account
INSERT INTO users (name, email, password, role, phone) VALUES
('Owner BelajarKu', 'owner@belajarku.id', '$2a$12$KJ8Yz9Xh3vL2mN5pQ7wR8eK1fG6tY4uI8oP3sA5dF7gH9jK2lM4nO', 'owner', '081234567890');

-- Default Pengajar
INSERT INTO users (name, email, password, role, phone) VALUES
('Pak Budi (Pengajar)', 'pengajar@belajarku.id', '$2a$12$KJ8Yz9Xh3vL2mN5pQ7wR8eK1fG6tY4uI8oP3sA5dF7gH9jK2lM4nO', 'pengajar', '081234567891');

-- Default Siswa Demo
INSERT INTO users (name, email, password, role, phone, tag) VALUES
('Ahmad Fauzi', 'siswa@belajarku.id', '$2a$12$KJ8Yz9Xh3vL2mN5pQ7wR8eK1fG6tY4uI8oP3sA5dF7gH9jK2lM4nO', 'siswa', '081234567892', 'Kelas A'),
('Siti Nurhaliza', 'siti@belajarku.id', '$2a$12$KJ8Yz9Xh3vL2mN5pQ7wR8eK1fG6tY4uI8oP3sA5dF7gH9jK2lM4nO', 'siswa', '081234567893', 'Kelas A'),
('Rizky Pratama', 'rizky@belajarku.id', '$2a$12$KJ8Yz9Xh3vL2mN5pQ7wR8eK1fG6tY4uI8oP3sA5dF7gH9jK2lM4nO', 'siswa', '081234567894', 'Kelas B');

-- Default Orang Tua Demo
INSERT INTO users (name, email, password, role, phone) VALUES
('Ibu Fauzi (Orang Tua Ahmad)', 'ibu.fauzi@belajarku.id', '$2a$12$KJ8Yz9Xh3vL2mN5pQ7wR8eK1fG6tY4uI8oP3sA5dF7gH9jK2lM4nO', 'orang_tua', '081234567895');

-- App Settings
INSERT INTO app_settings (setting_key, setting_value, setting_label, setting_type) VALUES
('registration_enabled', 'true', 'Izinkan Registrasi Baru', 'boolean'),
('chat_enabled', 'true', 'Izinkan Chat', 'boolean'),
('platform_name', 'BelajarKu', 'Nama Platform', 'text'),
('platform_tagline', 'Belajar Lebih Mudah, Ujian Lebih Menyenangkan', 'Tagline Platform', 'text'),
('currency_symbol', 'Rp', 'Simbol Mata Uang', 'text'),
('late_threshold_minutes', '10', 'Batas Toleransi Terlambat (menit)', 'number'),
('invoice_auto_send', 'true', 'Kirim Invoice Otomatis', 'boolean'),
('quota_warning_enabled', 'true', 'Aktifkan Peringatan Kuota Menipis', 'boolean');

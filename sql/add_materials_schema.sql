-- ============================================
-- Materials & Silabus Schema
-- Platform BelajarKu - Fase 3
-- ============================================

USE examora_db;

-- ============================================
-- Material Categories - Kategori Silabus
-- ============================================
CREATE TABLE IF NOT EXISTS material_categories (
    id INT AUTO_INCREMENT PRIMARY KEY,
    nama VARCHAR(150) NOT NULL,
    deskripsi TEXT DEFAULT NULL,
    jenjang ENUM('SD', 'SMP', 'SMA', 'UMUM') DEFAULT 'UMUM',
    mata_pelajaran VARCHAR(100) DEFAULT NULL COMMENT 'Mata pelajaran (Matematika, IPA, dll)',
    created_by INT NOT NULL,
    is_active BOOLEAN DEFAULT TRUE,
    created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
    updated_at DATETIME DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    FOREIGN KEY (created_by) REFERENCES users(id) ON DELETE CASCADE,
    INDEX idx_jenjang (jenjang),
    INDEX idx_mata_pelajaran (mata_pelajaran),
    INDEX idx_active (is_active)
);

-- ============================================
-- Materials - Arsip Materi/Silabus
-- ============================================
CREATE TABLE IF NOT EXISTS materials (
    id INT AUTO_INCREMENT PRIMARY KEY,
    category_id INT NOT NULL,
    title VARCHAR(255) NOT NULL,
    content LONGTEXT DEFAULT NULL COMMENT 'Konten teks materi (jika bukan file)',
    summary TEXT DEFAULT NULL COMMENT 'Ringkasan untuk preview',
    file_path VARCHAR(500) DEFAULT NULL COMMENT 'Path ke file PDF/DOC/Link URL',
    file_type ENUM('pdf', 'doc', 'docx', 'link', 'text', 'image') DEFAULT 'pdf',
    file_size BIGINT DEFAULT NULL COMMENT 'Ukuran file dalam bytes',
    target_tags VARCHAR(255) DEFAULT NULL COMMENT 'Tag/target kelas (comma-separated, NULL = semua)',
    generated_by INT DEFAULT NULL COMMENT 'User yang generate otomatis',
    is_generated BOOLEAN DEFAULT FALSE COMMENT 'Apakah auto-generated dari template',
    view_count INT DEFAULT 0,
    download_count INT DEFAULT 0,
    is_active BOOLEAN DEFAULT TRUE,
    created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
    updated_at DATETIME DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    FOREIGN KEY (category_id) REFERENCES material_categories(id) ON DELETE CASCADE,
    FOREIGN KEY (generated_by) REFERENCES users(id) ON DELETE SET NULL,
    INDEX idx_category (category_id),
    INDEX idx_title (title),
    INDEX idx_target_tags (target_tags(100)),
    INDEX idx_active (is_active),
    INDEX idx_created (created_at)
);

-- ============================================
-- Material Downloads Log
-- ============================================
CREATE TABLE IF NOT EXISTS material_downloads (
    id INT AUTO_INCREMENT PRIMARY KEY,
    material_id INT NOT NULL,
    user_id INT DEFAULT NULL,
    downloaded_at DATETIME DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (material_id) REFERENCES materials(id) ON DELETE CASCADE,
    FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE SET NULL,
    INDEX idx_material (material_id),
    INDEX idx_user (user_id)
);

-- ============================================
-- SEED DATA - Default Categories
-- ============================================

-- Kategori Silabus SD
INSERT INTO material_categories (nama, deskripsi, jenjang, mata_pelajaran, created_by, is_active) VALUES
('Silabus Matematika SD', 'Materi silabus Matematika untuk siswa SD kelas 1-6', 'SD', 'Matematika', 1, TRUE),
('Silabus IPA SD', 'Materi silabus IPA untuk siswa SD kelas 1-6', 'SD', 'IPA', 1, TRUE),
('Silabus Bahasa Indonesia SD', 'Materi silabus Bahasa Indonesia untuk siswa SD kelas 1-6', 'SD', 'Bahasa Indonesia', 1, TRUE),
('Silabus Pancasila SD', 'Materi silabus Pendidikan Pancasila untuk siswa SD kelas 1-6', 'SD', 'Pendidikan Pancasila', 1, TRUE);

-- Kategori Silabus SMP
INSERT INTO material_categories (nama, deskripsi, jenjang, mata_pelajaran, created_by, is_active) VALUES
('Silabus Matematika SMP', 'Materi silabus Matematika untuk siswa SMP kelas 7-9', 'SMP', 'Matematika', 1, TRUE),
('Silabus IPA SMP', 'Materi silabus IPA untuk siswa SMP kelas 7-9', 'SMP', 'IPA', 1, TRUE),
('Silabus Bahasa Indonesia SMP', 'Materi silabus Bahasa Indonesia untuk siswa SMP kelas 7-9', 'SMP', 'Bahasa Indonesia', 1, TRUE),
('Silabus SMP Umum', 'Materi silabus umum untuk siswa SMP', 'SMP', 'Umum', 1, TRUE);

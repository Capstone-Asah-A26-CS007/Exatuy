-- File Storage Schema for Exatuy
-- This migration creates the tables needed for file upload/download functionality

-- Files table to store file metadata
CREATE TABLE IF NOT EXISTS files (
    id INT PRIMARY KEY AUTO_INCREMENT,
    file_name VARCHAR(255) NOT NULL,
    original_name VARCHAR(255) NOT NULL,
    file_path VARCHAR(500) NOT NULL,
    file_size BIGINT NOT NULL,
    file_type VARCHAR(100) NOT NULL,
    mime_type VARCHAR(100) NOT NULL,
    uploader_id INT NOT NULL,
    folder_id INT DEFAULT NULL,
    quiz_id INT DEFAULT NULL,
    description TEXT,
    download_count INT DEFAULT 0,
    is_public BOOLEAN DEFAULT FALSE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    FOREIGN KEY (uploader_id) REFERENCES users(id) ON DELETE CASCADE,
    FOREIGN KEY (quiz_id) REFERENCES quizzes(id) ON DELETE SET NULL,
    FOREIGN KEY (folder_id) REFERENCES file_folders(id) ON DELETE SET NULL
);

-- File folders for organization
CREATE TABLE IF NOT EXISTS file_folders (
    id INT PRIMARY KEY AUTO_INCREMENT,
    folder_name VARCHAR(255) NOT NULL,
    parent_id INT DEFAULT NULL,
    owner_id INT NOT NULL,
    quiz_id INT DEFAULT NULL,
    folder_type ENUM('user', 'quiz', 'general') DEFAULT 'user',
    description TEXT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    FOREIGN KEY (owner_id) REFERENCES users(id) ON DELETE CASCADE,
    FOREIGN KEY (quiz_id) REFERENCES quizzes(id) ON DELETE SET NULL,
    FOREIGN KEY (parent_id) REFERENCES file_folders(id) ON DELETE CASCADE
);

-- File permissions table
CREATE TABLE IF NOT EXISTS file_permissions (
    id INT PRIMARY KEY AUTO_INCREMENT,
    file_id INT NOT NULL,
    user_id INT NOT NULL,
    can_view BOOLEAN DEFAULT FALSE,
    can_download BOOLEAN DEFAULT FALSE,
    can_delete BOOLEAN DEFAULT FALSE,
    granted_by INT,
    granted_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (file_id) REFERENCES files(id) ON DELETE CASCADE,
    FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE,
    FOREIGN KEY (granted_by) REFERENCES users(id) ON DELETE SET NULL,
    UNIQUE KEY unique_file_user (file_id, user_id)
);

-- File download history
CREATE TABLE IF NOT EXISTS file_downloads (
    id INT PRIMARY KEY AUTO_INCREMENT,
    file_id INT NOT NULL,
    user_id INT NOT NULL,
    download_ip VARCHAR(45),
    downloaded_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (file_id) REFERENCES files(id) ON DELETE CASCADE,
    FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE
);

-- Add indexes for better performance
CREATE INDEX IF NOT EXISTS idx_files_uploader ON files(uploader_id);
CREATE INDEX IF NOT EXISTS idx_files_folder ON files(folder_id);
CREATE IF NOT EXISTS idx_files_quiz ON files(quiz_id);
CREATE INDEX IF NOT EXISTS idx_files_created ON files(created_at);
CREATE INDEX IF NOT EXISTS idx_folders_owner ON file_folders(owner_id);
CREATE INDEX IF NOT EXISTS idx_folders_quiz ON file_folders(quiz_id);
CREATE INDEX IF NOT EXISTS idx_downloads_file ON file_downloads(file_id);
CREATE INDEX IF NOT EXISTS idx_downloads_user ON file_downloads(user_id);

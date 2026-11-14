-- Add Test Quiz: Cyber Security Intermediate
-- This quiz is for all tags (target_tag = NULL)
-- Note: created_by should be an admin user ID (e.g., 3)

-- Insert new quiz
INSERT INTO quiz (title, description, duration, is_active, target_tag, created_by, created_at, updated_at)
VALUES ('Test Quiz: Cyber Security Intermediate', 'Quiz untuk menguji pemahaman menengah tentang keamanan siber', 15, 1, NULL, 3, NOW(), NOW());

-- Insert questions for the new quiz (quiz_id will be the last inserted)
SET @new_quiz_id = LAST_INSERT_ID();

INSERT INTO questions (quiz_id, question_text, option_a, option_b, option_c, option_d, correct_answer, question_order) VALUES
(@new_quiz_id, 'Apa yang dimaksud dengan Social Engineering?', 'Teknik pemrograman sosial', 'Manipulasi psikologis untuk mendapatkan informasi', 'Jaringan sosial untuk hacker', 'Teknik mengenkripsi data sosial', 'B', 1),
(@new_quiz_id, 'Manakah yang BUKAN termasuk dalam CIA Triad?', 'Confidentiality', 'Integrity', 'Authentication', 'Availability', 'C', 2),
(@new_quiz_id, 'Apa fungsi dari antivirus?', 'Mempercepat kinerja komputer', 'Mendeteksi dan menghapus malware', 'Menyimpan data secara online', 'Mengkompres file', 'B', 3),
(@new_quiz_id, 'Apa yang dimaksud dengan DDoS attack?', 'Serangan yang menargetkan satu komputer', 'Serangan yang membanjiri server dengan traffic berlebih', 'Serangan untuk mencuri password', 'Serangan yang menyebarkan virus', 'B', 4),
(@new_quiz_id, 'Cookie pada browser berfungsi untuk?', 'Menyimpan informasi sesi pengguna', 'Menghapus virus', 'Mempercepat download', 'Memblokir iklan', 'A', 5),
(@new_quiz_id, 'Apa yang harus dilakukan sebelum mengklik link pendek (short link)?', 'Langsung klik karena lebih cepat', 'Periksa tujuan link dengan tool expander', 'Bagikan ke teman terlebih dahulu', 'Download link tersebut', 'B', 6),
(@new_quiz_id, 'Manakah yang merupakan praktik keamanan password yang BAIK?', 'Menggunakan password yang sama untuk semua akun', 'Mencatat password di sticky note', 'Menggunakan password manager', 'Membagikan password ke teman terpercaya', 'C', 7),
(@new_quiz_id, 'Apa itu ransomware?', 'Software untuk menghapus virus', 'Malware yang mengenkripsi file dan meminta tebusan', 'Aplikasi untuk backup data', 'Program antivirus gratis', 'B', 8),
(@new_quiz_id, 'TLS adalah singkatan dari?', 'Total Layer Security', 'Transport Layer Security', 'Technical Layer System', 'Transfer Level Security', 'B', 9),
(@new_quiz_id, 'Apa yang dimaksud dengan zero-day vulnerability?', 'Bug yang sudah diperbaiki', 'Celah keamanan yang belum diketahui vendor', 'Virus yang muncul setiap hari', 'Sistem keamanan terbaru', 'B', 10);

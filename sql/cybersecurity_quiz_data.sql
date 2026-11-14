-- Cybersecurity Quiz Data
-- Menghapus semua data quiz lama dan memasukkan quiz baru tentang cybersecurity

USE examora_db;

-- Disable foreign key checks temporarily
SET FOREIGN_KEY_CHECKS = 0;

-- Hapus semua data terkait quiz
DELETE FROM answers;
DELETE FROM submissions;
DELETE FROM quiz_sessions;
DELETE FROM quiz_questions;
DELETE FROM questions;
DELETE FROM quiz;
DELETE FROM arena_answers;
DELETE FROM arena_participants;
DELETE FROM arena_sessions;

-- Reset auto increment
ALTER TABLE answers AUTO_INCREMENT = 1;
ALTER TABLE submissions AUTO_INCREMENT = 1;
ALTER TABLE quiz_sessions AUTO_INCREMENT = 1;
ALTER TABLE questions AUTO_INCREMENT = 1;
ALTER TABLE quiz AUTO_INCREMENT = 1;

SET FOREIGN_KEY_CHECKS = 1;

-- User ID untuk user@examora.com adalah 2
-- Admin ID adalah 1

-- ============================================
-- QUIZ 1: Cyber Security Introduction (EASY)
-- ============================================
INSERT INTO quiz (title, description, duration, created_by, is_active) VALUES
('Cyber Security Introduction', 'Pengenalan dasar tentang keamanan siber - Level: Easy', 15, 1, TRUE);

SET @quiz1_id = LAST_INSERT_ID();

INSERT INTO questions (quiz_id, question_text, option_a, option_b, option_c, option_d, correct_answer, question_order) VALUES
(@quiz1_id, 'Apa yang dimaksud dengan Cyber Security?', 'Perlindungan sistem komputer dari serangan siber', 'Pembuatan software baru', 'Permainan video online', 'Jaringan sosial media', 'A', 1),
(@quiz1_id, 'Apa tujuan utama dari firewall?', 'Mempercepat koneksi internet', 'Memfilter lalu lintas jaringan dan mencegah akses tidak sah', 'Menyimpan data pengguna', 'Membuat backup otomatis', 'B', 2),
(@quiz1_id, 'Password yang baik seharusnya?', 'Menggunakan tanggal lahir', 'Singkat dan mudah diingat', 'Kombinasi huruf, angka, dan simbol', 'Sama dengan username', 'C', 3),
(@quiz1_id, 'Apa itu malware?', 'Software anti-virus', 'Perangkat lunak berbahaya yang dapat merusak sistem', 'Jenis jaringan komputer', 'Sistem operasi terbaru', 'B', 4),
(@quiz1_id, 'Phishing adalah?', 'Teknik memancing ikan', 'Serangan yang mencoba mendapatkan informasi sensitif dengan menyamar sebagai entitas terpercaya', 'Jenis malware', 'Metode enkripsi data', 'B', 5);

-- ============================================
-- QUIZ 2: Network Security Basics (EASY-MEDIUM)
-- ============================================
INSERT INTO quiz (title, description, duration, created_by, is_active) VALUES
('Network Security Basics', 'Dasar-dasar keamanan jaringan - Level: Easy-Medium', 20, 1, TRUE);

SET @quiz2_id = LAST_INSERT_ID();

INSERT INTO questions (quiz_id, question_text, option_a, option_b, option_c, option_d, correct_answer, question_order) VALUES
(@quiz2_id, 'Apa fungsi utama dari VPN (Virtual Private Network)?', 'Mempercepat download', 'Membuat koneksi yang aman melalui jaringan publik', 'Menyimpan file online', 'Berbagi printer', 'B', 1),
(@quiz2_id, 'Port berapa yang digunakan oleh HTTPS?', 'Port 21', 'Port 80', 'Port 443', 'Port 22', 'C', 2),
(@quiz2_id, 'Apa itu DDoS attack?', 'Serangan yang membanjiri server dengan traffic berlebihan', 'Metode enkripsi', 'Jenis antivirus', 'Protokol jaringan', 'A', 3),
(@quiz2_id, 'Man-in-the-Middle attack adalah?', 'Serangan yang menyadap komunikasi antara dua pihak', 'Serangan fisik ke server', 'Penginstalan software', 'Backup data', 'A', 4),
(@quiz2_id, 'SSL/TLS berguna untuk?', 'Mempercepat jaringan', 'Mengenkripsi komunikasi data di internet', 'Menyimpan password', 'Memblokir website', 'B', 5);

-- ============================================
-- QUIZ 3: Web Exploitation Fundamentals (MEDIUM)
-- ============================================
INSERT INTO quiz (title, description, duration, created_by, is_active) VALUES
('Web Exploitation Fundamentals', 'Dasar-dasar eksploitasi web - Level: Medium', 25, 1, TRUE);

SET @quiz3_id = LAST_INSERT_ID();

INSERT INTO questions (quiz_id, question_text, option_a, option_b, option_c, option_d, correct_answer, question_order) VALUES
(@quiz3_id, 'SQL Injection adalah kerentanan yang terjadi ketika?', 'Server tidak memiliki firewall', 'Input pengguna tidak divalidasi dan langsung digunakan dalam query SQL', 'Password terlalu lemah', 'Jaringan tidak terenkripsi', 'B', 1),
(@quiz3_id, 'Apa tujuan dari serangan XSS (Cross-Site Scripting)?', 'Menghapus database', 'Menyuntikkan script berbahaya ke halaman web yang dilihat pengguna lain', 'Mempercepat loading website', 'Memblokir akses pengguna', 'B', 2),
(@quiz3_id, 'Bagaimana cara mencegah SQL Injection?', 'Menggunakan parameterized queries dan prepared statements', 'Menggunakan password panjang', 'Mematikan server', 'Menghapus database', 'A', 3),
(@quiz3_id, 'CSRF (Cross-Site Request Forgery) mengeksploitasi?', 'Kelemahan di database', 'Kepercayaan website terhadap browser pengguna yang sudah terautentikasi', 'Kelemahan jaringan', 'Bugs di sistem operasi', 'B', 4),
(@quiz3_id, 'Apa itu IDOR (Insecure Direct Object Reference)?', 'Serangan ke database', 'Akses tidak sah ke objek melalui referensi langsung seperti ID', 'Jenis malware', 'Metode enkripsi', 'B', 5);

-- ============================================
-- QUIZ 4: Advanced Web Attacks (HARD)
-- ============================================
INSERT INTO quiz (title, description, duration, created_by, is_active) VALUES
('Advanced Web Attacks', 'Serangan web tingkat lanjut - Level: Hard', 30, 1, TRUE);

SET @quiz4_id = LAST_INSERT_ID();

INSERT INTO questions (quiz_id, question_text, option_a, option_b, option_c, option_d, correct_answer, question_order) VALUES
(@quiz4_id, 'Dalam Blind SQL Injection, bagaimana attacker mengekstrak data?', 'Melihat langsung hasil query', 'Menggunakan teknik boolean-based atau time-based inference', 'Membaca file log', 'Mendecrypt password', 'B', 1),
(@quiz4_id, 'Apa itu XXE (XML External Entity) attack?', 'Serangan ke jaringan', 'Eksploitasi parser XML yang tidak aman untuk membaca file internal atau melakukan SSRF', 'Serangan phishing', 'Brute force attack', 'B', 2),
(@quiz4_id, 'SSRF (Server-Side Request Forgery) memungkinkan attacker untuk?', 'Menghapus file pengguna', 'Membuat server melakukan request ke internal resources', 'Menginstall malware', 'Mengubah konfigurasi firewall', 'B', 3),
(@quiz4_id, 'Apa itu Deserialization Attack?', 'Serangan ke jaringan', 'Eksploitasi proses deserialisasi data yang tidak aman untuk mengeksekusi kode', 'Serangan brute force', 'SQL injection', 'B', 4),
(@quiz4_id, 'Template Injection terjadi ketika?', 'User input langsung di-render oleh template engine', 'Server menggunakan template', 'Website tidak memiliki CSS', 'Database tidak dienkripsi', 'A', 5);

-- ============================================
-- QUIZ 5: Penetration Testing & Exploitation (HARD)
-- ============================================
INSERT INTO quiz (title, description, duration, created_by, is_active) VALUES
('Penetration Testing & Exploitation', 'Teknik penetration testing dan eksploitasi - Level: Hard', 35, 1, TRUE);

SET @quiz5_id = LAST_INSERT_ID();

INSERT INTO questions (quiz_id, question_text, option_a, option_b, option_c, option_d, correct_answer, question_order) VALUES
(@quiz5_id, 'Apa fase pertama dalam metodologi penetration testing standar?', 'Exploitation', 'Reconnaissance', 'Maintaining Access', 'Covering Tracks', 'B', 1),
(@quiz5_id, 'Tools Burp Suite terutama digunakan untuk?', 'Network scanning', 'Web application security testing', 'Password cracking', 'Malware analysis', 'B', 2),
(@quiz5_id, 'Apa tujuan dari privilege escalation?', 'Menghapus log', 'Meningkatkan level akses dari user biasa ke administrator', 'Mempercepat koneksi', 'Memblokir firewall', 'B', 3),
(@quiz5_id, 'Dalam konteks web security, apa itu Race Condition?', 'Kompetisi antar hacker', 'Kerentanan saat outcome tergantung pada timing event yang tidak terkontrol', 'Jenis malware', 'Metode enkripsi', 'B', 4),
(@quiz5_id, 'Metasploit Framework digunakan untuk?', 'Desain grafis', 'Pengembangan dan eksekusi exploit code', 'Manajemen database', 'Pembuatan website', 'B', 5);

-- ============================================
-- USER SUBMISSIONS (user@examora.com = user_id 2)
-- Menjawab 4 dari 5 quiz
-- ============================================

-- Submission 1: Quiz 1 - Cyber Security Introduction (Score: 100 - Semua benar)
INSERT INTO submissions (quiz_id, user_id, score, total_questions, correct_answers, started_at, submitted_at, time_spent, status) VALUES
(@quiz1_id, 2, 100.00, 5, 5, DATE_SUB(NOW(), INTERVAL 4 DAY), DATE_SUB(NOW(), INTERVAL 4 DAY), 420, 'completed');

SET @sub1_id = LAST_INSERT_ID();

INSERT INTO answers (submission_id, question_id, selected_answer, is_correct, answered_at) VALUES
(@sub1_id, (SELECT id FROM questions WHERE quiz_id = @quiz1_id AND question_order = 1), 'A', TRUE, DATE_SUB(NOW(), INTERVAL 4 DAY)),
(@sub1_id, (SELECT id FROM questions WHERE quiz_id = @quiz1_id AND question_order = 2), 'B', TRUE, DATE_SUB(NOW(), INTERVAL 4 DAY)),
(@sub1_id, (SELECT id FROM questions WHERE quiz_id = @quiz1_id AND question_order = 3), 'C', TRUE, DATE_SUB(NOW(), INTERVAL 4 DAY)),
(@sub1_id, (SELECT id FROM questions WHERE quiz_id = @quiz1_id AND question_order = 4), 'B', TRUE, DATE_SUB(NOW(), INTERVAL 4 DAY)),
(@sub1_id, (SELECT id FROM questions WHERE quiz_id = @quiz1_id AND question_order = 5), 'B', TRUE, DATE_SUB(NOW(), INTERVAL 4 DAY));

-- Submission 2: Quiz 2 - Network Security Basics (Score: 80 - 4 benar, 1 salah)
INSERT INTO submissions (quiz_id, user_id, score, total_questions, correct_answers, started_at, submitted_at, time_spent, status) VALUES
(@quiz2_id, 2, 80.00, 5, 4, DATE_SUB(NOW(), INTERVAL 3 DAY), DATE_SUB(NOW(), INTERVAL 3 DAY), 580, 'completed');

SET @sub2_id = LAST_INSERT_ID();

INSERT INTO answers (submission_id, question_id, selected_answer, is_correct, answered_at) VALUES
(@sub2_id, (SELECT id FROM questions WHERE quiz_id = @quiz2_id AND question_order = 1), 'B', TRUE, DATE_SUB(NOW(), INTERVAL 3 DAY)),
(@sub2_id, (SELECT id FROM questions WHERE quiz_id = @quiz2_id AND question_order = 2), 'C', TRUE, DATE_SUB(NOW(), INTERVAL 3 DAY)),
(@sub2_id, (SELECT id FROM questions WHERE quiz_id = @quiz2_id AND question_order = 3), 'A', TRUE, DATE_SUB(NOW(), INTERVAL 3 DAY)),
(@sub2_id, (SELECT id FROM questions WHERE quiz_id = @quiz2_id AND question_order = 4), 'B', TRUE, DATE_SUB(NOW(), INTERVAL 3 DAY)),
(@sub2_id, (SELECT id FROM questions WHERE quiz_id = @quiz2_id AND question_order = 5), 'A', FALSE, DATE_SUB(NOW(), INTERVAL 3 DAY));

-- Submission 3: Quiz 3 - Web Exploitation Fundamentals (Score: 60 - 3 benar, 2 salah)
INSERT INTO submissions (quiz_id, user_id, score, total_questions, correct_answers, started_at, submitted_at, time_spent, status) VALUES
(@quiz3_id, 2, 60.00, 5, 3, DATE_SUB(NOW(), INTERVAL 2 DAY), DATE_SUB(NOW(), INTERVAL 2 DAY), 720, 'completed');

SET @sub3_id = LAST_INSERT_ID();

INSERT INTO answers (submission_id, question_id, selected_answer, is_correct, answered_at) VALUES
(@sub3_id, (SELECT id FROM questions WHERE quiz_id = @quiz3_id AND question_order = 1), 'B', TRUE, DATE_SUB(NOW(), INTERVAL 2 DAY)),
(@sub3_id, (SELECT id FROM questions WHERE quiz_id = @quiz3_id AND question_order = 2), 'B', TRUE, DATE_SUB(NOW(), INTERVAL 2 DAY)),
(@sub3_id, (SELECT id FROM questions WHERE quiz_id = @quiz3_id AND question_order = 3), 'A', TRUE, DATE_SUB(NOW(), INTERVAL 2 DAY)),
(@sub3_id, (SELECT id FROM questions WHERE quiz_id = @quiz3_id AND question_order = 4), 'A', FALSE, DATE_SUB(NOW(), INTERVAL 2 DAY)),
(@sub3_id, (SELECT id FROM questions WHERE quiz_id = @quiz3_id AND question_order = 5), 'A', FALSE, DATE_SUB(NOW(), INTERVAL 2 DAY));

-- Submission 4: Quiz 4 - Advanced Web Attacks (Score: 40 - 2 benar, 3 salah)
INSERT INTO submissions (quiz_id, user_id, score, total_questions, correct_answers, started_at, submitted_at, time_spent, status) VALUES
(@quiz4_id, 2, 40.00, 5, 2, DATE_SUB(NOW(), INTERVAL 1 DAY), DATE_SUB(NOW(), INTERVAL 1 DAY), 890, 'completed');

SET @sub4_id = LAST_INSERT_ID();

INSERT INTO answers (submission_id, question_id, selected_answer, is_correct, answered_at) VALUES
(@sub4_id, (SELECT id FROM questions WHERE quiz_id = @quiz4_id AND question_order = 1), 'B', TRUE, DATE_SUB(NOW(), INTERVAL 1 DAY)),
(@sub4_id, (SELECT id FROM questions WHERE quiz_id = @quiz4_id AND question_order = 2), 'B', TRUE, DATE_SUB(NOW(), INTERVAL 1 DAY)),
(@sub4_id, (SELECT id FROM questions WHERE quiz_id = @quiz4_id AND question_order = 3), 'A', FALSE, DATE_SUB(NOW(), INTERVAL 1 DAY)),
(@sub4_id, (SELECT id FROM questions WHERE quiz_id = @quiz4_id AND question_order = 4), 'A', FALSE, DATE_SUB(NOW(), INTERVAL 1 DAY)),
(@sub4_id, (SELECT id FROM questions WHERE quiz_id = @quiz4_id AND question_order = 5), 'B', FALSE, DATE_SUB(NOW(), INTERVAL 1 DAY));

-- Update user statistics for user@examora.com (user_id = 2)
UPDATE users SET
    total_quizzes = 4,
    total_points = 280,
    perfect_scores = 1
WHERE id = 2;

-- Verify the data
SELECT 'Quiz Data:' AS Info;
SELECT id, title, description, duration, is_active FROM quiz;

SELECT 'Submissions for user@examora.com:' AS Info;
SELECT s.id, q.title, s.score, s.correct_answers, s.total_questions, s.status, s.submitted_at
FROM submissions s
JOIN quiz q ON s.quiz_id = q.id
JOIN users u ON s.user_id = u.id
WHERE u.email = 'user@examora.com';

SELECT 'User Statistics:' AS Info;
SELECT name, email, total_quizzes, total_points, perfect_scores FROM users WHERE email = 'user@examora.com';

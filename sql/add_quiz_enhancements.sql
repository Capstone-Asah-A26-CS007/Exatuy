-- Quiz Enhancement Features Migration
-- Run this script to add new columns for quiz enhancements

-- 1. Add to quiz table: shuffle questions option and review mode
ALTER TABLE quiz ADD COLUMN shuffle_questions BOOLEAN DEFAULT TRUE;
ALTER TABLE quiz ADD COLUMN show_review BOOLEAN DEFAULT TRUE;

-- 2. Add to questions table: explanation and statistics
ALTER TABLE questions ADD COLUMN explanation TEXT DEFAULT NULL;
ALTER TABLE questions ADD COLUMN total_attempts INT DEFAULT 0;
ALTER TABLE questions ADD COLUMN correct_attempts INT DEFAULT 0;
ALTER TABLE questions ADD COLUMN difficulty_index DECIMAL(5,2) DEFAULT NULL;

-- Create index for better performance on statistics queries
CREATE INDEX idx_questions_stats ON questions(total_attempts, correct_attempts);

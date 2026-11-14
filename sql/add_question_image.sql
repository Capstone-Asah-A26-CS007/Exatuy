-- Add image_path column to questions table
-- Run this migration to support images in questions

DELIMITER //

DROP PROCEDURE IF EXISTS add_question_image_column//

CREATE PROCEDURE add_question_image_column()
BEGIN
    IF NOT EXISTS (
        SELECT * FROM information_schema.columns
        WHERE table_schema = DATABASE()
        AND table_name = 'questions'
        AND column_name = 'image_path'
    ) THEN
        ALTER TABLE questions ADD COLUMN image_path VARCHAR(255) DEFAULT NULL AFTER question_text;
    END IF;
END//

DELIMITER ;

CALL add_question_image_column();
DROP PROCEDURE IF EXISTS add_question_image_column;

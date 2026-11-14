-- Add exemption_time column to quiz table
-- This allows admin to configure the exact auto-completion time for exempted users
-- NULL = use default of 10 minutes

ALTER TABLE quiz ADD COLUMN exemption_time INT DEFAULT NULL;

-- File Management Setting
-- This migration adds the setting to enable/disable file management feature

-- Insert file_management_enabled setting (default: enabled)
INSERT INTO app_settings (setting_key, setting_value, description, created_at)
VALUES ('file_management_enabled', 'true', 'Enable/disable file upload and download feature', NOW())
ON DUPLICATE KEY UPDATE setting_value = VALUES(setting_value);

-- Add file management to admin settings page reference
-- This is for documentation purposes only

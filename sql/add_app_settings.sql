-- App Settings Table
-- Stores application configuration settings

CREATE TABLE IF NOT EXISTS app_settings (
    setting_key VARCHAR(100) PRIMARY KEY,
    setting_value TEXT,
    description VARCHAR(255),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
);

-- Insert default settings
INSERT INTO app_settings (setting_key, setting_value, description) VALUES
    ('registration_enabled', 'false', 'Enable/disable user registration')
ON DUPLICATE KEY UPDATE setting_key = setting_key;

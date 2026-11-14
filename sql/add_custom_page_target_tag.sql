-- Add target_tag and admin_comment columns to custom_pages
-- Run this SQL to update existing database
--
-- target_tag: restrict menu visibility to a specific peserta tag.
--             NULL = visible to all peserta.
-- admin_comment: internal note for admins only, never shown to end users.

ALTER TABLE custom_pages
  ADD COLUMN target_tag VARCHAR(50) DEFAULT NULL
    COMMENT 'Target peserta tag (null = semua tag)' AFTER sort_order,
  ADD COLUMN admin_comment TEXT DEFAULT NULL
    COMMENT 'Internal note, only visible to admin' AFTER target_tag;

ALTER TABLE custom_pages ADD INDEX idx_custom_pages_target_tag (target_tag);

-- ThinkVault: Admin Config Schema Migration
-- Version: 006
-- Date: 2026-03-04
-- Description: Creates app_config and config_audit_log tables

-- ============================================================
-- Application Configuration
-- ============================================================
CREATE TABLE IF NOT EXISTS app_config (
  config_key   VARCHAR(100) PRIMARY KEY,
  config_value TEXT         NOT NULL,
  description  VARCHAR(255) NULL,
  updated_at   DATETIME     NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
) ENGINE=InnoDB;

-- ============================================================
-- Configuration Audit Log
-- ============================================================
CREATE TABLE IF NOT EXISTS config_audit_log (
  id           INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  config_key   VARCHAR(100)  NOT NULL,
  old_value    TEXT          NULL,
  new_value    TEXT          NOT NULL,
  changed_by   INT UNSIGNED  NOT NULL,
  changed_at   DATETIME      NOT NULL DEFAULT CURRENT_TIMESTAMP,
  
  FOREIGN KEY (changed_by) REFERENCES users(id) ON DELETE CASCADE,
  INDEX idx_config_audit_key (config_key),
  INDEX idx_config_audit_time (changed_at)
) ENGINE=InnoDB;

-- ============================================================
-- Seed Default Config Variables
-- ============================================================
INSERT IGNORE INTO app_config (config_key, config_value, description)
VALUES 
  ('max_upload_size_mb', '10', 'Maximum size in megabytes for user file attachments'),
  ('max_notes_per_user', '1000', 'Maximum number of notes a user can create'),
  ('maintenance_mode', 'false', 'Set to true to lock out all non-admin users');

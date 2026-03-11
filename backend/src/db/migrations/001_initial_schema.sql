-- ThinkVault: Initial Schema Migration
-- Version: 001
-- Date: 2026-02-28
-- Description: Creates all core tables for v1

-- ============================================================
-- Users
-- ============================================================
CREATE TABLE IF NOT EXISTS users (
  id          INT UNSIGNED    AUTO_INCREMENT PRIMARY KEY,
  name        VARCHAR(100)    NOT NULL,
  email       VARCHAR(255)    NOT NULL UNIQUE,
  password    VARCHAR(255)    NOT NULL,
  role        ENUM('user', 'admin') NOT NULL DEFAULT 'user',
  is_locked   BOOLEAN         NOT NULL DEFAULT FALSE,
  locked_until DATETIME       NULL,
  otp_enabled BOOLEAN         NOT NULL DEFAULT FALSE,
  otp_secret  VARCHAR(255)    NULL,
  created_at  DATETIME        NOT NULL DEFAULT CURRENT_TIMESTAMP,
  updated_at  DATETIME        NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,

  INDEX idx_users_email (email)
) ENGINE=InnoDB;

-- ============================================================
-- Login Attempts (for lockout tracking)
-- ============================================================
CREATE TABLE IF NOT EXISTS login_attempts (
  id          INT UNSIGNED    AUTO_INCREMENT PRIMARY KEY,
  user_id     INT UNSIGNED    NOT NULL,
  ip_address  VARCHAR(45)     NULL,
  success     BOOLEAN         NOT NULL DEFAULT FALSE,
  attempted_at DATETIME       NOT NULL DEFAULT CURRENT_TIMESTAMP,

  FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE,
  INDEX idx_login_attempts_user (user_id),
  INDEX idx_login_attempts_time (attempted_at)
) ENGINE=InnoDB;

-- ============================================================
-- Categories
-- ============================================================
CREATE TABLE IF NOT EXISTS categories (
  id          INT UNSIGNED    AUTO_INCREMENT PRIMARY KEY,
  user_id     INT UNSIGNED    NOT NULL,
  name        VARCHAR(100)    NOT NULL,
  created_at  DATETIME        NOT NULL DEFAULT CURRENT_TIMESTAMP,
  updated_at  DATETIME        NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,

  FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE,
  UNIQUE KEY uq_category_user_name (user_id, name),
  INDEX idx_categories_user (user_id)
) ENGINE=InnoDB;

-- ============================================================
-- Notes
-- ============================================================
CREATE TABLE IF NOT EXISTS notes (
  id          INT UNSIGNED    AUTO_INCREMENT PRIMARY KEY,
  user_id     INT UNSIGNED    NOT NULL,
  category_id INT UNSIGNED    NULL,
  title       VARCHAR(255)    NOT NULL,
  content     MEDIUMTEXT      NULL,
  priority    ENUM('low', 'medium', 'high') NOT NULL DEFAULT 'medium',
  created_at  DATETIME        NOT NULL DEFAULT CURRENT_TIMESTAMP,
  updated_at  DATETIME        NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,

  FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE,
  FOREIGN KEY (category_id) REFERENCES categories(id) ON DELETE SET NULL,
  INDEX idx_notes_user (user_id),
  INDEX idx_notes_category (category_id),
  INDEX idx_notes_created (created_at),
  INDEX idx_notes_priority (priority),
  FULLTEXT INDEX ft_notes_search (title, content)
) ENGINE=InnoDB;

-- ============================================================
-- Tags
-- ============================================================
CREATE TABLE IF NOT EXISTS tags (
  id          INT UNSIGNED    AUTO_INCREMENT PRIMARY KEY,
  user_id     INT UNSIGNED    NOT NULL,
  name        VARCHAR(50)     NOT NULL,
  created_at  DATETIME        NOT NULL DEFAULT CURRENT_TIMESTAMP,

  FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE,
  UNIQUE KEY uq_tag_user_name (user_id, name),
  INDEX idx_tags_user (user_id)
) ENGINE=InnoDB;

-- ============================================================
-- Note-Tag Mapping (many-to-many)
-- ============================================================
CREATE TABLE IF NOT EXISTS note_tags (
  note_id     INT UNSIGNED    NOT NULL,
  tag_id      INT UNSIGNED    NOT NULL,

  PRIMARY KEY (note_id, tag_id),
  FOREIGN KEY (note_id) REFERENCES notes(id) ON DELETE CASCADE,
  FOREIGN KEY (tag_id) REFERENCES tags(id) ON DELETE CASCADE
) ENGINE=InnoDB;

-- ============================================================
-- Attachments
-- ============================================================
CREATE TABLE IF NOT EXISTS attachments (
  id          INT UNSIGNED    AUTO_INCREMENT PRIMARY KEY,
  note_id     INT UNSIGNED    NOT NULL,
  filename    VARCHAR(255)    NOT NULL,
  mime_type   VARCHAR(100)    NOT NULL,
  size_bytes  INT UNSIGNED    NOT NULL,
  storage_path VARCHAR(500)   NOT NULL,
  created_at  DATETIME        NOT NULL DEFAULT CURRENT_TIMESTAMP,

  FOREIGN KEY (note_id) REFERENCES notes(id) ON DELETE CASCADE,
  INDEX idx_attachments_note (note_id)
) ENGINE=InnoDB;

-- ============================================================
-- Feedback
-- ============================================================
CREATE TABLE IF NOT EXISTS feedback (
  id          INT UNSIGNED    AUTO_INCREMENT PRIMARY KEY,
  user_id     INT UNSIGNED    NOT NULL,
  type        ENUM('feedback', 'bug') NOT NULL DEFAULT 'feedback',
  subject     VARCHAR(255)    NOT NULL,
  body        TEXT            NOT NULL,
  status      ENUM('open', 'in_progress', 'resolved', 'closed') NOT NULL DEFAULT 'open',
  created_at  DATETIME        NOT NULL DEFAULT CURRENT_TIMESTAMP,
  updated_at  DATETIME        NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,

  FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE,
  INDEX idx_feedback_user (user_id),
  INDEX idx_feedback_status (status)
) ENGINE=InnoDB;

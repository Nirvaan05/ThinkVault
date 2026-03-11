-- ThinkVault: Token Blocklist Migration
-- Version: 002
-- Date: 2026-02-28
-- Description: Adds token_blocklist table for JWT revocation on logout

CREATE TABLE IF NOT EXISTS token_blocklist (
  id          INT UNSIGNED   AUTO_INCREMENT PRIMARY KEY,
  jti         VARCHAR(36)    NOT NULL UNIQUE,
  user_id     INT UNSIGNED   NOT NULL,
  expires_at  DATETIME       NOT NULL,
  created_at  DATETIME       NOT NULL DEFAULT CURRENT_TIMESTAMP,

  FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE,
  INDEX idx_blocklist_jti (jti),
  INDEX idx_blocklist_exp (expires_at)
) ENGINE=InnoDB;

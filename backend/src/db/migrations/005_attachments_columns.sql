-- ThinkVault: Attachment user_id column
-- Version: 005
-- Date: 2026-02-28
-- Description: Adds user_id to attachments for ownership checks without a JOIN.
--              Errors on duplicate column/key are suppressed by the migration runner.

ALTER TABLE attachments
  ADD COLUMN user_id INT UNSIGNED NOT NULL AFTER id,
  ADD CONSTRAINT fk_attachments_user FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE,
  ADD INDEX idx_attachments_user_note (user_id, note_id)

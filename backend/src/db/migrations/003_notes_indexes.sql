-- ThinkVault: Notes Phase 3 Column + Index Migration
-- Version: 003
-- Date: 2026-02-28
-- Description: Adds is_pinned column to notes (Phase 3) and a compound user+date
--              index. The FULLTEXT index already exists from 001. ER_DUP_KEYNAME
--              errors are ignored by the migration runner so this is idempotent.

ALTER TABLE notes ADD COLUMN is_pinned BOOLEAN NOT NULL DEFAULT FALSE AFTER priority;

ALTER TABLE notes ADD INDEX idx_notes_user_updated (user_id, updated_at);

ALTER TABLE notes ADD FULLTEXT INDEX idx_notes_fulltext (title, content)

-- ThinkVault: Organization & Search Index Migration
-- Version: 004
-- Date: 2026-02-28
-- Description: Adds composite indexes to support Phase 4 category/tag/priority
--              filter queries and full-text search performance.
--              All core tables (categories, tags, note_tags) and columns
--              (notes.category_id, notes.priority) already exist from migration 001.
--              ER_DUP_KEYNAME errors are ignored by the migration runner — idempotent.

-- Composite index for notes filtered by category within a user
ALTER TABLE notes ADD INDEX idx_notes_user_category (user_id, category_id);

-- Composite index for notes filtered by priority within a user
ALTER TABLE notes ADD INDEX idx_notes_user_priority (user_id, priority);

-- ThinkVault: Feedback Indexes Migration
-- Version: 007
-- Date: 2026-03-04
-- Description: Adds type index to feedback table for efficient admin filtering.
--              The feedback table itself was created in 001_initial_schema.sql.
--              ER_DUP_KEYNAME is suppressed by the migration runner on re-runs.

ALTER TABLE feedback ADD INDEX idx_feedback_type (type);

USE people_ops_suite;
-- New columns for the auto-recorded meetings flow. The original scheduling columns
-- (meeting_type, host_bu/team/sub_team/unit, is_recurring) are deliberately kept so the
-- existing meet-app scheduling functionality keeps working alongside this. The
-- auto-recording INSERT (upsertMeetRecordingQuery) doesn't set those columns, which is fine:
-- host_* / is_recurring have defaults, and meeting_type is nullable (see the staging
-- remediation note below), so auto-recorded rows simply leave them empty.
ALTER TABLE meeting
    ADD COLUMN space_name VARCHAR(255) NULL,
    ADD COLUMN external_participants TEXT NULL,
    ADD COLUMN drive_file_id VARCHAR(255) NULL,
    ADD COLUMN recording_state ENUM('PENDING', 'ATTACHED', 'FAILED') NULL;
CREATE TABLE calendar_watch_state (
    id INT PRIMARY KEY DEFAULT 1,
    sync_token VARCHAR(1000) NULL,
    updated_on DATETIME NULL ON UPDATE CURRENT_TIMESTAMP
);

INSERT INTO calendar_watch_state (id, sync_token) VALUES (1, NULL);



-- Prevents two concurrent upsertMeetRecording calls from ever creating duplicate rows for
-- the same Meet space; paired with an atomic INSERT ... ON DUPLICATE KEY UPDATE in code.
ALTER TABLE meeting ADD UNIQUE (space_name);

-- ── STAGING REMEDIATION (one-off, run manually) ──────────────────────────────────
-- ONLY for an environment where an earlier version of this migration already ran its
-- (now-removed) "DROP COLUMN meeting_type, host_bu, host_team, host_sub_team, host_unit,
-- is_recurring" block and therefore lost those columns (e.g. staging). This re-adds them so
-- the existing meeting-scheduling functionality works again.
--   * meeting_type is re-added as NULL (it was originally NOT NULL) so the auto-recording
--     INSERT -- which never sets meeting_type -- doesn't fail. The stats query already filters
--     `WHERE meeting_type IS NOT NULL`, so auto-recorded rows are correctly excluded.
--   * host_* / is_recurring are re-added with their original defaults.
-- Do NOT run this on a fresh DB built from meet_database.sql -- it already has these columns
-- and this block would error on duplicate columns. Uncomment and run only where needed:
--
-- ALTER TABLE meeting
--     ADD COLUMN meeting_type  VARCHAR(255) NULL,
--     ADD COLUMN host_bu       VARCHAR(50)  NULL DEFAULT 'N/A',
--     ADD COLUMN host_team     VARCHAR(50)  NULL DEFAULT 'N/A',
--     ADD COLUMN host_sub_team VARCHAR(50)  NULL DEFAULT 'N/A',
--     ADD COLUMN host_unit     VARCHAR(50)  NULL DEFAULT 'N/A',
--     ADD COLUMN is_recurring  BOOLEAN      NOT NULL DEFAULT 0;
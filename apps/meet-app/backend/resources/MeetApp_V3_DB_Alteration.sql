USE people_ops_suite;
-- New columns for the auto-recorded meetings flow. The original scheduling columns
-- (meeting_type, host_bu/team/sub_team/unit, is_recurring) are deliberately kept so the
-- existing meet-app scheduling functionality keeps working alongside this. The
-- auto-recording INSERT (upsertMeetRecordingQuery) doesn't set those columns, which is fine:
-- host_* / is_recurring have defaults, and meeting_type is made nullable just below, so
-- auto-recorded rows simply leave them empty.
ALTER TABLE meeting
    ADD COLUMN space_name VARCHAR(255) NULL,
    ADD COLUMN external_participants TEXT NULL,
    ADD COLUMN drive_file_id VARCHAR(255) NULL,
    ADD COLUMN recording_state ENUM('PENDING', 'ATTACHED', 'FAILED') NULL;

-- meeting_type was originally NOT NULL, but the auto-recording INSERT never sets it, so it
-- must allow NULL. Safe no-op if already nullable. Run this on any environment where the
-- meeting_type column still EXISTS (e.g. production upgrading from the original schema).
-- On an environment that DROPPED meeting_type (see staging remediation below), skip this --
-- the remediation re-adds it already nullable. The stats query filters `meeting_type IS NOT
-- NULL`, so auto-recorded rows (NULL type) stay correctly excluded from the type breakdown.
ALTER TABLE meeting MODIFY meeting_type VARCHAR(255) NULL;
CREATE TABLE calendar_watch_state (
    id INT PRIMARY KEY DEFAULT 1,
    sync_token VARCHAR(1000) NULL,
    updated_on DATETIME NULL ON UPDATE CURRENT_TIMESTAMP
);

INSERT INTO calendar_watch_state (id, sync_token) VALUES (1, NULL);

-- Links an auto-recorded meeting back to the Salesforce Opportunity it was scheduled for.
-- Value comes from the calendar event's own extendedProperties.private.revos_opportunity_id
-- (written by the RevOS add-on). NULL for the existing manual-scheduling flow, which has no
-- Salesforce opportunity at all.
ALTER TABLE people_ops_suite.meeting
ADD COLUMN `opportunity_id` VARCHAR(255) NULL;

-- Compact deal context (name, stage, amount, account, close date) alongside the meeting,
-- from the event's extendedProperties.private.revos_opportunity_snapshot -- a JSON string
-- the add-on already builds and writes onto the event. NULL wherever opportunity_id is NULL.
ALTER TABLE people_ops_suite.meeting
ADD COLUMN `opportunity_details` JSON NULL;

-- Tracks Meet transcript processing, parallel to recording_state/drive_file_id but
-- deliberately independent: not every meeting has transcription enabled, so unlike
-- recording_state (set to PENDING as soon as the meeting is registered), this stays NULL
-- until an actual transcript-ready notification arrives and sets it directly to ATTACHED
-- or FAILED. NULL means "no transcript for this meeting", not "waiting on one".
ALTER TABLE people_ops_suite.meeting
ADD COLUMN `transcript_state` ENUM('PENDING', 'ATTACHED', 'FAILED') NULL;

-- Drive file ID (a Google Doc) of the meeting's transcript, once resolved.
ALTER TABLE people_ops_suite.meeting
ADD COLUMN `transcript_file_id` VARCHAR(255) NULL;

-- Tracks Meet smart-notes ("Take Notes with Gemini") processing, parallel to
-- transcript_state/transcript_file_id but for a separate Google Doc artifact -- same
-- NULL-means-"none for this meeting" semantics, since smart notes additionally requires
-- an org-level admin-console toggle and can silently never arrive even when requested.
ALTER TABLE people_ops_suite.meeting
ADD COLUMN `smart_notes_state` ENUM('PENDING', 'ATTACHED', 'FAILED') NULL;

-- Drive file ID (a Google Doc, separate from the transcript's) of the meeting's smart
-- notes, once resolved.
ALTER TABLE people_ops_suite.meeting
ADD COLUMN `smart_notes_file_id` VARCHAR(255) NULL;



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
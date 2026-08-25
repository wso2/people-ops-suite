-- MeetApp V3 — auto-recorded meetings schema
-- Run once against the `people_ops_suite` database. Not idempotent by design: re-running
-- errors on duplicate columns/tables, which is the intended guard against running it twice.

USE people_ops_suite;

-- New columns for the auto-recorded meetings flow. The original scheduling columns
-- (meeting_type, host_bu/team/sub_team/unit, is_recurring) are deliberately kept so the
-- existing meet-app scheduling functionality keeps working alongside this. 
--   space_name            Meet space identifier; links a `meeting` row to its Meet space.
--   external_participants External (non-org) participant emails for the meeting.
--   drive_file_id         Drive file ID of the resolved recording, once attached.
--   recording_state       PENDING as soon as the meeting is registered, then ATTACHED or FAILED once the recording-ready notification is processed.
--   opportunity_id        Links to the Salesforce Opportunity the meeting was scheduled forfrom the calendar event's
--   opportunity_details   Compact deal snapshot (name, stage, amount, account, close date)
--   transcript_state      Parallel to recording_state, but deliberately independent: 
--   transcript_file_id    Drive file ID (a Google Doc) of the meeting's transcript,
--   smart_notes_state     Parallel to transcript_state, for Meet's "Take Notes with Gemini" output 
--   smart_notes_file_id   Drive file ID (a Google Doc, separate from the transcript's) of the meeting's smart notes.

-- The UNIQUE constraint on space_name prevents two concurrent upsertMeetRecording calls
-- from  creating duplicate rows for the same Meet space; 

ALTER TABLE meeting
    ADD COLUMN space_name            VARCHAR(255) NULL,
    ADD COLUMN external_participants TEXT         NULL,
    ADD COLUMN drive_file_id         VARCHAR(255) NULL,
    ADD COLUMN recording_state       ENUM('PENDING', 'ATTACHED', 'FAILED') NULL,
    ADD COLUMN opportunity_id        VARCHAR(255) NULL,
    ADD COLUMN opportunity_details   JSON         NULL,
    ADD COLUMN transcript_state      ENUM('PENDING', 'ATTACHED', 'FAILED') NULL,
    ADD COLUMN transcript_file_id    VARCHAR(255) NULL,
    ADD COLUMN smart_notes_state     ENUM('PENDING', 'ATTACHED', 'FAILED') NULL,
    ADD COLUMN smart_notes_file_id   VARCHAR(255) NULL,
    MODIFY COLUMN meeting_type       VARCHAR(255) NULL,
    ADD UNIQUE (space_name);

-- Holds the sync token for the calendar-watch flow. Single row, id fixed at 1 — the
-- calendar-watch-renewal component updates channel_id/resource_id/channel_expiration on
-- this same row once the watch channel is registered.
CREATE TABLE calendar_watch_state (
    id                 INT PRIMARY KEY DEFAULT 1,
    sync_token         VARCHAR(1000) NULL,
    channel_id         VARCHAR(255) NULL,
    resource_id        VARCHAR(255) NULL,
    channel_expiration BIGINT NULL,
    updated_on         DATETIME NULL ON UPDATE CURRENT_TIMESTAMP
);
INSERT INTO calendar_watch_state (id, sync_token) VALUES (1, NULL);


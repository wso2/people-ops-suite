-- MeetApp V3 — auto-recorded meetings schema
-- Run once against the `people_ops_suite` database. Not idempotent by design: re-running
-- errors on duplicate columns/tables, which is the intended guard against running it twice.

USE people_ops_suite;

-- New columns for the auto-recorded meetings flow. The original scheduling columns
-- (meeting_type, host_bu/team/sub_team/unit, is_recurring) are deliberately kept so the
-- existing meet-app scheduling functionality keeps working alongside this. The
-- auto-recording INSERT (upsertMeetRecordingQuery) doesn't set those columns, which is
-- fine: host_* / is_recurring have defaults, and meeting_type is made nullable in the same
-- statement below, so auto-recorded rows simply leave them empty.
--
--   space_name            Meet space identifier; links a `meeting` row to its Meet space.
--   external_participants External (non-org) participant emails for the meeting.
--   drive_file_id         Drive file ID of the resolved recording, once attached.
--   recording_state       PENDING as soon as the meeting is registered, then ATTACHED or
--                          FAILED once the recording-ready notification is processed.
--   opportunity_id        Links to the Salesforce Opportunity the meeting was scheduled
--                          for, from the calendar event's
--                          extendedProperties.private.revos_opportunity_id (written by the
--                          RevOS add-on). NULL for the existing manual-scheduling flow,
--                          which has no Salesforce opportunity at all.
--   opportunity_details   Compact deal snapshot (name, stage, amount, account, close date)
--                          from extendedProperties.private.revos_opportunity_snapshot, a
--                          JSON string the add-on already builds and writes onto the
--                          event. NULL wherever opportunity_id is NULL.
--   transcript_state      Parallel to recording_state, but deliberately independent: not
--                          every meeting has transcription enabled, so this stays NULL
--                          until an actual transcript-ready notification arrives and sets
--                          it directly to ATTACHED or FAILED. NULL means "no transcript
--                          for this meeting", not "waiting on one".
--   transcript_file_id    Drive file ID (a Google Doc) of the meeting's transcript, once
--                          resolved.
--   smart_notes_state     Parallel to transcript_state, for Meet's "Take Notes with
--                          Gemini" output — same NULL-means-"none" semantics, since smart
--                          notes additionally requires an org-level admin-console toggle
--                          and can silently never arrive even when requested.
--   smart_notes_file_id   Drive file ID (a Google Doc, separate from the transcript's) of
--                          the meeting's smart notes, once resolved.
--
-- meeting_type was originally NOT NULL; the auto-recording INSERT never sets it, so it's
-- made nullable here in the same statement (safe no-op if already nullable). The stats
-- query filters `meeting_type IS NOT NULL`, so auto-recorded rows (NULL type) stay
-- correctly excluded from the type breakdown.
--
-- The UNIQUE constraint on space_name prevents two concurrent upsertMeetRecording calls
-- from ever creating duplicate rows for the same Meet space; paired with an atomic
-- INSERT ... ON DUPLICATE KEY UPDATE in code.
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

-- Holds the watch channel's known-good state. Single row, id fixed at 1.
--   sync_token          Calendar incremental-sync token, used by meet-app-backend's own
--                        watch handler.
--   channel_id           }
--   resource_id           } written by the meet-watch-renewal Scheduled Task (a separate
--   channel_expiration   } digiops-hr component) once it registers/renews the channel.
-- channel_id/resource_id/channel_expiration are defined here directly rather than added
-- later by meet-watch-renewal's own watch_renewal_alteration.sql, since this table doesn't
-- exist in prod yet either way -- no reason to CREATE then ALTER the same fresh table in
-- two separate migration steps across two repos.
CREATE TABLE calendar_watch_state (
    id                 INT PRIMARY KEY DEFAULT 1,
    sync_token         VARCHAR(1000) NULL,
    channel_id         VARCHAR(255) NULL,
    resource_id        VARCHAR(255) NULL,
    channel_expiration BIGINT NULL,
    updated_on         DATETIME NULL ON UPDATE CURRENT_TIMESTAMP
);

INSERT INTO calendar_watch_state (id, sync_token) VALUES (1, NULL);

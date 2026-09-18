-- MeetApp V4 — Salesforce account link on auto-recorded meetings
--
-- Run once against the `people_ops_suite` database, AFTER MeetApp_V3_DB_Alteration.sql.
-- Not idempotent, by the same deliberate choice V3 made: re-running errors on duplicate
-- columns, which is the intended guard against running it twice.

USE people_ops_suite;

ALTER TABLE meeting
    ADD COLUMN account_id   VARCHAR(255) NULL,
    ADD COLUMN `call_activity_id` VARCHAR(64) NULL,
    ADD COLUMN account_name VARCHAR(255) NULL;

-- Meet's own resource name for the transcript, e.g.
-- `conferenceRecords/abc123/transcripts/xyz`.
--
-- WHY THIS IS NEEDED when transcript_file_id is already stored: the Drive file is the
-- transcript as a DOCUMENT -- prose, no structure. Meet also exposes the same conversation
-- through its API as timed entries (who spoke, what they said, when), and that is what a
-- transcript synchronised to the recording needs. Reaching those entries requires this
-- resource name, which the Pub/Sub notification already carries and which the pipeline
-- previously read once and discarded.
--
-- Rows written before this column existed keep it NULL, and fall back to the Drive
-- document -- readable, but with no timestamps to seek by.
ALTER TABLE meeting
    ADD COLUMN transcript_name VARCHAR(255) NULL;

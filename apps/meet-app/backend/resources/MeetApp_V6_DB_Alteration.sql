-- MeetApp V6 — one meeting, many recordings, transcripts and smart notes
--
-- Run once against the `people_ops_suite` database, AFTER MeetApp_V5_DB_Alteration.sql.
-- Not idempotent, by the same deliberate choice V3 to V5 made: re-running errors on the
-- existing tables, which is the intended guard against running it twice.
--
-- ADDITIVE ONLY. Nothing on `meeting` is altered or dropped: three tables are created and
-- the existing file ids are COPIED into them. The `meeting` columns stay and keep working.
--
-- WHY THIS EXISTS
--
-- Stopping and restarting a recording mid-call is normal, and Meet models it faithfully:
-- `conferenceRecords/{id}/recordings/{id}` is one resource per recording session, and
-- transcripts and smart notes are the same, one per session. So one call can produce several
-- of each, and their counts need not match -- recording, transcription and note-taking are
-- separate controls, so stopping one does not stop the others.
--
-- Until now `meeting` held one file id per kind, so a second recording-ready event for the
-- same meeting overwrote the first part's file id. The app kept only one part while the
-- others stayed in Drive, still attached to the calendar event but unreachable from the app.
--
-- Each part is keyed on Meet's OWN resource name. That name is stable per part, so a
-- Pub/Sub redelivery of the same event updates its own row rather than clobbering a sibling.

USE people_ops_suite;

-- One row per recording session, e.g. `conferenceRecords/abc123/recordings/xyz`.
CREATE TABLE meeting_recording (
    id              INT AUTO_INCREMENT PRIMARY KEY,
    meeting_id      INT          NOT NULL,
    recording_name  VARCHAR(255) NOT NULL,
    -- The call the part belongs to, e.g. `conferenceRecords/abc123`. NULL on backfilled rows.
    conference_record VARCHAR(255) NULL,
    drive_file_id   VARCHAR(255) NULL,
    -- From the Meet resource, not inferred. Orders the parts, and places transcript lines on
    -- the right one: a line's timestamp is absolute, so without the part's own start every
    -- timeline after the first is wrong by the length of everything before it. UTC.
    start_time      DATETIME     NULL,
    end_time        DATETIME     NULL,
    -- Position of the file among the calendar event's attachments, which the pipeline added
    -- in the order the parts arrived. Orders parts that have no Meet times: Meet deletes a
    -- call's record 30 days after it ends, so older parts only ever get this.
    attachment_order INT         NULL,
    state           ENUM('PENDING', 'ATTACHED', 'FAILED') NOT NULL DEFAULT 'PENDING',
    created_on      TIMESTAMP(6) NOT NULL DEFAULT CURRENT_TIMESTAMP(6),
    created_by      VARCHAR(60)  NOT NULL,
    updated_on      TIMESTAMP(6) NOT NULL DEFAULT CURRENT_TIMESTAMP(6) ON UPDATE CURRENT_TIMESTAMP(6),
    updated_by      VARCHAR(60)  NOT NULL,
    UNIQUE KEY uq_meeting_recording_name (recording_name),
    KEY idx_meeting_recording_meeting (meeting_id, start_time),
    -- Finds a backfilled row by its file when the real Meet name for it arrives.
    KEY idx_meeting_recording_file (meeting_id, drive_file_id),
    CONSTRAINT fk_meeting_recording_meeting FOREIGN KEY (meeting_id)
        REFERENCES meeting (meeting_id) ON DELETE CASCADE
);

-- One row per transcription session, e.g. `conferenceRecords/abc123/transcripts/xyz`.
-- Deliberately NOT a child of meeting_recording: a transcript is not owned by a recording and
-- the two are not 1:1. They are matched at read time by overlapping time windows, which is the
-- only thing that handles "one long transcript spanning two recordings" correctly.
CREATE TABLE meeting_transcript (
    id              INT AUTO_INCREMENT PRIMARY KEY,
    meeting_id      INT          NOT NULL,
    transcript_name VARCHAR(255) NOT NULL,
    conference_record VARCHAR(255) NULL,
    drive_file_id   VARCHAR(255) NULL,
    start_time      DATETIME     NULL,
    end_time        DATETIME     NULL,
    attachment_order INT         NULL,
    state           ENUM('PENDING', 'ATTACHED', 'FAILED') NOT NULL DEFAULT 'PENDING',
    created_on      TIMESTAMP(6) NOT NULL DEFAULT CURRENT_TIMESTAMP(6),
    created_by      VARCHAR(60)  NOT NULL,
    updated_on      TIMESTAMP(6) NOT NULL DEFAULT CURRENT_TIMESTAMP(6) ON UPDATE CURRENT_TIMESTAMP(6),
    updated_by      VARCHAR(60)  NOT NULL,
    UNIQUE KEY uq_meeting_transcript_name (transcript_name),
    KEY idx_meeting_transcript_meeting (meeting_id, start_time),
    KEY idx_meeting_transcript_file (meeting_id, drive_file_id),
    CONSTRAINT fk_meeting_transcript_meeting FOREIGN KEY (meeting_id)
        REFERENCES meeting (meeting_id) ON DELETE CASCADE
);

-- One row per Gemini note-taking session, e.g. `conferenceRecords/abc123/smartNotes/xyz`.
-- Can point at the same Google Doc as a transcript: with Gemini notes on, Meet writes the
-- transcript into the notes document.
CREATE TABLE meeting_smart_note (
    id              INT AUTO_INCREMENT PRIMARY KEY,
    meeting_id      INT          NOT NULL,
    smart_note_name VARCHAR(255) NOT NULL,
    conference_record VARCHAR(255) NULL,
    drive_file_id   VARCHAR(255) NULL,
    start_time      DATETIME     NULL,
    end_time        DATETIME     NULL,
    attachment_order INT         NULL,
    state           ENUM('PENDING', 'ATTACHED', 'FAILED') NOT NULL DEFAULT 'PENDING',
    created_on      TIMESTAMP(6) NOT NULL DEFAULT CURRENT_TIMESTAMP(6),
    created_by      VARCHAR(60)  NOT NULL,
    updated_on      TIMESTAMP(6) NOT NULL DEFAULT CURRENT_TIMESTAMP(6) ON UPDATE CURRENT_TIMESTAMP(6),
    updated_by      VARCHAR(60)  NOT NULL,
    UNIQUE KEY uq_meeting_smart_note_name (smart_note_name),
    KEY idx_meeting_smart_note_meeting (meeting_id, start_time),
    KEY idx_meeting_smart_note_file (meeting_id, drive_file_id),
    CONSTRAINT fk_meeting_smart_note_meeting FOREIGN KEY (meeting_id)
        REFERENCES meeting (meeting_id) ON DELETE CASCADE
);

-- COPY. Every meeting's current file becomes a part, so nothing already recorded disappears
-- from the app. The `meeting` columns are read, never changed. Note the current file is the
-- LAST part to have arrived, since each overwrote the one before; the parts backfill adds the
-- earlier ones from the calendar event's attachments and puts them all in order.
--
-- The recording and smart notes were never stored with their Meet resource name -- only the
-- transcript's was (V4) -- so those rows get a placeholder derived from the meeting id. It
-- satisfies the UNIQUE key and is obviously not a Meet name. When the real name for the same
-- file later arrives (a redelivery, or the backfill), the app finds the row by its file and
-- replaces the placeholder, rather than adding the same file a second time.
INSERT INTO meeting_recording (meeting_id, recording_name, drive_file_id, state, created_by, updated_by)
SELECT meeting_id,
       CONCAT('legacy:recording:', meeting_id),
       drive_file_id,
       COALESCE(recording_state, 'ATTACHED'),
       'V6_COPY',
       'V6_COPY'
FROM meeting
WHERE drive_file_id IS NOT NULL;

-- Real Meet name where V4 captured one, a placeholder otherwise. COALESCE rather than two
-- statements, so a transcript file with no stored name still carries over.
INSERT INTO meeting_transcript (meeting_id, transcript_name, drive_file_id, state, created_by, updated_by)
SELECT meeting_id,
       COALESCE(transcript_name, CONCAT('legacy:transcript:', meeting_id)),
       transcript_file_id,
       COALESCE(transcript_state, 'ATTACHED'),
       'V6_COPY',
       'V6_COPY'
FROM meeting
WHERE transcript_file_id IS NOT NULL;

INSERT INTO meeting_smart_note (meeting_id, smart_note_name, drive_file_id, state, created_by, updated_by)
SELECT meeting_id,
       CONCAT('legacy:smart-note:', meeting_id),
       smart_notes_file_id,
       COALESCE(smart_notes_state, 'ATTACHED'),
       'V6_COPY',
       'V6_COPY'
FROM meeting
WHERE smart_notes_file_id IS NOT NULL;

-- The columns on `meeting` are deliberately LEFT IN PLACE. From now on the app writes them
-- only for a meeting's first part and never overwrites them, and everything that reads them keeps
-- working while readers move to the tables above. Dropping them is a separate change, once
-- nothing reads them.

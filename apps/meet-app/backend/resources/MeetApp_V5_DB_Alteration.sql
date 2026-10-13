-- MeetApp V5 — Salesforce lead link on auto-recorded meetings
--
-- Run once against the `people_ops_suite` database, AFTER MeetApp_V4_DB_Alteration.sql.
-- Not idempotent, by the same deliberate choice V3 and V4 made: re-running errors on
-- duplicate columns, which is the intended guard against running it twice.
--
-- The Echo add-on's Inbound call type targets a Salesforce Lead, not a deal or an account,
-- and writes `revos_lead_id` / `revos_lead_company` on the event. Until now the calendar
-- watcher never read them, so an Inbound meeting had no Salesforce target and its call was
-- never logged. These columns hold that link; both stay NULL for every other call type and
-- for rows written before this alteration (the lead backfill fills recent Inbound rows).

USE people_ops_suite;

ALTER TABLE meeting
    ADD COLUMN lead_id      VARCHAR(255) NULL,
    ADD COLUMN lead_company VARCHAR(255) NULL;

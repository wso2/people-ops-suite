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

USE people_ops_suite;
ALTER TABLE meeting
    ADD COLUMN space_name VARCHAR(255) NULL,
    ADD COLUMN external_participants TEXT NULL,
    ADD COLUMN drive_file_id VARCHAR(255) NULL,
    ADD COLUMN recording_state ENUM('PENDING', 'ATTACHED', 'FAILED') NULL;
ALTER TABLE meeting
    DROP COLUMN meeting_type,
    DROP COLUMN host_bu,
    DROP COLUMN host_team,
    DROP COLUMN host_sub_team,
    DROP COLUMN host_unit,
    DROP COLUMN is_recurring;
CREATE TABLE calendar_watch_state (
    id INT PRIMARY KEY DEFAULT 1,
    sync_token VARCHAR(1000) NULL,
    updated_on DATETIME NULL ON UPDATE CURRENT_TIMESTAMP
);

INSERT INTO calendar_watch_state (id, sync_token) VALUES (1, NULL);
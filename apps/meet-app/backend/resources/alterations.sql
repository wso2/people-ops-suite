-- Add Event Creator column to store the event creation calendarId
ALTER TABLE people_ops_suite.meeting 
ADD COLUMN `event_creator` VARCHAR(50) NOT NULL DEFAULT '<ORIGINAL CREATOR>' AFTER `host_unit`; 
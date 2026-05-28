-- Add a column to store the meeting customer name
ALTER TABLE people_ops_suite.meeting
  ADD COLUMN customer_name VARCHAR(255) NULL
  AFTER wso2_participants;

-- Add Business Unit, Team, Unit and Sub-team columns to store the host's organizational state at the time of the meeting
ALTER TABLE people_ops_suite.meeting
  ADD COLUMN `host_bu` VARCHAR(50) NULL DEFAULT 'N/A' AFTER `host`,
  ADD COLUMN `host_team` VARCHAR(50) NULL DEFAULT 'N/A' AFTER `host_bu`,
  ADD COLUMN `host_sub_team` VARCHAR(50) NULL DEFAULT 'N/A' AFTER `host_team`,
  ADD COLUMN `host_unit` VARCHAR(50) NULL DEFAULT 'N/A' AFTER `host_sub_team`;
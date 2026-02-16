-- Add a flag to indicate whether a meeting belongs to a recurring series
ALTER TABLE people_ops_suite.meeting
  ADD COLUMN is_recurring BOOLEAN NOT NULL DEFAULT 0
  AFTER wso2_participants;

-- Add a column to store meeting type 
ALTER TABLE people_ops_suite.meeting
ADD COLUMN meeting_type VARCHAR(255) AFTER title;

-- Add Business Unit, Team, Unit and Sub-team columns to store the host's organizational state at the time of the meeting
ALTER TABLE `meeting` 
  ADD COLUMN `host_team` VARCHAR(50) NOT NULL AFTER `host`,
  ADD COLUMN `host_sub_team` VARCHAR(50) NOT NULL AFTER `host_team`,
  ADD COLUMN `host_bu` VARCHAR(50) NOT NULL AFTER `host_sub_team`,
  ADD COLUMN `host_unit` VARCHAR(50) NOT NULL AFTER `host_bu`;
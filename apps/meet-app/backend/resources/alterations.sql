-- Add a flag to indicate whether a meeting belongs to a recurring series
ALTER TABLE people_ops_suite.meeting
  ADD COLUMN is_recurring BOOLEAN NOT NULL DEFAULT 0
  AFTER wso2_participants;
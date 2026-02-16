USE `people_ops_suite`;

-- Create the meeting table to store meeting details
CREATE TABLE meeting (
  `meeting_id` INT NOT NULL AUTO_INCREMENT,    -- Unique meeting ID
  `title` VARCHAR(120) NOT NULL,                -- Title of the meeting
  `google_event_id` VARCHAR(120) NOT NULL,      -- Google event ID
  `host` VARCHAR(60) NOT NULL,                  -- Host of the meeting
  `host_team` VARCHAR(50) NOT NULL,            -- Department of the host
  `host_sub_team` VARCHAR(50) NOT NULL,        -- Team of the host
  `host_bu` VARCHAR(50) NOT NULL,              -- Sub team of the host
  `host_unit`VARCHAR(50) NOT NULL               -- Business unit of the host
  `start_time` DATETIME NOT NULL,               -- Start time of the meeting
  `end_time` DATETIME NOT NULL,                 -- End time of the meeting
  `wso2_participants` TEXT NOT NULL,            -- List of participants (comma-separated values)
  `meeting_status` ENUM('ACTIVE', 'CANCELLED') NOT NULL,  -- Status of the meeting
  `created_on` TIMESTAMP(6) NOT NULL DEFAULT CURRENT_TIMESTAMP(6),  -- Auto-generated timestamp on creation
  `created_by` VARCHAR(60) NOT NULL,            -- Creator of the meeting record
  `updated_on` TIMESTAMP(6) NOT NULL DEFAULT CURRENT_TIMESTAMP(6) ON UPDATE CURRENT_TIMESTAMP(6),
  `updated_by` VARCHAR(60) NOT NULL,            -- Last user who updated the record
  PRIMARY KEY (`meeting_id`)                    -- Primary key for the table
);

-- Create the meeting_type table to store meeting domain and types
CREATE TABLE meeting_type (
  `domain` VARCHAR(100) NOT NULL,               -- Domain name (e.g., Sales, Marketing, etc.)
  `types` TEXT NOT NULL,                        -- List of meeting types in JSON format
  `created_on` TIMESTAMP(6) NOT NULL DEFAULT CURRENT_TIMESTAMP(6),  -- Auto-generated timestamp on creation
  `created_by` VARCHAR(60) NOT NULL,            -- Creator of the meeting type record
  `updated_on` TIMESTAMP(6) NOT NULL DEFAULT CURRENT_TIMESTAMP(6) ON UPDATE CURRENT_TIMESTAMP(6),
  `updated_by` VARCHAR(60) NOT NULL,            -- Last user who updated the record
  PRIMARY KEY (`domain`)                       -- Primary key for the table
);

-- Insert data into the meeting_type table
INSERT INTO meeting_type (`domain`, `types`, `created_by`, `updated_by`)
VALUES
  ('Sales', 'Discovery Call, Technical Call, Demo Call, POC Call, Legal Chat, Procurement Chat, Pricing Chat',
  'system', 'system');

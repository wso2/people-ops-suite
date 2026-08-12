// Copyright (c) 2025 WSO2 LLC. (https://www.wso2.com).
//
// WSO2 LLC. licenses this file to you under the Apache License,
// Version 2.0 (the "License"); you may not use this file except
// in compliance with the License.
// You may obtain a copy of the License at
//
// http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing,
// software distributed under the License is distributed on an
// "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY
// KIND, either express or implied.  See the License for the
// specific language governing permissions and limitations
// under the License. 
import ballerina/sql;
import ballerinax/mysql;

# [Configurable] Database configs.
type DatabaseConfig record {|
    # If the MySQL server is secured, the username
    string user;
    # The password of the MySQL server for the provided username
    string password;
    # The name of the database
    string database;
    # Hostname of the MySQL server
    string host;
    # Port number of the MySQL server
    int port;
    # The `mysql:Options` configurations
    mysql:Options options?;
    # The `sql:ConnectionPool` configurations
    sql:ConnectionPool connectionPool?;
|};

# [Database] Insert type for Meeting.
public type AddMeetingPayload record {|
    # Title of the meeting
    string title;
    # Google event ID
    string googleEventId;
    # Host of the meeting
    string host;
    # Creator of the event
    string eventCreator;
    # Internal participants' email list
    string internalParticipants;
    # Meeting start time in ISO format
    string startTime;
    # Meeting end time in ISO format
    string endTime;
    # Whether the meeting is recurring
    boolean isRecurring;
    # Recurrence rule of the meeting
    string? recurrence_rule;
    # Meeting type
    string meetingType;
    # Business unit  of the host
    string? businessUnit;
    # Team of the host
    string? team;
    # Sub team of the host 
    string? subTeam;
    # Unit  of the host
    string? unit;
|};

# [Database]Meeting type.
public type Meeting record {|
    # Auto-increment meeting ID
    int meetingId;
    # Title of the meeting
    string title;
    # Google event ID
    string googleEventId;
    # Host of the meeting
    string host;
    # Meet creator email
    string eventCreator;
    # Meeting start time
    string startTime;
    # Meeting end time
    string endTime;
    # Internal participants' email list
    string internalParticipants;
    # Meeting status (e.g., 'ACTIVE', 'CANCELLED')
    MeetingStatus meetingStatus;
    # Timestamp when created
    string createdOn;
    # Person who created the meeting
    string createdBy;
    # Timestamp when updated
    string updatedOn;
    # Person who updated the meeting
    string updatedBy;
    # Total Count of Meeting
    int totalCount;
    # Time Status (e.g., 'PAST', 'UPCOMING')
    TimeStatus timeStatus;
    # Whether the meeting is recurring
    boolean isRecurring;
    # Recurrence rule of the meeting
    string? recurrence_rule;
|};

# [Database]RawMeetingTypes type.
public type RawMeetingTypes record {|
    # Meeting Domain
    string domain;
    # Meeting Types
    string types;
|};

# [Database]MeetingTypes type.
public type MeetingTypes record {|
    # Meeting Domain
    string domain;
    # Meeting Types
    string[] types;
|};

# [Database]MeetingStatus enum.
public enum MeetingStatus {
    ACTIVE = "ACTIVE",
    CANCELLED = "CANCELLED"
};

# [Database]TimeStatus enum.
public enum TimeStatus {
    PAST = "PAST",
    UPCOMING = "UPCOMING"
};

# [Database]Meeting type counts.
public type MeetingTypeStat record {|
    # Type of the meeting
    string meeting_type;
    # Number of meetings
    int count;
|};

# [Database]Meeting counts per host.
public type MeetingHostStat record {|
    # Email address of host 
    string host;
    # Total number of active meetings
    int count;
    # Team of the host
    string? team;
    # Sub team of the host
    string? subTeam;
|};

# [Database]Scheduled meeting count for a month.
#
# + month_key - The month
# + count - Number of meetings scheduled
public type ScheduledMeetingStat record {|
    string month_key;
    int count;
|};

# [Database] Recording processing state, for auto-recorded meetings tracked via the add-on.
public enum RecordingState {
    PENDING,
    ATTACHED,
    FAILED
}

# [Database] Insert/update payload for an auto-recorded meeting row.
#
# + title - The event's title
# + spaceName - Resource name of the Meet space (e.g. `spaces/abc123`) -- the lookup key
# + googleEventId - Calendar event ID the space was created for
# + organizer - Email of the event organizer
# + startTime - Event start time
# + endTime - Event end time
# + internalParticipants - wso2.com attendees, comma-joined
# + externalParticipants - Non-wso2.com attendees, comma-joined
# + recordingState - Current processing state
# + driveFileId - Drive file ID of the recording, once resolved
# + opportunityId - Salesforce Opportunity ID this call was scheduled for, if any
# + opportunityDetails - Compact JSON snapshot of the deal (name, stage, amount, account, close
# date), as a raw JSON string -- stored as-is, not parsed, since nothing here needs individual
# fields out of it
public type MeetRecordingPayload record {|
    string title;
    string spaceName;
    string googleEventId;
    string organizer;
    string startTime;
    string endTime;
    string internalParticipants;
    string externalParticipants;
    RecordingState recordingState;
    string? driveFileId = ();
    string? opportunityId = ();
    string? opportunityDetails = ();
|};

# [Database] An auto-recorded meeting row, read back by space name.
#
# + meetingId - Auto-increment meeting ID
# + spaceName - Resource name of the Meet space
# + title - The event's title
# + googleEventId - Calendar event ID
# + organizer - Email of the event organizer
# + startTime - Event start time
# + endTime - Event end time
# + internalParticipants - wso2.com attendees, comma-joined
# + externalParticipants - Non-wso2.com attendees, comma-joined
# + recordingState - Current processing state
# + driveFileId - Drive file ID of the recording, if resolved yet
# + opportunityId - Salesforce Opportunity ID this call was scheduled for, if any
# + opportunityDetails - Compact JSON snapshot of the deal, as a raw JSON string
# + transcriptState - Current transcript processing state, () if no transcript for this
# meeting (either transcription wasn't enabled, or no transcript-ready notification has
# arrived yet) -- reuses RecordingState rather than a separate enum with the same member
# names, which would collide as duplicate module-level constants
# + transcriptFileId - Drive file ID (Google Doc) of the transcript, if resolved yet
# + smartNotesState - Current smart-notes processing state, () if no smart notes for this
# meeting; same reused-RecordingState and NULL-means-"none" semantics as transcriptState
# + smartNotesFileId - Drive file ID (Google Doc, separate from the transcript's) of the
# smart notes, if resolved yet
public type MeetRecordingRow record {|
    int meetingId;
    string spaceName;
    string title;
    string googleEventId;
    string organizer;
    string startTime;
    string endTime;
    string internalParticipants;
    string externalParticipants;
    RecordingState recordingState;
    string? driveFileId;
    string? opportunityId;
    string? opportunityDetails;
    RecordingState? transcriptState;
    string? transcriptFileId;
    RecordingState? smartNotesState;
    string? smartNotesFileId;
|};

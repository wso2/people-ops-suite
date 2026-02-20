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

// Copyright (c) 2025, WSO2 LLC. (https://www.wso2.com). All Rights Reserved.
//
// This software is the property of WSO2 LLC. and its suppliers, if any.
// Dissemination of any information or reproduction of any material contained
// herein in any form is strictly forbidden, unless permitted by WSO2 expressly.
// You may not alter or remove any copyright or other notice from copies of this content.
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
    # WSO2 participants' email list
    string wso2Participants;
    # Meeting start time in ISO format
    string startTime;
    # Meeting end time in ISO format
    string endTime;
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
    # WSO2 participants' email list
    string wso2Participants;
    # Meeting status (e.g., 'ACTIVE', 'CANCELLED')
    string meetingStatus;
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
    # Time Status (e.g., 'PAST', 'FUTURE')
    string timeStatus;
|};

# [Database]MeetingTypes type.
public type MeetingTypes record {|
    # Meeting Domain
    string domain;
    # Meeting Types
    string[] types;
|};

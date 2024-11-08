// Copyright (c) 2024 WSO2 LLC. (http://www.wso2.org).
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

# [Database] connection pool.
type ConnectionPool record {|
    # Maximum number of open connections
    int maxOpenConnections;
    # Maximum lifetime of a connection
    decimal maxConnectionLifeTime;
    # Minimum number of open connections
    int minIdleConnections;
|};

# [Configurable] database configs.
type DatabaseConfig record {|
    # Database User 
    string user;
    # Database Password
    string password;
    # Database Name
    string database;
    # Database Host
    string host;
    # Database port
    int port;
    # Database connection pool
    ConnectionPool connectionPool;
|};

# Day record.
public type Day record {|
    # Date of day
    string date;
|};

# Holiday record.
public type Holiday record {|
    # ID of the holiday
    string id;
    # Title of the holiday
    string title;
    # Date of the holiday
    string date;
    # Country of the holiday
    string country;
|};

# [Database] Leave type.
public type Leave record {|
    # Leave ID
    @sql:Column {name: "id"}
    int id;
    # Employee email
    @sql:Column {name: "email"}
    string email;
    # Leave type
    @sql:Column {name: "leave_type"}
    string? leaveType;
    # Leave period type
    @sql:Column {name: "leave_period_type"}
    string? periodType;
    # Copy email list
    @sql:Column {name: "copy_email_list"}
    string? copyEmailList;
    # Notify everyone
    @sql:Column {name: "notify_everyone"}
    boolean? notifyEveryone;
    # Submit comment
    @sql:Column {name: "submit_note"}
    string? submitComment;
    # Cancel comment
    @sql:Column {name: "cancel_note"}
    string? cancelComment;
    # Created date
    @sql:Column {name: "created_date"}
    string? createdDate;
    # Updated date
    @sql:Column {name: "updated_date"}
    string? updatedDate;
    # Email ID
    @sql:Column {name: "email_id"}
    string? emailId;
    # Email subject
    @sql:Column {name: "email_subject"}
    string? emailSubject;
    # Leave is active
    @sql:Column {name: "active"}
    boolean? isActive;
    # Leave start date
    @sql:Column {name: "start_date"}
    string startDate;
    # Leave end date
    @sql:Column {name: "end_date"}
    string endDate;
    # Leave start half
    @sql:Column {name: "start_half"} // 0 is first half, 1 is second half
    int? startHalf;
    # Leave end half
    @sql:Column {name: "end_half"}
    boolean? isEndHalf;
    # Leave canceled date
    @sql:Column {name: "canceled_date"}
    string? canceledDate;
    # Leave number of days
    @sql:Column {name: "num_days"}
    float? numberOfDays;
    # Leave is public comment
    @sql:Column {name: "public_submit_note"}
    boolean? isPublicComment;
    # Leave calendar event ID
    @sql:Column {name: "calendar_event_id"}
    string? calendarEventId;
    # Employee location
    @sql:Column {name: "location"}
    string? location;
|};

# Database config record.
type LeaveDatabaseConfig record {|
    *DatabaseConfig;
    # Additional configurations related to the MySQL database connection
    mysql:Options? options;
|};

# Leave day record.
public type LeaveDay record {|
    # Date of leave
    string date;
    # Leave type
    LeaveType 'type;
    # Whether leave is a morning leave or not (optional)
    boolean isMorningLeave?;
    # Leave period type
    LeavePeriodType periodType;
|};

# [Query Filter] Leave entity filters
public type LeaveFilter record {|
    # Start date (yyyy-mm-dd)
    string? startDate?;
    # End date (yyyy-mm-dd)
    string? endDate?;
    # Leave type
    string[]? leaveTypes?;
    # Leave period type
    string? periodType?;
    # Email addresses of employees
    string[]? emails?;
    # Is leave active
    boolean? isActive?;
    # Order by Ascending or Descending
    OrderBy? orderBy?;
|};

# Leave input for leave creation
public type LeaveInput record {|
    # Start date (yyyy-mm-dd)
    string startDate;
    # End date (yyyy-mm-dd)
    string endDate;
    # Leave type
    string leaveType;
    # Leave period type
    string periodType;
    # Email address of the employee
    string email;
    # Is morning leave
    boolean? isMorningLeave;
    # Email recipients
    string[] emailRecipients = [];
    # Calendar event ID
    string? calendarEventId?;
    # Comment
    string? comment?;
    # isPublicComment
    boolean? isPublicComment?;
    # ID of email notification
    string? emailId = ();
    # Subject of email notification
    string? emailSubject = ();
|};
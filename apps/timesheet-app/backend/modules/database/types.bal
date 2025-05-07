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
    sql:ConnectionPool connectionPool;
|};

# Database config record.
type DatabaseClientConfig record {|
    *DatabaseConfig;
    # Additional configurations related to the MySQL database connection
    mysql:Options? options;
|};

# Work policy record.
public type WorkPolicy record {|
    # Company name
    string companyName;
    # Number of OT hours per year
    int otHoursPerYear;
    # Number of working hours per day
    decimal workingHoursPerDay;
    # Lunch time duration per day
    decimal lunchHoursPerDay;
|};

# Enum type for the timesheet status.
public enum TimesheetStatus {
    PENDING = "PENDING",
    APPROVED = "APPROVED",
    REJECTED = "REJECTED"
};

# TimeLog record type.
public type TimeLog record {|
    # Time log record id
    int recordId;
    # Employee's email address
    string employeeEmail?;
    # Record date
    string recordDate;
    # Company name
    string companyName?;
    # Clock in time
    string clockInTime;
    # Clock out time
    string clockOutTime;
    # Total work duration
    int isLunchIncluded;
    # Overtime duration
    decimal overtimeDuration?;
    # Overtime reason
    string overtimeReason?;
    # Email of the lead
    string leadEmail?;
    # Overtime rejection reason
    string overtimeRejectReason?;
    # Overtime status
    TimesheetStatus overtimeStatus?;
|};

# TimeLogCreatePayload record type.
public type TimeLogCreatePayload record {|
    # Employee's email address
    string employeeEmail;
    # Email of the creator
    string createdBy;
    # Email of the updater
    string updatedBy;
    # Company name
    string companyName;
    # Lead email
    string leadEmail;
    # TimeLogs array
    TimeLog[] timeLogs;
|};

# Common filter for the db queries.
public type TimeLogFilter record {|
    # Employee email
    string? employeeEmail = ();
    # Email of the lead
    string? leadEmail = ();
    # TimesheetStatus
    TimesheetStatus? status = ();
    # Limit of the records
    int? recordsLimit = ();
    # Offset of the records
    int? recordOffset = ();
    # Start date to filter
    string? rangeStart = ();
    # End date to filter
    string? rangeEnd = ();
    # Dates array to filter
    string[]? recordDates = ();
    # Company name to filter
    string? companyName = ();
    # Record id array to filter
    int[]? recordIds = ();
|};

# Timesheet information record type.
public type TimesheetInfo record {|
    # Total count of the records
    int totalRecords;
    # Total count of the pending records
    decimal? pendingRecords;
    # Total count of the approved records
    decimal? approvedRecords;
    # Total count of the rejected records
    decimal? rejectedRecords;
    # Total count of the overtime taken
    decimal? totalOverTimeTaken;
    # Count of overtime left from yearly quota
    decimal? overTimeLeft;
|};

# Update type for the time log record.
public type TimeLogUpdate record {|
    # Time log record id
    int recordId;
    # Email of the employee
    string employeeEmail?;
    # Record date
    string recordDate?;
    # Clock in time
    string clockInTime?;
    # Clock out time
    string clockOutTime?;
    # Total work duration
    int isLunchIncluded?;
    # Overtime duration
    decimal overtimeDuration?;
    # Overtime reason
    string overtimeReason?;
    # Overtime rejection reason
    string overtimeRejectReason?;
    # Overtime status
    TimesheetStatus overtimeStatus?;
|};

# Approve or reject time logs type.
public type TimeLogReview record {|
    # Time sheet record id
    int[] recordIds;
    # Overtime rejection reason
    string overtimeRejectReason?;
    # Overtime status
    TimesheetStatus overtimeStatus;
|};

# Update type for the work policies record.
public type WorkPolicyUpdatePayload record {|
    # Company name
    string companyName;
    # overtime hours per year
    decimal otHoursPerYear?;
    # working hours per day
    decimal workingHoursPerDay?;
    # lunch time duration per day
    decimal lunchHoursPerDay?;
    # Email of the updater
    string updatedBy;
|};

# Timesheet information record type.
public type OvertimeInfo record {|
    # overtime hours per year
    int otHoursPerYear;
    # Total count of the overtime taken
    decimal totalOverTimeTaken;
    # Count of overtime left from yearly quota
    decimal overtimeLeft;
|};

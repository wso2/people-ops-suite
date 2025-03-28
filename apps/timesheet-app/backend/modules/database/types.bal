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

# [Database]SampleCollection type.
public type SampleCollection record {|
    # Id of the collection
    int id;
    # Name
    string name;
    # Timestamp, when created
    string createdOn;
    # Person, who created
    string createdBy;
    # Timestamp, when updated
    string updatedOn;
    # Person, who updates
    string updatedBy;
|};

# [Database]Collection insert type.
public type AddSampleCollection record {|
    # Name of the collection
    string name;
|};

# Work policies record.
public type WorkPolicies record {|
    # Number of OT hours per year
    int otHoursPerYear;
    # Number of working hours per day
    decimal workingHoursPerDay;
    # Lunch time duration per day
    decimal lunchHoursPerDay;
|};

# Enum for time sheet status.
public enum TimeSheetStatus {
    PENDING = "PENDING",
    APPROVED = "APPROVED",
    REJECTED = "REJECTED"
};

# Work policy record.
public type TimeSheetRecord record {|
    # Time sheet record id
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
    decimal? overtimeDuration?;
    # Overtime reason
    string? overtimeReason?;
    # Leads email
    string? leadEmail?;
    # Overtime rejection reason
    string? overtimeRejectReason?;
    # Overtime status
    TimeSheetStatus overtimeStatus;
|};

# Timesheet records common filter type.
public type TimesheetCommonFilter record {|
    # Employee email
    string? employeeEmail;
    # Lead emails
    string? leadEmail;
    # TimeSheetStatus
    TimeSheetStatus? status;
    # Limit of the records
    int? recordsLimit;
    # Offset of the records
    int? recordOffset;
    # Start date to filter
    string? rangeStart;
    # End date to filter
    string? rangeEnd;
    # Dates array to filter
    string[]? recordDates;
|};

# Timesheet information record type.
public type TimesheetMetaData record {|
    # Total count of the overtime records
    decimal? overtimeCount;
    # Total count of the records
    int totalRecords;
    # Lunch time duration per day
    decimal? recordsWithOvertime;
    # Employee email
    string? employeeEmail;
    # Lead emails
    string? leadEmail;
    # Company name
    string companyName;
|};

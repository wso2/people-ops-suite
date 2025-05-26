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
import timesheet_app.database;
import timesheet_app.entity;

# Application Privileges
const EMPLOYEE_PRIVILEGE = 987;
const LEAD_PRIVILEGE = 862;
const HR_ADMIN_PRIVILEGE = 762;

# Employee record with permissions
public type EmployeeInformation record {
    # Entity employee type record
    entity:Employee employeeInfo;
    # Privileges of the employee
    int[] privileges;
    # Work policies of the employee
    database:WorkPolicy workPolicies;
};

# Timesheet records collection type.
public type TimeSheetRecords record {
    # Overtime information from the database
    int? totalRecordCount;
    # List of timesheet records
    database:TimeLog[]? timeLogs;
    # Timesheet information for leads
    database:TimesheetStats? timesheetStats;
};

# TimeLogCreate record type.
public type TimeLogCreate record {|
    # Employee's email address
    string employeeEmail;
    # TimeLogs array
    database:TimeLog[] timeLogs;
|};

# Approve or reject time logs type.
public type TimeLogReviews record {|
    # Time sheet record id
    int[] recordIds;
    # Overtime rejection reason
    string overtimeRejectReason?;
    # Overtime status
    database:TimeLogStatus timeLogStatus;
|};

# Update type for the time log record.
public type TimeLogUpdatePayload record {|
    # Employee email
    string employeeEmail;
    # Time log record id
    int recordId;
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
|};

# Constants for date formatting
const YEAR_START_POSTFIX = "-01-01";
const YEAR_END_POSTFIX = "-12-31";

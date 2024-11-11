// Copyright (c) 2024 WSO2 LLC. (https://www.wso2.com).
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
import leave_service.database;
import leave_service.employee;

# Calculated leave record.
public type CalculatedLeave record {|
    # Number of working days
    float workingDays;
    # Whether the leave has an overlap
    boolean hasOverlap;
    # Message of the leave
    string message?;
    # List of holidays
    Holiday[] holidays?;
|};

# Day record.
public type Day record {|
    # string date
    string date;
    # List of holidays
    Holiday[] holidays?;
|};

# Employee record.
public type Employee record {|
    *employee:Employee;
|};

# Record for fetched leaves.
public type FetchedLeavesRecord record {|
    # List of leaves
    database:Leave[] leaves;
    # List of leave stats
    LeaveStat[] stats;
|};

# Form data record.
public type FormData record {|
    # List of email recipients
    string[] emailRecipients = [];
    # List of lead emails
    string[] leadEmails;
    # Whether the employee is a lead
    boolean isLead = false;
    # Location of employee
    string? location = ();
    # Legally entitled leaves
    LeavePolicy legallyEntitledLeave?;
    # Leave report content
    ReportContent leaveReportContent = {};
    # List of leave types
    record {|
        string key;
        string value;
    |}[] leaveTypes = [
        {'key: "casual", value: "Other leave (Casual, Sick, etc.)"},
        {'key: "annual", value: "Annual leave/PTO"},
        {'key: "paternity", value: "Paternity leave"},
        {'key: "maternity", value: "Maternity leave"},
        {'key: "lieu", value: "Lieu leave"}
    ];
|};

# Holiday record.
public type Holiday record {|
    # Title of the holiday
    string title;
    # Date of the holiday
    string date;
|};

# Leave record.
public type Leave record {|
    # Leave ID
    int id;
    # Start date of the leave
    string startDate;
    # End date of the leave
    string endDate;
    # Whether the leave is active
    boolean isActive;
    # Type of the leave
    string leaveType;
    # Period type of the leave
    string periodType;
    # Whether the leave is a morning leave
    boolean? isMorningLeave;
    # Email of the employee
    string email;
    # Created date of the leave
    string createdDate;
    # List of email recipients
    string[] emailRecipients = [];
    # Number of days of the leave
    float numberOfDays;
    # Employee location
    string? location = ();
    # Whether the leave can be cancelled by the user
    boolean isCancelAllowed = false;
|};

# Leave day record.
public type LeaveDay record {|
    *database:LeaveDay;
|};

# Leave Entitlement record.
public type LeaveEntitlement record {|
    # Year of the leave entitlement
    int year;
    # Employee location
    string? location;
    # Leave policy
    LeavePolicy leavePolicy;
    # Leaves taken after policy adjustment
    LeavePolicy policyAdjustedLeave;
|};

# Leave details record.
public type LeaveDetails record {|
    *LeaveInput;
    # Leave ID
    int id;
    # Is leave active
    boolean isActive;
    # Created date
    string createdDate;
    # Effective days
    LeaveDay[] effectiveDays = [];
    # Calendar event ID
    string? calendarEventId;
    # Number of leave days
    float? numberOfDays = 0.0;
    # Employee location
    string? location;
|};

# Leave input for leave creation.
public type LeaveInput record {|
    *database:LeaveInput;
|};

# Payload for leave creation.
public type LeavePayload record {|
    *database:LeavePayload;
|};

# Leave policy record.
public type LeavePolicy record {|
    # Annual leave count
    float? annual?;
    # Casual leave count
    float? casual?;
|};

# Leave entity record.
public type LeaveResponse record {|
    *database:LeaveResponse;
|};

# Lead report generation payload.
public type LeadReportPayload readonly & record {|
    # Start date of the report
    string? startDate = ();
    # End date of the report
    string? endDate = ();
    # Employee status list
    EmployeeStatus[]? employeeStatuses = DEFAULT_EMPLOYEE_STATUSES;
|};

# Leave stat record.
public type LeaveStat record {|
    # Leave type
    string 'type;
    # Number of leave types 
    float count;
|};

# Leaves report content.
public type ReportContent map<map<float>>;

# Report generation payload.
public type ReportPayload readonly & record {|
    # Start date of the report
    string? startDate = ();
    # End date of the report
    string? endDate = ();
    # Location of employees
    string? location = ();
    # Business unit of employees
    string? businessUnit = ();
    # Department of employees
    string? department = ();
    # Team of employees
    string? team = ();
    # Employee status list
    EmployeeStatus[]? employeeStatuses = DEFAULT_EMPLOYEE_STATUSES;
|};

# User calendar content.
public type UserCalendarInformation record {|
    # List of leaves
    Leave[] leaves;
    # List of holidays
    Holiday[] holidays;
|};

# Uncounted leaves
public type UncountedLeaves database:LIEU_LEAVE;

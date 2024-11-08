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
import leave_service.database;
import ballerina/http;

# Employee record.
public type Employee record {|
    # Id of the employee
    string employeeId;
    # First name
    string? firstName;
    # Last name
    string? lastName;
    # WSO2 email
    string? workEmail;
    # Image URL of the employee
    string? employeeThumbnail;
    # Employee location
    string? location;
    # Employee location
    string? leadEmail;
    # Start date of the employee
    string? startDate;
    # Final day of employment of the employee
    string? finalDayOfEmployment;
    # Employee is a lead or not
    boolean? lead;
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

# Leave day record.
public type LeaveDay record {|
    *database:LeaveDay;
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
    # Leave ID
    readonly int id;
    # Start date
    string startDate;
    # End date
    string endDate;
    # Is leave active
    boolean isActive;
    # Leave type
    string leaveType;
    # Leave period type
    string periodType;
    # Email of the employee
    string email;
    # Created date
    string createdDate;
    # Email recipients
    readonly & string[] emailRecipients = [];
    # Effective days
    readonly & LeaveDay[] effectiveDays = [];
    # Number of days
    float numberOfDays;
    # Is morning leave
    boolean? isMorningLeave;
    # Calendar event ID
    string? calendarEventId;
    # Employee location
    string? location;
    # ID of email notification
    string? emailId = ();
    # Subject of email notification
    string? emailSubject = ();
|};

# Leaves report content.
public type ReportContent map<map<float>>;

# Validation error code
public type ValidationErrorCode http:STATUS_BAD_REQUEST|http:STATUS_INTERNAL_SERVER_ERROR;

# Validation error detail record.
public type ValidationErrorDetail record {
    # Error message for response
    string externalMessage; // `message` is made a mandatory field
    # Error code for response
    ValidationErrorCode code = http:STATUS_INTERNAL_SERVER_ERROR;
};

# Validation error record
public type ValidationError error<ValidationErrorDetail>;

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

# Application Privileges
const EMPLOYEE_PRIVILEGE = 987;
const LEAD_PRIVILEGE = 862;
const HR_ADMIN_PRIVILEGE = 762;

# Employee record with permissions
public type EmployeeInformation record {
    # Id of the employee
    string employeeId;
    # Email of the employee
    string workEmail;
    # First name of the employee
    string firstName;
    # Last name of the employee
    string lastName;
    # Job role
    string jobRole;
    # Thumbnail of the employee
    string? employeeThumbnail;
    # Company of the employee
    string company;
    # Manager email of the employee
    string managerEmail;
    # Indicator of lead or not
    boolean lead;
    # Privileges of the employee
    int[] privileges;
    # Work policies of the employee
    database:WorkPolicies workPolicies;
};

# Timesheet records collection type.
public type TimeSheetRecords record {
    # Overtime information from the database
    int? totalRecordCount;
    # List of timesheet records
    database:TimeSheetRecord[]? timesheetRecords;
    # Timesheet information for leads
    database:TimesheetInfo? timesheetInfo;
};

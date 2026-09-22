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

import ballerina/log;

# Allowed employment types.
configurable string[] allowedEmploymentTypes = ?;

# Retrieves basic employee details by work email.
#
# + workEmail - WSO2 email address
# + return - Employee | Error
public isolated function fetchEmployeesBasicInfo(string workEmail) returns Employee|error {
    string document = string `
        query employeeQuery ($workEmail: String!) {
            employee(email: $workEmail) {
                employeeId,
                workEmail,
                firstName,
                lastName,
                jobRole,
                employeeThumbnail,
                businessUnit: businessUnit,
                team: department,
                subTeam: team,
                unit: subTeam
            }
        }
    `;
    EmployeeResponse|error response = hrClient->execute(document, {workEmail});
    if response is error {
        return response;
    }
    return response.data.employee;
}

# Retrieves all active or marked-leaver employees with specific employment types.
#
# + emails - Optional list of emails to filter by
# + department - Optional department to filter by, exact match (e.g. "SALES")
# + return - Employee Info Array
public isolated function getEmployees(string[]? emails = (), string? department = ()) returns EmployeeBasic[]|error {

    EmployeeFilter filter = {
        employeeStatus: [Active, Marked\ leaver],
        employmentType: allowedEmploymentTypes,
        emails: emails,
        department
    };

    string document = string `query getAllEmployees($filter: EmployeeFilter!, $limit: Int, $offset: Int) {
        employees(filter: $filter, limit: $limit, offset: $offset) {
            workEmail
            firstName
            lastName
            employeeThumbnail
            team: department
            subTeam: team
            jobRole
        }
    }`;

    EmployeeBasic[] employees = [];
    boolean fetchMore = true;
    while fetchMore {
        EmployeesResponse response = check hrClient->execute(
            document,
            {filter, 'limit: DEFAULT_LIMIT, offset: employees.length()}
        );
        employees.push(...response.data.employees);
        fetchMore = response.data.employees.length() > 0;
    }
    return employees;
}

# Departments whose members should get automatic view access to Meet recordings, regardless
# of whether they were on the specific call. Exact strings as stored by the HR entity API.
configurable string[] recordingAccessDepartments = ["SALES", "CHANNEL SALES", "SALES ENGINEERING"];

# When non-empty, used instead of recordingAccessDepartments -- returned directly, skipping
# the HR entity lookup entirely. For testing on staging with a specific, controlled list of
# emails (e.g. your own test accounts) instead of granting access to real department members.
configurable string[] recordingAccessTestEmails = [];

# Retrieves the work emails that should get automatic view access to Meet recordings: either
# recordingAccessTestEmails directly (if set), or everyone in recordingAccessDepartments
# (Sales, Channel Sales, and Sales Engineering by default) via the HR entity API. The API's
# department filter only accepts one exact value at a time (not a list), so the department
# path makes one call per department and combines the results.
#
# + return - Work emails of matching employees, or Error
public isolated function getSalesDepartmentEmails() returns string[]|error {
    // Blank entries are dropped BEFORE the emptiness check, because the Choreo config UI
    // cannot express a genuinely empty array. A plain `length() > 0` is then TRUE, so the
    // HR lookup is skipped entirely and a single empty string is handed to Drive, which
    // refuses it with "The specified emailAddress is invalid or not applicable for the
    // given permission type" -- once per artifact, on every meeting, for ever. 
    string[] testEmails = from string email in recordingAccessTestEmails
        where email.trim().length() > 0
        select email.trim();
    if testEmails.length() > 0 {
        return testEmails;
    }

    string[] emails = [];
    foreach string department in recordingAccessDepartments {
        EmployeeBasic[] employees = check getEmployees(department = department);
        // COUNTS ONLY, never the addresses
        log:printInfo(string `Recording access: department '${department}' resolved to ` +
                string `${employees.length()} employee(s).`);
        foreach EmployeeBasic employee in employees {
            // Same reasoning one level down: a record with no work email must not become a
            // blank Drive grant. Drive rejects it, and because the grants are best-effort
            // the whole department share is reported as failed over one empty string.
            string workEmail = employee.workEmail.trim();
            if workEmail.length() == 0 {
                continue;
            }
            emails.push(workEmail);
        }
    }
    log:printInfo(string `Recording access: ${recordingAccessDepartments.length()} department(s) ` +
            string `resolved to ${emails.length()} email(s) in total.`);
    return emails;
}

# Retrieves organization details including nested departments, teams, and sub-teams.
#
# + filter - Filter criteria (Business Unit IDs or Names)
# + return - Array of Business Units | Error
public isolated function getOrgDetails(OrgDetailsFilter? filter = ()) returns BusinessUnit[]|error {
    string document = string `
        query getOrgDetails($filter: OrgDetailsFilter, $limit: Int, $offset: Int) {
            orgDetails(filter: $filter, limit: $limit, offset: $offset) {
                id
                businessUnit
                departments {
                    id
                    department
                    teams {
                        id
                        team
                        subTeams {
                            id
                            subTeam
                        }
                    }
                }
            }
        }
    `;

    BusinessUnit[] businessUnits = [];
    boolean fetchMore = true;
    while fetchMore {
        
        OrgDetailsResponse|error response = trap hrClient->execute(
            document,
            {filter, 'limit: DEFAULT_LIMIT, offset: businessUnits.length()}
        );
        if response is error {
            return response;
        }
        businessUnits.push(...response.data.orgDetails);
        fetchMore = response.data.orgDetails.length() > 0;
    }

    return businessUnits;
}

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

import ballerina/time;

# Get legally entitled leave for an employee based on location.
#
# + employee - Employee record
# + return - Location based leave policy or error
isolated function getLegallyEntitledLeave(readonly & Employee employee) returns LeavePolicy|error {

    match employee.location {
        LK => {
            string? employmentStartDate = employee.startDate;
            string? employmentEndDate = employee.finalDayOfEmployment;
            if employmentStartDate is () || employmentStartDate.length() == 0 {
                return error("Employee start date is not set.");
            }
            time:Civil civilEndDate = employmentEndDate is string ?
                check getCivilDateFromString(employmentStartDate) : time:utcToCivil(time:utcNow());
            time:Civil civilEmploymentStartDate = check getCivilDateFromString(employmentStartDate);

            int yearsOfEmployment = civilEndDate.year - civilEmploymentStartDate.year;
            float lkAnnualLeave = 14.0;
            float lkCasualLeave = 7.0;

            if yearsOfEmployment == 0 {
                // First year of employment
                lkAnnualLeave = 0.0;
                // One day of Casual leave for every two months of employment. This value will change throughout the year
                int monthsOfEmployment = civilEndDate.month - civilEmploymentStartDate.month;
                lkCasualLeave = <float>(monthsOfEmployment / 2);
            } else if yearsOfEmployment == 1 {
                // Second year of employment
                if civilEmploymentStartDate.month >= 10 {
                    // If employment start date is on or after October
                    lkAnnualLeave = 4.0;
                } else if civilEmploymentStartDate.month >= 7 {
                    // If employment start date is on or after July and before October
                    lkAnnualLeave = 7.0;
                } else if civilEmploymentStartDate.month >= 4 {
                    // If employment start date is on or after April and before July
                    lkAnnualLeave = 10.0;
                }
                // If employment start date is on or after January and before April
            }

            return {
                annual: lkAnnualLeave,
                casual: lkCasualLeave
            };
        }
        _ => {
            return {};
        }
    }
}

# Get leave report content for a given leaves.
#
# + leaves - Leaves to be used to generate report content
# + return - Report content
isolated function getLeaveReportContent(LeaveResponse[] leaves) returns ReportContent {
    ReportContent reportContent = {};
    foreach LeaveResponse leave in leaves {
        string leaveType = leave.leaveType;
        if leaveType == TOTAL_LEAVE_TYPE {
            // This type is not supported and should not exist.
            break;
        }

        // Handling sick leave as casual leave.
        if leaveType is database:SICK_LEAVE {
            leaveType = database:CASUAL_LEAVE;
        }

        map<float>? employeeLeaveMap = reportContent[leave.email];
        if employeeLeaveMap is map<float> {
            float? leaveTypeCount = employeeLeaveMap[leaveType];
            if leaveTypeCount is float {
                employeeLeaveMap[leaveType] = leaveTypeCount + leave.numberOfDays;
            } else {
                employeeLeaveMap[leaveType] = leave.numberOfDays;
            }

            employeeLeaveMap[TOTAL_LEAVE_TYPE] = leave.numberOfDays + employeeLeaveMap.get(TOTAL_LEAVE_TYPE);
            if leaveType !is database:LIEU_LEAVE {
                employeeLeaveMap[TOTAL_EXCLUDING_LIEU_LEAVE_TYPE] = leave.numberOfDays +
                    employeeLeaveMap.get(TOTAL_EXCLUDING_LIEU_LEAVE_TYPE);
            }
        } else {
            reportContent[leave.email] = {
                [leaveType]: leave.numberOfDays,
                [TOTAL_LEAVE_TYPE]: leave.numberOfDays,
                [TOTAL_EXCLUDING_LIEU_LEAVE_TYPE]: leaveType is database:LIEU_LEAVE ? 0 : leave.numberOfDays
            };
        }
    }

    return reportContent;
}

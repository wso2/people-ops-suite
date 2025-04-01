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

# Fetch work policies of a company.
#
# + companyName - Company name to filter
# + return - Work policies or an error
public isolated function getWorkPolicies(string companyName) returns WorkPolicies|error? {
    WorkPolicies|sql:Error policy = databaseClient->queryRow(getWorkPoliciesQuery(companyName));

    if policy is sql:Error && policy is sql:NoRowsError {
        return;
    }
    return policy;
}

# Function to get timesheet records using filters.
#
# + filter - Filter type for the records
# + return - Timesheet records or an error
public isolated function getTimesheetRecords(TimesheetCommonFilter filter) returns TimeSheetRecord[]|error? {
    stream<TimeSheetRecord, error?> recordsResult =
        databaseClient->query(getTimesheetRecordsOfEmployee(filter));

    TimeSheetRecord[] timesheetRecords = [];
    check from TimeSheetRecord timesheetRecord in recordsResult
        do {
            timesheetRecords.push(timesheetRecord);
        };

    return timesheetRecords;
}

# Function to retrieve the timesheet records count.
#
# + filter - Filter type for the records
# + return - Timesheet record count or an error
public isolated function getTotalRecordCount(TimesheetCommonFilter filter)
    returns int|error? {

    int|sql:Error count = databaseClient->queryRow(getTotalRecordCountQuery(filter));
    if count is sql:NoRowsError {
        return 0;
    }
    if count is sql:Error {
        return;
    }
    return count;
}

# Function to insert timesheet records.
#
# + timesheetRecords - Timesheet records payload
# + employeeEmail - Email of the employee
# + leadEmail - Email of the employee's lead
# + companyName - Name of the company of the employee
# + return - Execution result or an error
public isolated function insertTimesheetRecords(TimeSheetRecord[] timesheetRecords, string employeeEmail,
        string companyName, string leadEmail) returns sql:Error|sql:ExecutionResult[] {

    sql:ExecutionResult[]|sql:Error executionResult =
        databaseClient->batchExecute(insertTimesheetRecordsQuery(timesheetRecords, employeeEmail, companyName,
            leadEmail));

    if executionResult is error {
        return executionResult;
    }
    return executionResult;
}

# Function to fetch employee timesheet info.
#
# + filter - Filter type for the timesheet information
# + return - Timesheet info or an error
public isolated function getTimesheetInfo(TimesheetCommonFilter filter) returns TimesheetInfo|error? {
    TimesheetInfo|sql:Error policy = databaseClient->queryRow(getTimesheetInfoQuery(filter));

    if policy is sql:Error && policy is sql:NoRowsError {
        return;
    }
    return policy;
}

# Function to update timesheet records.
#
# + updateRecords - Records to be updated
# + invokerEmail - Email of the invoker
# + return - An error if occurred
public isolated function updateTimesheetRecords(string invokerEmail, TimesheetUpdate[] updateRecords) returns error? {
    do {
        transaction {
            foreach TimesheetUpdate updateRecord in updateRecords {
                _ = check databaseClient->execute(updateTimesheetRecordQuery(updateRecord, invokerEmail));
            }
            check commit;
        }
    } on fail error e {
        return e;
    }
}

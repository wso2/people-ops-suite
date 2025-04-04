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
    WorkPolicies|error policies = databaseClient->queryRow(getWorkPoliciesQuery(companyName));

    if policies is sql:NoRowsError {
        return;
    }
    return policies;
}

# Function to get timesheet records using filters.
#
# + filter - Filter type for the records
# + return - Timesheet records or an error
public isolated function getTimesheetRecords(TimesheetCommonFilter filter) returns TimeLog[]|error? {
    stream<TimeLog, error?> recordsResult =
        databaseClient->query(getTimesheetRecordsOfEmployee(filter));

    return from TimeLog timesheetRecord in recordsResult
        select timesheetRecord;
}

# Function to retrieve the timesheet record count.
#
# + filter - Filter type for the records
# + return - Timesheet record count or an error
public isolated function getTotalRecordCount(TimesheetCommonFilter filter) returns int|error? {
    int|sql:Error count = databaseClient->queryRow(getTotalRecordCountQuery(filter));
    if count is sql:NoRowsError {
        return 0;
    }
    return count;
}

# Function to insert timesheet records.
#
# + timesheetRecords - Timesheet record payload
# + employeeEmail - Email of the employee
# + leadEmail - Email of the employee's lead
# + companyName - Name of the company of the employee
# + return - Execution result or an error
public isolated function insertTimesheetRecords(TimeLog[] timesheetRecords, string employeeEmail,
        string companyName, string leadEmail) returns error|int[] {

    sql:ExecutionResult[]|sql:Error executionResults =
        databaseClient->batchExecute(insertTimesheetRecordsQuery(timesheetRecords, employeeEmail, companyName,
            leadEmail));

    if executionResults is error {
        return executionResults;
    }
    return from sql:ExecutionResult executionResult in executionResults
        select check executionResult.lastInsertId.ensureType(int);
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
public isolated function updateTimesheetRecords(string invokerEmail, TimeLogUpdate[] updateRecords) returns error? {
    do {
        transaction {
            foreach TimeLogUpdate updateRecord in updateRecords {
                _ = check databaseClient->execute(updateTimesheetRecordQuery(updateRecord, invokerEmail));
            }
            check commit;
        }
    } on fail error e {
        return e;
    }
}

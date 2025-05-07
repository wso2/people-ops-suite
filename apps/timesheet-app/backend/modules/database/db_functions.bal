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

# Fetch work policy of a company.
#
# + companyName - Company name to filter
# + return - Work policy or an error
public isolated function fetchWorkPolicy(string companyName) returns WorkPolicy|error? {
    WorkPolicy|error policies = databaseClient->queryRow(fetchWorkPolicyQuery(companyName));

    if policies is sql:NoRowsError {
        return;
    }
    return policies;
}

# Fetch work policies of companies.
#
# + return - Work policies or an error
public isolated function fetchWorkPolicies() returns WorkPolicy[]|error {
    stream<WorkPolicy, error?> workPolicyResult = databaseClient->query(fetchWorkPolicyQuery(()));

    return from WorkPolicy workPolicies in workPolicyResult
        select workPolicies;
}

# Function to update work policy of a company.
#
# + workPolicy - Record to be updated
# + updatedBy - Email of the updated
# + return - An error if occurred
public isolated function updateWorkPolicy(WorkPolicyUpdate workPolicy, string updatedBy) returns error? {

    sql:ExecutionResult result = check databaseClient->execute(updateWorkPolicyQuery(workPolicy, updatedBy));
    if result.affectedRowCount < 1 {
        return error(string `Error while updating the Work Policy: ${workPolicy.companyName}`);
    }
}

# Function to get timesheet records using filters.
#
# + filter - Filter type for the records
# + return - TimeLog records or an error
public isolated function fetchTimeLogs(TimeLogFilter filter) returns TimeLog[]|error {
    stream<TimeLog, error?> recordsResult = databaseClient->query(fetchTimeLogsQuery(filter));

    return from TimeLog timesheetRecord in recordsResult
        select timesheetRecord;
}

# Function to retrieve the timesheet record count.
#
# + filter - Filter type for the records
# + return - Timesheet record count or an error
public isolated function fetchTimeLogCount(TimeLogFilter filter) returns int|error {
    int|sql:Error count = databaseClient->queryRow(fetchTimeLogCountQuery(filter));
    if count is sql:NoRowsError {
        return 0;
    }
    return count;
}

# Function to insert timesheet records.
#
# + timeLogs - Timesheet record payload
# + employeeEmail - Email of the employee
# + leadEmail - Email of the employee's lead
# + companyName - Name of the company of the employee
# + return - Execution result array or an error
public isolated function insertTimeLogs(TimeLog[] timeLogs, string employeeEmail,
        string companyName, string leadEmail) returns error|int[] {

    sql:ExecutionResult[]|error executionResults =
        databaseClient->batchExecute(insertTimeLogQueries(timeLogs, employeeEmail, companyName,
            leadEmail));

    if executionResults is error {
        return executionResults;
    }
    return from sql:ExecutionResult executionResult in executionResults
        select check executionResult.lastInsertId.ensureType(int);
}

# Function to fetch employee timesheet info.
#
# + companyName - Name of the company
# + employeeEmail - Email of the employee
# + leadEmail - Email of the lead
# + return - Timesheet info or an error
public isolated function fetchTimeLogStats(string? employeeEmail, string? leadEmail, string companyName)
    returns TimesheetInfo|error {
    return check databaseClient->queryRow(fetchTimeLogStatsQuery(employeeEmail, leadEmail, companyName));
}

# Function to fetch employee timesheet info.
#
# + companyName - Name of the company
# + employeeEmail - Email of the employee
# + return - Timesheet info or an error
public isolated function fetchOvertimeInfo(string companyName, string employeeEmail) returns OvertimeInfo|error {
    return check databaseClient->queryRow(fetchOvertimeInfoQuery(companyName, employeeEmail, getStartDateOfYear(),
        getEndDateOfYear()));
}

# Function to update timesheet records.
#
# + reviewRecord - TimeLogReview object containing records to be updated
# + updatedBy - Email of the invoker
# + return - An error if occurred
public isolated function updateTimesheetRecords(string updatedBy, TimeLogReview reviewRecord) returns error? {
    do {
        transaction {
            foreach int recordId in reviewRecord.recordIds {
                TimeLogUpdate updateRecord = {
                    recordId: recordId,
                    overtimeStatus: reviewRecord.overtimeStatus,
                    overtimeRejectReason: reviewRecord.overtimeRejectReason
                };
                _ = check databaseClient->execute(updateTimeLogsQuery(updateRecord, updatedBy));
            }
            check commit;
        }
    } on fail error e {
        return e;
    }
}

# Function to update a timesheet record.
#
# + timeLog - Record to be updated
# + updatedBy - Email of the invoker
# + return - An error if occurred
public isolated function updateTimesheetRecord(TimeLogUpdate timeLog, string updatedBy) returns error? {
    _ = check databaseClient->execute(updateTimeLogsQuery(timeLog, updatedBy));
}

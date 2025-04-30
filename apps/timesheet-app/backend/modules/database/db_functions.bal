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
# + companyName - Name of the company to be updated
# + workPolicies - Record to be updated
# + invokerEmail - Email of the invoker
# + return - An error if occurred
public isolated function updateWorkPolicy(WorkPolicyUpdate workPolicies, string invokerEmail,
        string companyName) returns error? {

    _ = check databaseClient->execute(updateWorkPolicyQuery(workPolicies, invokerEmail, companyName));
}

# Function to get timesheet records using filters.
#
# + filter - Filter type for the records
# + return - TimeLog records or an error
public isolated function fetchTimesheetRecords(TimesheetCommonFilter filter) returns TimeLog[]|error? {
    stream<TimeLog, error?> recordsResult = databaseClient->query(fetchTimesheetRecordsOfEmployee(filter));

    return from TimeLog timesheetRecord in recordsResult
        select timesheetRecord;
}

# Function to retrieve the timesheet record count.
#
# + filter - Filter type for the records
# + return - Timesheet record count or an error
public isolated function fetchTotalRecordCount(TimesheetCommonFilter filter) returns int|error? {
    int|sql:Error count = databaseClient->queryRow(fetchTotalRecordCountQuery(filter));
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
# + return - Execution result array or an error
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
public isolated function fetchTimesheetInfo(TimesheetCommonFilter filter) returns TimesheetInfo|error? {
    return check databaseClient->queryRow(fetchTimesheetInfoQuery(filter));
}

# Function to fetch employee timesheet info.
#
# + filter - Filter type for the timesheet information
# + return - Timesheet info or an error
public isolated function fetchOvertimeInfo(TimesheetCommonFilter filter) returns OvertimeInfo|error {
    return check databaseClient->queryRow(fetchOvertimeInfoQuery(filter));
}

# Function to update timesheet records.
#
# + reviewRecord - TimeLogReview object containing records to be updated
# + invokerEmail - Email of the invoker
# + return - An error if occurred
public isolated function updateTimesheetRecords(string invokerEmail, TimeLogReview reviewRecord) returns error? {
    do {
        transaction {
            foreach int recordId in reviewRecord.recordIds {
                TimeLogUpdate updateRecord = {
                    recordId: recordId,
                    overtimeStatus: reviewRecord.overtimeStatus,
                    overtimeRejectReason: reviewRecord.overtimeRejectReason
                };
                _ = check databaseClient->execute(updateTimesheetRecordQuery(updateRecord, invokerEmail));
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
# + invokerEmail - Email of the invoker
# + return - An error if occurred
public isolated function updateTimesheetRecord(TimeLogUpdate timeLog, string invokerEmail) returns error? {
    _ = check databaseClient->execute(updateTimesheetRecordQuery(timeLog, invokerEmail));
}

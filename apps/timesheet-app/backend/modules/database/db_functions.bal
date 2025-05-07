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
    WorkPolicy|error policy = databaseClient->queryRow(fetchWorkPoliciesQuery(companyName));
    if policy is sql:NoRowsError {
        return;
    }

    return policy;
}

# Fetch work policies of companies.
#
# + return - Work policies or an error
public isolated function fetchWorkPolicies() returns WorkPolicy[]|error {
    stream<WorkPolicy, error?> workPolicyStream = databaseClient->query(fetchWorkPoliciesQuery(()));

    return from WorkPolicy policy in workPolicyStream
        select policy;
}

# Function to update work policy of a company.
#
# + workPolicy - Record to be updated
# + return - An error if occurred
public isolated function updateWorkPolicy(WorkPolicyUpdatePayload workPolicy) returns error? {
    sql:ExecutionResult result = check databaseClient->execute(updateWorkPolicyQuery(workPolicy));
    if result.affectedRowCount < 1 {
        return error(string `Error while updating the Work Policy: ${workPolicy.companyName}`);
    }
}

# Function to get timeLogs using filters.
#
# + filter - Filter type for the records
# + return - TimeLog records or an error
public isolated function fetchTimeLogs(TimeLogFilter filter) returns TimeLog[]|error {
    stream<TimeLog, error?> timeLogStream = databaseClient->query(fetchTimeLogsQuery(filter));

    return from TimeLog timeLog in timeLogStream
        select timeLog;
}

# Function to retrieve the timeLogs count.
#
# + filter - Filter type for the records
# + return - Timesheet record count or an error
public isolated function fetchTimeLogCount(TimeLogFilter filter) returns int|error {
    int|error count = databaseClient->queryRow(fetchTimeLogCountQuery(filter));
    if count is sql:NoRowsError {
        return 0;
    }

    return count;
}

# Insert timeLogs of employee.
#
# + payload - TimeLogCreatePayload to be inserted
# + return - Execution result array or an error
public isolated function insertTimeLogs(TimeLogCreatePayload payload) returns int[]|error {

    sql:ExecutionResult[]|error executionResults = databaseClient->batchExecute(insertTimeLogQueries(payload));
    if executionResults is error {
        return executionResults;
    }

    return from sql:ExecutionResult executionResult in executionResults
        select check executionResult.lastInsertId.ensureType(int);
}

# Fetch time log stats of a given employee.
#
# + employeeEmail - Email of the employee
# + leadEmail - Email of the lead
# + return - TimeLog stats or an error
public isolated function fetchTimeLogStats(string? employeeEmail, string? leadEmail) returns TimesheetStats|error {
    return check databaseClient->queryRow(fetchTimeLogStatsQuery(employeeEmail, leadEmail));
}

# Fetch overtime stats of a given employee
#
# + companyName - Name of the company
# + employeeEmail - Email of the employee
# + startDate - Start date
# + endDate - End date
# + return - OvertimeStats or an error
public isolated function fetchOvertimeStats(string employeeEmail, string companyName, string startDate, string endDate)
    returns OvertimeStats|error {

    return check databaseClient->queryRow(fetchOvertimeStatsQuery(employeeEmail, companyName, startDate, endDate));
}

# Function to update timeLogs.
#
# + payload - TimeLogUpdate payload
# + return - An error if occurred
public isolated function updateTimeLogs(TimeLogUpdate[] payload) returns int[]|error {

    sql:ExecutionResult[]|error executionResults = databaseClient->batchExecute(updateTimeLogsQuery(payload));
    if executionResults is error {
        return executionResults;
    }

    return from sql:ExecutionResult executionResult in executionResults
        select check executionResult.lastInsertId.ensureType(int);

}

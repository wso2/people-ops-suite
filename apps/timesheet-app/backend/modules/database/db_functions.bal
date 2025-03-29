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

# Fetch sample collections.
#
# + name - Name to filter
# + 'limit - Limit of the response
# + offset - Offset of the number of sample collection to retrieve
# + return - List of sample collections|Error
public isolated function fetchSampleCollections(string? name, int? 'limit, int? offset) returns SampleCollection[]|error {
    stream<SampleCollection, error?> resultStream = databaseClient->
            query(getSampleCollectionsQuery(name, 'limit, offset));

    SampleCollection[] sampleCollections = [];
    check from SampleCollection sampleCollection in resultStream
        do {
            sampleCollections.push(sampleCollection);
        };

    return sampleCollections;
}

# Fetch specific sample collection.
#
# + id - Identification of the sample collection
# + return - Sample collections|Error, if so
public isolated function fetchSampleCollection(int id) returns SampleCollection|error? {
    SampleCollection|sql:Error sampleCollection = databaseClient->queryRow(getSampleCollectionQuery(id));

    if sampleCollection is sql:Error && sampleCollection is sql:NoRowsError {
        return;
    }
    return sampleCollection;
}

# Insert sample collection.
#
# + sampleCollection - Sample collection payload
# + createdBy - Person who created the sample collection
# + return - Id of the sample collection|Error
public isolated function addSampleCollection(AddSampleCollection sampleCollection, string createdBy) returns int|error {
    sql:ExecutionResult|error executionResults = databaseClient->execute(addSampleCollectionQuery(sampleCollection, createdBy));
    if executionResults is error {
        return executionResults;
    }

    return <int>executionResults.lastInsertId;
}

# Fetch work policy.
#
# + companyName - Company name to filter
# + return - A work policy or an error
public isolated function getWorkPolicy(string companyName) returns WorkPolicies|error? {
    WorkPolicies|sql:Error policy = databaseClient->queryRow(getWorkPolicyQuery(companyName));

    if policy is sql:Error && policy is sql:NoRowsError {
        return;
    }
    return policy;
}

# Function to get timesheet records using filters.
#
# + filter - Filter type for the records
# + return - A work policy or an error
public isolated function getTimeSheetRecords(TimesheetCommonFilter filter) returns TimeSheetRecord[]|error? {
    stream<TimeSheetRecord, error?> recordsResult =
        databaseClient->query(getTimeSheetRecordsOfEmployee(filter));

    TimeSheetRecord[] timesheetRecords = [];
    check from TimeSheetRecord timesheetRecord in recordsResult
        do {
            timesheetRecords.push(timesheetRecord);
        };

    return timesheetRecords;
}

# Function to retrieve the timesheet records count of an employee.
#
# + filter - Filter type for the records
# + return - Timesheet record count of the employee or an error
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
# + return - Id of the timesheet records|Error
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
# + filter - Filter type for the records
# + return - Timesheet info record or an error
public isolated function getEmployeeTimesheetInfo(TimesheetCommonFilter filter) returns TimesheetInfo|error? {
    TimesheetInfo|sql:Error policy = databaseClient->queryRow(getEmployeeTimesheetInfoQuery(filter));

    if policy is sql:Error && policy is sql:NoRowsError {
        return;
    }
    return policy;
}

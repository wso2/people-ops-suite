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

import ballerina/sql;
import ballerinax/mysql;

// Initializing Db client for leave database
final mysql:Client leaveDbClient = check initializeLeaveClient();

# Get leaves from database with the given filter.
#
# + filter - Leave filter 
# + 'limit - Maximum records limit  
# + offset - Offset value
# + return - Return list of Leaves
public isolated function getLeaves(LeaveFilter filter, int? 'limit = (), int? offset = ()) returns Leave[]|error {
    sql:ParameterizedQuery sqlQuery = getLeavesQuery(filter, getValidatedLimit('limit), getValidatedOffset(offset));
    stream<Leave, sql:Error?> resultStream = leaveDbClient->query(sqlQuery);
    return from Leave leave in resultStream
        select leave;
}

# Query to fetch leave by ID.
#
# + id - Leave ID
# + return - Select query
public isolated function getLeave(int id) returns Leave|error? {

    sql:ParameterizedQuery mainQuery = getCommonLeaveQuery();
    sql:ParameterizedQuery finalQuery = sql:queryConcat(mainQuery, ` WHERE id = ${id}`);
    Leave|error leave = leaveDbClient->queryRow(finalQuery);
    if leave is sql:NoRowsError {
        return ();
    }
    if leave is error {
        return error("Error occurred while fetching leave!", leave);
    }

    return leave;
}

# Create a new leave in the database.
#
# + input - Input data for the leave
# + numDaysForLeave - Number of days for leave
# + location - Employee location
# + return - Return Value Description
public isolated function insertLeave(LeaveInput input, float numDaysForLeave, string location) returns Leave|error {

    sql:ExecutionResult|error result = leaveDbClient->execute(insertLeaveQuery(input, numDaysForLeave, location));
    if result is error {
        return error("Error occurred while inserting leave!", result);
    }
    int lastInsertId = check result.lastInsertId.ensureType();
    Leave|error? insertedLeave = getLeave(lastInsertId);
    if insertedLeave is error? {
        return error("Error occurred while fetching inserted leave!");
    }
    return insertedLeave;
}

# Cancel an existing active leave.
#
# + id - Leave ID  
# + return - Returns nil on success, error on failure
public isolated function cancelLeave(int id) returns error? {

    sql:ParameterizedQuery sqlQuery = `UPDATE leave_submissions SET active = 0 WHERE id = ${id}`;
    sql:ExecutionResult|sql:Error result = leaveDbClient->execute(sqlQuery);
    if result is error {
        return error("Error occurred while cancelling leave!", result);
    }
}

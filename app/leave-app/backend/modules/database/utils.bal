// Copyright (c) 2024 WSO2 LLC. (https://www.wso2.com).
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

# Build the filter (WHERE) clause of the SQL query with the given set of filter types
# and their corresponding literals.
#
# + mainQuery - Main query without the new sub query
# + filterQueries - Array of filter queries needed to be concatenate with the main query
# + return - SQL filter clause
isolated function buildSqlQuery(sql:ParameterizedQuery mainQuery, sql:ParameterizedQuery[] filterQueries)
    returns sql:ParameterizedQuery {
    sql:ParameterizedQuery sqlQuery = mainQuery;
    foreach int i in 0 ... filterQueries.length() - 1 {
        if i == 0 {
            sqlQuery = sql:queryConcat(sqlQuery, ` WHERE `, filterQueries[i]);
        }
        else {
            sqlQuery = sql:queryConcat(sqlQuery, ` AND `, filterQueries[i]);
        }
    }
    return sqlQuery;
}

# Get the validated pagination limit and ensure it is within the accepted pagination range.
# This will be used when building MySQL queries and sending 'limit as `pageSize` to NetSuite.
#
# + 'limit - Pagination limit if any
# + return - Return validated limit
public isolated function getValidatedLimit(int? 'limit) returns int {
    return ('limit !is () && 'limit > 0) ? ('limit > UPPER_LIMIT ? UPPER_LIMIT : 'limit) : DEFAULT_LIMIT;
}

# Get the validated pagination offset and ensure it is within the accepted offset range.
# This will be used when building MySQL queries and sending offset to NetSuite.
#
# + offset - Pagination offset if any
# + return - Return validated offset
public isolated function getValidatedOffset(int? offset) returns int {
    return offset !is () && offset > -1 ? offset : 0;
}

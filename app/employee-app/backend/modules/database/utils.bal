// Copyright (c) 2024, WSO2 LLC.
//
// WSO2 Inc. licenses this file to you under the Apache License,
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

# Helper function to add a filter condition if the filter is not null or empty.
#
# + filterQueries - Filter qyery array
# + condition - Condition to be applied to the query
# + filterValue - Value of the filter
isolated function addFilterCondition(
        sql:ParameterizedQuery[] filterQueries,
        sql:ParameterizedQuery condition,
        FilterValue? filterValue
) {

    if filterValue is string[]|int[]|HiringStatus[] && filterValue.length() > 0 {
        filterQueries.push(sql:queryConcat(condition, ` IN (`, sql:arrayFlattenQuery(filterValue), `)`));
    } else if filterValue is string|int {
        filterQueries.push(sql:queryConcat(condition, ` = ${filterValue}`));
    } else if filterValue is Compensation[]|Document[] {
        filterQueries.push(sql:queryConcat(condition, ` = ${filterValue.toJsonString()}`));
    }
}

# Build the database select query with dynamic filter attributes.
#
# + mainQuery - Main query without the new sub query
# + filters - Array of sub queries to be added to the main query
# + return - Dynamically build sql:ParameterizedQuery
isolated function buildSqlSelectQuery(sql:ParameterizedQuery mainQuery, sql:ParameterizedQuery[] filters)
    returns sql:ParameterizedQuery {

    boolean isFirstSearch = true;
    sql:ParameterizedQuery updatedQuery = mainQuery;
    foreach sql:ParameterizedQuery filter in filters {
        if isFirstSearch {
            updatedQuery = sql:queryConcat(mainQuery, ` WHERE `, filter);
            isFirstSearch = false;
            continue;
        }
        updatedQuery = sql:queryConcat(updatedQuery, ` AND `, filter);
    }
    return updatedQuery;
}

# Build the database update query with dynamic attributes.
#
# + mainQuery - Main query without the new sub query
# + filters - Array of sub queries to be added to the main query
# + return - Dynamically build sql:ParameterizedQuery
isolated function buildSqlUpdateQuery(sql:ParameterizedQuery mainQuery, sql:ParameterizedQuery[] filters)
    returns sql:ParameterizedQuery {

    boolean isFirstUpdate = true;
    sql:ParameterizedQuery updatedQuery = ``;
    foreach sql:ParameterizedQuery filter in filters {
        if isFirstUpdate {
            updatedQuery = sql:queryConcat(mainQuery, filter);
            isFirstUpdate = false;
            continue;
        }
        updatedQuery = sql:queryConcat(updatedQuery, ` , `, filter);
    }
    return updatedQuery;
}

isolated function stringToParameterizedQueryConversion(string queryStr) returns sql:ParameterizedQuery {
    sql:ParameterizedQuery query = `""`;
    query.strings = [queryStr];
    return query;
}

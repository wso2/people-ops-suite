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
import ballerina/time;

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

# Turns an RFC 3339 instant as Meet gives it (e.g. `2026-10-01T10:20:00.123456Z`) into the
# `yyyy-MM-dd HH:mm:ss` UTC form the DATETIME columns hold, dropping the fraction. Unknown or
# unparseable times become () -- a part with no time is still a part worth keeping.
#
# + rfc3339 - The instant, or () / "" when Meet did not set it
# + return - The DB form, or ()
public isolated function toDbDateTime(string? rfc3339) returns string? {
    if rfc3339 is () || rfc3339 == "" {
        return;
    }
    time:Utc|error utc = time:utcFromString(rfc3339);
    if utc is error {
        return;
    }
    time:Civil civil = time:utcToCivil(utc);
    decimal seconds = civil.second ?: 0d;
    return string `${civil.year}-${twoDigits(civil.month)}-${twoDigits(civil.day)} ` +
        string `${twoDigits(civil.hour)}:${twoDigits(civil.minute)}:${twoDigits(<int>seconds.floor())}`;
}

isolated function twoDigits(int n) returns string => n < 10 ? string `0${n}` : n.toString();

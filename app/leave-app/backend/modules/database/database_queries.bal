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

# Common query to fetch leave/leaves from the database.
#
# + return - Select query
isolated function getCommonLeaveQuery() returns sql:ParameterizedQuery => `
    SELECT 
        id, 
        email, 
        leave_type,
        leave_period_type,
        copy_email_list,
        notify_everyone,
        submit_note,
        cancel_note,
        created_date,
        updated_date,
        email_id,
        email_subject,
        active,
        start_date,
        end_date,
        start_half,
        end_half,
        canceled_date,
        num_days,
        public_submit_note,
        calendar_event_id,
        location
    FROM leave_app.leave_submissions
`;

# Query to fetch leaves from the database.
#
# + filter - Query filter  
# + 'limit - Maximum records limit  
# + offset - Offset value
# + return - Select query
isolated function getLeavesQuery(LeaveFilter filter, int? 'limit = (), int? offset = ())
    returns sql:ParameterizedQuery {

    sql:ParameterizedQuery mainQuery = getCommonLeaveQuery();

    sql:ParameterizedQuery[] filterQueries = [];

    string[]? emails = filter?.emails;
    if emails is string[] && emails.length() > 0 {
        filterQueries.push(sql:queryConcat(`email IN (`, sql:arrayFlattenQuery(emails), `)`));
    }
    string? startDate = filter?.startDate;
    string? endDate = filter?.endDate;
    if startDate is string && endDate is string {
        filterQueries.push(`((start_date BETWEEN ${startDate} AND ${endDate}) 
            OR (end_date BETWEEN ${startDate} AND ${endDate}) 
            OR (start_date < ${startDate} AND end_date > ${endDate}))`);
    } else if startDate is string {
        filterQueries.push(
            `(start_date >= ${startDate} OR (end_date >= ${startDate} AND start_date < ${startDate}))`
        );
    } else if endDate is string {
        filterQueries.push(`(end_date <= ${endDate} OR (start_date <= ${endDate} AND end_date > ${endDate}))`);
    }

    if filter?.isActive is boolean {
        filterQueries.push(`active = ${filter?.isActive}`);
    }

    string[]? leaveTypes = filter?.leaveTypes;
    if leaveTypes is string[] && leaveTypes.length() != 0 {
        filterQueries.push(sql:queryConcat(`leave_type IN (`, sql:arrayFlattenQuery(leaveTypes), `)`));
    }

    sql:ParameterizedQuery sqlQuery = buildSqlQuery(mainQuery, filterQueries);
    sql:ParameterizedQuery orderBy = filter?.orderBy == ASC ? `ASC` : `DESC`;
    return sql:queryConcat(sqlQuery, ` ORDER BY created_date `, orderBy,
        ` LIMIT ${'limit ?: MAXIMUM_LIMIT_VALUE} OFFSET ${offset ?: 0}`);
}

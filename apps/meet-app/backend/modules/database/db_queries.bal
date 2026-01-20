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

# Build query to retrieve meeting types.
#
# + domain - Domain of the meeting
# + return - sql:ParameterizedQuery - Select query for the meeting_types table
isolated function getMeetingTypesQuery(string domain) returns sql:ParameterizedQuery =>
`
    SELECT 
        domain,
        types
    FROM 
        meeting_type
    WHERE
        domain = ${domain}
`;

# Build query to add a meeting.
#
# + meeting - Meeting to be added
# + createdBy - User who is creating the meeting
# + return - sql:ParameterizedQuery - Insert query for the meeting table
isolated function addMeetingQuery(AddMeetingPayload meeting, string createdBy) returns sql:ParameterizedQuery =>
`
    INSERT INTO meeting
    (
        title, 
        google_event_id, 
        host, 
        start_time, 
        end_time, 
        wso2_participants,
        is_recurring,
        meeting_status,
        meeting_type,
        created_by, 
        updated_by
    )
    VALUES
    (
        ${meeting.title}, 
        ${meeting.googleEventId}, 
        ${meeting.host}, 
        ${meeting.startTime}, 
        ${meeting.endTime}, 
        ${meeting.internalParticipants},
        ${meeting.isRecurring},
        ${ACTIVE},
        ${meeting.meetingType},
        ${createdBy}, 
        ${createdBy}
    )
`;

# Build query to retrieve meetings.
#
# + hostOrInternalParticipant - Filter by host or internal participant  
# + title - Title to filter  
# + host - Host filter  
# + startTime - Start time filter  
# + endTime - End time filter  
# + internalParticipants - Participants filter
# + 'limit - Limit of the data  
# + offset - offset of the query
# + return - sql:ParameterizedQuery - Select query for the meeting table
isolated function getMeetingsQuery(string? hostOrInternalParticipant, string? title, string? host,
        string? startTime, string? endTime, string[]? internalParticipants, int? 'limit, int? offset)
    returns sql:ParameterizedQuery {

    sql:ParameterizedQuery mainQuery = `
            SELECT 
                meeting_id AS 'meetingId',
                title, 
                google_event_id AS 'googleEventId',
                host, 
                DATE_FORMAT(start_time, '%Y-%m-%d %H:%i:%s') AS 'startTime',
                DATE_FORMAT(end_time, '%Y-%m-%d %H:%i:%s') AS 'endTime',
                wso2_participants as internalParticipants, 
                is_recurring AS 'isRecurring',
                meeting_status as meetingStatus,
                created_on AS 'createdOn',
                created_by AS 'createdBy',
                updated_on AS 'updatedOn',
                updated_by AS 'updatedBy',
                COUNT(*) OVER() AS totalCount,
                CASE
                    WHEN start_time < UTC_TIMESTAMP() THEN ${PAST}
                    ELSE ${UPCOMING}
                END AS timeStatus
            FROM 
                meeting
    `;

    // Setting the filters based on the meeting object.
    sql:ParameterizedQuery[] filters = [];

    if host is string {
        filters.push(sql:queryConcat(`host = `, `${host}`));
    }
    if hostOrInternalParticipant is string {
        filters.push(sql:queryConcat(
            `(host = ${hostOrInternalParticipant} OR wso2_participants LIKE ${"%" + hostOrInternalParticipant + "%"})`
        ));
    }
    if title is string {
        filters.push(sql:queryConcat(`title LIKE ${"%" + title + "%"}`));
    }
    if internalParticipants is string[] && internalParticipants.length() > 0 {
        boolean first = true;
        sql:ParameterizedQuery internalParticipantsFilter = `(`;
        foreach string participant in internalParticipants {
            if first {
                internalParticipantsFilter = sql:queryConcat(
                    internalParticipantsFilter,
                    `wso2_participants LIKE ${"%" + participant + "%"}`
                );
                first = false;
                continue;
            }
            // If the first participant is already added, add OR for the rest of the participants.
            internalParticipantsFilter = sql:queryConcat(
                internalParticipantsFilter,
                ` OR wso2_participants LIKE ${"%" + participant + "%"}`
            );
        }
        internalParticipantsFilter = sql:queryConcat(internalParticipantsFilter, `)`);
        filters.push(internalParticipantsFilter);
    }
    if startTime is string {
        filters.push(sql:queryConcat(`start_time >= ${startTime}`));
    }
    if endTime is string {
        filters.push(sql:queryConcat(`end_time <= ${endTime}`));
    }

    // Building the WHERE clause.
    mainQuery = buildSqlSelectQuery(mainQuery, filters);

    // Sorting the result by created_on.
    mainQuery = sql:queryConcat(mainQuery, ` ORDER BY start_time DESC`);

    // Setting the limit and offset.
    if 'limit is int {
        mainQuery = sql:queryConcat(mainQuery, ` LIMIT ${'limit}`);
        if offset is int {
            mainQuery = sql:queryConcat(mainQuery, ` OFFSET ${offset}`);
        }
    } else {
        mainQuery = sql:queryConcat(mainQuery, ` LIMIT 100`);
    }

    return mainQuery;
}

# Build query to retrieve a specific meeting.
#
# + meetingId - ID of the meeting to retrieve
# + return - sql:ParameterizedQuery - Select query for the meeting table
isolated function getMeetingQuery(int meetingId) returns sql:ParameterizedQuery =>
`
    SELECT
        meeting_id AS 'meetingId',
        title, 
        google_event_id AS 'googleEventId',
        host, 
        DATE_FORMAT(start_time, '%Y-%m-%d %H:%i:%s') AS 'startTime',
        DATE_FORMAT(end_time, '%Y-%m-%d %H:%i:%s') AS 'endTime',
        wso2_participants as internalParticipants, 
        is_recurring AS 'isRecurring', 
        meeting_status as meetingStatus,
        created_on AS 'createdOn',
        created_by AS 'createdBy',
        updated_on AS 'updatedOn',
        updated_by AS 'updatedBy',
        CASE
            WHEN start_time < UTC_TIMESTAMP() THEN ${PAST}
            ELSE ${UPCOMING}
        END AS timeStatus
    FROM 
        meeting
    WHERE
        meeting_id = ${meetingId}
`;

# Build query to update the meetingStatus.
#
# + meetingId - ID of the meeting to cancel
# + return - sql:ParameterizedQuery - Update query for the meeting table
isolated function cancelMeetingStatusQuery(int meetingId) returns sql:ParameterizedQuery =>
`
    UPDATE 
        meeting
    SET 
        meeting_status = ${CANCELLED}
    WHERE 
        meeting_id = ${meetingId};
`;

# Build query to count meetings grouped by Month.
#
# + startTime - Start of the range
# + endTime - End of the range
# + return - sql:ParameterizedQuery
isolated function getMonthlyScheduledCountsQuery(string startTime, string endTime) returns sql:ParameterizedQuery =>
`
    SELECT 
        DATE_FORMAT(start_time, '%Y-%m') as month_key,
        COUNT(*) as count
    FROM meeting
    WHERE 
        meeting_status = ${ACTIVE} AND
        start_time >= ${startTime} AND
        start_time < ${endTime}
    GROUP BY 
        DATE_FORMAT(start_time, '%Y-%m')
`;

# Build query to count meetings grouped by the meeting_type column.
#
# + startTime - Start of the range
# + endTime - End of the range
# + return - sql:ParameterizedQuery
isolated function countMeetingTypesQuery(string startTime, string endTime) returns sql:ParameterizedQuery =>
`
    SELECT 
        meeting_type,
        COUNT(*) as count
    FROM meeting
    WHERE 
        meeting_status = ${ACTIVE} AND
        start_time >= ${startTime} AND
        start_time < ${endTime} AND
        meeting_type IS NOT NULL  -- Exclude rows where type might be missing
    GROUP BY 
        meeting_type
    ORDER BY 
        count DESC
`;

# Build query to count meetings grouped by Host.
#
# + startTime - Start of the range
# + endTime - End of the range
# + return - sql:ParameterizedQuery
isolated function countMeetingsByHostQuery(string startTime, string endTime) returns sql:ParameterizedQuery =>
`
    SELECT 
        host,
        COUNT(*) as count
    FROM meeting
    WHERE 
        meeting_status = ${ACTIVE} AND
        start_time >= ${startTime} AND
        start_time < ${endTime}
    GROUP BY 
        host
`;

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
        host_bu,
        host_team,
        host_sub_team,
        host_unit,
        event_creator,
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
        ${meeting.businessUnit},
        ${meeting.team},
        ${meeting.subTeam},
        ${meeting.unit},
        ${meeting.eventCreator},
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
# + searchString - Search String to filter host and title 
# + region - Region filter
# + startTime - Start time filter  
# + endTime - End time filter  
# + internalParticipants - Participants filter
# + 'limit - Limit of the data  
# + offset - offset of the query
# + return - sql:ParameterizedQuery - Select query for the meeting table
isolated function getMeetingsQuery(string? hostOrInternalParticipant, string? title, string? host, string? searchString, string? region,
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
    if region is string {
        filters.push(sql:queryConcat(`host_sub_team = `, `${region}`));
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
    if searchString is string {
        filters.push(sql:queryConcat(`(host like ${"%" + searchString + "%"} OR title LIKE ${"%" + searchString + "%"} )`));
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
        event_creator as 'eventCreator',
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
# + region - Region filter
# + return - sql:ParameterizedQuery
isolated function getMonthlyScheduledCountsQuery(string startTime, string endTime, string? region)
    returns sql:ParameterizedQuery {
    sql:ParameterizedQuery query = `
        SELECT 
            DATE_FORMAT(start_time, '%Y-%m') as month_key,
            COUNT(*) as count
        FROM meeting
        WHERE 
            meeting_status = ${ACTIVE} AND
            start_time >= ${startTime} AND
            start_time < ${endTime}
    `;

    if region is string {
        query = sql:queryConcat(query, ` AND host_sub_team = ${region}`);
    }
    query = sql:queryConcat(query, ` 
        GROUP BY 
            DATE_FORMAT(start_time, '%Y-%m')
    `);

    return query;
}

# Build query to count meetings grouped by the meeting_type column.
#
# + startTime - Start of the range
# + endTime - End of the range
# + region - Region filter
# + return - sql:ParameterizedQuery
isolated function countMeetingTypesQuery(string startTime, string endTime, string? region) 
    returns sql:ParameterizedQuery {
    sql:ParameterizedQuery query = `
        SELECT 
            meeting_type,
            COUNT(*) as count
        FROM meeting
        WHERE 
            meeting_status = ${ACTIVE} AND
            start_time >= ${startTime} AND
            start_time < ${endTime} AND
            meeting_type IS NOT NULL
    `;
    if region is string {
        query = sql:queryConcat(query, ` AND host_sub_team = ${region}`);
    }
    query = sql:queryConcat(query, ` 
        GROUP BY 
            meeting_type
        ORDER BY 
            count DESC
    `);

    return query;
}

# Build query to count meetings grouped by Host.
#
# + startTime - Start of the range
# + endTime - End of the range
# + region - Region filter
# + return - sql:ParameterizedQuery
isolated function countMeetingsByHostQuery(string startTime, string endTime , string? region) returns sql:ParameterizedQuery {
    sql:ParameterizedQuery query = `
    SELECT 
        host,
        host_team AS team,
        host_sub_team AS subTeam,
        COUNT(*) as count
    FROM meeting
    WHERE 
        meeting_status = ${ACTIVE} AND
        start_time >= ${startTime} AND
        start_time < ${endTime}
    `;
    if region is string {
        query = sql:queryConcat(query, ` AND host_sub_team = ${region}`);
    }
    query = sql:queryConcat(query,`
        GROUP BY 
        host,
        host_team,
        host_sub_team
    `);
    return  query;
}

# Build query to retrieve the meeting titles by region within a date range.
# 
# + startTime - Start of the range
# + endTime - End of the range
# + region - Region filter
# + return - sql:ParameterizedQuery
isolated function meetingTitlesByRegionsQuery(string startTime, string endTime, string region)
    returns sql:ParameterizedQuery =>
`
    SELECT
        title
    FROM
        meeting
    WHERE
        host_sub_team = ${region} AND
        start_time >= ${startTime} AND
        start_time < ${endTime} AND
        meeting_status = ${ACTIVE}
`;

# Build an atomic insert-or-update query for an auto-recorded meeting row, keyed by the
# space_name UNIQUE constraint. MySQL's ON DUPLICATE KEY UPDATE does the "does this
# already exist" check and the write as one uninterruptible operation, closing the race
# window a separate select-then-branch would have. meeting_id = LAST_INSERT_ID(meeting_id)
# is a standard trick so the existing row's ID is still returned correctly even when the
# duplicate-key path (update, not insert) is the one that runs.
#
# + payload - Details to write
# + actor - User performing the write
# + return - sql:ParameterizedQuery - Upsert query for the meeting table
isolated function upsertMeetRecordingQuery(MeetRecordingPayload payload, string actor) returns sql:ParameterizedQuery =>
`
    INSERT INTO meeting
    (
        title,
        space_name,
        google_event_id,
        host,
        event_creator,
        start_time,
        end_time,
        wso2_participants,
        external_participants,
        recording_state,
        drive_file_id,
        opportunity_id,
        opportunity_details,
        meeting_status,
        created_by,
        updated_by
    )
    VALUES
    (
        ${payload.title},
        ${payload.spaceName},
        ${payload.googleEventId},
        ${payload.organizer},
        ${payload.organizer},
        ${payload.startTime},
        ${payload.endTime},
        ${payload.internalParticipants},
        ${payload.externalParticipants},
        ${payload.recordingState},
        ${payload.driveFileId},
        ${payload.opportunityId},
        ${payload.opportunityDetails},
        ${ACTIVE},
        ${actor},
        ${actor}
    )
    ON DUPLICATE KEY UPDATE
        meeting_id = LAST_INSERT_ID(meeting_id),
        title = VALUES(title),
        google_event_id = VALUES(google_event_id),
        host = VALUES(host),
        event_creator = VALUES(event_creator),
        start_time = VALUES(start_time),
        end_time = VALUES(end_time),
        wso2_participants = VALUES(wso2_participants),
        external_participants = VALUES(external_participants),
        recording_state = VALUES(recording_state),
        drive_file_id = VALUES(drive_file_id),
        opportunity_id = VALUES(opportunity_id),
        opportunity_details = VALUES(opportunity_details),
        updated_by = VALUES(updated_by)
`;

# Build an insert-or-refresh query for calendar-watch's own registration of an event,
# keyed the same way as upsertMeetRecordingQuery. Deliberately does NOT overwrite
# recording_state/drive_file_id on the duplicate-key (update) path -- calendar-watch can
# be notified again about an event it already registered (e.g. attaching a recording is
# itself a calendar-event edit, which triggers another change notification), and blindly
# resetting those two columns back to their initial values would erase progress
# processRecordingReady() already made. They're still set correctly on a genuine first
# insert, since VALUES(...) in the INSERT list still applies then.
#
# + payload - Details to write
# + actor - User performing the write
# + return - sql:ParameterizedQuery - Insert-or-refresh query for the meeting table
isolated function registerMeetRecordingQuery(MeetRecordingPayload payload, string actor) returns sql:ParameterizedQuery =>
`
    INSERT INTO meeting
    (
        title,
        space_name,
        google_event_id,
        host,
        event_creator,
        start_time,
        end_time,
        wso2_participants,
        external_participants,
        recording_state,
        drive_file_id,
        opportunity_id,
        opportunity_details,
        meeting_status,
        created_by,
        updated_by
    )
    VALUES
    (
        ${payload.title},
        ${payload.spaceName},
        ${payload.googleEventId},
        ${payload.organizer},
        ${payload.organizer},
        ${payload.startTime},
        ${payload.endTime},
        ${payload.internalParticipants},
        ${payload.externalParticipants},
        ${payload.recordingState},
        ${payload.driveFileId},
        ${payload.opportunityId},
        ${payload.opportunityDetails},
        ${ACTIVE},
        ${actor},
        ${actor}
    )
    ON DUPLICATE KEY UPDATE
        meeting_id = LAST_INSERT_ID(meeting_id),
        title = VALUES(title),
        google_event_id = VALUES(google_event_id),
        host = VALUES(host),
        event_creator = VALUES(event_creator),
        start_time = VALUES(start_time),
        end_time = VALUES(end_time),
        wso2_participants = VALUES(wso2_participants),
        external_participants = VALUES(external_participants),
        opportunity_id = IF(VALUES(opportunity_id) IS NULL, opportunity_id, VALUES(opportunity_id)),
        opportunity_details = IF(VALUES(opportunity_id) IS NULL, opportunity_details, VALUES(opportunity_details)),
        updated_by = VALUES(updated_by)
`;

# Build query to fetch the stored Calendar-watch sync token.
#
# + return - sql:ParameterizedQuery - Select query for the calendar_watch_state table
isolated function getSyncTokenQuery() returns sql:ParameterizedQuery =>
`
    SELECT sync_token AS syncToken FROM calendar_watch_state WHERE id = 1
`;

# Build query to store the Calendar-watch sync token for the next poll.
#
# + syncToken - Token to store
# + return - sql:ParameterizedQuery - Update query for the calendar_watch_state table
isolated function setSyncTokenQuery(string syncToken) returns sql:ParameterizedQuery =>
`
    UPDATE calendar_watch_state SET sync_token = ${syncToken} WHERE id = 1
`;

# Build query to fetch an auto-recorded meeting row by its space name.
#
# + spaceName - Resource name of the Meet space
# + return - sql:ParameterizedQuery - Select query for the meeting table
isolated function getMeetRecordingBySpaceNameQuery(string spaceName) returns sql:ParameterizedQuery =>
`
    SELECT
        meeting_id AS meetingId,
        space_name AS spaceName,
        title,
        google_event_id AS googleEventId,
        host AS organizer,
        DATE_FORMAT(start_time, '%Y-%m-%d %H:%i:%s') AS startTime,
        DATE_FORMAT(end_time, '%Y-%m-%d %H:%i:%s') AS endTime,
        wso2_participants AS internalParticipants,
        external_participants AS externalParticipants,
        recording_state AS recordingState,
        drive_file_id AS driveFileId,
        opportunity_id AS opportunityId,
        opportunity_details AS opportunityDetails,
        transcript_state AS transcriptState,
        transcript_file_id AS transcriptFileId,
        smart_notes_state AS smartNotesState,
        smart_notes_file_id AS smartNotesFileId
    FROM meeting
    WHERE space_name = ${spaceName}
`;

# Build a narrow update for just the transcript columns of an existing meeting row, keyed
# by space_name. Deliberately separate from upsertMeetRecordingQuery/
# registerMeetRecordingQuery -- folding transcript_state/transcript_file_id into either of
# those would require re-supplying every recording column too on every write, or risk
# overwriting them with stale values, which is exactly the class of bug already found once
# with recording_state (see registerMeetRecordingQuery's doc comment above). A plain
# UPDATE is enough here since the row is always already registered by calendar-watch by
# the time a transcript-ready notification can arrive.
#
# + spaceName - Resource name of the Meet space, the lookup key
# + transcriptState - New transcript processing state
# + transcriptFileId - Drive file ID (Google Doc) of the transcript, once resolved
# + actor - User performing the write
# + return - sql:ParameterizedQuery - Update query for the meeting table
isolated function updateMeetTranscriptQuery(string spaceName, RecordingState transcriptState,
        string? transcriptFileId, string actor) returns sql:ParameterizedQuery =>
`
    UPDATE meeting
    SET
        transcript_state = ${transcriptState},
        transcript_file_id = ${transcriptFileId},
        updated_by = ${actor}
    WHERE space_name = ${spaceName}
`;

# Build a narrow update for just the smart-notes columns of an existing meeting row, keyed
# by space_name. Same rationale as updateMeetTranscriptQuery -- a separate Google Doc
# artifact, tracked independently, never folded into the recording/transcript writes.
#
# + spaceName - Resource name of the Meet space, the lookup key
# + smartNotesState - New smart-notes processing state
# + smartNotesFileId - Drive file ID (Google Doc) of the smart notes, once resolved
# + actor - User performing the write
# + return - sql:ParameterizedQuery - Update query for the meeting table
isolated function updateMeetSmartNotesQuery(string spaceName, RecordingState smartNotesState,
        string? smartNotesFileId, string actor) returns sql:ParameterizedQuery =>
`
    UPDATE meeting
    SET
        smart_notes_state = ${smartNotesState},
        smart_notes_file_id = ${smartNotesFileId},
        updated_by = ${actor}
    WHERE space_name = ${spaceName}
`;
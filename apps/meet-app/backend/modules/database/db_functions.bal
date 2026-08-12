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

# Fetch meeting types.
#
# + domain - meeting domain
# + return - Meeting | Error, if not found
public isolated function fetchMeetingTypes(string domain) returns MeetingTypes|error {
    RawMeetingTypes|sql:Error meetingTypes = databaseClient->queryRow(getMeetingTypesQuery(domain));

    if meetingTypes is sql:NoRowsError {
        return {
            domain,
            types: []
        };
    }

    if meetingTypes is sql:Error {
        return meetingTypes
;
    }

    // Convert the types field (comma-separated) into a string array.
    string:RegExp r = re `,`;
    string[] types = r.split(meetingTypes.types).map(str => str.trim());

    return {
        domain: meetingTypes.domain,
        types
    };
}

# Create new meeting.
#
# + addMeetingPayload - Meeting details
# + createdBy - Person who created the meeting
# + return - Id of the meeting | Error
public isolated function addMeeting(AddMeetingPayload addMeetingPayload, string createdBy) returns int|error {
    sql:ExecutionResult executionResults = check databaseClient->execute(
        addMeetingQuery(addMeetingPayload, createdBy));
    return executionResults.lastInsertId.ensureType(int);
}

# Fetch meetings.
#
# + hostOrInternalParticipant - Filter by host or internal participant
# + title - Name to filter  
# + host - Host email filter  
# + searchString - Search String to filter host and title
# + region - Region filter
# + startTime - Start time filter  
# + endTime - End time filter  
# + internalParticipants - Internal participants filter
# + 'limit - Limit of the response
# + offset - Offset of the number of meetings to retrieve  
# + return - List of meetings | Error
public isolated function fetchMeetings(string? hostOrInternalParticipant, string? title, string? host, string? searchString, string? region,
        string? startTime, string? endTime, string[]? internalParticipants, int? 'limit, int? offset)
    returns Meeting[]|error {

    stream<Meeting, error?> resultStream = databaseClient->query(
        getMeetingsQuery(
            hostOrInternalParticipant, title, host, searchString, region, startTime, endTime, internalParticipants, 'limit, offset
        )
    );

    return from Meeting meeting in resultStream
        select meeting;
}

# Fetch specific meeting.
#
# + meetingId - The ID of the meeting to fetch
# + return - Meeting | Error, if not found
public isolated function fetchMeeting(int meetingId) returns Meeting|error? {
    Meeting|sql:Error meeting = databaseClient->queryRow(getMeetingQuery(meetingId));

    if meeting is sql:NoRowsError {
        return;
    }
    return meeting;
}

# Cancels a meeting by updating its status to 'CANCELLED'.
#
# + meetingId - The ID of the meeting to cancel
# + return - Id of the cancelled meeting|Error
public isolated function cancelMeeting(int meetingId) returns int|error {
    sql:ExecutionResult result = check databaseClient->execute(cancelMeetingStatusQuery(meetingId));
    if result.affectedRowCount < 1 {
        return error("Error while cancelling the meeting");
    }
    return meetingId;
}

# Fetches scheduled counts grouped by month for a date range.
#
# + startTime - Start ISO string
# + endTime - End ISO string
# + region - Region filter
# + return - Monthly counts or Error
public isolated function getMonthlyScheduledCounts(string startTime, string endTime, string? region) returns map<int>|error {
    stream<ScheduledMeetingStat, sql:Error?> resultStream = databaseClient->query(
        getMonthlyScheduledCountsQuery(startTime, endTime, region)
    );

    return map from ScheduledMeetingStat stat in resultStream
        select [stat.month_key, stat.count];
}

# Fetches meeting counts grouped by type within a date range.
#
# + startTime - Start ISO string
# + endTime - End ISO string
# + region - Region filter
# + return - List of stats or Error
public isolated function getMeetingTypeStats(string startTime, string endTime, string? region) returns MeetingTypeStat[]|error {
    stream<MeetingTypeStat, sql:Error?> resultStream = databaseClient->query(
        countMeetingTypesQuery(startTime, endTime, region)
    );

    return from MeetingTypeStat stat in resultStream
        select stat;
}

# Fetches meeting counts grouped by Host.
#
# + startTime - Start ISO string
# + endTime - End ISO string
# + region - Region filter
# + return - List of stats or Error
public isolated function getMeetingCountsByHost(string startTime, string endTime, string? region) returns MeetingHostStat[]|error {
    stream<MeetingHostStat, sql:Error?> resultStream = databaseClient->query(
        countMeetingsByHostQuery(startTime, endTime, region)
    );

    return from MeetingHostStat stat in resultStream
        select stat;
}

# Fetches meeting titles by region within a date range.
#
# + startTime - Start ISO string
# + endTime - End ISO string
# + region - Region filter
# + return - List of meeting titles or Error
public isolated function getMeetingIdsByRegions(string startTime, string endTime, string region) returns string[]|error {
    stream<record {string title;}, sql:Error?> titleStream =
    databaseClient->query(meetingTitlesByRegionsQuery(startTime, endTime, region));

    return from var row in titleStream
        select row.title;
}

# Creates or updates an auto-recorded meeting row, keyed by space name. Atomic: relies on
# a UNIQUE constraint on space_name plus ON DUPLICATE KEY UPDATE, so there's no separate
# check-then-write window where two concurrent calls for the same meeting could race.
#
# + payload - Details to write
# + actor - User performing the write
# + return - The row's meeting_id, or Error
public isolated function upsertMeetRecording(MeetRecordingPayload payload, string actor) returns int|error {
    sql:ExecutionResult result = check databaseClient->execute(upsertMeetRecordingQuery(payload, actor));
    return result.lastInsertId.ensureType(int);
}

# Registers (or refreshes non-recording details of) an auto-recorded meeting row, keyed by
# space name -- for calendar-watch's own use. Unlike upsertMeetRecording, this never
# overwrites recording_state/drive_file_id on an existing row; see
# registerMeetRecordingQuery for why.
#
# + payload - Details to write
# + actor - User performing the write
# + return - The row's meeting_id, or Error
public isolated function registerMeetRecording(MeetRecordingPayload payload, string actor) returns int|error {
    sql:ExecutionResult result = check databaseClient->execute(registerMeetRecordingQuery(payload, actor));
    return result.lastInsertId.ensureType(int);
}

# Gets the stored Calendar-watch sync token, if one's been set yet.
#
# + return - The stored sync token, `()` if none stored yet, or Error
public isolated function getSyncToken() returns string?|error {
    record {string? syncToken;}|sql:Error result = databaseClient->queryRow(getSyncTokenQuery());
    if result is sql:NoRowsError {
        return;
    }
    if result is sql:Error {
        return result;
    }
    return result.syncToken;
}

# Stores the sync token to use on the next Calendar-watch poll.
#
# + syncToken - Token returned by the most recent getChangedEvents call
# + return - Error if the write fails
public isolated function setSyncToken(string syncToken) returns error? {
    _ = check databaseClient->execute(setSyncTokenQuery(syncToken));
}

# Fetches an auto-recorded meeting row by its space name.
#
# + spaceName - Resource name of the Meet space
# + return - The matching row, () if not found, or Error
public isolated function getMeetRecordingBySpaceName(string spaceName) returns MeetRecordingRow|error? {
    MeetRecordingRow|sql:Error result = databaseClient->queryRow(getMeetRecordingBySpaceNameQuery(spaceName));
    if result is sql:NoRowsError {
        return;
    }
    return result;
}

# Updates just the transcript columns of an existing meeting row, keyed by space name. See
# updateMeetTranscriptQuery for why this is a dedicated narrow UPDATE rather than folded
# into upsertMeetRecording/registerMeetRecording.
#
# + spaceName - Resource name of the Meet space, the lookup key
# + transcriptState - New transcript processing state
# + transcriptFileId - Drive file ID (Google Doc) of the transcript, once resolved
# + actor - User performing the write
# + return - Error if the write fails
public isolated function updateMeetTranscript(string spaceName, RecordingState transcriptState,
        string? transcriptFileId, string actor) returns error? {
    _ = check databaseClient->execute(updateMeetTranscriptQuery(spaceName, transcriptState, transcriptFileId, actor));
}

# Updates just the smart-notes columns of an existing meeting row, keyed by space name.
# See updateMeetSmartNotesQuery for why this is a dedicated narrow UPDATE.
#
# + spaceName - Resource name of the Meet space, the lookup key
# + smartNotesState - New smart-notes processing state
# + smartNotesFileId - Drive file ID (Google Doc) of the smart notes, once resolved
# + actor - User performing the write
# + return - Error if the write fails
public isolated function updateMeetSmartNotes(string spaceName, RecordingState smartNotesState,
        string? smartNotesFileId, string actor) returns error? {
    _ = check databaseClient->execute(updateMeetSmartNotesQuery(spaceName, smartNotesState, smartNotesFileId, actor));
}

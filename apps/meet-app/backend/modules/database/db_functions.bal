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
        string? startTime, string? endTime, string[]? internalParticipants, boolean echoOnly, int? 'limit, int? offset)
    returns Meeting[]|error {

    stream<Meeting, error?> resultStream = databaseClient->query(
        getMeetingsQuery(
            hostOrInternalParticipant, title, host, searchString, region, startTime, endTime, internalParticipants,
            echoOnly, 'limit, offset
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
        string? transcriptFileId, string actor, string? transcriptName = ()) returns error? {
    _ = check databaseClient->execute(
            updateMeetTranscriptQuery(spaceName, transcriptState, transcriptFileId, transcriptName, actor));
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

# Claims the one-shot Salesforce call-activity logging for a meeting, keyed by space name.
#
# Returns true for exactly one caller per meeting: the conditional UPDATE only matches while
# `call_activity_id` is still NULL, and MySQL applies the predicate and the write atomically.
# Every later caller -- a redelivered Pub/Sub notification, or a concurrent run for one of
# the other two artifacts -- gets false and must not log anything. Callers that win the claim
# and then fail must call releaseCallActivityClaim so the work can be retried.
#
# + spaceName - Resource name of the Meet space, the lookup key
# + actor - User performing the write
# + return - True if this caller won the claim, false if it was already taken, or Error
public isolated function claimCallActivity(string spaceName, string actor) returns boolean|error {
    sql:ExecutionResult result = check databaseClient->execute(claimCallActivityQuery(spaceName, actor));
    return result.affectedRowCount == 1;
}

# Records the Salesforce activity Id against the meeting, replacing the claim sentinel.
#
# + spaceName - Resource name of the Meet space, the lookup key
# + callActivityId - Salesforce Id of the created activity
# + actor - User performing the write
# + return - Error if the write fails
public isolated function setCallActivityId(string spaceName, string callActivityId, string actor) returns error? {
    _ = check databaseClient->execute(setCallActivityIdQuery(spaceName, callActivityId, actor));
}

# Hands back a claim taken by claimCallActivity when the activity could not be created, so a
# later notification can retry it. Only clears rows still holding the sentinel, so it can
# never wipe a real activity Id.
#
# + spaceName - Resource name of the Meet space, the lookup key
# + actor - User performing the write
# + return - Error if the write fails
public isolated function releaseCallActivityClaim(string spaceName, string actor) returns error? {
    _ = check databaseClient->execute(releaseCallActivityClaimQuery(spaceName, actor));
}

# Finds recent Inbound meetings with no lead link stored -- candidates for the lead backfill.
#
# + inboundMeetingType - The `meeting_type` the add-on stores for an Inbound call
# + days - How far back to look, by start time
# + afterMeetingId - Only meetings with a larger id (the cursor)
# + 'limit - Most rows to return
# + return - Candidates, oldest id first, or Error
public isolated function fetchLeadBackfillCandidates(string inboundMeetingType, int days, int afterMeetingId,
        int 'limit) returns LeadBackfillCandidate[]|error {
    stream<LeadBackfillCandidate, error?> resultStream = databaseClient->query(
        getLeadBackfillCandidatesQuery(inboundMeetingType, days, afterMeetingId, 'limit));
    return from LeadBackfillCandidate candidate in resultStream
        select candidate;
}

# Records one part of a call, keyed by its Meet name: inserts it the first time, updates it
# on every later write (a redelivery, or FAILED becoming ATTACHED on a retry).
#
# A part the V6 migration copied in carries a placeholder name, not its Meet name, so the
# first time the real name arrives for that same file it would otherwise land as a second row
# for one file. This adopts the placeholder row instead: same file, now with its real name.
#
# + kind - Which kind of part
# + payload - Details to write
# + actor - User performing the write
# + return - Error if the write fails
public isolated function upsertMeetingPart(PartKind kind, MeetingPartPayload payload, string actor) returns error? {
    string? startTime = toDbDateTime(payload.startTime);
    string? endTime = toDbDateTime(payload.endTime);
    // Renames the placeholder when there is one; a no-op otherwise. Either way the upsert then
    // finds or creates the row by the real name and writes the state.
    _ = check databaseClient->execute(adoptLegacyPartQuery(kind, payload, startTime, endTime, actor));
    _ = check databaseClient->execute(upsertMeetingPartQuery(kind, payload, startTime, endTime, actor));
}

# Fetches one part by its Meet name.
#
# + kind - Which kind of part
# + name - Meet's resource name
# + return - The part, () if not recorded yet, or Error
public isolated function getMeetingPartByName(PartKind kind, string name) returns MeetingPart|error? {
    MeetingPart|sql:Error part = databaseClient->queryRow(getMeetingPartByNameQuery(kind, name));
    if part is sql:NoRowsError {
        return;
    }
    return part;
}

# Fetches one part of a meeting by its id.
#
# + kind - Which kind of part
# + meetingId - Meeting the part must belong to
# + partId - The part's id
# + return - The part, () if the meeting has no such part, or Error
public isolated function getMeetingPart(PartKind kind, int meetingId, int partId) returns MeetingPart|error? {
    MeetingPart|sql:Error part = databaseClient->queryRow(getMeetingPartQuery(kind, meetingId, partId));
    if part is sql:NoRowsError {
        return;
    }
    return part;
}

# Fetches every part of one kind for a meeting, in the order they happened.
#
# + kind - Which kind of part
# + meetingId - The meeting
# + return - The parts, or Error
public isolated function getMeetingParts(PartKind kind, int meetingId) returns MeetingPart[]|error {
    stream<MeetingPart, error?> resultStream = databaseClient->query(getMeetingPartsQuery(kind, meetingId));
    return from MeetingPart part in resultStream
        select part;
}

# Whether one of the meeting's ATTACHED parts of this kind already uses the file. With
# Gemini notes on, a transcript and smart notes are one Google Doc, which is shared once.
#
# + kind - Which kind of part to look among
# + meetingId - The meeting
# + driveFileId - The file
# + return - True if such a part exists, or Error
public isolated function hasAttachedPartWithFile(PartKind kind, int meetingId, string driveFileId)
        returns boolean|error {
    record {int total;} row = check databaseClient->queryRow(
            countAttachedPartsWithFileQuery(kind, meetingId, driveFileId));
    return row.total > 0;
}

# Records where a meeting's file sits among the calendar event's attachments, which orders
# parts that have no Meet times.
#
# + kind - Which kind of part
# + meetingId - The meeting
# + driveFileId - The file
# + attachmentOrder - Its position among the event's attachments, from 0
# + actor - User performing the write
# + return - Error if the write fails
public isolated function setPartAttachmentOrder(PartKind kind, int meetingId, string driveFileId, int attachmentOrder,
        string actor) returns error? {
    _ = check databaseClient->execute(setPartAttachmentOrderQuery(kind, meetingId, driveFileId, attachmentOrder,
            actor));
}

# Finds recent add-on meetings for the parts backfill.
#
# + days - How far back to look, by start time
# + afterMeetingId - Only meetings with a larger id (the cursor)
# + 'limit - Most rows to return
# + return - Candidates, oldest id first, or Error
public isolated function fetchPartsBackfillCandidates(int days, int afterMeetingId, int 'limit)
        returns PartsBackfillCandidate[]|error {
    stream<PartsBackfillCandidate, error?> resultStream = databaseClient->query(
            getPartsBackfillCandidatesQuery(days, afterMeetingId, 'limit));
    return from PartsBackfillCandidate candidate in resultStream
        select candidate;
}

# Stores a meeting's lead link, if it has none yet.
#
# + meetingId - Meeting to update
# + leadId - Salesforce Lead id
# + leadCompany - The lead's company, if known
# + actor - User performing the write
# + return - True if the row was updated, false if it already had a lead, or Error
public isolated function setMeetingLead(int meetingId, string leadId, string? leadCompany, string actor)
        returns boolean|error {
    sql:ExecutionResult result = check databaseClient->execute(setMeetingLeadQuery(meetingId, leadId, leadCompany,
            actor));
    return result.affectedRowCount == 1;
}

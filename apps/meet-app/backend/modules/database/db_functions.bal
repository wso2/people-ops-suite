// Copyright (c) 2025, WSO2 LLC. (https://www.wso2.com). All Rights Reserved.
//
// This software is the property of WSO2 LLC. and its suppliers, if any.
// Dissemination of any information or reproduction of any material contained
// herein in any form is strictly forbidden, unless permitted by WSO2 expressly.
// You may not alter or remove any copyright or other notice from copies of this content.
import ballerina/sql;

# Fetch meeting types.
#
# + domain - meeting domain
# + return - Meeting | Error, if not found
public isolated function fetchMeetingTypes(string domain) returns MeetingTypes|error? {
    record {|string domain; string types;|}|sql:Error meetingTypes = databaseClient->queryRow(
        getMeetingTypesQuery(domain));

    if meetingTypes is sql:Error && meetingTypes is sql:NoRowsError {
        return;
    }
    if meetingTypes is sql:Error {
        return meetingTypes;
    }

    // Convert the types field (comma-separated) into a string array
    string:RegExp r = re `,`;
    string[] types = r.split(meetingTypes.types).map(str => str.trim());

    return {
        domain: meetingTypes.domain,
        types: types
    };
}

# Create new meeting.
#
# + addMeetingPayload - Meeting details
# + createdBy - Person who created the meeting
# + return - Id of the meeting | Error
public isolated function addMeeting(AddMeetingPayload addMeetingPayload, string createdBy) returns int|error {
    sql:ExecutionResult|error executionResults = databaseClient->execute(
        addMeetingQuery(addMeetingPayload, createdBy));
    if executionResults is error {
        return executionResults;
    }

    return executionResults.lastInsertId.ensureType(int);
}

# Fetch meetings.
#
# + title - Name to filter  
# + host - Host email filter  
# + startTime - Start time filter  
# + endTime - End time filter  
# + wso2Participants - WSO2 participants filter
# + 'limit - Limit of the response
# + offset - Offset of the number of meetings to retrieve  
# + return - List of meetings | Error
public isolated function fetchMeetings(string? title, string? host, string? startTime, string? endTime,
        string? wso2Participants, int? 'limit, int? offset) returns Meeting[]|error {

    stream<Meeting, error?> resultStream = databaseClient->
                query(getMeetingsQuery(title, host, startTime, endTime, wso2Participants, 'limit, offset));

    Meeting[] meetings = [];

    check from Meeting meeting in resultStream
        do {
            meetings.push(meeting);
        };

    return meetings;
}

# Fetch specific meeting.
#
# + meetingId - The ID of the meeting to fetch
# + return - Meeting | Error, if not found
public isolated function fetchMeeting(int meetingId) returns Meeting|error? {
    Meeting|sql:Error meeting = databaseClient->queryRow(getMeetingQuery(meetingId));

    if meeting is sql:Error && meeting is sql:NoRowsError {
        return;
    }
    return meeting;
}

# Cancels a meeting by updating its status to 'CANCELLED'.
#
# + meetingId - The ID of the meeting to cancel
# + return - Id of the cancelled meeting|Error
public isolated function cancelMeeting(int meetingId) returns int|error {
    // Update the meetingStatus
    sql:ExecutionResult|error executionResults = databaseClient->execute(updateMeetingStatusQuery(meetingId));
    if executionResults is error {
        return executionResults;
    }

    return meetingId.ensureType(int);
}

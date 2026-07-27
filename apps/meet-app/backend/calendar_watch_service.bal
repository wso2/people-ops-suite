// Copyright (c) 2026 WSO2 LLC. (https://www.wso2.com).
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
import meet_app.calendar;
import meet_app.database;

import ballerina/http;
import ballerina/log;

configurable int calendarWatchListenerPort = 9093;
configurable string sharedAccountEmail = ?;
configurable string calendarWatchToken = ?;

// Isolated listener, same reasoning as meet_events_service.bal -- separate from the main
// Asgardeo-gated service, no push-token verification beyond the shared-secret channel token
// Google echoes back on every ping.
service /calendar\-watch on new http:Listener(calendarWatchListenerPort) {

    # One-time setup: registers the watch channel on the Shared Account's calendar. Call
    # this once (and again whenever the channel is renewed/re-created), pointing webhookUrl
    # at this same service's own tunnel URL + "/calendar-watch".
    #
    # + webhookUrl - Publicly reachable URL for Google to send pings to
    # + channelId - Unique ID for this channel (pick any new string each time you register)
    # + return - Confirmation or error
    resource function post register(string webhookUrl, string channelId) returns http:Ok|http:InternalServerError {
        error? result = calendar:watchCalendar(webhookUrl, channelId, calendarWatchToken);
        if result is error {
            log:printError("Failed to register calendar watch channel.", result);
            return <http:InternalServerError>{body: {message: "Failed to register calendar watch."}};
        }
        return <http:Ok>{body: {message: "Calendar watch registered."}};
    }

    # Receives Google's push notification pings -- these carry no event data, just headers
    # telling you something changed and which channel it was.
    #
    # + xGoogChannelToken - Shared secret, must match calendarWatchToken
    # + xGoogResourceState - "sync" on the initial confirmation ping, "exists" on real changes
    # + return - Always 200 -- Google stops sending pings if it ever sees a non-2xx
    resource function post .(@http:Header {name: "X-Goog-Channel-Token"} string? xGoogChannelToken,
            @http:Header {name: "X-Goog-Resource-State"} string? xGoogResourceState) returns http:Ok {
        if xGoogChannelToken != calendarWatchToken {
            log:printError("Calendar watch ping had a mismatched or missing channel token; ignoring.");
            return {body: {message: "ignored"}};
        }

        // The very first ping after registering a channel is just a confirmation, not a
        // real change -- nothing to sync yet.
        if xGoogResourceState == "sync" {
            return {body: {message: "sync acknowledged"}};
        }

        error? result = processCalendarChanges();
        if result is error {
            log:printError("Failed to process calendar changes.", result);
        }
        return {body: {message: "ok"}};
    }
}

isolated function processCalendarChanges() returns error? {
    string? syncToken = check database:getSyncToken();
    calendar:ChangedEventsResult changes = check calendar:getChangedEvents(syncToken);

    foreach json event in changes.events {
        error? result = registerEventIfRelevant(event);
        if result is error {
            log:printError("Skipping one changed event due to an error.", result);
        }
    }

    check database:setSyncToken(changes.nextSyncToken);
}

isolated function registerEventIfRelevant(json event) returns error? {
    json|error conferenceData = event.conferenceData;
    if conferenceData is error {
        // No conference on this event at all -- not one of ours, ignore.
        return;
    }

    json|error conferenceType = conferenceData.conferenceSolution.'key.'type;
    if conferenceType is error || conferenceType != "addOn" {
        return;
    }

    string eventId = check event.id.ensureType(string);
    string title = check event.summary.ensureType(string);
    string organizerEmail = check event.organizer.email.ensureType(string);
    string startTime = check event.'start.dateTime.ensureType(string);
    string endTime = check event.end.dateTime.ensureType(string);
    json[] entryPoints = check conferenceData.entryPoints.ensureType();
    if entryPoints.length() == 0 {
        return;
    }
    string meetingUri = check entryPoints[0].uri.ensureType(string);
    string[] uriParts = re `/`.split(meetingUri);
    string meetingCode = uriParts[uriParts.length() - 1];

    string spaceName = check calendar:resolveSpaceName(meetingCode);

    json[] attendees = [];
    json|error attendeesResult = event.attendees;
    if attendeesResult is json[] {
        attendees = attendeesResult;
    }

    string:RegExp wso2EmailRegex = re `(?i:^([a-z0-9_\-\.]+)@wso2\.com$)`;
    string[] internalEmails = [];
    string[] externalEmails = [];
    foreach json attendee in attendees {
        string attendeeEmail = check attendee.email.ensureType(string);
        if attendeeEmail == organizerEmail || attendeeEmail == sharedAccountEmail {
            continue;
        }
        if wso2EmailRegex.isFullMatch(attendeeEmail) {
            internalEmails.push(attendeeEmail);
        } else {
            externalEmails.push(attendeeEmail);
        }
    }

    _ = check database:upsertMeetRecording({
        spaceName,
        title,
        googleEventId: eventId,
        organizer: organizerEmail,
        startTime,
        endTime,
        internalParticipants: string:'join(", ", ...internalEmails),
        externalParticipants: string:'join(", ", ...externalEmails),
        recordingState: database:PENDING,
        driveFileId: ()
    }, SYSTEM_ACTOR);
}

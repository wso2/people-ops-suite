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
    # + return - 200 once processed; 503 on a genuine processing failure, since Google's docs
    #   confirm 500/502/503/504 responses are retried with backoff, unlike a bare 200 which
    #   tells Google nothing needs to happen again
    resource function post .(@http:Header {name: "X-Goog-Channel-Token"} string? xGoogChannelToken,
            @http:Header {name: "X-Goog-Resource-State"} string? xGoogResourceState)
            returns http:Ok|http:ServiceUnavailable {
        if xGoogChannelToken != calendarWatchToken {
            log:printError("Calendar watch ping had a mismatched or missing channel token; ignoring.");
            return <http:Ok>{body: {message: "ignored"}};
        }

        // The very first ping after registering a channel is just a confirmation, not a
        // real change -- nothing to sync yet.
        if xGoogResourceState == "sync" {
            return <http:Ok>{body: {message: "sync acknowledged"}};
        }

        error? result = processCalendarChanges();
        if result is error {
            log:printError("Failed to process calendar changes.", result);
            return <http:ServiceUnavailable>{body: {message: "Failed to process calendar changes; retry."}};
        }
        return <http:Ok>{body: {message: "ok"}};
    }
}

// Consecutive-failure count per event ID, so one permanently-broken event can't block the
// sync token forever -- it gets a bounded number of retries, then is given up on (loudly),
// rather than either silently dropping it on the first failure or stalling everything else
// behind it indefinitely. Restarting the service resets these, which is an acceptable
// trade-off: worst case a few extra retries for something that was already failing.
isolated map<int> eventFailureCounts = {};
const int MAX_CONSECUTIVE_EVENT_FAILURES = 3;

isolated function processCalendarChanges() returns error? {
    string? syncToken = check database:getSyncToken();
    calendar:ChangedEventsResult changes = check calendar:getChangedEvents(syncToken);

    boolean readyToAdvance = true;
    foreach json event in changes.events {
        string eventId = check event.id.ensureType(string);
        error? result = registerEventIfRelevant(event);
        if result is error {
            int attempts = bumpFailureCount(eventId);
            if attempts >= MAX_CONSECUTIVE_EVENT_FAILURES {
                log:printError(string `Giving up on event ${eventId} after ${attempts} failed attempts; ` +
                        "it will not be retried again.", result);
                clearFailureCount(eventId);
            } else {
                log:printError(string `Event ${eventId} failed (attempt ${attempts}/${MAX_CONSECUTIVE_EVENT_FAILURES}); ` +
                        "will retry next poll.", result);
                readyToAdvance = false;
            }
        } else {
            clearFailureCount(eventId);
        }
    }

    if readyToAdvance {
        check database:setSyncToken(changes.nextSyncToken);
    }
}

isolated function bumpFailureCount(string eventId) returns int {
    lock {
        int next = (eventFailureCounts[eventId] ?: 0) + 1;
        eventFailureCounts[eventId] = next;
        return next;
    }
}

isolated function clearFailureCount(string eventId) {
    lock {
        _ = eventFailureCounts.removeIfHasKey(eventId);
    }
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

    // Every genuine sales meeting has a customer on it. An add-on-created meeting with no
    // external participants means the add-on was picked by mistake for what's really an
    // internal meeting -- flag it and leave it untracked, rather than silently tracking
    // (and later sharing) a recording of an internal meeting no customer was ever part of.
    // The calendar event itself is left completely untouched either way.
    if externalEmails.length() == 0 {
        log:printError(string `Meeting "${title}" (${eventId}, organizer ${organizerEmail}) was created via the ` +
                "add-on but has no external participants -- not a real sales meeting. Not tracking it for recording.");
        return;
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

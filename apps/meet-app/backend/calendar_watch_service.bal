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

function init() returns error? {
    // Fail closed on a missing watch-channel secret. calendarWatchToken is required, but an
    // empty deployed value ("") would make the ping check below and the /register admin-token
    // guard both accept an attacker-supplied empty token -- so refuse to start rather than run
    // open (CWE-1188). (Renewal is now handled by the separate meet-watch-renewal Choreo
    // Scheduled Task, not by this service -- this check used to live in that job's own init().)
    if calendarWatchToken.trim() == "" {
        return error("calendarWatchToken is not configured; refusing to start with an empty " +
                "watch-channel secret (the /calendar-watch and /register endpoints would fail open).");
    }
}

// Isolated listener, same reasoning as meet_events_service.bal -- separate from the main
// Asgardeo-gated service, no push-token verification beyond the shared-secret channel token
// Google echoes back on every ping.
service /calendar\-watch on new http:Listener(calendarWatchListenerPort) {

    # One-time manual setup/testing endpoint: registers a watch channel on the Shared
    # Account's calendar directly. Routine renewal is handled by the separate
    # meet-watch-renewal Choreo Scheduled Task, not by this service. Point webhookUrl at
    # this same service's own base URL -- Choreo's exposed path for this service already IS
    # the "/calendar-watch" root, so nothing further should be appended.
    #
    # Guarded by adminToken (reusing calendarWatchToken as a second, unrelated purpose --
    # it is otherwise just the ping-matching secret) because this whole service has to sit
    # unauthenticated at the Choreo gateway for Google's own webhook pings to ever reach
    # the resource below, which would otherwise leave this registration action wide open to
    # anyone on the internet.
    #
    # + webhookUrl - Publicly reachable URL for Google to send pings to
    # + channelId - Unique ID for this channel (pick any new string each time you register)
    # + adminToken - Must match the configured calendarWatchToken
    # + return - The registered channel's details, or error
    resource function post register(string webhookUrl, string channelId, string adminToken)
            returns calendar:WatchChannelResponse|http:InternalServerError|http:Unauthorized {
        if adminToken != calendarWatchToken {
            log:printError("Calendar watch registration attempt had a missing or mismatched admin token; refusing.");
            return <http:Unauthorized>{body: {message: "Unauthorized."}};
        }

        calendar:WatchChannelResponse|error result = calendar:watchCalendar(webhookUrl, channelId, calendarWatchToken);
        if result is error {
            log:printError("Failed to register calendar watch channel.", result);
            return <http:InternalServerError>{body: {message: "Failed to register calendar watch."}};
        }
        return result;
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

// Google can deliver multiple push pings back-to-back with no guarantee of serialized
// delivery -- without this guard, concurrent runs could read the same syncToken and race
// to write nextSyncToken. upsertMeetRecording is idempotent, so this couldn't lose data,
// only cause redundant reprocessing; guarding it is simpler than relying on that.
isolated boolean calendarChangesProcessingInProgress = false;

isolated function processCalendarChanges() returns error? {
    lock {
        if calendarChangesProcessingInProgress {
            return;
        }
        calendarChangesProcessingInProgress = true;
    }
    error? result = fetchProcessAndStoreCalendarChanges();
    lock {
        calendarChangesProcessingInProgress = false;
    }
    return result;
}

isolated function fetchProcessAndStoreCalendarChanges() returns error? {
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
    // entryPoints can hold more than just the video link (e.g. a phone dial-in entry
    // alongside it) -- entryPoints[0] isn't guaranteed to be the video one, so find it by
    // type explicitly rather than assuming position.
    json[] entryPoints = check conferenceData.entryPoints.ensureType();
    string? meetingUri = ();
    foreach json entryPoint in entryPoints {
        string|error entryPointType = entryPoint.entryPointType.ensureType(string);
        if entryPointType is string && entryPointType == "video" {
            meetingUri = check entryPoint.uri.ensureType(string);
            break;
        }
    }
    if meetingUri is () {
        // No video entry point -- nothing to record against, skip this event.
        return;
    }
    string[] uriParts = re `/`.split(meetingUri);
    string meetingCode = uriParts[uriParts.length() - 1];

    string spaceName = check calendar:resolveSpaceName(meetingCode);

    // Written by the RevOS add-on onto every event it creates or links, as PRIVATE extended
    // properties -- which Google scopes to the one calendar copy they were set on (the
    // organizer's), not to the event generally. The Shared Account's own copy of this event
    // (what `event` here is -- read via the calendar-watch poll) never has them, so they're
    // read from a separate, targeted fetch of the organizer's own copy instead, impersonated
    // via CES's existing DWD credential. A failure here (or the properties genuinely being
    // absent, e.g. an event tagged addOn by mistake with no deal linked) is not fatal --
    // the meeting is still tracked, just without opportunity data.
    string? opportunityId = ();
    string? opportunityDetails = ();
    json|error organizerEventResult = calendar:getEvent(organizerEmail, eventId);
    if organizerEventResult is error {
        log:printError(string `Could not fetch organizer's own copy of event ${eventId} to read ` +
                "opportunity properties; continuing without them.", organizerEventResult);
    } else {
        json|error opportunityIdResult = organizerEventResult.extendedProperties.'private.revos_opportunity_id;
        if opportunityIdResult is string {
            opportunityId = opportunityIdResult;
        }

        // Compact deal snapshot (name, stage, amount, account, close date) the add-on writes
        // as one JSON-string property. Stored as-is -- MySQL validates it as JSON on insert,
        // nothing here needs to parse it back out. Only captured when an opportunityId is
        // also present, so the row can never hold deal details without the id they belong to
        // (matches the schema's documented "NULL wherever opportunity_id is NULL" invariant).
        if opportunityId is string {
            json|error opportunitySnapshotResult =
                organizerEventResult.extendedProperties.'private.revos_opportunity_snapshot;
            if opportunitySnapshotResult is string {
                opportunityDetails = opportunitySnapshotResult;
            }
        }
    }

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

    _ = check database:registerMeetRecording({
        spaceName,
        title,
        googleEventId: eventId,
        organizer: organizerEmail,
        startTime,
        endTime,
        internalParticipants: string:'join(", ", ...internalEmails),
        externalParticipants: string:'join(", ", ...externalEmails),
        recordingState: database:PENDING,
        driveFileId: (),
        opportunityId,
        opportunityDetails
    }, SYSTEM_ACTOR);
}

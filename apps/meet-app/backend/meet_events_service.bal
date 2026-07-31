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
import meet_app.driveservice;
import meet_app.people;

import ballerina/http;
import ballerina/lang.array;
import ballerina/lang.'string as strings;
import ballerina/lang.value;
import ballerina/log;

configurable int meetEventsListenerPort = 9091;

// Writes performed by these automated flows aren't tied to a specific logged-in user,
// unlike the rest of this app's created_by/updated_by values.
const string SYSTEM_ACTOR = "meet-app-system";

# Pub/Sub push envelope -- the actual notification is base64-encoded inside `message.data`.
# Left open (not a closed record) since Google's push includes other fields (e.g.
# `attributes`) that don't matter here but must not break data binding.
#
# + message - The Pub/Sub message wrapper
# + subscription - Resource name of the subscription that delivered this push
type PubSubPushEnvelope record {
    record {
        string data;
        string messageId?;
        string publishTime?;
    } message;
    string subscription?;
};

# Recording-ready notification payload, once decoded. Left open for the same reason as
# PubSubPushEnvelope above.
#
# + recording - The recording this notification is about
type RecordingReadyEvent record {
    record {
        string name;
    } recording;
};

# One-off manual registration, for testing without waiting on the Calendar-watch flow --
# fill this in with a real test meeting's details before triggering its recording-ready
# event, so processRecordingReady() has something to look up.
#
# + spaceName - Resource name of the Meet space (e.g. `spaces/abc123`)
# + title - The event's title
# + googleEventId - Calendar event ID the space was created for
# + organizer - Email of the event organizer
# + startTime - Event start time
# + endTime - Event end time
# + internalParticipants - wso2.com attendees, comma-joined
# + externalParticipants - Non-wso2.com attendees, comma-joined
type SeedRegistryRequest record {|
    string spaceName;
    string title;
    string googleEventId;
    string organizer;
    string startTime;
    string endTime;
    string internalParticipants;
    string externalParticipants;
|};

// Isolated listener, deliberately separate from the main Asgardeo-gated service on 9090.
// No push-token verification for now -- accepted trade-off for today's demo, behind a
// short-lived tunnel URL; revisit before this is ever exposed on a stable public endpoint.
service /meet\-events on new http:Listener(meetEventsListenerPort) {

    # One-off manual seed -- see SeedRegistryRequest.
    #
    # + req - Test meeting details to register
    # + return - Confirmation or error
    resource function post seed(@http:Payload SeedRegistryRequest req) returns http:Ok|http:InternalServerError {
        int|error result = database:upsertMeetRecording({
            spaceName: req.spaceName,
            title: req.title,
            googleEventId: req.googleEventId,
            organizer: req.organizer,
            startTime: req.startTime,
            endTime: req.endTime,
            internalParticipants: req.internalParticipants,
            externalParticipants: req.externalParticipants,
            recordingState: database:PENDING,
            driveFileId: ()
        }, SYSTEM_ACTOR);
        if result is error {
            log:printError("Failed to seed registry.", result);
            return <http:InternalServerError>{body: {message: "Failed to seed registry."}};
        }
        return <http:Ok>{body: {message: "seeded"}};
    }

    # + envelope - The Pub/Sub push envelope
    # + return - 200 once processed, or if the message is permanently unparseable (retrying
    #   a malformed message would never help); 503 on a genuine processing failure, since
    #   Pub/Sub retries non-2xx responses with backoff automatically
    resource function post .(@http:Payload PubSubPushEnvelope envelope) returns http:Ok|http:ServiceUnavailable {
        byte[]|error decoded = array:fromBase64(envelope.message.data);
        if decoded is error {
            log:printError("Could not base64-decode Pub/Sub message data.", decoded);
            return <http:Ok>{body: {message: "ignored"}};
        }

        string|error decodedString = strings:fromBytes(decoded);
        if decodedString is error {
            log:printError("Decoded Pub/Sub message data was not valid UTF-8.", decodedString);
            return <http:Ok>{body: {message: "ignored"}};
        }
        RecordingReadyEvent|error event = value:fromJsonStringWithType(decodedString);
        if event is error {
            log:printError("Could not parse recording-ready payload.", event);
            return <http:Ok>{body: {message: "ignored"}};
        }

        error? result = processRecordingReady(event.recording.name);
        if result is error {
            log:printError("Failed to process recording-ready event.", result);
            return <http:ServiceUnavailable>{body: {message: "Failed to process recording-ready event; retry."}};
        }
        return <http:Ok>{body: {message: "ok"}};
    }
}

isolated function processRecordingReady(string recordingName) returns error? {
    // The recording lookup goes through drive-service (Meet-read scope, narrowly held
    // alongside Drive on the Shared Account's own refresh token); the attach still goes
    // through CES, which has DWD Calendar scope covering impersonating the organizer.
    driveservice:RecordingInfoResponse info = check driveservice:resolveRecording(recordingName);
    string spaceName = info.spaceName;
    string fileId = info.fileId;

    database:MeetRecordingRow? tracked = check database:getMeetRecordingBySpaceName(spaceName);
    if tracked is () {
        log:printError(string `No registered event found for space ${spaceName}; skipping.`);
        return;
    }

    error? attachResult = calendar:attachRecording(tracked.organizer, tracked.googleEventId, fileId,
            "Meeting Recording", "video/mp4");
    if attachResult is error {
        _ = check database:upsertMeetRecording({
            spaceName: tracked.spaceName,
            title: tracked.title,
            googleEventId: tracked.googleEventId,
            organizer: tracked.organizer,
            startTime: tracked.startTime,
            endTime: tracked.endTime,
            internalParticipants: tracked.internalParticipants,
            externalParticipants: tracked.externalParticipants,
            recordingState: database:FAILED,
            driveFileId: fileId
        }, SYSTEM_ACTOR);
        return attachResult;
    }

    string:RegExp commaSplit = re `,`;
    string[] internalEmails = tracked.internalParticipants.length() > 0
        ? commaSplit.split(tracked.internalParticipants).map(e => e.trim())
        : [];
    // Grant Drive view access only to internal (wso2.com) people -- the organizer plus the
    // internal participants. External participants are deliberately excluded: WSO2 blocks
    // sharing Drive files outside the org, so trying to grant them always failed, which kept
    // the recording marked FAILED and made Pub/Sub retry the whole thing forever (re-sharing
    // to everyone else on each retry). External attendees still get the calendar attachment.
    string[] participantEmails = [tracked.organizer, ...internalEmails];

    // Access-granting below is BEST-EFFORT. Failures are logged for follow-up but must never
    // fail this function -- otherwise the webhook returns 503, Pub/Sub retries the whole event
    // forever, and every retry re-attaches and re-shares (spamming everyone) while a permanent
    // grant failure (e.g. a Drive cross-domain / silent-sharing restriction) never resolves.
    // The recording is already attached at this point; that's the actual deliverable.
    driveservice:GrantResult[]|error shareResult = driveservice:grantAccess(fileId, participantEmails, true);
    if shareResult is error {
        log:printError("Recording attached, but some participant Drive permission grants failed " +
                "(best-effort, not retrying).", shareResult);
    }

    // Everyone in Sales, Channel Sales, and Sales Engineering also gets view access, even if
    // they weren't on this particular call -- but silently (no notification email), since
    // they weren't actually a participant.
    string[]|error salesDepartmentEmails = people:getSalesDepartmentEmails();
    if salesDepartmentEmails is error {
        log:printError("Could not fetch Sales department list; skipping their access grant for this recording.",
                salesDepartmentEmails);
    } else {
        string[] extraEmails = [];
        foreach string email in salesDepartmentEmails {
            if participantEmails.indexOf(email) == () {
                extraEmails.push(email);
            }
        }
        driveservice:GrantResult[]|error deptShareResult = driveservice:grantAccess(fileId, extraEmails, false);
        if deptShareResult is error {
            log:printError("Recording attached, but some Sales department Drive permission grants failed " +
                    "(best-effort, not retrying).", deptShareResult);
        }
    }

    // The recording is attached -- mark ATTACHED and return success (200) regardless of how
    // sharing went. Sharing failures are logged above for manual follow-up; they deliberately
    // do NOT trigger a Pub/Sub retry. (A DB write failure below still surfaces as an error, so
    // a genuinely transient DB problem is retried.)
    _ = check database:upsertMeetRecording({
        spaceName: tracked.spaceName,
        title: tracked.title,
        googleEventId: tracked.googleEventId,
        organizer: tracked.organizer,
        startTime: tracked.startTime,
        endTime: tracked.endTime,
        internalParticipants: tracked.internalParticipants,
        externalParticipants: tracked.externalParticipants,
        recordingState: database:ATTACHED,
        driveFileId: fileId
    }, SYSTEM_ACTOR);
}

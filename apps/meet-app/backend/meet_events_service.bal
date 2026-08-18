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
import ballerina/jwt;
import ballerina/lang.array;
import ballerina/lang.'string as strings;
import ballerina/lang.value;
import ballerina/log;

configurable int meetEventsListenerPort = 9091;

// Authentication of the Pub/Sub push. This endpoint must sit unauthenticated at the Choreo
// gateway (Google's push carries no Choreo credential), so the caller is authenticated HERE
// instead, by verifying the Google-signed OIDC token Pub/Sub attaches when the push
// subscription is configured with a service account. Gated on `pubsubAuthEnabled` so the code
// can be deployed first and enforcement switched on only once the push subscription has been
// (re)created with `--push-auth-service-account`; otherwise real messages -- which would not
// yet carry a token -- would be rejected.
configurable boolean pubsubAuthEnabled = false;
// The service account set as the push subscription's auth identity; must equal the token's
// `email` claim.
configurable string pubsubPushServiceAccount = "";
// The audience the token must carry -- the value passed to `--push-auth-token-audience`, or
// the push endpoint URL if no override was set.
configurable string pubsubPushAudience = "";

// Google's OIDC issuer and public-key (JWKS) endpoint for verifying Pub/Sub push tokens.
const string GOOGLE_OIDC_ISSUER = "https://accounts.google.com";
const string GOOGLE_JWKS_URL = "https://www.googleapis.com/oauth2/v3/certs";

# Verifies the Google-signed OIDC token on a Pub/Sub push. Returns an error (which the caller
# turns into a 401) if enforcement is on and the token is missing, malformed, wrongly signed,
# or does not carry the expected issuer/audience/service-account. A no-op when enforcement is
# off.
#
# + authorization - The raw `Authorization` header value (expected `Bearer <jwt>`)
# + return - `()` if authenticated (or enforcement disabled), else an error
isolated function verifyPubsubPush(string? authorization) returns error? {
    if !pubsubAuthEnabled {
        return;
    }
    if authorization is () || !authorization.startsWith("Bearer ") {
        return error("Missing or malformed Authorization header on Pub/Sub push.");
    }
    string token = authorization.substring(7).trim();
    jwt:ValidatorConfig validatorConfig = {
        issuer: GOOGLE_OIDC_ISSUER,
        audience: pubsubPushAudience,
        signatureConfig: {jwksConfig: {url: GOOGLE_JWKS_URL}}
    };
    jwt:Payload payload = check jwt:validate(token, validatorConfig);
    anydata email = payload["email"];
    anydata emailVerified = payload["email_verified"];
    if email != pubsubPushServiceAccount {
        return error(string `Pub/Sub push token 'email' claim did not match the expected push service account.`);
    }
    if emailVerified != true {
        return error("Pub/Sub push token 'email_verified' claim was not true.");
    }
    return;
}

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

# Meet event notification payload, once decoded -- a recording-ready, transcript-ready, or
# smart-notes-ready notification. Google sends exactly one of these, distinguished by
# which top-level key is present (the Workspace Events subscription is configured with all
# three event types). Left open for the same reason as PubSubPushEnvelope above.
#
# + recording - Present for a recording-ready notification
# + transcript - Present for a transcript-ready notification
# + smartNote - Present for a smart-notes-ready notification
type MeetEventEnvelope record {
    record {
        string name;
    } recording?;
    record {
        string name;
    } transcript?;
    record {
        string name;
    } smartNote?;
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
// This endpoint is unauthenticated at the Choreo gateway (Google's Pub/Sub push carries no
// gateway credential), so the caller is authenticated in-app: when pubsubAuthEnabled is set,
// verifyPubsubPush() validates the Google-signed OIDC token on every push; when disabled
// (the staged-rollout default) verification is skipped.
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

    # + authorization - `Authorization: Bearer <OIDC JWT>` header Pub/Sub attaches when the
    #   push subscription is configured with an auth service account
    # + envelope - The Pub/Sub push envelope
    # + return - 401 if the push token is missing/invalid (enforcement on); 200 once processed,
    #   or if the message is permanently unparseable (retrying a malformed message would never
    #   help); 503 on a genuine processing failure, since Pub/Sub retries non-2xx responses
    #   with backoff automatically
    resource function post .(@http:Header {name: "Authorization"} string? authorization,
            @http:Payload PubSubPushEnvelope envelope)
            returns http:Ok|http:Unauthorized|http:ServiceUnavailable {
        error? authResult = verifyPubsubPush(authorization);
        if authResult is error {
            log:printError("Rejected unauthenticated/invalid Pub/Sub push.", authResult);
            return <http:Unauthorized>{body: {message: "Unauthorized."}};
        }

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
        MeetEventEnvelope|error event = value:fromJsonStringWithType(decodedString);
        if event is error {
            log:printError("Could not parse Meet event payload.", event);
            return <http:Ok>{body: {message: "ignored"}};
        }

        record {string name;}? recording = event?.recording;
        record {string name;}? transcript = event?.transcript;
        record {string name;}? smartNote = event?.smartNote;

        error? result;
        if recording is record {string name;} {
            result = processRecordingReady(recording.name);
        } else if transcript is record {string name;} {
            result = processTranscriptReady(transcript.name);
        } else if smartNote is record {string name;} {
            result = processSmartNotesReady(smartNote.name);
        } else {
            log:printError("Meet event payload had none of 'recording', 'transcript', 'smartNote'; ignoring.");
            return <http:Ok>{body: {message: "ignored"}};
        }

        if result is error {
            log:printError("Failed to process Meet event.", result);
            return <http:ServiceUnavailable>{body: {message: "Failed to process Meet event; retry."}};
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

    // Google Meet names the recording file itself after the meeting code and a timestamp
    // Replace it with the actual event title + start time.
    error? renameResult = driveservice:renameFile(fileId, string `${tracked.title} (${tracked.startTime})`);
    if renameResult is error {
        log:printError("Could not rename the recording's Drive file (best-effort, not retrying).", renameResult);
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
            driveFileId: fileId,
            opportunityId: tracked.opportunityId,
            opportunityDetails: tracked.opportunityDetails
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
        driveFileId: fileId,
        opportunityId: tracked.opportunityId,
        opportunityDetails: tracked.opportunityDetails
    }, SYSTEM_ACTOR);
}

# Mirrors processRecordingReady, but for the transcript pipeline: resolves the transcript
# to its Drive (Google Doc) file, attaches it to the calendar event, shares it, and marks
# the row's transcript state -- tracked independently of recording_state via a dedicated
# narrow UPDATE (updateMeetTranscript) rather than the upsert used for recordings, since
# not every meeting has a transcript and this must never touch the recording columns.
#
# + transcriptName - Full resource name of the transcript
# + return - Error if a retry-worthy step failed
isolated function processTranscriptReady(string transcriptName) returns error? {
    driveservice:TranscriptInfoResponse info = check driveservice:resolveTranscript(transcriptName);
    string spaceName = info.spaceName;
    string fileId = info.fileId;

    database:MeetRecordingRow? tracked = check database:getMeetRecordingBySpaceName(spaceName);
    if tracked is () {
        log:printError(string `No registered event found for space ${spaceName}; skipping.`);
        return;
    }

    error? attachResult = calendar:attachRecording(tracked.organizer, tracked.googleEventId, fileId,
            "Meeting Transcript", "application/vnd.google-apps.document");
    if attachResult is error {
        check database:updateMeetTranscript(spaceName, database:FAILED, fileId, SYSTEM_ACTOR);
        return attachResult;
    }

    string:RegExp commaSplit = re `,`;
    string[] internalEmails = tracked.internalParticipants.length() > 0
        ? commaSplit.split(tracked.internalParticipants).map(e => e.trim())
        : [];
    // Same internal-only rationale as processRecordingReady: external participants can't
    // be granted Drive access (cross-domain sharing is blocked org-wide), so including
    // them here would keep this permanently FAILED and stuck on Pub/Sub retry.
    string[] participantEmails = [tracked.organizer, ...internalEmails];

    // Best-effort, same reasoning as the recording flow: sharing failures must never fail
    // this function, or a permanent grant failure retries forever, re-attaching and
    // re-sharing on every retry. sendNotificationEmail is false here (unlike recording's
    // participant grant) -- recording, transcript, and smart notes arrive as three
    // separate, independently-timed notifications for the same meeting, and participants
    // already got one "shared with you" email off the recording; access is still granted
    // silently, discoverable via the calendar event's accumulating attachments.
    driveservice:GrantResult[]|error shareResult = driveservice:grantAccess(fileId, participantEmails, false);
    if shareResult is error {
        log:printError("Transcript attached, but some participant Drive permission grants failed " +
                "(best-effort, not retrying).", shareResult);
    }

    string[]|error salesDepartmentEmails = people:getSalesDepartmentEmails();
    if salesDepartmentEmails is error {
        log:printError("Could not fetch Sales department list; skipping their access grant for this transcript.",
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
            log:printError("Transcript attached, but some Sales department Drive permission grants failed " +
                    "(best-effort, not retrying).", deptShareResult);
        }
    }

    check database:updateMeetTranscript(spaceName, database:ATTACHED, fileId, SYSTEM_ACTOR);
}

# Mirrors processTranscriptReady, but for smart notes ("Take Notes with Gemini") -- a
# separate Google Doc artifact, resolved via its own drive-service endpoint and tracked
# via its own dedicated narrow UPDATE (updateMeetSmartNotes), independent of both
# recording_state and transcript_state.
#
# + smartNotesName - Full resource name of the smart notes
# + return - Error if a retry-worthy step failed
isolated function processSmartNotesReady(string smartNotesName) returns error? {
    driveservice:SmartNotesInfoResponse info = check driveservice:resolveSmartNotes(smartNotesName);
    string spaceName = info.spaceName;
    string fileId = info.fileId;

    database:MeetRecordingRow? tracked = check database:getMeetRecordingBySpaceName(spaceName);
    if tracked is () {
        log:printError(string `No registered event found for space ${spaceName}; skipping.`);
        return;
    }

    error? attachResult = calendar:attachRecording(tracked.organizer, tracked.googleEventId, fileId,
            "Meeting Notes", "application/vnd.google-apps.document");
    if attachResult is error {
        check database:updateMeetSmartNotes(spaceName, database:FAILED, fileId, SYSTEM_ACTOR);
        return attachResult;
    }

    string:RegExp commaSplit = re `,`;
    string[] internalEmails = tracked.internalParticipants.length() > 0
        ? commaSplit.split(tracked.internalParticipants).map(e => e.trim())
        : [];
    // Same internal-only rationale as processRecordingReady/processTranscriptReady:
    // external participants can't be granted Drive access (cross-domain sharing is
    // blocked org-wide), so including them here would keep this permanently FAILED and
    // stuck on Pub/Sub retry.
    string[] participantEmails = [tracked.organizer, ...internalEmails];

    // Best-effort, same reasoning as the other two flows: sharing failures must never
    // fail this function, or a permanent grant failure retries forever, re-attaching and
    // re-sharing on every retry. sendNotificationEmail is false here for the same reason
    // as processTranscriptReady -- avoid a third "shared with you" email for the same
    // meeting; access is still granted silently.
    driveservice:GrantResult[]|error shareResult = driveservice:grantAccess(fileId, participantEmails, false);
    if shareResult is error {
        log:printError("Smart notes attached, but some participant Drive permission grants failed " +
                "(best-effort, not retrying).", shareResult);
    }

    string[]|error salesDepartmentEmails = people:getSalesDepartmentEmails();
    if salesDepartmentEmails is error {
        log:printError("Could not fetch Sales department list; skipping their access grant for these smart notes.",
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
            log:printError("Smart notes attached, but some Sales department Drive permission grants failed " +
                    "(best-effort, not retrying).", deptShareResult);
        }
    }

    check database:updateMeetSmartNotes(spaceName, database:ATTACHED, fileId, SYSTEM_ACTOR);
}

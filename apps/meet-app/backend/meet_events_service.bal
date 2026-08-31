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
import meet_app.salesentity;

import ballerina/http;
import ballerina/jwt;
import ballerina/lang.array;
import ballerina/lang.'string as strings;
import ballerina/lang.value;
import ballerina/log;
import ballerina/time;

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
service /meet\-artifacts on new http:Listener(meetEventsListenerPort) {

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
    error? renameResult = driveservice:renameFile(fileId, recordingTitle(tracked));
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

    logCallActivityIfComplete(spaceName);
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

    logCallActivityIfComplete(spaceName);
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

    logCallActivityIfComplete(spaceName);
}

// Drive view links are built from the file ID rather than asked for, since drive-service
// returns only the ID. The two shapes are not interchangeable: a recording is an MP4, a
// plain Drive file that opens under drive.google.com/file; a transcript and smart notes are
// native Google Docs, which only open properly under docs.google.com/document.
// How many external attendees are worth a contact lookup before giving up -- see
// resolveCallContactId.
const int MAX_CONTACT_LOOKUPS = 5;

const string DRIVE_FILE_VIEW_URL_PREFIX = "https://drive.google.com/file/d/";
const string GOOGLE_DOC_VIEW_URL_PREFIX = "https://docs.google.com/document/d/";

# The name the recording's Drive file carries, which is also what the Salesforce activity
# uses as its subject. Google names the file after the raw meeting code and a timestamp;
# processRecordingReady renames it to this. Defined once so the rename and the activity
# subject cannot drift apart into two different "recording titles".
#
# + tracked - The meeting row
# + return - Display title of the recording
isolated function recordingTitle(database:MeetRecordingRow tracked) returns string =>
    string `${tracked.title} (${tracked.startTime})`;

# Length of the meeting in seconds, from its stored start and end times.
#
# Both are stored as naive `yyyy-MM-dd HH:mm:ss` with no zone, so both are read as UTC here
# -- the offset is the same on each and cancels out of the difference. Returns `()` rather
# than an error if either fails to parse, since a missing duration must not stop the call
# being logged.
#
# + tracked - The meeting row
# + return - Duration in whole seconds, or `()` if it couldn't be worked out
isolated function meetingDurationSeconds(database:MeetRecordingRow tracked) returns int? {
    time:Utc|error 'start = time:utcFromString(toRfc3339(tracked.startTime));
    time:Utc|error end = time:utcFromString(toRfc3339(tracked.endTime));
    if 'start is error || end is error {
        return;
    }
    decimal seconds = time:utcDiffSeconds(end, 'start);
    if seconds <= 0d {
        return;
    }
    return <int>seconds.round(0);
}

# Turns the DB's naive `yyyy-MM-dd HH:mm:ss` into the RFC 3339 shape time:utcFromString
# expects. See meetingDurationSeconds for why pinning it to Z is safe here.
#
# + dbTimestamp - Timestamp as stored
# + return - RFC 3339 timestamp
isolated function toRfc3339(string dbTimestamp) returns string {
    string:RegExp space = re ` `;
    return string `${space.replaceAll(dbTimestamp, "T")}Z`;
}

# The date the call took place, as Salesforce wants it.
#
# Salesforce stores a date only on this kind of activity -- there is no creatable
# time-of-day field -- so the meeting's start timestamp is cut to its `yyyy-MM-dd` prefix.
# The read query formats start_time with DATE_FORMAT so it is always long enough, but the
# length is checked anyway: substring() panics rather than erroring on a short string, and a
# panic here would take down the webhook over a merely-missing optional field.
#
# + startTime - Meeting start timestamp as stored
# + return - `yyyy-MM-dd` date, or `()` if the timestamp wasn't the expected shape
isolated function callDate(string startTime) returns string? {
    if startTime.length() < 10 {
        return;
    }
    return startTime.substring(0, 10);
}

# The activity's `comment`, carrying the view links for whichever artifacts resolved.
#
# This is the field the whole feature exists to deliver: it is what a rep opening the
# opportunity in Salesforce actually sees. Salesforce allows 32,000 characters here, so
# links comfortably fit -- but a transcript's contents would not, which is why only links go
# in.
#
# + tracked - The meeting row, after all three artifacts attached
# + return - Comment body for the call activity
isolated function buildCallActivityComment(database:MeetRecordingRow tracked) returns string {
    string[] lines = [
        string `Auto-logged from the WSO2 Meet recording pipeline for "${tracked.title}".`,
        ""
    ];
    string? recordingFileId = tracked.driveFileId;
    if recordingFileId is string {
        lines.push(string `Recording: ${DRIVE_FILE_VIEW_URL_PREFIX}${recordingFileId}/view`);
    }
    string? transcriptFileId = tracked.transcriptFileId;
    if transcriptFileId is string {
        lines.push(string `Transcript: ${GOOGLE_DOC_VIEW_URL_PREFIX}${transcriptFileId}/edit`);
    }
    string? smartNotesFileId = tracked.smartNotesFileId;
    if smartNotesFileId is string {
        lines.push(string `Smart notes: ${GOOGLE_DOC_VIEW_URL_PREFIX}${smartNotesFileId}/edit`);
    }
    return string:'join("\n", ...lines);
}

# Finds the Salesforce Contact for the call by looking up the external attendees.
#
# Only external (non-wso2.com) attendees are tried: the internal ones are WSO2 staff, who
# are Salesforce Users rather than Contacts of the customer account, so looking them up
# would either miss or attach the wrong person. The first email that resolves wins --
# Salesforce's activity model has room for exactly one `WhoId`, so there is nothing useful
# to do with a second match. A lookup failure is logged and skipped rather than propagated:
# `contactId` is optional, and losing it must not cost the whole activity.
#
# + tracked - The meeting row
# + return - Salesforce Contact Id, or `()` if no external attendee resolved to one
isolated function resolveCallContactId(database:MeetRecordingRow tracked) returns string? {
    if tracked.externalParticipants.trim().length() == 0 {
        return;
    }
    string:RegExp commaSplit = re `,`;
    int attempts = 0;
    foreach string rawEmail in commaSplit.split(tracked.externalParticipants) {
        string email = rawEmail.trim();
        if email.length() == 0 {
            continue;
        }
        // Bounded on purpose. This runs inside the Pub/Sub push response, so every lookup
        // spends the subscription's acknowledgement deadline; a large external invite list
        // would otherwise mean one sequential HTTP round trip per attendee. The first few
        // attendees are overwhelmingly where the match is, and a miss only costs the
        // optional contactId.
        if attempts >= MAX_CONTACT_LOOKUPS {
            log:printInfo(string `Stopped contact lookup after ${MAX_CONTACT_LOOKUPS} external attendees ` +
                    string `for space ${tracked.spaceName}; logging the call without a contact.`);
            break;
        }
        attempts += 1;
        string?|error contactId = salesentity:findContactIdByEmail(email);
        if contactId is error {
            log:printError("Contact lookup failed for an external attendee; trying the next one.", contactId);
            continue;
        }
        if contactId is string {
            return contactId;
        }
    }
    return;
}

# Logs the meeting as a completed call against its Salesforce Opportunity -- but only once
# the recording, the transcript AND the smart notes have all reached ATTACHED.
#
# The three artifacts arrive as three independent Pub/Sub notifications in no guaranteed
# order, so this runs at the end of all three processors and simply returns unless it finds
# the row fully complete. Whichever notification lands last is the one that actually logs.
#
# Deliberately BEST-EFFORT, in the same spirit as the Drive sharing in the three processors:
# every failure is logged and swallowed rather than returned. Returning an error would make
# the webhook answer 503, and Pub/Sub would then retry the whole notification -- re-running
# the attach and re-sharing the file with everyone, which is the exact retry-storm this
# pipeline was already bitten by once. The attachments are the primary deliverable and are
# already in place by this point.
#
# + spaceName - Resource name of the Meet space, the lookup key
isolated function logCallActivityIfComplete(string spaceName) {
    database:MeetRecordingRow|error? tracked = database:getMeetRecordingBySpaceName(spaceName);
    if tracked is error {
        log:printError("Could not re-read the meeting row to check call-activity readiness.", tracked);
        return;
    }
    if tracked is () {
        return;
    }

    // The gate. All three must be ATTACHED -- note transcript_state/smart_notes_state are
    // NULL for a meeting that never produced that artifact, so those meetings never log a
    // call. That is the specified behaviour, not an oversight.
    if tracked.recordingState != database:ATTACHED || tracked.transcriptState != database:ATTACHED
        || tracked.smartNotesState != database:ATTACHED {
        return;
    }

    // Cheap pre-check before the claim, so the common "already done" case costs one read
    // instead of a write. The claim below is what actually makes this safe.
    if tracked.callActivityId is string {
        return;
    }

    // Without an opportunity there is nothing to log the call against: the API requires
    // exactly one of opportunityId/leadId, and this pipeline never has a lead. Meetings
    // booked without picking a deal in the add-on land here.
    string? opportunityId = tracked.opportunityId;
    if opportunityId is () {
        log:printInfo(string `Meeting for space ${spaceName} has all artifacts attached but no opportunity; ` +
                "skipping the Salesforce call activity.");
        return;
    }

    boolean|error claimed = database:claimCallActivity(spaceName, SYSTEM_ACTOR);
    if claimed is error {
        log:printError("Could not claim the Salesforce call-activity write; skipping it.", claimed);
        return;
    }
    if !claimed {
        // Another run (or a redelivered notification) already holds it.
        return;
    }

    salesentity:CreateCallActivityInput input = {
        subject: recordingTitle(tracked),
        // callType is deliberately left unset. It maps to Salesforce's Task.CallType, a
        // picklist meaning the direction of the call (Inbound/Outbound/Internal); the
        // Opportunity RecordType we have on the snapshot answers a different question and
        // would be rejected outright by a restricted picklist. Omitted and null are treated
        // identically by the service, which normalises both to "not supplied".
        occurredOn: callDate(tracked.startTime),
        comment: buildCallActivityComment(tracked),
        opportunityId: opportunityId,
        contactId: resolveCallContactId(tracked),
        durationSeconds: meetingDurationSeconds(tracked)
    };

    string|error activityId = salesentity:createCallActivity(input);
    if activityId is error {
        log:printError(string `Failed to log the Salesforce call activity for space ${spaceName}; ` +
                "releasing the claim so it can be retried.", activityId);
        error? released = database:releaseCallActivityClaim(spaceName, SYSTEM_ACTOR);
        if released is error {
            log:printError(string `Could not release the call-activity claim for space ${spaceName}; ` +
                    "the row will stay marked in-progress and needs clearing by hand.", released);
        }
        return;
    }

    error? recorded = database:setCallActivityId(spaceName, activityId, SYSTEM_ACTOR);
    if recorded is error {
        log:printError(string `Logged Salesforce call activity ${activityId} for space ${spaceName}, but could ` +
                "not record its id; the row still holds the in-progress marker, which keeps it from being " +
                "logged twice.", recorded);
        return;
    }
    log:printInfo(string `Logged Salesforce call activity ${activityId} for space ${spaceName}.`);
}

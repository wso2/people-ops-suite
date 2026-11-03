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
import meet_app.echobackend;
import meet_app.people;
import meet_app.salesentity;

import ballerina/http;
import ballerina/jwt;
import ballerina/lang.array;
import ballerina/lang.'string as strings;
import ballerina/lang.value;
import ballerina/log;
import ballerina/time;
import ballerinax/googleapis.calendar as gcalendar;

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

// The add-on's call type for a recorded WSO2-only discussion about a deal or account, and
// the Salesforce Task.CallType picklist value its call activity is logged with.
const string INTERNAL_MEETING_TYPE = "internal";
const string SF_CALL_TYPE_INTERNAL = "Internal";

// The add-on's call type for an Inbound call, the one that targets a Salesforce Lead.
const string INBOUND_MEETING_TYPE = "inbound";

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

    // A call can hold several recordings -- each stop and restart is its own resource -- so
    // "already done" is decided per recording, not per meeting. The meeting's own columns
    // count too: they hold the part the pipeline attached before parts were kept separately.
    if check isPartAttached(database:RECORDING_PART, recordingName, fileId)
        || (tracked.recordingState == database:ATTACHED && tracked.driveFileId == fileId) {
        log:printInfo(string `Recording ${recordingName} is already attached; skipping.`);
        // Recorded again so a part copied in by the V6 migration picks up its real name.
        check database:upsertMeetingPart(database:RECORDING_PART,
                partPayload(tracked.meetingId, recordingName, info, database:ATTACHED), SYSTEM_ACTOR);
        // Still checked, because the artifact being attached does NOT mean the call
        // activity was logged.
        logCallActivityIfComplete(spaceName);
        return;
    }

    // The meeting's own columns keep holding the first part, for the readers that know only
    // one recording per meeting. A later part never overwrites them.
    boolean isFirstPart = tracked.recordingState != database:ATTACHED;

    // Google Meet names the recording file itself after the meeting code and a timestamp
    // Replace it with the actual event title + start time.
    error? renameResult = driveservice:renameFile(fileId, recordingTitle(tracked));
    if renameResult is error {
        log:printError("Could not rename the recording's Drive file (best-effort, not retrying).", renameResult);
    }

    error? attachResult = calendar:attachRecording(tracked.organizer, tracked.googleEventId, fileId,
            RECORDING_ATTACHMENT_TITLE, "video/mp4");
    if attachResult is error {
        check database:upsertMeetingPart(database:RECORDING_PART,
                partPayload(tracked.meetingId, recordingName, info, database:FAILED), SYSTEM_ACTOR);
        if !isFirstPart {
            return attachResult;
        }
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

    // The recording is attached -- mark ATTACHED and return success (200) regardless of how
    // sharing went. Sharing failures are logged above for manual follow-up; they deliberately
    // do NOT trigger a Pub/Sub retry. (A DB write failure below still surfaces as an error, so
    // a genuinely transient DB problem is retried.)
    check database:upsertMeetingPart(database:RECORDING_PART,
            partPayload(tracked.meetingId, recordingName, info, database:ATTACHED), SYSTEM_ACTOR);
    if isFirstPart {
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

    // Started, not awaited -- see shareWithDepartments for why this must not hold up the
    // webhook's response. Started only AFTER the ATTACHED write: if that write fails, the
    // handler returns 503 and Pub/Sub redelivers, and a share started before it would then
    // run twice, concurrently, on the same file.
    _ = start shareWithDepartments(fileId, participantEmails.cloneReadOnly(), "Recording");

    logCallActivityIfComplete(spaceName);
}

# Resolves the transcript to its Drive (Google Doc) file, attaches it to the calendar event, shares it, and marks
# the row's transcript state 
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

    // Pub/Sub redelivers whenever it does not get a 200 in time, and without this the
    // handler starts from the top every time: re-attaching the file, renaming it again,
    // and re-running the participant grant. Decided per transcript, since a call can hold
    // several -- see processRecordingReady.
    if check isPartAttached(database:TRANSCRIPT_PART, transcriptName, fileId)
        || (tracked.transcriptState == database:ATTACHED && tracked.transcriptFileId == fileId) {
        log:printInfo(string `Transcript ${transcriptName} is already attached; skipping.`);
        check database:upsertMeetingPart(database:TRANSCRIPT_PART,
                partPayload(tracked.meetingId, transcriptName, info, database:ATTACHED), SYSTEM_ACTOR);
        // Notified again, because the transcript being attached does NOT mean echo-backend heard
        // about it: the first attempt may have failed. echo-backend ignores a meeting it already has.
        _ = start echobackend:notifyTranscriptReady(tracked.meetingId);
        // Still checked, because the artifact being attached does NOT mean the call
        // activity was logged.
        logCallActivityIfComplete(spaceName);
        return;
    }

    // The meeting's own columns keep holding the first transcript -- see processRecordingReady.
    boolean isFirstPart = tracked.transcriptState != database:ATTACHED;

    error? attachResult = calendar:attachRecording(tracked.organizer, tracked.googleEventId, fileId,
            TRANSCRIPT_ATTACHMENT_TITLE, "application/vnd.google-apps.document");
    if attachResult is error {
        check database:upsertMeetingPart(database:TRANSCRIPT_PART,
                partPayload(tracked.meetingId, transcriptName, info, database:FAILED), SYSTEM_ACTOR);
        if isFirstPart {
            check database:updateMeetTranscript(spaceName, database:FAILED, fileId, SYSTEM_ACTOR);
        }
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
    // re-sharing on every retry. sendNotificationEmail is false here 
    driveservice:GrantResult[]|error shareResult = driveservice:grantAccess(fileId, participantEmails, false);
    if shareResult is error {
        log:printError("Transcript attached, but some participant Drive permission grants failed " +
                "(best-effort, not retrying).", shareResult);
    }

    // transcriptName is stored alongside the file id: the Drive document is the transcript
    // as prose, while this resource name is what reaches Meet's timed entries — the only
    // form a transcript synchronised to the recording can be built from.
    check database:upsertMeetingPart(database:TRANSCRIPT_PART,
            partPayload(tracked.meetingId, transcriptName, info, database:ATTACHED), SYSTEM_ACTOR);
    if isFirstPart {
        check database:updateMeetTranscript(spaceName, database:ATTACHED, fileId, SYSTEM_ACTOR, transcriptName);
    }

    // Tell echo-backend now so it starts extracting the MEDDPICC answers immediately instead of
    // at its next poll. Started, not awaited, and only after the ATTACHED write it reads; it
    // can never fail this function, and a missed call is caught by echo-backend's own poll.
    _ = start echobackend:notifyTranscriptReady(tracked.meetingId);

    // Started, not awaited, and only after the ATTACHED write -- see processRecordingReady.
    // Skipped when the transcript IS the smart-notes document: with Gemini note-taking on, Meet
    // writes the transcript into the notes doc, so both artifacts resolve to one file. Checked
    // across every smart-notes part, since a call can hold several.
    if (tracked.smartNotesState == database:ATTACHED && tracked.smartNotesFileId == fileId)
        || isSharedDocument(database:SMART_NOTE_PART, tracked.meetingId, fileId) {
        log:printInfo(string `Transcript for space ${spaceName} is the smart-notes document; ` +
                "its department share is not repeated.");
    } else {
        _ = start shareWithDepartments(fileId, participantEmails.cloneReadOnly(), "Transcript");
    }

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

    // Pub/Sub redelivers whenever it does not get a 200 in time, and without this the
    // handler starts from the top every time: re-attaching the file, renaming it again,
    // and re-running the participant grant.
    // Decided per smart-notes session, since a call can hold several -- see processRecordingReady.
    if check isPartAttached(database:SMART_NOTE_PART, smartNotesName, fileId)
        || (tracked.smartNotesState == database:ATTACHED && tracked.smartNotesFileId == fileId) {
        log:printInfo(string `Smart notes ${smartNotesName} are already attached; skipping.`);
        check database:upsertMeetingPart(database:SMART_NOTE_PART,
                partPayload(tracked.meetingId, smartNotesName, info, database:ATTACHED), SYSTEM_ACTOR);

        logCallActivityIfComplete(spaceName);
        return;
    }

    // The meeting's own columns keep holding the first smart notes -- see processRecordingReady.
    boolean isFirstPart = tracked.smartNotesState != database:ATTACHED;

    error? attachResult = calendar:attachRecording(tracked.organizer, tracked.googleEventId, fileId,
            SMART_NOTES_ATTACHMENT_TITLE, "application/vnd.google-apps.document");
    if attachResult is error {
        check database:upsertMeetingPart(database:SMART_NOTE_PART,
                partPayload(tracked.meetingId, smartNotesName, info, database:FAILED), SYSTEM_ACTOR);
        if isFirstPart {
            check database:updateMeetSmartNotes(spaceName, database:FAILED, fileId, SYSTEM_ACTOR);
        }
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
    // as processTranscriptReady.
    driveservice:GrantResult[]|error shareResult = driveservice:grantAccess(fileId, participantEmails, false);
    if shareResult is error {
        log:printError("Smart notes attached, but some participant Drive permission grants failed " +
                "(best-effort, not retrying).", shareResult);
    }

    check database:upsertMeetingPart(database:SMART_NOTE_PART,
            partPayload(tracked.meetingId, smartNotesName, info, database:ATTACHED), SYSTEM_ACTOR);
    if isFirstPart {
        check database:updateMeetSmartNotes(spaceName, database:ATTACHED, fileId, SYSTEM_ACTOR);
    }

    // Started, not awaited, and only after the ATTACHED write -- see processRecordingReady.
    // Skipped when a transcript already resolved to this same document -- see the matching
    // check in processTranscriptReady.
    if (tracked.transcriptState == database:ATTACHED && tracked.transcriptFileId == fileId)
        || isSharedDocument(database:TRANSCRIPT_PART, tracked.meetingId, fileId) {
        log:printInfo(string `Smart notes for space ${spaceName} are the transcript document; ` +
                "its department share is not repeated.");
    } else {
        _ = start shareWithDepartments(fileId, participantEmails.cloneReadOnly(), "Smart notes");
    }

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

// How long before its scheduled start a call may begin and still be that meeting's call, for
// the parts backfill. People join early; a call that starts after the scheduled end is not
// this meeting's.
const decimal BACKFILL_EARLY_START_SECONDS = 1800;

// Meet deletes a call's record 30 days after it ends. A meeting that started longer ago than
// this has nothing left to ask Meet for, so only its calendar event is read.
const decimal MEET_RETENTION_SECONDS = 31d * 24 * 3600;

// The titles the pipeline gives the parts it attaches to the calendar event. The parts
// backfill reads them back to tell the kinds apart, so both use these.
const string RECORDING_ATTACHMENT_TITLE = "Meeting Recording";
const string TRANSCRIPT_ATTACHMENT_TITLE = "Meeting Transcript";
const string SMART_NOTES_ATTACHMENT_TITLE = "Meeting Notes";

# Finds the parts one meeting has no record of and, unless this is a dry run, stores them.
#
# Stores only. The live pipeline attached every part to the calendar event, renamed and shared
# it when its notification arrived; what was lost is the database record, because each part
# overwrote the meeting's single file column. So nothing is attached, renamed or shared again.
#
# Two sources, in this order:
# 1. Meet, for a call still inside its 30 days: every part with its real name and exact times.
# 2. The calendar event, for a meeting of any age: every file the pipeline attached. A part
#    only the event knows gets a placeholder name and no times; its place among the event's
#    attachments -- the order the parts arrived in -- orders it instead.
#
# + candidate - The meeting
# + dryRun - When true, only report
# + return - What was found and done
isolated function backfillMeetingParts(database:PartsBackfillCandidate candidate, boolean dryRun)
        returns PartsBackfillItem {
    PartsBackfillItem item = {
        meetingId: candidate.meetingId,
        title: candidate.title,
        startTime: candidate.startTime,
        callsFound: 0,
        eventAttachments: 0,
        missingParts: [],
        failedParts: [],
        unreadSources: [],
        status: CHECKED
    };
    // Files already reported missing, so a file both sources list is reported once.
    string[] reportedFiles = [];

    int transcriptsAdded = backfillFromMeet(item, candidate, dryRun, reportedFiles);
    transcriptsAdded += backfillFromEvent(item, candidate, dryRun, reportedFiles);
    if item.unreadSources.length() > 0 {
        item.status = INCOMPLETE;
    }

    // echo-backend reads the stored transcripts, so it is told once the meeting has new ones to
    // analyse. Started, not awaited; a missed call is caught by its own poll.
    if transcriptsAdded > 0 {
        _ = start echobackend:notifyTranscriptReady(candidate.meetingId);
    }
    return item;
}

# Source 1: Meet's own list of the meeting's calls and their parts, when still kept.
#
# + item - The meeting's result, updated in place
# + candidate - The meeting
# + dryRun - When true, only report
# + reportedFiles - Files reported missing so far, updated in place
# + return - How many missing transcripts were stored
isolated function backfillFromMeet(PartsBackfillItem item, database:PartsBackfillCandidate candidate, boolean dryRun,
        string[] reportedFiles) returns int {
    time:Utc|error scheduledStart = time:utcFromString(toRfc3339(candidate.startTime));
    if scheduledStart is error {
        log:printError(string `Parts backfill: meeting ${candidate.meetingId} has an unreadable start time.`,
                scheduledStart);
        item.unreadSources.push("meet");
        return 0;
    }
    if time:utcDiffSeconds(time:utcNow(), scheduledStart) > MEET_RETENTION_SECONDS {
        return 0;
    }

    string earliest = time:utcToString(time:utcAddSeconds(scheduledStart, -BACKFILL_EARLY_START_SECONDS));
    driveservice:CallArtifacts[]|error calls =
        driveservice:listSpaceArtifacts(candidate.spaceName, earliest, toRfc3339(candidate.endTime));
    if calls is error {
        log:printError(string `Parts backfill: could not list the calls of meeting ${candidate.meetingId}.`, calls);
        item.unreadSources.push("meet");
        return 0;
    }

    item.callsFound = calls.length();
    int transcriptsAdded = 0;
    foreach driveservice:CallArtifacts call in calls {
        _ = backfillParts(item, database:RECORDING_PART, call, call.recordings, dryRun, reportedFiles);
        transcriptsAdded += backfillParts(item, database:TRANSCRIPT_PART, call, call.transcripts, dryRun,
                reportedFiles);
        _ = backfillParts(item, database:SMART_NOTE_PART, call, call.smartNotes, dryRun, reportedFiles);
    }
    return transcriptsAdded;
}

# Stores each part Meet listed that the meeting has no record of. A part the meeting already
# has is rewritten with what Meet reports, which only gives a part with a placeholder name its
# real name, call and times.
#
# + item - The meeting's result, updated in place
# + kind - Which kind of part
# + call - The call the parts belong to
# + artifacts - The parts Meet listed
# + dryRun - When true, only report
# + reportedFiles - Files reported missing so far, updated in place
# + return - How many missing parts were stored
isolated function backfillParts(PartsBackfillItem item, database:PartKind kind, driveservice:CallArtifacts call,
        driveservice:Artifact[] artifacts, boolean dryRun, string[] reportedFiles) returns int {
    int added = 0;
    foreach driveservice:Artifact artifact in artifacts {
        boolean|error known = isKnownPart(kind, item.meetingId, artifact);
        if known is error {
            log:printError(string `Parts backfill: could not check ${artifact.name}.`, known);
            item.failedParts.push(artifact.name);
            continue;
        }
        if !known {
            item.missingParts.push(artifact.name);
            reportedFiles.push(artifact.fileId);
        }
        if dryRun {
            continue;
        }
        error? stored = database:upsertMeetingPart(kind, {
            meetingId: item.meetingId,
            name: artifact.name,
            conferenceRecord: call.conferenceRecordName,
            driveFileId: artifact.fileId,
            startTime: artifact.startTime,
            endTime: artifact.endTime,
            state: database:ATTACHED
        }, SYSTEM_ACTOR);
        if stored is error {
            log:printError(string `Parts backfill: could not store ${artifact.name}.`, stored);
            item.failedParts.push(artifact.name);
            continue;
        }
        if !known {
            added += 1;
        }
    }
    return added;
}

# Source 2: every file the pipeline attached to the calendar event. Stores the ones the
# meeting has no record of, and records each file's place among the attachments so parts
# without Meet times still come out in the order they arrived.
#
# + item - The meeting's result, updated in place
# + candidate - The meeting
# + dryRun - When true, only report
# + reportedFiles - Files reported missing so far, updated in place
# + return - How many missing transcripts were stored
isolated function backfillFromEvent(PartsBackfillItem item, database:PartsBackfillCandidate candidate, boolean dryRun,
        string[] reportedFiles) returns int {
    gcalendar:Attachment[]|error? attachments =
        calendar:getCalendarEventAttachments(candidate.googleEventId, candidate.organizer);
    if attachments is error {
        log:printError(string `Parts backfill: could not read the event of meeting ${candidate.meetingId}.`,
                attachments);
        item.unreadSources.push("calendar");
        return 0;
    }

    int transcriptsAdded = 0;
    int position = 0;
    foreach gcalendar:Attachment attachment in attachments ?: [] {
        string? fileId = attachment?.fileId;
        database:PartKind? kind = attachmentKind(attachment);
        if fileId is () || kind is () {
            continue;
        }
        int attachmentOrder = position;
        position += 1;
        item.eventAttachments += 1;

        // Prefixed like the V6 placeholders, so Meet's real name, if it ever arrives for this
        // file, replaces it instead of adding the file a second time.
        string name = string `${database:LEGACY_PART_PREFIX}file:${fileId}`;
        boolean|error known = database:hasAttachedPartWithFile(kind, item.meetingId, fileId);
        if known is error {
            log:printError(string `Parts backfill: could not check ${name}.`, known);
            item.failedParts.push(name);
            continue;
        }
        if !known && reportedFiles.indexOf(fileId) == () {
            item.missingParts.push(name);
            reportedFiles.push(fileId);
        }
        if dryRun {
            continue;
        }
        if !known {
            error? stored = database:upsertMeetingPart(kind,
                    {meetingId: item.meetingId, name, driveFileId: fileId, state: database:ATTACHED}, SYSTEM_ACTOR);
            if stored is error {
                log:printError(string `Parts backfill: could not store ${name}.`, stored);
                item.failedParts.push(name);
                continue;
            }
            if kind == database:TRANSCRIPT_PART {
                transcriptsAdded += 1;
            }
        }
        // Not fatal: without it the part is still stored, only possibly out of order.
        error? ordered = database:setPartAttachmentOrder(kind, item.meetingId, fileId, attachmentOrder, SYSTEM_ACTOR);
        if ordered is error {
            log:printError(string `Parts backfill: could not record the order of ${name}.`, ordered);
        }
    }
    return transcriptsAdded;
}

# Which kind of part a calendar attachment is, by the title the pipeline gave it. An MP4
# with another title is a recording too: Meet attaches its own when recording starts on time.
# Anything else is not a part.
#
# + attachment - The event's attachment
# + return - The kind, or () when it is not a part
isolated function attachmentKind(gcalendar:Attachment attachment) returns database:PartKind? {
    match attachment?.title {
        RECORDING_ATTACHMENT_TITLE => {
            return database:RECORDING_PART;
        }
        TRANSCRIPT_ATTACHMENT_TITLE => {
            return database:TRANSCRIPT_PART;
        }
        SMART_NOTES_ATTACHMENT_TITLE => {
            return database:SMART_NOTE_PART;
        }
    }
    if attachment?.mimeType == "video/mp4" {
        return database:RECORDING_PART;
    }
    return;
}

# Whether the meeting already has this part attached, under its real name or -- for a file
# the V6 migration copied in -- under a placeholder with the same file.
#
# + kind - Which kind of part
# + meetingId - The meeting
# + artifact - The part Meet listed
# + return - True if already attached, or Error
isolated function isKnownPart(database:PartKind kind, int meetingId, driveservice:Artifact artifact)
        returns boolean|error =>
    check isPartAttached(kind, artifact.name, artifact.fileId)
        || check database:hasAttachedPartWithFile(kind, meetingId, artifact.fileId);

# Whether this exact part is already recorded as ATTACHED with this file -- the redelivery
# check, per part rather than per meeting.
#
# + kind - Which kind of part
# + name - Meet's resource name for the part
# + fileId - The Drive file the notification resolved to
# + return - True if already attached, or Error
isolated function isPartAttached(database:PartKind kind, string name, string fileId) returns boolean|error {
    database:MeetingPart? part = check database:getMeetingPartByName(kind, name);
    return part is database:MeetingPart && part.state == database:ATTACHED && part.driveFileId == fileId;
}

# Whether the meeting already has an ATTACHED part of the other document kind in this file --
# a transcript and smart notes that are one Google Doc, which is shared with the departments
# once. A failed lookup answers false: sharing a file twice costs repeated grants, while
# skipping a share could leave the departments without it.
#
# + otherKind - The other document kind to look among
# + meetingId - The meeting
# + fileId - The document
# + return - True if the document is already one of those parts
isolated function isSharedDocument(database:PartKind otherKind, int meetingId, string fileId) returns boolean {
    boolean|error shared = database:hasAttachedPartWithFile(otherKind, meetingId, fileId);
    if shared is error {
        log:printError("Could not check whether the document is already shared as another part; " +
                "sharing it anyway.", shared);
        return false;
    }
    return shared;
}

# The part row for a resolved artifact.
#
# + meetingId - Meeting the part belongs to
# + name - Meet's resource name for the part
# + info - What drive-service resolved it to
# + state - Processing state to record
# + return - The payload
isolated function partPayload(int meetingId, string name, driveservice:ArtifactInfoResponse info,
        database:RecordingState state) returns database:MeetingPartPayload => {
    meetingId,
    name,
    conferenceRecord: info?.conferenceRecordName,
    driveFileId: info.fileId,
    startTime: info?.startTime,
    endTime: info?.endTime,
    state
};

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

# The activity's `comment`, carrying the view links for every attached part.
#
# This is the field the whole feature exists to deliver: it is what a rep opening the
# opportunity in Salesforce actually sees. Salesforce allows 32,000 characters here, so
# links comfortably fit -- but a transcript's contents would not, which is why only links go
# in.
#
# The call is logged once, when the first recording, transcript and smart notes are all in, so
# it links every part attached by then; a part that arrives later is not listed.
#
# + tracked - The meeting row, after all three artifacts attached
# + files - Drive file ids of the attached parts, per kind, in the order they happened
# + return - Comment body for the call activity
isolated function buildCallActivityComment(database:MeetRecordingRow tracked, CallFiles files) returns string {
    string[] lines = [
        string `Auto-logged from the WSO2 Meet recording pipeline for "${tracked.title}".`,
        ""
    ];
    addFileLines(lines, "Recording", files.recordings, DRIVE_FILE_VIEW_URL_PREFIX, "/view");
    addFileLines(lines, "Transcript", files.transcripts, GOOGLE_DOC_VIEW_URL_PREFIX, "/edit");
    addFileLines(lines, "Smart notes", files.smartNotes, GOOGLE_DOC_VIEW_URL_PREFIX, "/edit");
    return string:'join("\n", ...lines);
}

# Appends one link per file, numbered only when there is more than one.
#
# + lines - The comment lines so far
# + label - What the files are, e.g. "Recording"
# + fileIds - The files, in order
# + urlPrefix - View URL up to the file id
# + urlSuffix - View URL after the file id
isolated function addFileLines(string[] lines, string label, string[] fileIds, string urlPrefix, string urlSuffix) {
    foreach int i in 0 ..< fileIds.length() {
        string numbered = fileIds.length() > 1 ? string `${label} ${i + 1}` : label;
        lines.push(string `${numbered}: ${urlPrefix}${fileIds[i]}${urlSuffix}`);
    }
}

# The attached files of each kind, for the call activity's comment.
#
# + recordings - Recording file ids, in order
# + transcripts - Transcript file ids, in order
# + smartNotes - Smart notes file ids, in order
type CallFiles record {|
    string[] recordings;
    string[] transcripts;
    string[] smartNotes;
|};

# Gathers every attached part's file for the comment. A kind whose parts cannot be read falls
# back to the meeting's own column, which still holds its first part -- a shorter comment beats
# none, since the call is logged only once.
#
# + tracked - The meeting row
# + return - The files per kind
isolated function attachedCallFiles(database:MeetRecordingRow tracked) returns CallFiles => {
    recordings: attachedFiles(database:RECORDING_PART, tracked.meetingId, tracked.driveFileId),
    transcripts: attachedFiles(database:TRANSCRIPT_PART, tracked.meetingId, tracked.transcriptFileId),
    smartNotes: attachedFiles(database:SMART_NOTE_PART, tracked.meetingId, tracked.smartNotesFileId)
};

isolated function attachedFiles(database:PartKind kind, int meetingId, string? fallbackFileId) returns string[] {
    database:MeetingPart[]|error parts = database:getMeetingParts(kind, meetingId);
    if parts is error {
        log:printError(string `Could not read the meeting's ${kind} parts; the call activity lists only the first.`,
                parts);
        if fallbackFileId is string {
            return [fallbackFileId];
        }
        return [];
    }
    string[] fileIds = [];
    foreach database:MeetingPart part in parts {
        string? fileId = part.driveFileId;
        if part.state == database:ATTACHED && fileId is string && fileIds.indexOf(fileId) == () {
            fileIds.push(fileId);
        }
    }
    return fileIds;
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

# Logs the meeting as a completed call against its Salesforce Opportunity -- or against its
# Account, for the call types that link to a customer rather than to a deal -- but only once
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

    // Without a Salesforce target there is nothing to log the call against: the API requires
    // exactly one of opportunityId/accountId/leadId.
    //
    // An account-type call (`monthly_weekly`, `outbound`) never carries a deal -- the add-on
    // links it straight to the customer -- so it logs against the account instead of being
    // dropped. An Inbound call targets a Salesforce Lead and logs against it. Each is real
    // customer contact and belongs on a timeline. What lands here now is only a meeting tagged
    // for the add-on with nothing picked at all.
    string? opportunityId = tracked.opportunityId;
    string? accountId = opportunityId is () ? tracked.accountId : ();
    string? leadId = opportunityId is () && accountId is () ? tracked.leadId : ();
    if opportunityId is () && accountId is () && leadId is () {
        log:printInfo(string `Meeting for space ${spaceName} has all artifacts attached but no opportunity, ` +
                "account or lead; skipping the Salesforce call activity.");
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
        // callType maps to Salesforce's Task.CallType, a picklist meaning the direction of
        // the call (Inbound/Outbound/Internal). Only an Internal discussion sets it, so the
        // customer's timeline shows it was a WSO2-only call; everything else leaves it unset,
        // since the Opportunity RecordType answers a different question and would be rejected
        // by a restricted picklist. Omitted and null are treated identically by the service.
        callType: tracked.meetingType == INTERNAL_MEETING_TYPE ? SF_CALL_TYPE_INTERNAL : (),
        occurredOn: callDate(tracked.startTime),
        comment: buildCallActivityComment(tracked, attachedCallFiles(tracked)),
        // Exactly one target, picked above in the order deal, account, lead. The add-on writes
        // the deal's own account onto a deal-linked event as well, so a row can genuinely hold
        // both ids -- and the two share one Salesforce field, so sending both is a 400.
        opportunityId: opportunityId,
        accountId: accountId,
        leadId: leadId,
        // A lead takes the Task's WhoId, the field a contact would use, so the service refuses
        // the two together. The lead IS the person on a lead call.
        contactId: leadId is () ? resolveCallContactId(tracked) : (),
        durationSeconds: meetingDurationSeconds(tracked),
        // The organizer is the rep who scheduled and ran the call, so Salesforce should show them
        // as having made it -- not the integration user.
        ownerEmail: tracked.organizer
    };

    string|error activityId = salesentity:createCallActivity(input);
    if activityId is salesentity:CallActivityIndeterminate {
        // Deliberately KEEPS the claim. The activity may already exist in Salesforce; releasing
        // here would let a later notification create a duplicate on the rep's timeline. 
        log:printError(string `Could not confirm whether the Salesforce call activity for space ${spaceName} ` +
                "was created; keeping the claim so it cannot be logged twice. Check Salesforce for an " +
                "activity against this meeting and clear the claim by hand if none exists.", activityId);
        return;
    }
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
    log:printInfo(string `Logged Salesforce call activity ${activityId} for space ${spaceName} against ` +
            (opportunityId is () ? string `account ${accountId ?: ""}` : string `opportunity ${opportunityId}`) +
            ".");
}

# Grants the recording-access departments view access to an artifact, off the response path.
#
# Sharing with the Sales departments is several hundred separate
# Drive calls, one per person; Pub/Sub stops waiting for the webhook after about ten seconds
# and treats the silence as a failed delivery, so it redelivers.
#
# + fileId - Drive file to share
# + participantEmails - Already granted individually; excluded so nobody is granted twice
# + artifact - Names the artifact in log lines ("Recording", "Transcript", "Smart notes")
isolated function shareWithDepartments(string fileId, string[] participantEmails, string artifact) {
    string[]|error salesDepartmentEmails = people:getSalesDepartmentEmails();
    if salesDepartmentEmails is error {
        log:printError(string `Could not fetch Sales department list; skipping their access ` +
                string `grant for this ${artifact.toLowerAscii()}.`, salesDepartmentEmails);
        return;
    }

    string[] extraEmails = [];
    foreach string email in salesDepartmentEmails {
        if participantEmails.indexOf(email) == () {
            extraEmails.push(email);
        }
    }
    // drive-service rejects an empty list with a 400, which would then be logged as a grant
    // failure when in fact there was simply nobody left to grant.
    if extraEmails.length() == 0 {
        return;
    }

    // In batches: one request for a few hundred people outlives the Choreo gateway's 60s limit
    // and is cut off part-way -- see grantAccessInBatches.
    error? deptShareResult = driveservice:grantAccessInBatches(fileId, extraEmails, false);
    if deptShareResult is error {
        log:printError(string `${artifact} attached, but some Sales department Drive permission ` +
                "grants failed (best-effort, not retrying).", deptShareResult);
    }
}

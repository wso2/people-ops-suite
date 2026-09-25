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
import ballerina/http;
import ballerina/url;

# Resolves a recording (from a recording-ready notification) to its Meet space and Drive
# file, via drive-service.
#
# + recordingName - Full resource name of the recording (e.g. `conferenceRecords/abc/recordings/xyz`)
# + return - Space name and Drive file ID, or error
public isolated function resolveRecording(string recordingName) returns RecordingInfoResponse|error {
    string encodedRecordingName = check url:encode(recordingName, "UTF-8");
    http:Response response = check driveServiceClient->get(string `/recordings?name=${encodedRecordingName}`);
    if response.statusCode == 200 {
        json responseJson = check response.getJsonPayload();
        return responseJson.cloneWithType(RecordingInfoResponse);
    }
    json? errorResponseBody = check response.getJsonPayload();
    return error(string `Status: ${response.statusCode}, Response: ${errorResponseBody.toJsonString()}`);
}

# Resolves a transcript (from a transcript-ready notification) to its Meet space and
# Drive (Google Doc) file, via drive-service.
#
# + transcriptName - Full resource name of the transcript (e.g. `conferenceRecords/abc/transcripts/xyz`)
# + return - Space name and Drive file ID, or error
public isolated function resolveTranscript(string transcriptName) returns TranscriptInfoResponse|error {
    string encodedTranscriptName = check url:encode(transcriptName, "UTF-8");
    http:Response response = check driveServiceClient->get(string `/transcripts?name=${encodedTranscriptName}`);
    if response.statusCode == 200 {
        json responseJson = check response.getJsonPayload();
        return responseJson.cloneWithType(TranscriptInfoResponse);
    }
    json? errorResponseBody = check response.getJsonPayload();
    return error(string `Status: ${response.statusCode}, Response: ${errorResponseBody.toJsonString()}`);
}

# Resolves smart notes (from a smart-notes-ready notification) to its Meet space and
# Drive (Google Doc) file, via drive-service.
#
# + smartNotesName - Full resource name of the smart notes (e.g. `conferenceRecords/abc/smartNotes/xyz`)
# + return - Space name and Drive file ID, or error
public isolated function resolveSmartNotes(string smartNotesName) returns SmartNotesInfoResponse|error {
    string encodedSmartNotesName = check url:encode(smartNotesName, "UTF-8");
    http:Response response = check driveServiceClient->get(string `/smart-notes?name=${encodedSmartNotesName}`);
    if response.statusCode == 200 {
        json responseJson = check response.getJsonPayload();
        return responseJson.cloneWithType(SmartNotesInfoResponse);
    }
    json? errorResponseBody = check response.getJsonPayload();
    return error(string `Status: ${response.statusCode}, Response: ${errorResponseBody.toJsonString()}`);
}

# Grants view access to a recording for each person in the list, via drive-service.
#
# + fileId - Drive file ID of the recording
# + emails - Email addresses to grant Viewer access to
# + sendNotificationEmail - Whether Drive should email each person about the new access.
#   Pass true for people who were actually on the call; false for broad, non-participant
#   grants (e.g. every Sales/Channel Sales/Sales Engineering employee) so they don't get a
#   "shared with you" email for every recording.
# + return - Every per-email result, only if all of them succeeded; otherwise an aggregate
#   error carrying the failure count and the distinct reasons (deliberately NOT the email
#   addresses, which are recipient PII we don't put in logs), so a partial failure isn't
#   silently treated as a full success by callers that only check for `error`. The full
#   per-email outcome is still available in the returned results on the success path.
public isolated function grantAccess(string fileId, string[] emails, boolean sendNotificationEmail)
        returns GrantResult[]|error {
    GrantAccessResponse grantResponse = check postGrants(driveServiceClient, fileId, emails, sendNotificationEmail);

    // Aggregate failures WITHOUT the email addresses -- those are recipient PII we don't want
    // in application logs. Keep only a count and the distinct failure reasons (Google's own
    // error strings, which describe the permission problem, not the recipient).
    int failedCount = 0;
    string[] reasons = [];
    foreach GrantResult result in grantResponse.results {
        if !result.granted {
            failedCount += 1;
            addReason(reasons, result.'error ?: "unknown error");
        }
    }
    if failedCount > 0 {
        return error(string `${failedCount} of ${grantResponse.results.length()} Drive permission grant(s) failed. ` +
                string `Reason(s): ${string:'join("; ", ...reasons)}`);
    }
    return grantResponse.results;
}

# Grants view access from department-wide share in batches.
#
# One request for the whole list does not work: drive-service is reached through the Choreo
# gateway, which cuts every request at 60 seconds, and a few hundred Drive writes take several
# minutes. So the list is sent in batches of GRANT_BATCH_SIZE people at a time, one batch after another.
#
# + fileId - Drive file ID to share
# + emails - Email addresses to grant Viewer access to
# + sendNotificationEmail - Whether Drive should email each person about the new access
# + return - An aggregate error (a count and the distinct reasons, never the email addresses)
#   if any grant failed; otherwise nil
public isolated function grantAccessInBatches(string fileId, string[] emails, boolean sendNotificationEmail)
        returns error? {
    int failedCount = 0;
    string[] reasons = [];
    int batchStart = 0;
    while batchStart < emails.length() {
        int batchEnd = int:min(batchStart + GRANT_BATCH_SIZE, emails.length());
        string[] batch = emails.slice(batchStart, batchEnd);
        GrantAccessResponse|error batchResponse =
            postGrants(driveServiceBulkClient, fileId, batch, sendNotificationEmail);
        if batchResponse is error {
            // The whole batch is unaccounted for -- count every address in it as failed.
            failedCount += batch.length();
            addReason(reasons, batchResponse.message());
        } else {
            foreach GrantResult result in batchResponse.results {
                if !result.granted {
                    failedCount += 1;
                    addReason(reasons, result.'error ?: "unknown error");
                }
            }
        }
        batchStart = batchEnd;
    }
    if failedCount > 0 {
        return error(string `${failedCount} of ${emails.length()} Drive permission grant(s) failed. ` +
                string `Reason(s): ${string:'join("; ", ...reasons)}`);
    }
}

# Sends one permissions request to drive-service and returns its per-email results.
#
# + driveClient - Which client to send it with (see client.bal)
# + fileId - Drive file ID to share
# + emails - Email addresses to grant Viewer access to
# + sendNotificationEmail - Whether Drive should email each person about the new access
# + return - drive-service's per-email results, or an error if the request itself failed
isolated function postGrants(http:Client driveClient, string fileId, string[] emails,
        boolean sendNotificationEmail) returns GrantAccessResponse|error {
    http:Request req = new;
    req.setPayload({emails, sendNotificationEmail});
    http:Response response = check driveClient->post(string `/files/${fileId}/permissions`, req);
    if response.statusCode != 200 {
        json? errorResponseBody = check response.getJsonPayload();
        return error(string `Status: ${response.statusCode}, Response: ${errorResponseBody.toJsonString()}`);
    }
    json responseJson = check response.getJsonPayload();
    return responseJson.cloneWithType(GrantAccessResponse);
}

# Adds a failure reason to the list unless it is already there.
#
# + reasons - The distinct reasons collected so far
# + reason - The reason to add
isolated function addReason(string[] reasons, string reason) {
    if reasons.indexOf(reason) == () {
        reasons.push(reason);
    }
}

# Renames a Drive file, via drive-service  used to replace Google Meet's default
# recording filename (meeting code + timestamp, decided entirely on Google's side)
#
# + fileId - Drive file ID of the recording
# + name - New file name
# + return - error, if the rename failed
public isolated function renameFile(string fileId, string name) returns error? {
    http:Request req = new;
    req.setPayload({name});
    http:Response response = check driveServiceClient->patch(string `/files/${fileId}`, req);
    if response.statusCode != 204 {
        json? errorResponseBody = check response.getJsonPayload();
        return error(string `Status: ${response.statusCode}, Response: ${errorResponseBody.toJsonString()}`);
    }
}

# Lists a transcript's timed entries, with speakers resolved.
#
# This is the structured form of the conversation -- who spoke, what they said, and when --
# as opposed to the Drive document, which is the same conversation as prose. Only the
# structured form can drive a player.
#
# + transcriptName - Meet resource name (e.g. `conferenceRecords/abc/transcripts/xyz`)
# + return - The conversation, or an error
public isolated function listTranscript(string transcriptName) returns TranscriptResponse|error {
    string encoded = check url:encode(transcriptName, "UTF-8");
    return driveServiceClient->get(string `/transcripts/entries?name=${encoded}`);
}

# Reads a Google Doc as plain text.
#
# Used for smart notes, which Meet writes only as a Doc -- there is no API giving them back
# as structure the way transcripts have one.
#
# + fileId - Drive file id of the document
# + return - Its text, or an error
public isolated function exportDocumentText(string fileId) returns DocumentTextResponse|error {
    string encoded = check url:encode(fileId, "UTF-8");
    return driveServiceClient->get(string `/files/${encoded}/text`);
}

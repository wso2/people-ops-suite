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
    http:Request req = new;
    req.setPayload({emails, sendNotificationEmail});
    http:Response response = check driveServiceClient->post(string `/files/${fileId}/permissions`, req);
    if response.statusCode != 200 {
        json? errorResponseBody = check response.getJsonPayload();
        return error(string `Status: ${response.statusCode}, Response: ${errorResponseBody.toJsonString()}`);
    }
    json responseJson = check response.getJsonPayload();
    GrantAccessResponse grantResponse = check responseJson.cloneWithType(GrantAccessResponse);

    // Aggregate failures WITHOUT the email addresses -- those are recipient PII we don't want
    // in application logs. Keep only a count and the distinct failure reasons (Google's own
    // error strings, which describe the permission problem, not the recipient).
    int failedCount = 0;
    string[] reasons = [];
    foreach GrantResult result in grantResponse.results {
        if !result.granted {
            failedCount += 1;
            string reason = result.'error ?: "unknown error";
            if reasons.indexOf(reason) == () {
                reasons.push(reason);
            }
        }
    }
    if failedCount > 0 {
        return error(string `${failedCount} of ${grantResponse.results.length()} Drive permission grant(s) failed. ` +
                string `Reason(s): ${string:'join("; ", ...reasons)}`);
    }
    return grantResponse.results;
}

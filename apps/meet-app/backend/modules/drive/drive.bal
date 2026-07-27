// Copyright (c) 2025 WSO2 LLC. (https://www.wso2.com).
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
import meet_app.database;
import ballerina/http;
import ballerina/url;

# Sets file permission for a user on Google Drive.
#
# + fileId - Google Drive file ID.
# + role - The permission role to assign.
# + 'type - The type of the permission.
# + emailAddress - The email of the user to whom the permission will be granted.
# + return - JSON response if successful, else an error
public isolated function setFilePermission(string fileId, DrivePermissionRole role, DrivePermissionType 'type,
        string emailAddress) returns DrivePermissionResponse|error {

    DrivePermissionPayload drivePermissionPayload = {
        role,
        'type,
        emailAddress
    };

    http:Request req = new;
    json drivePermissionPayloadJson = drivePermissionPayload.toJson();
    req.setPayload(drivePermissionPayloadJson);
    http:Response response = check driveClient->post(string `/${fileId}/permissions`, req);

    if response.statusCode == 200 {
        json responseJson = check response.getJsonPayload();
        DrivePermissionResponse drivePermissionResponse = check responseJson.cloneWithType(DrivePermissionResponse);
        return drivePermissionResponse;
    }

    json? errorResponseBody = check response.getJsonPayload();
    return error(string `Status: ${response.statusCode}, Response: ${errorResponseBody.toJsonString()}`);
}

# Grants view access to a recording for each person in the list, one permission per
# person -- not a single domain-wide grant, so access stays limited to people who were
# actually on the call. Uses the Shared Account's own credential, since it owns the file.
#
# + fileId - Drive file ID of the recording
# + emails - Email addresses to grant Viewer access to
# + sendNotificationEmail - Whether Drive should email each person about the new access.
#   Defaults to true (Google's own default) for people who were actually on the call; pass
#   false for broad, non-participant grants (e.g. every Account Manager) so they don't get
#   a "shared with you" email for every recording.
# + return - Error only if a permission grant fails; individual failures are still attempted
#   for the remaining emails rather than aborting the whole batch
public isolated function grantRecordingAccess(string fileId, string[] emails, boolean sendNotificationEmail = true)
        returns error? {
    error[] failures = [];
    foreach string email in emails {
        DrivePermissionPayload payload = {
            role: VIEWER,
            'type: USER,
            emailAddress: email
        };
        http:Request req = new;
        req.setPayload(payload.toJson());
        http:Response|error response = sharedAccountDriveClient->post(
                string `/${fileId}/permissions?sendNotificationEmail=${sendNotificationEmail}`, req);
        if response is error {
            failures.push(response);
            continue;
        }
        if response.statusCode != 200 {
            json|error errorBody = response.getJsonPayload();
            failures.push(error(string `Failed to grant access to ${email}: ${response.statusCode} ${
                errorBody is json ? errorBody.toJsonString() : ""}`));
        }
    }
    if failures.length() > 0 {
        return error(string `${failures.length()} of ${emails.length()} Drive permission grants failed.`,
                cause = failures[0]);
    }
}

# Counts WSO2 recordings within a specific date range.
#
# + startTime - ISO string for start of period
# + endTime - ISO string for end of period
# + region - Region filter
# + return - Count of files or error
public isolated function countWso2RecordingsInDateRange(string startTime, string endTime, string? region) returns int|error {
    string[] titlesToMatch = [];
    if region is string {
        titlesToMatch = check database:getMeetingIdsByRegions(startTime, endTime, region);
        if titlesToMatch.length() == 0 {
            return 0;
        }
    }
    string driveQuery = string `name contains 'WSO2' and 'me' in owners and mimeType = 'video/mp4' and trashed = false and createdTime >= '${startTime}' and createdTime < '${endTime}'`;
    string encodedQuery = check url:encode(driveQuery, "UTF-8");

    int totalCount = 0;
    string? pageToken = ();
    boolean hasMorePages = true;

    while (hasMorePages) {
        string path = string `?q=${encodedQuery}&fields=files(id,name),nextPageToken&pageSize=1000${
            pageToken is string ? "&pageToken=" + pageToken : ""}`;
        http:Response response = check driveClient->get(path);
        if response.statusCode == 200 {
            json payload = check response.getJsonPayload();
            DriveSearchResponse searchResponse = check payload.cloneWithType(DriveSearchResponse);

            if region is string {
                foreach var file in searchResponse.files {
                    string fileName = file.name;
                    boolean isMatch = false;
                    foreach string title in titlesToMatch {
                        if fileName.includes(title) {
                            isMatch = true;
                            break;
                        }
                    }
                    if isMatch {
                        totalCount += 1;
                    }
                }
            } else {
                totalCount += searchResponse.files.length();
            }
            pageToken = searchResponse.nextPageToken;
            hasMorePages = pageToken is string;
        } else {
            return error(string `Drive API Error: ${response.statusCode}`,
                        body = check response.getJsonPayload());
        }
    }

    return totalCount;
}

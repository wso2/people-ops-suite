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

# Counts WSO2 recordings within a specific date range.
#
# + startTime - ISO string for start of period
# + endTime - ISO string for end of period
# + return - Count of files or error
public isolated function countWso2RecordingsInDateRange(string startTime, string endTime) returns int|error {

    string query = string `name contains 'WSO2' and 'me' in owners and mimeType = 'video/mp4' and trashed = false and createdTime >= '${
                    startTime}' and createdTime < '${endTime}'`;

    string encodedQuery = check url:encode(query, "UTF-8");
    string basePath = string `?q=${encodedQuery}&fields=files(id,name),nextPageToken&pageSize=1000`;

    int totalCount = 0;
    string? pageToken = ();
    boolean hasMorePages = true;

    while (hasMorePages) {
        string path = basePath;
        if pageToken is string {
            path = path + "&pageToken=" + pageToken;
        }

        http:Response response = check driveClient->get(path);

        if response.statusCode == 200 {
            json payload = check response.getJsonPayload();
            DriveSearchResponse searchResponse = check payload.cloneWithType(DriveSearchResponse);

            totalCount += searchResponse.files.length();

            if searchResponse.nextPageToken is string {
                pageToken = searchResponse.nextPageToken;
            } else {
                hasMorePages = false;
            }
        } else {
            json errorBody = check response.getJsonPayload();
            return error(string `Drive API Error: ${response.statusCode}`, body = errorBody);
        }
    }

    return totalCount;
}

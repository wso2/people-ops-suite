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

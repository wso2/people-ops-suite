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
import ballerina/test;

configurable string jwtKey = ?;

http:Client testClient = check new (string `http://localhost:9090`);

# Test get user-info resource.
#
# + return - Error if so
@test:Config
public function getUserInfoTest() returns error? {
    // Resource get user\-info.
    http:Response errorResponse = check testClient->/user\-info.get();
    test:assertEquals(errorResponse.statusCode, http:STATUS_INTERNAL_SERVER_ERROR,
            "Assertion Failed! : get user-info HeaderTest");

    // Happy path.
    http:Response successResponse = check testClient->/user\-info.get(headers = {"x-jwt-assertion": jwtKey});
    test:assertEquals(
            successResponse.statusCode,
            http:STATUS_OK,
            string `Assertion Failed! : ${(check successResponse.getJsonPayload()).toString()}`
    );
}

# Test post meetings resource.
#
# + return - Error if so
@test:Config
public function postMeetingsTest() returns error? {
    // Resource get collections.
    http:Response errorResponse = check testClient->/meetings.post(
        {
            "title": "Sample Meeting",
            "description": "Sample Meeting",
            "startTime": "2025-04-01T07:15:00.000Z",
            "endTime": "2025-04-01T07:30:00.000Z",
            "timeZone": "Asia/Colombo",
            "internalParticipants": [
                "user1@example.com"
            ],
            "externalParticipants": [
                "user2@example.com"
            ]
        }
    );
    test:assertEquals(
            errorResponse.statusCode,
            http:STATUS_INTERNAL_SERVER_ERROR,
            "Assertion Failed! : post meetings HeaderTest"
    );

    // Happy path.
    http:Response successResponse = check testClient->/meetings.post(
        {
            "title": "Sample Meeting",
            "description": "Sample Meeting",
            "startTime": "2025-03-25T07:15:00.000Z",
            "endTime": "2025-03-25T07:30:00.000Z",
            "timeZone": "Asia/Colombo",
            "internalParticipants": [
                "user1@example.com"
            ],
            "externalParticipants": [
                "user2@example.com"
            ]
        },
        headers = {"x-jwt-assertion": jwtKey}
    );
    test:assertEquals(
            successResponse.statusCode,
            http:STATUS_CREATED,
            string `Assertion Failed! : ${(check successResponse.getJsonPayload()).toString()}`
    );

    // Invalid media type.
    json|error responseData = successResponse.getJsonPayload();
    if responseData is error {
        test:assertFail("Assertion Failed! : JSON response expected");
    }
}

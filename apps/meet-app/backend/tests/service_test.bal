// Copyright (c) 2025, WSO2 LLC. (https://www.wso2.com). All Rights Reserved.
//
// This software is the property of WSO2 LLC. and its suppliers, if any.
// Dissemination of any information or reproduction of any material contained
// herein in any form is strictly forbidden, unless permitted by WSO2 expressly.
// You may not alter or remove any copyright or other notice from copies of this content. 
import ballerina/http;
import ballerina/test;

configurable string jwtKey = ?;
configurable int servicePort = 9090;

http:Client testClient = check new (string `http://localhost:${servicePort}`);

# Test get user-info resource.
#
# + return - Error if so
@test:Config
public function getUserInfoTest() returns error? {
    // Resource get user\-info.
    http:Response errorResponse = check testClient->/user\-info.get();
    test:assertEquals(errorResponse.statusCode, http:STATUS_INTERNAL_SERVER_ERROR, "Assertion Failed! : get user-info HeaderTest");

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
            "startTime": "2025-03-25T07:15:00.000Z",
            "endTime": "2025-03-25T07:30:00.000Z",
            "timeZone": "Asia/Colombo",
            "wso2Participants": [
                "patric@wso2.com"
            ],
            "externalParticipants": [
                "cptap2n@gmail.com",
                "kiltonmithun@gmail.com"
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
            "wso2Participants": [
                "patric@wso2.com"
            ],
            "externalParticipants": [
                "cptap2n@gmail.com",
                "kiltonmithun@gmail.com"
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

// Copyright (c) 2024, WSO2 LLC. (https://www.wso2.com). All Rights Reserved.
//
// This software is the property of WSO2 LLC. and its suppliers, if any.
// Dissemination of any information or reproduction of any material contained
// herein in any form is strictly forbidden, unless permitted by WSO2 expressly.
// You may not alter or remove any copyright or other notice from copies of this content. 
import ballerina/http;
import ballerina/test;

configurable string jwtKey = ?;

http:Client testClient = check new ("http://localhost:9090");

# Test get user-info resource for the happy path.
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

# Test get collections resource.
#
# + return - Error if so
@test:Config
public function getCollectionsTest() returns error? {
    // Resource get collections.
    http:Response errorResponse = check testClient->/collections.get();
    test:assertEquals(errorResponse.statusCode, http:STATUS_INTERNAL_SERVER_ERROR, "Assertion Failed! : get collections HeaderTest");

    // Happy path.
    http:Response successResponse = check testClient->/collections.get(headers = {"x-jwt-assertion": jwtKey});
    test:assertEquals(
        successResponse.statusCode,
        http:STATUS_OK,
        string `Assertion Failed! : ${(check successResponse.getJsonPayload()).toString()}`
    );

    // Invalid media type.
    json|error responseData = successResponse.getJsonPayload();
    if responseData is error {
        test:assertFail("Assertion Failed! : JSON response expected");
    }

    // Malformed response body. 
    SampleCollection|error convertedData = responseData.cloneWithType();
    if convertedData is error {
        test:assertFail("Assertion Failed! : Malformed response");
    }
}

# Test post collections resource.
#
# + return - Error if so
@test:Config
public function postCollectionsTest() returns error? {
    // Resource get collections.
    http:Response errorResponse = check testClient->/collections.post(
        message = {
            "name": "test 1"
        }
    );
    test:assertEquals(
        errorResponse.statusCode,
        http:STATUS_INTERNAL_SERVER_ERROR,
        "Assertion Failed! : get collections HeaderTest"
    );

    // Happy path.
    http:Response successResponse = check testClient->/collections.post(
        message = {
            "name": "test 2"
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

    // Malformed response body.
    PostCollectionResponseData|error convertedData = responseData.cloneWithType();
    if convertedData is error {
        test:assertFail("Assertion Failed! : Malformed response");
    }
}

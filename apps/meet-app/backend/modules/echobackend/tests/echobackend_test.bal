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
import ballerina/http;
import ballerina/test;

// A stand-in for echo-backend that records what meet-app sends it.
isolated string lastPath = "";
isolated string lastAuthorization = "";
isolated int answerWith = 202;

listener http:Listener mockEcho = new (19099);

service / on mockEcho {
    // Token endpoint for the OAuth2 client-credentials grant.
    resource function post token() returns json {
        return {access_token: "m2m-token", token_type: "Bearer", expires_in: 3600};
    }

    resource function post internal/meetings/[int meetingId]/transcript\-ready(
            @http:Header {name: "Authorization"} string? authorization) returns http:Response {
        lock {
            lastPath = string `/internal/meetings/${meetingId}/transcript-ready`;
        }
        lock {
            lastAuthorization = authorization ?: "";
        }
        http:Response res = new;
        lock {
            res.statusCode = answerWith;
        }
        return res;
    }
}

function mockClient() returns http:Client|error {
    return new ("http://localhost:19099");
}

final EchoOauth2Config & readonly mockOauth = {tokenUrl: "http://localhost:19099/token", clientId: "id", clientSecret: "s"};

@test:Config {}
function testSendsTheMeetingId() returns error? {
    lock {
        answerWith = 202;
    }
    http:Client? c = check newEchoClient("http://localhost:19099", mockOauth);
    if c is () {
        test:assertFail("a configured client was expected");
    }
    check send(c, 616);
    lock {
        test:assertEquals(lastPath, "/internal/meetings/616/transcript-ready");
    }
    lock {
        test:assertEquals(lastAuthorization, "Bearer m2m-token", "echo-backend checks this token");
    }
}

@test:Config {}
function testAnythingButAcceptedIsAnError() returns error? {
    lock {
        answerWith = 401;
    }
    http:Client c = check mockClient();
    error? result = send(c, 7);
    test:assertTrue(result is error, "a rejected call must be reported so it is logged");
    if result is error {
        test:assertTrue(result.message().includes("401"));
    }
    lock {
        answerWith = 202;
    }
}

@test:Config {}
function testPathHasTheFixedShape() {
    test:assertEquals(transcriptReadyPath(1), "/internal/meetings/1/transcript-ready");
}

@test:Config {}
function testNotConfiguredMeansNoClient() returns error? {
    test:assertTrue(check newEchoClient("", mockOauth) is (), "no URL: off");
    test:assertTrue(check newEchoClient("http://localhost:19099", ()) is (), "no OAuth2 client: off");
    test:assertTrue(check newEchoClient("http://localhost:19099", mockOauth) is http:Client);
}

@test:Config {}
function testTokenEndpointDownMeansOffNotACrash() {
    EchoOauth2Config down = {tokenUrl: "http://localhost:1/token", clientId: "id", clientSecret: "s"};
    test:assertTrue(startEchoClient("http://localhost:19099", down) is (), "startup must not fail");
}

// With nothing configured (the default) the notifier does nothing and, above all, does not fail.
@test:Config {}
function testNotifyDoesNothingWhenOff() {
    notifyTranscriptReady(616);
}

@test:Config {}
function testNotifyNeverFailsWhenEchoIsUnreachable() returns error? {
    http:Client c = check new ("http://localhost:1");
    error? result = send(c, 5);
    test:assertTrue(result is error, "the error is returned to notifyTranscriptReady, which only logs it");
}

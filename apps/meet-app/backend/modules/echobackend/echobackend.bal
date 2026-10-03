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
import ballerina/log;

# Base URL of echo-backend's API endpoint, including the version path (for example
# https://<host>/<org>/echo-backend-api/v1.0). Empty switches the notification off, which is the
# safe default: echo-backend then finds new transcripts on its own poll, a few minutes later.
configurable string echoBackendBaseUrl = "";

# Shared secret echo-backend expects in the X-Echo-Webhook-Token header. Must equal its
# ECHO_WEBHOOK_SECRET. Empty switches the notification off.
configurable string echoWebhookToken = "";

# OAuth2 client-credentials settings, only needed when echo-backend is reached through the
# Choreo gateway, which wants a token on top of the shared secret.
configurable EchoOauth2Config? echoOauthConfig = ();

# OAuth2 client-credentials settings for the Choreo gateway.
#
# + tokenUrl - Token endpoint
# + clientId - Client ID
# + clientSecret - Client secret
public type EchoOauth2Config record {|
    string tokenUrl;
    string clientId;
    string clientSecret;
|};

# Header carrying the shared secret (matches echo-backend's WebhookTokenHeader).
const string WEBHOOK_TOKEN_HEADER = "X-Echo-Webhook-Token";

# echo-backend gets a notification only when it is fully configured.
final http:Client? echoClient = check newEchoClient(echoBackendBaseUrl, echoWebhookToken, echoOauthConfig);

isolated function newEchoClient(string baseUrl, string token, EchoOauth2Config? oauth) returns http:Client?|error {
    if baseUrl.trim() == "" || token == "" {
        return ();
    }
    // Short timeout and no retries: this runs in the background after the transcript is
    // already stored, and echo-backend's own poll catches anything this call misses.
    http:ClientConfiguration config = {
        httpVersion: http:HTTP_1_1,
        http1Settings: {keepAlive: http:KEEPALIVE_NEVER},
        timeout: 10
    };
    if oauth is EchoOauth2Config {
        config.auth = {...oauth};
    }
    return new (baseUrl, config);
}

# Tells echo-backend that a meeting's transcript is now ATTACHED, so it starts extracting the
# MEDDPICC answers immediately instead of at its next poll.
#
# Best effort and fire-and-forget: it never returns an error and never throws. A failure here
# must not disturb meet-app's own work, and costs nothing but a short delay, because
# echo-backend polls for attached transcripts as well and picks the meeting up there. It does
# nothing when echo-backend is not configured. Calling it again for the same meeting is
# harmless: echo-backend ignores a meeting it has already analysed or queued.
#
# + meetingId - The meeting's id (the `meeting_id` echo-backend reads)
public isolated function notifyTranscriptReady(int meetingId) {
    http:Client? echo = echoClient;
    if echo is () {
        return;
    }
    error? result = send(echo, echoWebhookToken, meetingId);
    if result is error {
        log:printWarn(string `Could not notify echo-backend about the transcript of meeting ${meetingId}; ` +
                "it will pick the meeting up on its next poll.", result);
    }
}

isolated function send(http:Client echo, string token, int meetingId) returns error? {
    http:Response response = check echo->post(transcriptReadyPath(meetingId), (),
            {[WEBHOOK_TOKEN_HEADER]: token});
    // 202 is echo-backend's answer whether or not it queued a run (it may already have one).
    if response.statusCode != http:STATUS_ACCEPTED {
        return error(string `echo-backend answered ${response.statusCode}`);
    }
}

isolated function transcriptReadyPath(int meetingId) returns string {
    return string `/internal/meetings/${meetingId}/transcript-ready`;
}

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

configurable string salesEntityServiceBaseUrl = ?;
configurable SalesEntityRetryConfig retryConfig = ?;
configurable Oauth2Config oauthConfig = ?;

# Meet Backend -> Sales Entity Service (REST) credentials.
#
# Deliberately a SECOND, separate client from `meet_app.sales` even though both are called
# "sales entity". They are two different Choreo components with two different base URLs and
# two different protocols: `meet_app.sales` is the GraphQL `entity` service
# (`.../sales-entity/sales-entity/v1.0`), while this is the REST `entity-service`
# (`.../sales-entity-service/v1.0`) that owns `/contacts/search` and `/activities/calls`.
# Pointing one client at both would silently 404 half the calls.
@display {
    label: "Sales Entity Service",
    id: "meet-app/sales-entity-service"
}

final http:Client salesEntityServiceClient = check new (salesEntityServiceBaseUrl, {
    auth: {
        ...oauthConfig
    },
    httpVersion: http:HTTP_1_1,
    http1Settings: {keepAlive: http:KEEPALIVE_NEVER},
    retryConfig: {
        ...retryConfig
    }
});

# The same service, but with retries deliberately switched OFF -- used only for
# `POST /activities/calls`.
#
# That request CREATES a Salesforce Task. The transport retries on connection-level
# failures, and the one failure it cannot tell apart is "the request never arrived" from
# "the request arrived, the Task was created, and the response was lost on the way back".
# Retrying the second case creates a second Task. The `call_activity_id` claim can't prevent
# that: it guards against this app calling createCallActivity twice, whereas this duplicate
# happens inside a single call, below the level the claim can see.
#
# The endpoint takes no idempotency key, so not retrying is the only way to keep the create
# safe. A genuinely dropped request means one missed activity, logged loudly -- much cheaper
# than a duplicate call on a rep's opportunity timeline. Reads keep using the retrying client
# above, where replaying a request is harmless.
@display {
    label: "Sales Entity Service (no retry)",
    id: "meet-app/sales-entity-service-no-retry"
}

final http:Client salesEntityServiceWriteClient = check new (salesEntityServiceBaseUrl, {
    auth: {
        ...oauthConfig
    },
    httpVersion: http:HTTP_1_1,
    http1Settings: {keepAlive: http:KEEPALIVE_NEVER}
});

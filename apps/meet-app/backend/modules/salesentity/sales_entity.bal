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

# Looks up a Salesforce Contact Id by email, via sales-entity-service.
# 
# Returns `()` -- not an error -- when the email simply isn't a known contact. That is the
# ordinary case for an internal attendee or a customer who was never entered in Salesforce,
# and it must not stop the call activity from being logged; `contactId` is optional on the
# activity, so a miss just means the activity lands on the opportunity timeline alone.
#
# + email - Email address to match a contact on
# + return - The contact's Salesforce Id, `()` if no contact matched (or the match carried
# no id), or an error if the lookup itself failed
public isolated function findContactIdByEmail(string email) returns string?|error {
    ContactFilter filter = {email: email};
    http:Request req = new;
    req.setPayload(filter);
    http:Response response = check salesEntityServiceClient->post("/contacts/search", req);
    if response.statusCode != 200 {
        json|error errorResponseBody = response.getJsonPayload();
        return error(string `Contact search failed. Status: ${response.statusCode}, ` +
                string `Response: ${errorResponseBody is json ? errorResponseBody.toJsonString() : "<no body>"}`);
    }
    json responseJson = check response.getJsonPayload();
    Contact[] contacts = check responseJson.cloneWithType();
    if contacts.length() == 0 {
        return;
    }
    return contacts[0].id;
}

# Logs a completed call against a Salesforce Opportunity, via sales-entity-service's
# `POST /activities/calls`.
#
# `ownerId` is deliberately never sent: the service defaults an omitted owner to the
# integration user, which is the correct attribution for an activity this pipeline created
# on its own rather than one a rep logged by hand.
#
# + input - Call details. `subject` and `opportunityId` must both be set -- the service
# rejects a request with no opportunity (and no lead) as a 400
# + return - Salesforce Id of the created activity, or an error
public isolated function createCallActivity(CreateCallActivityInput input) returns string|error {
    http:Request req = new;
    req.setPayload(input);
    http:Response response = check salesEntityServiceClient->post("/activities/calls", req);
    if response.statusCode != 201 {
        json|error errorResponseBody = response.getJsonPayload();
        return error(string `Call activity creation failed. Status: ${response.statusCode}, ` +
                string `Response: ${errorResponseBody is json ? errorResponseBody.toJsonString() : "<no body>"}`);
    }
    // The service returns the bare activity id as the body. It arrives as text/plain when
    // sent as a Ballerina string body, so read text first and only fall back to JSON --
    // getJsonPayload() on a text/plain body is itself an error.
    string|error activityId = response.getTextPayload();
    if activityId is string {
        return activityId.trim();
    }
    json responseJson = check response.getJsonPayload();
    return responseJson.toString().trim();
}

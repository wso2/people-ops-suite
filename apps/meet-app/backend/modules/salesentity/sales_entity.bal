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
# ordinary case for an attendee who was never entered in Salesforce, and it must not stop the
# call activity from being logged: `contactId` is optional on the activity, so a miss just
# means the activity lands on the opportunity timeline alone.
#
# + email - Email address to match a contact on
# + return - The contact's Salesforce Id, `()` if no contact matched (or the match carried no
# id), or an error if the lookup itself failed
public isolated function findContactIdByEmail(string email) returns string?|error {
    ContactFilter filter = {email: email};
    http:Request req = new;
    req.setPayload(filter);

    // The retrying client is the right one here: a search is a read, so replaying it is
    // harmless.
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
# Sent on the NON-retrying client. This request creates a Salesforce Task, and the transport
# cannot tell "the request never arrived" apart from "the request arrived, the Task was
# created, and the response was lost coming back" -- retrying the second case creates a
# duplicate. The endpoint takes no idempotency key, and the caller's `call_activity_id` claim
# cannot help, because that duplicate happens inside a single call, below the level the claim
# can see.
#
# `ownerId` is deliberately never sent: the service defaults an omitted owner to the
# integration user, which is the right attribution for an activity this pipeline raised on its
# own rather than one a rep logged by hand.
#
# + input - Call details. `subject` and `opportunityId` must both be set -- the service rejects
# a request carrying no opportunity (and no lead) with a 400
# + return - Salesforce Id of the created activity; CALL_ACTIVITY_ID_UNKNOWN if it was created
# but its id could not be read back; or an error ONLY if the activity was not created
public isolated function createCallActivity(CreateCallActivityInput input) returns string|error {
    http:Request req = new;
    req.setPayload(input);

    http:Response response = check salesEntityServiceWriteClient->post("/activities/calls", req);
    if response.statusCode != 201 {
        json|error errorResponseBody = response.getJsonPayload();
        return error(string `Call activity creation failed. Status: ${response.statusCode}, ` +
                string `Response: ${errorResponseBody is json ? errorResponseBody.toJsonString() : "<no body>"}`);
    }

    // From here the Task exists in Salesforce, so nothing below may return an error. The
    // caller releases its claim on an error, and a released claim lets a later run create the
    // activity a second time. Losing track of the id costs traceability; reporting a false
    // failure costs a duplicate on the rep's timeline.
    return readActivityId(response);
}

# Reads the activity id off a successful create response.
#
# The service returns the bare id as the body, so it arrives as text/plain. It is validated
# rather than trusted: an unrecognised shape -- a JSON error envelope, an HTML gateway page --
# would otherwise be stored in `call_activity_id` verbatim and read back later as though it
# were a real Salesforce id.
#
# + response - The 201 response from the create
# + return - The validated id, or CALL_ACTIVITY_ID_UNKNOWN if the body did not carry one
isolated function readActivityId(http:Response response) returns string {
    // Read once and keep the result. Re-reading a consumed payload can fail, and a `check` on
    // that failure would be exactly the after-201 error the caller must never see.
    string|error textPayload = response.getTextPayload();
    if textPayload is error {
        return CALL_ACTIVITY_ID_UNKNOWN;
    }

    string activityId = textPayload.trim();
    // A body serialised as a JSON string arrives wrapped in quotes; unwrap before validating.
    string unquoted = activityId.length() > 1 && activityId.startsWith("\"") && activityId.endsWith("\"")
        ? activityId.substring(1, activityId.length() - 1)
        : activityId;

    return SALESFORCE_ID_PATTERN.isFullMatch(unquoted) ? unquoted : CALL_ACTIVITY_ID_UNKNOWN;
}

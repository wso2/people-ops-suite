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

# [Configurable] OAuth2 entity application configuration.
type Oauth2Config record {|
    # OAuth2 token endpoint
    string tokenUrl;
    # OAuth2 client ID
    string clientId;
    # OAuth2 client secret
    string clientSecret;
|};

# Retry config for the sales-entity-service client.
public type SalesEntityRetryConfig record {|
    # Retry count
    int count = RETRY_COUNT;
    # Retry interval
    decimal interval = RETRY_INTERVAL;
    # Retry backOff factor
    float backOffFactor = RETRY_BACKOFF_FACTOR;
    # Retry max interval
    decimal maxWaitInterval = RETRY_MAX_INTERVAL;
|};

# Filter for `POST /contacts/search`.
#
# The service's own filter record carries ~15 fields, every one of them defaulted. Only the
# ones this app actually filters on are declared here -- sending the rest as explicit nulls
# would say the same thing as omitting them, just more verbosely and with more to keep in
# sync when the service adds a field.

public type ContactFilter record {|
    #Contact email to match on
    string email;
    #Maximum rows to return
    int 'limit = CONTACT_SEARCH_LIMIT;
|};

# One contact from `POST /contacts/search`.
#
# Open on purpose: the service returns ~25 fields per contact and this app needs exactly
# two of them. A closed record would break on the next field the service adds.
#

public type Contact record {
    #Salesforce Contact Id -- the value that goes in the call activity's `contactId`
    string? id = ();
    #Contact email, echoed back
    string? email = ();
};

# Payload for `POST /activities/calls`, mirroring the service's `CreateCallActivityInput`.

public type CreateCallActivityInput record {|
    #Short title for the call, shown in the Salesforce activity timeline
    string subject;
    #Description of the call, shown in the Salesforce activity timeline
    string? description?;
    #Direction of the call (Salesforce's Task.CallType picklist:Inbound/Outbound/Internal).
    string? callType?;
    #Date the call took place, `yyyy-MM-dd`. 
    string? occurredOn?;
    #Free-text notes; this is where the recording/transcript/smart-notes links go.
    string? comment?;
    #Opportunity the call relates to. The service requires EXACTLY ONE of `opportunityId`.
    string? opportunityId?;
    #Account the call relates to
    string? accountId?;
    #Contact who was on the call
    string? contactId?;
    #Length of the call in seconds
    int? durationSeconds?;
|};

# Raised when a call-activity create could not be confirmed either way: the request left this
# process but no response came back, so the Task may or may not exist in Salesforce.
#
# Distinct from a plain error on purpose. A plain error means the service answered and refused,
# so nothing was created and the claim is safe to release. This one means we do not know -- and
# releasing the claim on "do not know" is what puts a duplicate on a rep's timeline, the exact
# outcome createCallActivity's post-201 handling already goes out of its way to avoid.
public type CallActivityIndeterminate distinct error;

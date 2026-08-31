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
#
# + email - Contact email to match on
# + 'limit - Maximum rows to return
public type ContactFilter record {|
    string email;
    int 'limit = CONTACT_SEARCH_LIMIT;
|};

# One contact from `POST /contacts/search`.
#
# Open on purpose: the service returns ~25 fields per contact and this app needs exactly
# two of them. A closed record would break on the next field the service adds.
#
# + id - Salesforce Contact Id -- the value that goes in the call activity's `contactId`
# + email - Contact email, echoed back
public type Contact record {
    string? id = ();
    string? email = ();
};

# Payload for `POST /activities/calls`, mirroring the service's `CreateCallActivityInput`.
#
# + subject - Short title for the call, shown in the Salesforce activity timeline
# + callType - Direction of the call (Salesforce's Task.CallType picklist:
# Inbound/Outbound/Internal). Part of the service's contract, but this app never sets it --
# nothing in the recording pipeline knows the call's direction
# + occurredOn - Date the call took place, `yyyy-MM-dd`. Salesforce stores a date only --
# there is no time-of-day field creatable on an activity of this kind, so the meeting's
# start time is truncated to its date before it gets here
# + comment - Free-text notes; this is where the recording/transcript/smart-notes links go.
# The underlying Salesforce field holds 32,000 characters
# + opportunityId - Opportunity the call relates to. The service requires EXACTLY ONE of
# `opportunityId` or `leadId` and rejects a request carrying both or neither with a 400
# + contactId - Contact who was on the call. Only meaningful alongside `opportunityId` --
# a lead already occupies the same underlying Salesforce field (`WhoId`)
# + durationSeconds - Length of the call in seconds
public type CreateCallActivityInput record {|
    string subject;
    string? callType?;
    string? occurredOn?;
    string? comment?;
    string? opportunityId?;
    string? contactId?;
    int? durationSeconds?;
|};

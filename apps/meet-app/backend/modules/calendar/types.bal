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

# [Configurable] OAuth2 entity application configuration.
type Oauth2Config record {|
    # OAuth2 token endpoint
    string tokenUrl;
    # OAuth2 client ID
    string clientId;
    # OAuth2 client secret
    string clientSecret;
|};

# Retry config for the calendar client.
public type CalendarRetryConfig record {|
    # Retry count
    int count = RETRY_COUNT;
    # Retry interval
    decimal interval = RETRY_INTERVAL;
    # Retry backOff factor
    float backOffFactor = RETRY_BACKOFF_FACTOR;
    # Retry max interval
    decimal maxWaitInterval = RETRY_MAX_INTERVAL;
|};

# Recurrence config for calendar events.
public type RecurrenceConfig record {|
    # Recurrence frequency
    string frequency;
    # Number of occurrences
    int count;
|};

# Event create request record.
public type CreateCalendarEventRequest record {|
    # Event title
    string title;
    # Event description
    string description;
    # Event start time
    string startTime;
    # Event end time
    string endTime;
    # Event time zone
    string timeZone;
    # Internal participants
    string[] internalParticipants;
    # External participants
    string[] externalParticipants;
    # Whether this is recurring
    boolean? isRecurring?;
    # Full RRULE string
    string? recurrenceRule?;
    # Structured recurrence fallback if RRULE is not sent
    RecurrenceConfig? recurrence?;
|};

# Event create payload record.
public type CreateCalendarEventPayload record {|
    # Event title
    string summary;
    # Event description
    string description;
    # Event start time
    record {|
        string dateTime;
        string timeZone;
    |} 'start;
    # Event end time
    record {|
        string dateTime;
        string timeZone;
    |} end;
    # Event attendees
    record {|
        string email;
    |}[] attendees;
    # Event guests can modify
    boolean guestsCanModify;
    # Recurrence rules
    string[]? recurrence?;
    # Event conference data
    record {|
        record {|
            string requestId;
            record {|
                string 'type;
            |} conferenceSolutionKey;
        |} createRequest;
    |} conferenceData;
|};

# Event create success response record.
public type CreateCalendarEventResponse record {|
    # Success message
    string message;
    # Created event ID
    string id;
|};

# Event delete response record.
public type DeleteCalendarEventResponse record {|
    # Success message
    string message;
|};

// Copyright (c) 2025, WSO2 LLC. (https://www.wso2.com). All Rights Reserved.
//
// This software is the property of WSO2 LLC. and its suppliers, if any.
// Dissemination of any information or reproduction of any material contained
// herein in any form is strictly forbidden, unless permitted by WSO2 expressly.
// You may not alter or remove any copyright or other notice from copies of this content.

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

# Event create request record
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
    # WSO2 participants
    string[] wso2Participants;
    # External participants
    string[] externalParticipants;
|};

# Event create payload record
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

# Event create success response record
public type CreateCalendarEventResponse record {|
    # Success message
    string message;
    # Created event ID
    string id;
|};

# Event delete response record
public type DeleteCalendarEventResponse record {|
    # Success message
    string message;
|};

// Copyright (c) 2024 WSO2 LLC. (https://www.wso2.com).
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

# [Configurable] Choreo OAuth2 application configuration.
type ChoreoApp record {|
    # OAuth2 token endpoint
    string tokenUrl;
    # OAuth2 client ID
    string clientId;
    # OAuth2 client secret
    string clientSecret;
|};

# Time record.
public type Time record {|
    # The date, in the format "yyyy-mm-dd"
    @display {label: "Date"}
    string date?;
    # A combined date-time value formatted according to RFC3339
    @display {label: "Date And Time"}
    string dateTime?;
    # The time zone in which the time is specified
    @display {label: "Time Zone"}
    string timeZone?;
|};

# Elements representing event input record.
public type EventPayload record {|
    # Title of the event
    @display {label: "Event Title"}
    string summary?;
    # Description of the event
    @display {label: "Event Description"}
    string description?;
    # Location of the event
    @display {label: "Event Location"}
    string location?;
    # Color Id of the event
    @display {label: "Event Color Id"}
    string colorId?;
    # Opaque identifier of the event
    @display {label: "Event Id"}
    string id?;
    # Start time of the event
    @display {label: "Event Start Time"}
    Time 'start;
    # End time of the event
    @display {label: "Event End Time"}
    Time end;
    # List of RRULE, EXRULE, RDATE and EXDATE lines for a recurring event, as specified in RFC5545
    @display {label: "Recurrence Config"}
    string[] recurrence?;
    # The start time of the event in recurring events
    @display {label: "Start Time in Recurrent Event"}
    Time originalStartTime?;
    # Whether the event blocks time on the calendar
    @display {label: "Time Blocks Config"}
    string transparency?;
    # Visibility of the event
    @display {label: "Event Visibility"}
    string visibility?;
|};

# Server Message.
public type CreatedMessage record {|
    # Human readable error message
    string message?;
    # Id of the created object
    string id?;
|};

# Day record.
public type Day record {|
    # Date of day
    string date;
|};

# Holiday record.
public type Holiday record {|
    # ID of the holiday
    string id;
    # Title of the holiday
    string title;
    # Date of the holiday
    string date;
    # Country of the holiday
    string country;
|};

# Holiday group record type, which contains the country name and the list of holidays.
public type HolidayGroup record {|
    # Country name(example, US, UK, etc)  
    string country;
    # List of holidays
    Event[] holidays;
|};

# Event record.
public type Event record {|
    # ID of the event
    string id;
    # Event type
    EventType kind;
    # Created time
    string created;
    # Updated
    string updated;
    # Summary
    string summary;
    # Organizer record
    record {
        string email;
        string displayName;
        boolean self;
    } organizer;
    # Start date and datetime record
    record {
        string date?;
        string datetime?;
    } 'start;
    # End date and datetime record
    record {
        string date?;
        string datetime?;
    } end;
    json...; // Rest descriptor allows additional fields
|};

# Event type record.
public type EventType GOOGLE_CALENDAR_EVENT;

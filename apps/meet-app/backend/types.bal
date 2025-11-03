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
import meet_app.database;

import ballerinax/googleapis.calendar as gcalendar;

# Represents the details of a scheduled meeting.
public type Meeting record {|
    # Auto-increment meeting ID
    int meetingId;
    # Title of the meeting
    string title;
    # Google event ID
    string googleEventId;
    # Host of the meeting
    string host;
    # Meeting start time
    string startTime;
    # Meeting end time
    string endTime;
    # Internal participants' email list
    string internalParticipants;
    # Meeting status (e.g., 'ACTIVE', 'CANCELLED')
    database:MeetingStatus meetingStatus;
    # Time Status (e.g., 'PAST', 'UPCOMING')
    database:TimeStatus timeStatus;
    # Whether the meeting is recurring
    boolean isRecurring;  
|};

# Represents the response structure for retrieving user information.
public type UserInfoResponse record {|
    # Id of the employee
    string employeeId;
    # Email of the employee
    string workEmail;
    # First name of the employee
    string firstName;
    # Last name of the employee
    string lastName;
    # Job role
    string jobRole;
    # Thumbnail of the employee
    string? employeeThumbnail;
    # User Privileges
    int[] privileges;
|};

# Represents the response after successfully creating a meeting.
public type MeetingCreationResponse record {|
    # Success message
    string message;
    # Meeting ID
    int meetingId;
|};

# Represents the response when retrieving a list of meetings.
public type MeetingListResponse record {|
    # Meeting count
    int count;
    # Meeting list
    Meeting[] meetings;
|};

# Represents the response when retrieving attachments for a meeting.
public type AttachmentListResponse record {|
    # Attachment list
    gcalendar:Attachment[] attachments;
|};

# Represents the response after successfully deleting a meeting.
public type MeetingDeletionResponse record {|
    # Success message
    string message;
|};

# Represent the name and email address of a support team.
public type SupportTeamEmail record {|
    # Name of the support team
    string team;
    # Email address of the support team
    string email;
|};

# List of App Configurations.
public type AppConfig record {|
    # List of support team emails
    SupportTeamEmail[] supportTeamEmails;
|};

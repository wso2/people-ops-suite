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
import meet_app.driveservice;

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
    # External (non-wso2.com) attendees, comma-joined. Null on meetings recorded before
    # this was captured — distinct from a meeting that genuinely had none.
    string? externalParticipants;
    # Meeting status (e.g., 'ACTIVE', 'CANCELLED')
    database:MeetingStatus meetingStatus;
    # Time Status (e.g., 'PAST', 'UPCOMING')
    database:TimeStatus timeStatus;
    # Whether the meeting is recurring
    boolean isRecurring;
    # Call type / meeting category, when the calendar add-on linked this meeting.
    string? meetingType;
    # Salesforce Opportunity id, when the call type targets a deal.
    string? opportunityId;
    # Deal snapshot as a JSON string; never present without opportunityId.
    string? opportunityDetails;
    # Salesforce Account id, when the call type targets an account.
    string? accountId;
    # The account's display name.
    string? accountName;
    # Salesforce Lead id, when the call type targets a lead (Inbound).
    string? leadId;
    # The lead's company, shown where an account name would be.
    string? leadCompany;
    # Every recording of the call, in the order they happened -- each stop and restart is a
    # new part. Only on the single-meeting route; the list leaves it out.
    MeetingPartView[] recordings?;
    # Every transcript of the call, in order. Only on the single-meeting route.
    MeetingPartView[] transcripts?;
    # Every smart notes of the call, in order. Only on the single-meeting route.
    MeetingPartView[] smartNotes?;
|};

# One recording, transcript or smart notes of a call, as the meeting page lists it. Pass its
# id to the playback, transcript or smart-notes route to open that part.
public type MeetingPartView record {|
    # Part id
    int id;
    # When the part started, RFC 3339 UTC; () for a part stored before times were kept
    string? startTime;
    # When the part ended, RFC 3339 UTC; () when unknown
    string? endTime;
    # PENDING, ATTACHED or FAILED; only ATTACHED parts can be opened
    database:RecordingState state;
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
    # Business unit  of the host
    string? businessUnit;
    # Team of the host
    string? team;
    # Sub team of the host 
    string? subTeam;
    # Unit  of the host
    string? unit;
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

# Represents a signed, time-limited URL for streaming a meeting's recording.
public type PlaybackResponse record {|
    # URL a <video> element can be pointed at directly.
    string url;
    # When the URL stops working, as an ISO-8601 instant. Returned so the caller can
    # refresh before a viewer meets a stall rather than after.
    string expiresAt;
|};

# Represents a meeting's transcript as timed, speaker-attributed lines.
public type TranscriptResponse record {|
    # The utterances, in order.
    driveservice:TranscriptLine[] lines;
|};

# Represents a meeting's smart notes.
public type SmartNotesResponse record {|
    # The notes as plain text. Meet writes these only as a Google Doc, so there is no
    # richer structure to offer.
    string text;
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

# Represent the designations of a sales team.
public type SalesDesignations record {|
    # Team Name Of Account Manager
    string teamNameOfAccountManager;
    # Team Name Of Technical Officer
    string teamNameOfTechnicalOfficer;
|};

# Represent the regions.
public type Regions record {|
    # List of Regions
    string[] regions;
|};

# What the lead backfill did, or would do, for one Inbound meeting.
public enum LeadBackfillStatus {
    # Dry run: the event carries a lead, which would be stored
    WOULD_LINK,
    # The lead was stored and the call handed to the Salesforce call-activity logging
    LINKED,
    # Another writer stored a lead first; nothing changed
    ALREADY_LINKED,
    # The organizer's copy of the event has no lead link
    NO_LEAD_ON_EVENT,
    # The organizer's copy of the event could not be read
    EVENT_READ_FAILED,
    # The lead could not be stored
    UPDATE_FAILED
}

# One Inbound meeting in a lead backfill response.
public type LeadBackfillItem record {|
    # Meeting ID
    int meetingId;
    # Title of the meeting
    string title;
    # Start time of the meeting
    string startTime;
    # Lead id read from the event, if any
    string? leadId;
    # Lead company read from the event, if any
    string? leadCompany;
    # What happened
    LeadBackfillStatus status;
|};

# One batch of the lead backfill.
public type LeadBackfillResponse record {|
    # Whether this was a dry run (nothing written)
    boolean dryRun;
    # The meetings looked at in this batch
    LeadBackfillItem[] meetings;
    # Pass as afterMeetingId to get the next batch; () when this was the last one
    int? nextAfterMeetingId;
|};

# What the parts backfill did, or would do, for one meeting.
public enum PartsBackfillStatus {
    # Both sources were read and every part they listed was looked at
    CHECKED,
    # A source could not be read (see unreadSources); a later run retries it
    INCOMPLETE
}

# One meeting in a parts backfill response. Parts are named by Meet's resource name.
public type PartsBackfillItem record {|
    # Meeting ID
    int meetingId;
    # Title of the meeting
    string title;
    # Scheduled start of the meeting
    string startTime;
    # Calls Meet found on the meeting's space inside its window; 0 for a meeting older than
    # Meet's 30 days, whose parts come from the calendar event alone
    int callsFound;
    # Files attached to the calendar event as a recording, transcript or notes
    int eventAttachments;
    # Parts the meeting had no record of: stored, or in a dry run, would be stored. Named by
    # Meet's resource name, or `legacy:file:<meeting id>:<Drive file id>` when only the event
    # knows them
    string[] missingParts;
    # Parts left alone: listed by Meet but not attached to the calendar event, or still being
    # processed by their own notification. Their notification attaches and shares them.
    string[] unattachedParts;
    # Parts that could not be checked or stored; a later run retries them
    string[] failedParts;
    # Sources that could not be read: "meet" and/or "calendar"
    string[] unreadSources;
    # What happened
    PartsBackfillStatus status;
|};

# One batch of the parts backfill.
public type PartsBackfillResponse record {|
    # Whether this was a dry run (nothing written)
    boolean dryRun;
    # The meetings looked at in this batch
    PartsBackfillItem[] meetings;
    # Pass as afterMeetingId to get the next batch; () when this was the last one
    int? nextAfterMeetingId;
|};

# Builds one lead backfill result row.
#
# + candidate - The Inbound meeting looked at
# + leadId - Lead id read from the event, if any
# + leadCompany - Lead company read from the event, if any
# + status - What happened
# + return - The result row
isolated function leadBackfillItem(database:LeadBackfillCandidate candidate, string? leadId, string? leadCompany,
        LeadBackfillStatus status) returns LeadBackfillItem => {
    meetingId: candidate.meetingId,
    title: candidate.title,
    startTime: candidate.startTime,
    leadId,
    leadCompany,
    status
};

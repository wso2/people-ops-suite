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
import ballerina/url;

# Create a meet
#
# + return - Meet Uri
public isolated function createMeet() returns error|string {
    http:Response meetResponse = check calendarClient->post(string `/meet/${calendarId}`, {});
    if meetResponse.statusCode === 201 {
    json meetJsonPayload = check meetResponse.getJsonPayload();
    string extractedMeetUri = check meetJsonPayload.id;
    return extractedMeetUri;
    }
    json? errorResponseBody = check meetResponse.getJsonPayload();
    return error(string `Status: ${meetResponse.statusCode}, Response: ${errorResponseBody.toJsonString()}`);
}

# Attaches a Drive file to an existing calendar event as a recording attachment.
#
# + salesUser - Email of the event organizer, impersonated for the attach
# + eventId - Event ID to attach the file to
# + fileId - Drive file ID to attach
# + title - Display title for the attachment
# + mimeType - MIME type of the attached file
# + return - Error if the attach fails
public isolated function attachRecording(string salesUser, string eventId, string fileId, string title,
        string mimeType) returns error? {
    http:Request req = new;
    req.setPayload({fileId, title, mimeType});
    http:Response response = check calendarClient->post(
            string `/calendars/${salesUser}/events/${eventId}/attachments`, req);
    if response.statusCode != 200 {
        json? errorResponseBody = check response.getJsonPayload();
        return error(string `Status: ${response.statusCode}, Response: ${errorResponseBody.toJsonString()}`);
    }
}

# Registers a push-notification channel on the Shared Account's calendar via CES.
#
# + webhookUrl - Publicly reachable URL Google should POST pings to
# + channelId - Caller-chosen unique ID for this channel
# + token - Shared secret Google echoes back on every ping
# + return - The registered channel's ID, resourceId, and expiration, or error
public isolated function watchCalendar(string webhookUrl, string channelId, string token)
        returns WatchChannelResponse|error {
    http:Request req = new;
    req.setPayload({webhookUrl, channelId, token});
    http:Response response = check calendarClient->post(string `/calendars/${calendarId}/watch`, req);
    if response.statusCode != 200 && response.statusCode != 201 {
        json? errorResponseBody = check response.getJsonPayload();
        return error(string `Status: ${response.statusCode}, Response: ${errorResponseBody.toJsonString()}`);
    }
    json responseJson = check response.getJsonPayload();
    return responseJson.cloneWithType(WatchChannelResponse);
}

# Gets a single event as a specific user would see it (impersonated via CES's own DWD
# credential), via CES. Needed specifically to read `extendedProperties.private` values the
# RevOS add-on writes -- Google scopes "private" extended properties to the one calendar
# copy they were set on, so they're only visible when reading the *organizer's* own copy of
# the event, not the Shared Account's (an attendee's) copy that the calendar-watch poll
# (getChangedEvents) returns.
#
# + organizerEmail - Whose copy of the event to read, impersonated via CES's DWD credential
# + eventId - The event's ID
# + return - The event as raw JSON (only `extendedProperties` is actually used), or error
public isolated function getEvent(string organizerEmail, string eventId) returns json|error {
    http:Response response = check calendarClient->get(string `/calendars/${organizerEmail}/events/${eventId}`);
    if response.statusCode != 200 {
        json? errorResponseBody = check response.getJsonPayload();
        return error(string `Status: ${response.statusCode}, Response: ${errorResponseBody.toJsonString()}`);
    }
    return response.getJsonPayload();
}

# Resolves a meeting's join code to its real Meet space resource name, via CES.
#
# + meetingCode - The short code from a meet.google.com/xxx-xxxx-xxx URL
# + return - The real space resource name (e.g. `spaces/abc123`), or an error
public isolated function resolveSpaceName(string meetingCode) returns string|error {
    http:Response response = check calendarClient->get(
            string `/meet/space-name?meetingCode=${meetingCode}&ownerEmail=${calendarId}`);
    if response.statusCode == 200 {
        json responseJson = check response.getJsonPayload();
        return responseJson.message.ensureType(string);
    }
    json? errorResponseBody = check response.getJsonPayload();
    return error(string `Status: ${response.statusCode}, Response: ${errorResponseBody.toJsonString()}`);
}

# Gets events that changed on the Shared Account's calendar since the last sync, via CES.
#
# + syncToken - Token from the previous call, or `()` for the first-ever sync
# + return - Changed events plus a fresh syncToken, or error
public isolated function getChangedEvents(string? syncToken) returns ChangedEventsResult|error {
    string path = syncToken is string
        ? string `/calendars/${calendarId}/events-changes?syncToken=${check url:encode(syncToken, "UTF-8")}`
        : string `/calendars/${calendarId}/events-changes`;
    http:Response response = check calendarClient->get(path);
    if response.statusCode == 200 {
        json responseJson = check response.getJsonPayload();
        return responseJson.cloneWithType(ChangedEventsResult);
    }
    json? errorResponseBody = check response.getJsonPayload();
    return error(string `Status: ${response.statusCode}, Response: ${errorResponseBody.toJsonString()}`);
}

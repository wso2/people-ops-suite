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
import ballerina/http;
import ballerina/uuid;
import ballerinax/googleapis.calendar as gcalendar;

configurable string calendarId = ?;
configurable string disclaimerMessage = ?;

# Create an event in the calendar.
#
# + createCalendarEventRequest - Create calendar event request
# + creatorEmail - Event creator Email
# + return - JSON response if successful, else an error
public isolated function createCalendarEvent(CreateCalendarEventRequest createCalendarEventRequest,
        string creatorEmail) returns CreateCalendarEventResponse|error {

    // WSO2 participants validation.
    string:RegExp wso2EmailDomainRegex = re `^([a-zA-Z0-9_\-\.]+)(@wso2\.com|@ws02\.com)$`;
    foreach string participant in createCalendarEventRequest.wso2Participants {
        if !wso2EmailDomainRegex.isFullMatch(participant.trim()) {
            return error(string `Invalid WSO2 participant email: ${participant}`);
        }
    }

    string updatedDisclaimer = replaceCreatorEmail(disclaimerMessage, creatorEmail);
    string separator = string `<hr style="border: none; border-top: 2px solid #ccc; margin: 15px 0;"><br>`;
    string updatedDescription = updatedDisclaimer + separator + createCalendarEventRequest.description;

    // Format the event payload as required by the Google Calendar API.
    CreateCalendarEventPayload calendarEventPayload = {
        summary: createCalendarEventRequest.title,
        description: updatedDescription,
        'start: {
            dateTime: createCalendarEventRequest.startTime,
            timeZone: createCalendarEventRequest.timeZone
        },
        end: {
            dateTime: createCalendarEventRequest.endTime,
            timeZone: createCalendarEventRequest.timeZone
        },
        attendees: [
            ...createCalendarEventRequest.wso2Participants.map((email) => ({email: email.trim()})),
            ...createCalendarEventRequest.externalParticipants.map((email) => ({email: email.trim()}))
        ],
        guestsCanModify: true,
        conferenceData: {
            createRequest: {
                requestId: uuid:createType4AsString(),
                conferenceSolutionKey: {
                    'type: CONFERENCE_SOLUTION_TYPE
                }
            }
        }
    };

    // Make the API call to create the event.
    http:Request req = new;
    json calendarEventPayloadJson = calendarEventPayload.toJson();
    req.setPayload(calendarEventPayloadJson);
    http:Response response = check calendarClient->post(string `/events/${calendarId}?sendUpdates=all`, req);

    // Check if the event was created successfully.
    if response.statusCode == 201 {
        json responseJson = check response.getJsonPayload();
        CreateCalendarEventResponse createCalendarEventResponse = check responseJson
        .cloneWithType(CreateCalendarEventResponse);
        return createCalendarEventResponse;
    }

    json? errorResponseBody = check response.getJsonPayload();
    return error(string `Status: ${response.statusCode}, Response: ${errorResponseBody.toJsonString()}`);
}

# Delete an event from the calendar.
#
# + eventId - Event Id
# + return - JSON response if successful, else an error
public isolated function deleteCalendarEvent(string eventId) returns DeleteCalendarEventResponse|error {

    // Make the API call to delete the event.
    http:Response response = check calendarClient->delete(string `/events/${calendarId}/${eventId}`);

    // Check if the event was deleted successfully.
    if response.statusCode == 200 {
        json responseJson = check response.getJsonPayload();
        DeleteCalendarEventResponse deleteCalendarEventResponse = check responseJson
        .cloneWithType(DeleteCalendarEventResponse);
        return deleteCalendarEventResponse;
    }

    json? errorResponseBody = check response.getJsonPayload();
    return error(string `Status: ${response.statusCode}, Response: ${errorResponseBody.toJsonString()}`);
}

# Get an event from the calendar.
#
# + eventId - Event Id
# + return - JSON response if successful, else an error
public isolated function getCalendarEventAttachments(string eventId) returns gcalendar:Attachment[]|error? {

    // Make the API call to get the event attachments.
    http:Response response = check calendarClient->get(string `/calendars/${calendarId}/events/${eventId}`);

    // Check if the event attachments were fetched successfully.
    if response.statusCode == 200 {
        json responseJson = check response.getJsonPayload();
        gcalendar:Event calendarEvent = check responseJson.cloneWithType(gcalendar:Event);
        if calendarEvent.attachments is () {
            return [];
        }
        return calendarEvent.attachments;
    }

    json? errorResponseBody = check response.getJsonPayload();
    return error(string `Status: ${response.statusCode}, Response: ${errorResponseBody.toJsonString()}`);
}

# Replace the ${creatorEmail} placeholder with a mailto link.
#
# + message - Message with the creator email placeholder
# + creatorEmail - Event creator Email
# + return - Updated message with the creator email replaced by a mailto link
isolated function replaceCreatorEmail(string message, string creatorEmail) returns string {
    // Regex pattern to find the ${creatorEmail} placeholder
    string:RegExp pattern = re `\$\{creatorEmail\}`;

    // Replace ${creatorEmail} with <a href="mailto:creatorEmail">creatorEmail</a>
    string result = pattern.replace(message, string `<a href="mailto:${creatorEmail}">${creatorEmail}</a>`);
    return result;
}

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
import meet_app.authorization;
import meet_app.calendar;
import meet_app.database;
import meet_app.entity;

import ballerina/cache;
import ballerina/http;
import ballerina/log;
import ballerinax/googleapis.calendar as gcalendar;

final cache:Cache userInfoCache = new (capacity = 100, evictionFactor = 0.2);

@display {
    label: "Meet Backend Service",
    id: "people-ops/meet-application"
}

service class ErrorInterceptor {
    *http:ResponseErrorInterceptor;

    remote function interceptResponseError(error err, http:RequestContext ctx) returns http:BadRequest|error {

        // Handle data-binding errors.
        if err is http:PayloadBindingError {
            string customError = string `Payload binding failed!`;
            log:printError(customError, err);
            return {
                body: {
                    message: customError
                }
            };
        }
        return err;
    }
}

service http:InterceptableService / on new http:Listener(9090) {

    # Request interceptor.
    #
    # + return - authorization:JwtInterceptor, ErrorInterceptor
    public function createInterceptors() returns http:Interceptor[] =>
        [new authorization:JwtInterceptor(), new ErrorInterceptor()];

    # Fetch user information of the logged in users.
    #
    # + ctx - Request object
    # + return - User information | Error
    resource function get user\-info(http:RequestContext ctx) returns UserInfoResponse|http:InternalServerError {

        // User information header.
        authorization:CustomJwtPayload|error userInfo = ctx.getWithType(authorization:HEADER_USER_INFO);
        if userInfo is error {
            return <http:InternalServerError>{
                body: {
                    message: "User information header not found!"
                }
            };
        }

        // Custom Resource level authorization.
        entity:Employee|error loggedInUser = entity:fetchEmployeesBasicInfo(userInfo.email);
        if loggedInUser is error {
            string customError = string `Error occurred while retrieving user data: ${userInfo.email}!`;
            log:printError(customError, loggedInUser);
            return <http:InternalServerError>{
                body: {
                    message: customError
                }
            };
        }

        // Fetch the user's privileges based on the roles.
        int[] privileges = [];
        if authorization:checkPermissions([authorization:authorizedRoles.SALES_TEAM], userInfo.groups) {
            privileges.push(authorization:SALES_TEAM_PRIVILEGE);
        }
        if authorization:checkPermissions([authorization:authorizedRoles.SALES_ADMIN], userInfo.groups) {
            privileges.push(authorization:SALES_ADMIN_PRIVILEGE);
        }

        return {...loggedInUser, privileges};
    }

    # Fetch meeting types from the database.
    #
    # + domain - Domain to filter 
    # + return - Meeting types | Error
    isolated resource function get meetings/types(http:RequestContext ctx, string domain)
        returns database:MeetingTypes|http:Forbidden|http:InternalServerError {

        // User information header.
        authorization:CustomJwtPayload|error userInfo = ctx.getWithType(authorization:HEADER_USER_INFO);
        if userInfo is error {
            return <http:InternalServerError>{
                body: {
                    message: "User information header not found!"
                }
            };
        }

        // Custom Resource level authorization.
        if !authorization:checkPermissions([authorization:authorizedRoles.SALES_TEAM], userInfo.groups) {
            return <http:Forbidden>{
                body: {
                    message: "Insufficient privileges!"
                }
            };
        }

        // Fetch the meeting types from the database.
        database:MeetingTypes|error? meetingTypes = database:fetchMeetingTypes(domain);
        if meetingTypes is error {
            string customError = string `Error occurred while retrieving the meeting types!`;
            log:printError(customError, meetingTypes);
            return <http:InternalServerError>{
                body: {
                    message: customError
                }
            };
        }
        if meetingTypes is null {
            string customError = string `No meeting types found for the domain: ${domain}!`;
            log:printError(customError);
            return <http:InternalServerError>{
                body: {
                    message: customError
                }
            };
        }

        return meetingTypes;
    }

    # Create a new meeting.
    #
    # + createCalendarEventRequest - Create calendar event request
    # + return - Created meeting | Error
    isolated resource function post meetings(http:RequestContext ctx,
            calendar:CreateCalendarEventRequest createCalendarEventRequest)
        returns MeetingCreationResponse|http:Forbidden|http:InternalServerError {

        // User information header.
        authorization:CustomJwtPayload|error userInfo = ctx.getWithType(authorization:HEADER_USER_INFO);
        if userInfo is error {
            return <http:InternalServerError>{
                body: {
                    message: "User information header not found!"
                }
            };
        }

        // Custom Resource level authorization.
        if !authorization:checkPermissions([authorization:authorizedRoles.SALES_TEAM], userInfo.groups) {
            return <http:Forbidden>{
                body: {
                    message: "Insufficient privileges!"
                }
            };
        }

        // Attempt to create the meeting.
        calendar:CreateCalendarEventResponse|error calendarCreateEventResponse = calendar:createCalendarEvent(
            createCalendarEventRequest, userInfo.email);
        if calendarCreateEventResponse is error {
            string customError = string `Error occurred while creating the calendar event!`;
            log:printError(customError, calendarCreateEventResponse);
            return <http:InternalServerError>{
                body: {
                    message: customError
                }
            };
        }

        // Prepare the meeting details to insert into the database.
        database:AddMeetingPayload addMeetingPayload = {
            title: createCalendarEventRequest.title,
            googleEventId: calendarCreateEventResponse.id,
            host: userInfo.email,
            wso2Participants: string:'join(", ", ...createCalendarEventRequest.wso2Participants
                    .map(wso2Participant => wso2Participant.trim())),
            startTime: createCalendarEventRequest.startTime
            .substring(0, createCalendarEventRequest.startTime.length() - 5),
            endTime: createCalendarEventRequest.endTime
            .substring(0, createCalendarEventRequest.endTime.length() - 5)
        };

        // Insert the meeting details into the database.
        int|error meetingId = database:addMeeting(addMeetingPayload, userInfo.email);
        if meetingId is error {
            string customError = string `Error occurred while adding meeting to database!`;
            log:printError(customError, meetingId);
            return <http:InternalServerError>{
                body: {
                    message: customError
                }
            };
        }

        return {message: "Meeting created successfully.", meetingId};
    }

    # Fetch meetings from the database.
    #
    # + title - Name to filter  
    # + host - Host to filter
    # + startTime - Start time to filter
    # + endTime - End time to filter
    # + wso2Participants - Participants to filter
    # + 'limit - Limit of the data  
    # + offset - Offset of the data
    # + return - Meetings | Error
    isolated resource function get meetings(http:RequestContext ctx, string? title, string? host,
            string? startTime, string? endTime, string? wso2Participants, int? 'limit, int? offset)
        returns MeetingListResponse|http:Forbidden|http:InternalServerError {

        // User information header.
        authorization:CustomJwtPayload|error userInfo = ctx.getWithType(authorization:HEADER_USER_INFO);
        if userInfo is error {
            return <http:InternalServerError>{
                body: {
                    message: "User information header not found!"
                }
            };
        }

        // Custom Resource level authorization.
        if !authorization:checkPermissions([authorization:authorizedRoles.SALES_TEAM], userInfo.groups) {
            return <http:Forbidden>{
                body: {
                    message: "Insufficient privileges!"
                }
            };
        }

        boolean isAdmin = authorization:checkPermissions([authorization:authorizedRoles.SALES_ADMIN],
                userInfo.groups);

        // Return Forbidden if a non-admin user provides a host query parameter.
        if (!isAdmin && (host != ()) && (host != userInfo.email)) {
            return <http:Forbidden>{
                body: {message: "Insufficient privileges to filter by host!"}
            };
        }

        // Determine the host filter based on user role.
        string? filteredHost = isAdmin ? (host != () ? host : ()) : userInfo.email;

        // Fetch the meetings from the database.
        database:Meeting[]|error meetings = database:fetchMeetings(title, filteredHost, startTime, endTime,
            wso2Participants, 'limit, offset);
        if meetings is error {
            string customError = string `Error occurred while retrieving the meetings!`;
            log:printError(customError, meetings);
            return <http:InternalServerError>{
                body: {
                    message: customError
                }
            };
        }

        return {
            count: (meetings.length() > 0) ? meetings[0].totalCount : 0,
            meetings: from var meeting in meetings
                select {
                    meetingId: meeting.meetingId,
                    title: meeting.title,
                    googleEventId: meeting.googleEventId,
                    host: meeting.host,
                    startTime: meeting.startTime,
                    endTime: meeting.endTime,
                    wso2Participants: meeting.wso2Participants,
                    meetingStatus: meeting.meetingStatus,
                    timeStatus: meeting.timeStatus
                }
        };
    }

    # Get attachments of a meeting.
    #
    # + meetingId - meetingId to get attachments 
    # + return - Attachments|Error
    isolated resource function get meetings/[int meetingId]/attachments(http:RequestContext ctx)
        returns AttachmentListResponse|http:InternalServerError|http:Forbidden {

        // User information header.
        authorization:CustomJwtPayload|error userInfo = ctx.getWithType(authorization:HEADER_USER_INFO);
        if userInfo is error {
            return <http:InternalServerError>{
                body: {
                    message: "User information header not found!"
                }
            };
        }

        // Custom Resource level authorization.
        if !authorization:checkPermissions([authorization:authorizedRoles.SALES_TEAM], userInfo.groups) {
            return <http:Forbidden>{
                body: {
                    message: "Insufficient privileges!"
                }
            };
        }

        // Fetch the meeting from the database.
        database:Meeting|error? meeting = database:fetchMeeting(meetingId);
        if meeting is error {
            string customError = string `Error occurred while fetching the meeting!`;
            log:printError(customError, meeting);
            return <http:InternalServerError>{
                body: {
                    message: customError
                }
            };
        }
        if meeting is null {
            string customError = string `Meeting not found!`;
            log:printError(customError);
            return <http:InternalServerError>{
                body: {
                    message: customError
                }
            };
        }

        boolean isAdmin = authorization:checkPermissions([authorization:authorizedRoles.SALES_ADMIN],
                userInfo.groups);

        // Return Forbidden if a non-admin user views attachments of a meeting they did not host.
        if !isAdmin && (meeting.host != userInfo.email) {
            return <http:Forbidden>{
                body: {message: "Insufficient privileges to view the attachments!"}
            };
        }

        // Fetch the attachments of the meeting.
        gcalendar:Attachment[]|error? calendarEventAttachments = calendar:getCalendarEventAttachments(
                meeting.googleEventId);
        if calendarEventAttachments is error {
            string customError = string `Error occurred while fetching the attachments!`;
            log:printError(customError, calendarEventAttachments);
            return <http:InternalServerError>{
                body: {
                    message: customError
                }
            };
        }

        return {attachments: calendarEventAttachments ?: []};
    }

    # Delete meeting.
    #
    # + meetingId - meetingId to delete  
    # + return - Ok|InternalServerError|Forbidden
    isolated resource function delete meetings/[int meetingId](http:RequestContext ctx)
        returns MeetingDeletionResponse|http:InternalServerError|http:Forbidden {

        // User information header.
        authorization:CustomJwtPayload|error userInfo = ctx.getWithType(authorization:HEADER_USER_INFO);
        if userInfo is error {
            return <http:InternalServerError>{
                body: {
                    message: "User information header not found!"
                }
            };
        }

        // Custom Resource level authorization.
        if !authorization:checkPermissions([authorization:authorizedRoles.SALES_TEAM], userInfo.groups) {
            return <http:Forbidden>{
                body: {
                    message: "Insufficient privileges!"
                }
            };
        }

        // Fetch meeting details.
        database:Meeting|error? meeting = database:fetchMeeting(meetingId);
        if meeting is error {
            string customError = string `Error occurred while deleting the meeting!`;
            log:printError(customError, meeting);
            return <http:InternalServerError>{
                body: {
                    message: customError
                }
            };
        }
        if meeting is null {
            string customError = string `Meeting not found!`;
            log:printError(customError);
            return <http:InternalServerError>{
                body: {
                    message: customError
                }
            };
        }

        boolean isAdmin = authorization:checkPermissions([authorization:authorizedRoles.SALES_ADMIN],
                userInfo.groups);

        // Check if the user has sufficient privileges to delete and ensure the meeting is active and upcoming.
        if !isAdmin && (meeting.host != userInfo.email) {
            return <http:Forbidden>{
                body: {message: "Insufficient privileges to delete the meeting!"}
            };
        }
        if (meeting.meetingStatus != database:ACTIVE) {
            return <http:Forbidden>{
                body: {message: "Cannot delete a meeting that is not active!"}
            };
        }
        if (meeting.timeStatus != database:UPCOMING) {
            return <http:Forbidden>{
                body: {message: "Cannot delete a past meeting!"}
            };
        }

        // Delete the meeting from the calendar.
        calendar:DeleteCalendarEventResponse|error deleteCalendarEventResponse = calendar:deleteCalendarEvent(
                meeting.googleEventId);
        if deleteCalendarEventResponse is error {
            string customError = string `Error occurred while deleting the meeting!`;
            log:printError(customError, deleteCalendarEventResponse);
            return <http:InternalServerError>{
                body: {
                    message: customError
                }
            };
        }

        // Cancel the meeting in the database.
        int|error cancelledMeetingId = database:cancelMeeting(meetingId);
        if cancelledMeetingId is error {
            string customError = string `Error occurred while deleting meeting from database!`;
            log:printError(customError, cancelledMeetingId);
            return <http:InternalServerError>{
                body: {
                    message: customError
                }
            };
        }

        return {message: deleteCalendarEventResponse.message};
    }
}

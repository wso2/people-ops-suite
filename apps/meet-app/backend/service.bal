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
import meet_app.drive;
import meet_app.people;
import meet_app.sales;

import ballerina/cache;
import ballerina/http;
import ballerina/lang.array;
import ballerina/log;
import ballerina/time;
import ballerinax/googleapis.calendar as gcalendar;

public configurable AppConfig appConfig = ?;

final cache:Cache cache = new ({
    capacity: 2000,
    defaultMaxAge: 1800.0,
    cleanupInterval: 900.0
});

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

    # Retrieve application configurations.
    #
    # + return - Application configuration object or error
    resource function get app\-config() returns AppConfig => appConfig;

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

        // Check if the employees are already cached.
        if cache.hasKey(userInfo.email) {
            UserInfoResponse|error cachedUserInfo = cache.get(userInfo.email).ensureType();
            if cachedUserInfo is UserInfoResponse {
                return cachedUserInfo;
            }
        }

        // Fetch the user information from the people service.
        people:Employee|error loggedInUser = people:fetchEmployeesBasicInfo(userInfo.email);
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

        UserInfoResponse userInfoResponse = {...loggedInUser, privileges};

        error? cacheError = cache.put(userInfo.email, userInfoResponse);
        if cacheError is error {
            log:printError("An error occurred while writing user info to the cache", cacheError);
        }
        return userInfoResponse;
    }

    # Fetch list of employees.
    #
    # + ctx - Request object
    # + return - List  of employees | Error
    resource function get employees(http:RequestContext ctx)
        returns people:EmployeeBasic[]|http:InternalServerError {

        // Check if the employees are already cached.
        if cache.hasKey(EMPLOYEES_CACHE_KEY) {
            people:EmployeeBasic[]|error cachedEmployees = cache.get(EMPLOYEES_CACHE_KEY).ensureType();
            if cachedEmployees is people:EmployeeBasic[] {
                return cachedEmployees;
            }
        }

        people:EmployeeBasic[]|error employees = people:getEmployees();
        if employees is error {
            string customError = string `Error occurred while retrieving employees!`;
            log:printError(customError, employees);
            return <http:InternalServerError>{
                body: {
                    message: customError
                }
            };
        }

        employees = from var employee in employees
            order by employee.workEmail.toLowerAscii() ascending
            select employee;

        if employees is error {
            string customError = string `Error occurred while retrieving employees!`;
            log:printError(customError, employees);
            return <http:InternalServerError>{
                body: {
                    message: customError
                }
            };
        }

        error? cacheError = cache.put(EMPLOYEES_CACHE_KEY, employees);
        if cacheError is error {
            log:printError("An error occurred while writing employees to the cache", cacheError);
        }
        return employees;
    }

    # Fetch list of customers from Salesforce.
    #
    # + ctx - Request object
    # + return - List  of customers | Error
    resource function get customers(http:RequestContext ctx)
        returns sales:CustomerBasic[]|http:InternalServerError {

        // Check if the customers are already cached.
        if cache.hasKey(CUSTOMERS_CACHE_KEY) {
            sales:CustomerBasic[]|error cachedCustomers = cache.get(CUSTOMERS_CACHE_KEY).ensureType();
            if cachedCustomers is sales:CustomerBasic[] {
                return cachedCustomers;
            }
        }

        sales:CustomerBasic[]|error customers = sales:getCustomers();
        if customers is error {
            string customError = string `Error occurred while retrieving customers!`;
            log:printError(customError, customers);
            return <http:InternalServerError>{
                body: {
                    message: customError
                }
            };
        }

        customers = from var customer in customers
            order by customer.name.toLowerAscii() ascending
            select customer;

        if customers is error {
            string customError = string `Error occurred while retrieving customers!`;
            log:printError(customError, customers);
            return <http:InternalServerError>{
                body: {
                    message: customError
                }
            };
        }

        error? cacheError = cache.put(CUSTOMERS_CACHE_KEY, customers);
        if cacheError is error {
            log:printError("An error occurred while writing customers to the cache", cacheError);
        }
        return customers;
    }

    # Fetch list of contacts from Salesforce for a given customer ID.
    #
    # + ctx - Request object
    # + return - List  of contacts | Error
    resource function get contacts(http:RequestContext ctx, string customerId)
        returns sales:ContactBasic[]|http:InternalServerError {

        // Check if the contacts are already cached.
        if cache.hasKey(customerId) {
            sales:ContactBasic[]|error cachedContact = cache.get(customerId).ensureType();
            if cachedContact is sales:ContactBasic[] {
                return cachedContact;
            }
        }

        sales:ContactBasic[]|error contacts = sales:getContacts(customerId);
        if contacts is error {
            string customError = string `Error occurred while retrieving contacts!`;
            log:printError(customError, contacts);
            return <http:InternalServerError>{
                body: {
                    message: customError
                }
            };
        }

        contacts = from var contact in contacts
            order by contact.email.toLowerAscii() ascending
            select contact;

        if contacts is error {
            string customError = string `Error occurred while retrieving contacts!`;
            log:printError(customError, contacts);
            return <http:InternalServerError>{
                body: {
                    message: customError
                }
            };
        }

        error? cacheError = cache.put(customerId, contacts);
        if cacheError is error {
            log:printError("An error occurred while writing customers to the cache", cacheError);
        }
        return contacts;
    }

    # Fetch meeting types from the database.
    #
    # + domain - Domain to filter 
    # + return - Meeting types | Error
    resource function get meetings/types(http:RequestContext ctx, string domain)
        returns database:MeetingTypes|http:Forbidden|http:InternalServerError {

        // Fetch the meeting types from the database.
        database:MeetingTypes|error meetingTypes = database:fetchMeetingTypes(domain);
        if meetingTypes is error {
            string customError = string `Error occurred while retrieving the meeting types!`;
            log:printError(customError, meetingTypes);
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
    resource function post meetings(http:RequestContext ctx,
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

        string originalTitle = createCalendarEventRequest.title;
        string meetingType = "General";
        string[] titleParts = re `-`.split(createCalendarEventRequest.title);
        if titleParts.length() == 3 {
            meetingType = titleParts[1].trim();
            createCalendarEventRequest.title = string `${titleParts[0]} - ${titleParts[2]}`;
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
        boolean isRecurring = (createCalendarEventRequest?.isRecurring ?: false);
        string rule = "";
        int[] meetingIds = [];
        if isRecurring {
            gcalendar:Event|error masterEventResp = calendar:getCalendarEvent(calendarCreateEventResponse.id);
            if masterEventResp is error {
                string customError = string `Error occurred while getting master event!`;
                log:printError(customError, masterEventResp);
                return <http:InternalServerError>{
                    body: {
                        message: customError
                    }
                };
            }
            gcalendar:Event masterEvent = masterEventResp;
            string[]? recurrence = masterEvent.recurrence;
            if recurrence is string[] && recurrence.length() > 0 {
                rule = recurrence[0];
            }

            gcalendar:Event[]|error instances = calendar:getEventInstances(calendarCreateEventResponse.id);
            if instances is error {
                string customError = string `Error occurred while fetching recurring instances!`;
                log:printError(customError, instances);
                return <http:InternalServerError>{
                    body: {
                        message: customError
                    }
                };
            }

            foreach gcalendar:Event instance in instances {
                gcalendar:Time? startTime = instance.'start;
                string? dateTimeStart = startTime?.dateTime;
                if dateTimeStart is () {
                    string customError = "No start dateTime";
                    log:printError(customError);
                    return <http:InternalServerError>{
                        body: {
                            message: customError
                        }
                    };
                }
                time:Utc|time:Error utcStartRes = time:utcFromString(dateTimeStart);
                if utcStartRes is time:Error {
                    string customError = "Invalid start time format";
                    log:printError(customError, utcStartRes);
                    return <http:InternalServerError>{
                        body: {
                            message: customError
                        }
                    };
                }
                time:Utc utcStart = utcStartRes;
                string utcStartStr = time:utcToString(utcStart);
                string startTimeDb = utcStartStr.includes(".") ? utcStartStr.substring(0,
                    utcStartStr.length() - 4) : utcStartStr.substring(0, utcStartStr.length() - 1);

                gcalendar:Time? endTime = instance.'end;
                string? dateTimeEnd = endTime?.dateTime;
                if dateTimeEnd is () {
                    string customError = "No end dateTime";
                    log:printError(customError);
                    return <http:InternalServerError>{
                        body: {
                            message: customError
                        }
                    };
                }
                time:Utc|time:Error utcEndRes = time:utcFromString(dateTimeEnd);
                if utcEndRes is time:Error {
                    string customError = "Invalid end time format";
                    log:printError(customError, utcEndRes);
                    return <http:InternalServerError>{
                        body: {
                            message: customError
                        }
                    };
                }
                time:Utc utcEnd = utcEndRes;
                string utcEndStr = time:utcToString(utcEnd);
                string endTimeDb = utcEndStr.includes(".") ? utcEndStr.substring(0,
                    utcEndStr.length() - 4) : utcEndStr.substring(0, utcEndStr.length() - 1);

                database:AddMeetingPayload addMeetingPayload = {
                    title: originalTitle,
                    googleEventId: instance.id,
                    host: userInfo.email,
                    internalParticipants: string:'join(", ", ...createCalendarEventRequest.internalParticipants
                    .map(internalParticipant => internalParticipant.trim())),
                    startTime: startTimeDb,
                    endTime: endTimeDb,
                    isRecurring: true,
                    recurrence_rule: rule,
                    meetingType: meetingType
                };
                int|error meetingId = database:addMeeting(addMeetingPayload, userInfo.email);
                if meetingId is error {
                    string customError = string `Error occurred while adding instance to database: ${instance.id}!`;
                    log:printError(customError, meetingId);
                    return <http:InternalServerError>{
                        body: {
                            message: customError
                        }
                    };
                }
                meetingIds.push(meetingId);
            }
            if meetingIds.length() == 0 {
                return <http:InternalServerError>{
                    body: {
                        message: "No instances added to database!"
                    }
                };
            }
        } else {
            database:AddMeetingPayload addMeetingPayload = {
                title: originalTitle,
                googleEventId: calendarCreateEventResponse.id,
                host: userInfo.email,
                internalParticipants: string:'join(", ", ...createCalendarEventRequest.internalParticipants
                .map(internalParticipant => internalParticipant.trim())),
                startTime: createCalendarEventRequest.startTime
                .substring(0, createCalendarEventRequest.startTime.length() - 6),
                endTime: createCalendarEventRequest.endTime
                .substring(0, createCalendarEventRequest.endTime.length() - 6),
                isRecurring: false,
                recurrence_rule: null,
                meetingType: meetingType
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
            meetingIds.push(meetingId);
        }

        return {message: "Meeting created successfully.", meetingId: meetingIds[0]};
    }

    # Fetch meetings from the database.
    #
    # + title - Name to filter  
    # + host - Host to filter
    # + startTime - Start time to filter
    # + endTime - End time to filter
    # + internalParticipants - Participants to filter
    # + 'limit - Limit of the data  
    # + offset - Offset of the data
    # + return - Meetings | Error
    resource function get meetings(http:RequestContext ctx, string? title, string? host,
            string? startTime, string? endTime, string[]? internalParticipants, int? 'limit, int? offset)
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

        boolean isAdmin = authorization:checkPermissions([authorization:authorizedRoles.SALES_ADMIN], userInfo.groups);

        // Return Forbidden if a non-admin user provides a host query parameter.
        if (!isAdmin && (host != ()) && (host != userInfo.email)) {
            return <http:Forbidden>{
                body: {message: "Insufficient privileges to filter by host!"}
            };
        }

        // Fetch the meetings from the database.
        string? hostOrInternalParticipant = (host is () && !isAdmin) ? userInfo.email : null;
        database:Meeting[]|error meetings = database:fetchMeetings(hostOrInternalParticipant, title, host,
            startTime, endTime, internalParticipants, 'limit, offset);
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
                    internalParticipants: meeting.internalParticipants,
                    meetingStatus: meeting.meetingStatus,
                    timeStatus: meeting.timeStatus,
                    isRecurring: meeting.isRecurring
                }
        };
    }

    # Get attachments of a meeting.
    #
    # + meetingId - meetingId to get attachments 
    # + return - Attachments|Error
    resource function get meetings/[int meetingId]/attachments(http:RequestContext ctx)
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

        boolean isAdmin = authorization:checkPermissions([authorization:authorizedRoles.SALES_ADMIN], userInfo.groups);

        // Return Forbidden if a non-admin user views attachments of a meeting they did not host.
        string:RegExp r = re `,`;
        string user = userInfo.email;
        if !isAdmin && meeting.host != user && r.split(meeting.internalParticipants).indexOf(user) == () {
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

        // Update editor permissions for all available video/mp4 attachments of the meeting.
        foreach gcalendar:Attachment attachment in calendarEventAttachments ?: [] {
            if attachment.mimeType == "video/mp4" {
                drive:DrivePermissionResponse|error permissionResult = drive:setFilePermission(
                    <string>attachment.fileId, drive:EDITOR, drive:USER, meeting.host
                );

                if permissionResult is error {
                    string customError = string `Failed to update Editor permission for the host!`;
                    log:printError(customError, permissionResult);
                }
            }
        }

        return {attachments: calendarEventAttachments ?: []};
    }

    # Delete meeting.
    #
    # + meetingId - meetingId to delete  
    # + return - Ok|InternalServerError|Forbidden
    resource function delete meetings/[int meetingId](http:RequestContext ctx)
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

        boolean isAdmin = authorization:checkPermissions([authorization:authorizedRoles.SALES_ADMIN], userInfo.groups);

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

    # Get analytics for a specific date range.
    #
    # + startDate - Start date in ISO format
    # + endDate - End date in ISO format
    # + return - Statistics or Error
    resource function get stats(http:RequestContext ctx, string startDate, string endDate)
        returns json|http:InternalServerError|http:BadRequest|error {

        // Validate Dates
        time:Utc|error startRes = time:utcFromString(startDate);
        time:Utc|error endRes = time:utcFromString(endDate);

        if startRes is error || endRes is error {
            return <http:BadRequest>{body: {message: "Invalid Date Format"}};
        }
        time:Utc startUtc = startRes;
        time:Utc endUtc = endRes;

        if startUtc[0] > endUtc[0] {
            return <http:BadRequest>{body: {message: "Start Date must be before End Date"}};
        }

        future<map<int>|error> scheduledCounts = start database:getMonthlyScheduledCounts(startDate, endDate);
        future<database:MeetingTypeStat[]|error> meetingTypes = start database:getMeetingTypeStats(startDate, endDate);
        future<json|error> PeopleStats = start getPeopleAnalytics(startDate, endDate);

        time:Civil startCivil = time:utcToCivil(startUtc);
        time:Civil endCivil = time:utcToCivil(endUtc);
        map<future<int|error>> driveFutureMap = {};
        map<json> metaDataMap = {};

        int cursorYear = startCivil.year;
        int cursorMonth = startCivil.month;

        while (true) {
            if (cursorYear > endCivil.year) || (cursorYear == endCivil.year && cursorMonth > endCivil.month) {
                break;
            }
            string monthStr = cursorMonth < 10 ? string `0${cursorMonth}` : cursorMonth.toString();
            string monthKey = string `${cursorYear}-${monthStr}`;
            string queryStartTime = string `${cursorYear}-${monthStr}-01T00:00:00Z`;
            int nextMonthVal = cursorMonth + 1;
            int nextYearVal = cursorYear;

            if (nextMonthVal > 12) {
                nextMonthVal = 1;
                nextYearVal = nextYearVal + 1;
            }
            string nextMonthStr = nextMonthVal < 10 ? string `0${nextMonthVal}` : nextMonthVal.toString();
            string queryEndTime = string `${nextYearVal}-${nextMonthStr}-01T00:00:00Z`;

            if (cursorYear == startCivil.year && cursorMonth == startCivil.month) {
                queryStartTime = startDate;
            }
            if (cursorYear == endCivil.year && cursorMonth == endCivil.month) {
                queryEndTime = endDate;
            }

            // Drive API
            future<int|error> fDrive = start drive:countWso2RecordingsInDateRange(queryStartTime, queryEndTime);
            driveFutureMap[monthKey] = fDrive;
            metaDataMap[monthKey] = {
                "year": cursorYear,
                "month": cursorMonth,
                "key": monthKey
            };

            cursorMonth = cursorMonth + 1;
            if cursorMonth > 12 {
                cursorMonth = 1;
                cursorYear = cursorYear + 1;
            }
        }

        map<int> dbCounts = check wait scheduledCounts;
        map<int|error> driveResults = {};

        foreach string key in driveFutureMap.keys() {
            driveResults[key] = wait driveFutureMap.get(key);
        }
        json[] monthlyStats = [];
        string[] sortedKeys = driveFutureMap.keys().sort(array:DESCENDING);

        foreach string key in sortedKeys {
            json meta = metaDataMap.get(key);
            // Drive Count
            int|error? driveCount = driveResults[key];
            // DB Count
            int scheduledCount = dbCounts.hasKey(key) ? dbCounts.get(key) : 0;

            _ = check meta.mergeJson({
                "recordingCount": (driveCount is int) ? driveCount : 0,
                "scheduledCount": scheduledCount
            });
            monthlyStats.push(meta);
        }
        database:MeetingTypeStat[]|error typeResults = wait meetingTypes;
        json[] typeStatsJson = [];
        if typeResults is database:MeetingTypeStat[] {
            typeStatsJson = <json[]>typeResults.toJson();
        }
        json|error peopleRes = wait PeopleStats;
        json[] regionalStats = [];
        json[] amStats = [];
        if peopleRes is json {
            regionalStats = <json[]>(check peopleRes.regionalStats);
            amStats = <json[]>(check peopleRes.amStats);
        }

        return {
            "monthlyStats": monthlyStats,
            "typeStats": typeStatsJson,
            "regionalStats": regionalStats,
            "amStats": amStats
        };
    }
}

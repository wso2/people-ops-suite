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
import leave_service.authorization;
import leave_service.database;
import leave_service.email;
import leave_service.employee;

import ballerina/http;
import ballerina/log;
import ballerina/time;

@display {
    label: "Leave Backend Service",
    id: "people-ops/leave-application"
}
service http:InterceptableService / on new http:Listener(9090) {

    # Request interceptor.
    # + return - authorization:JwtInterceptor
    public function createInterceptors() returns http:Interceptor[] => [new authorization:JwtInterceptor()];

    function init() returns error? => log:printInfo("Leave application backend service started.");

    # Get leaves for the given filters.
    #
    # + ctx - HTTP request context
    # + email - Email of the user to filter the leaves
    # + startDate - Start date filter
    # + endDate - End date filter
    # + isActive - Whether to filter active or inactive leaves
    # + return - List of leaves
    resource function get leaves(http:RequestContext ctx, string? email = (), string? startDate = (),
            string? endDate = (), boolean? isActive = (), int? 'limit = (), int? offset = 0
    ) returns FetchedLeavesRecord|http:Forbidden|http:InternalServerError|http:BadRequest {

        if email is string && !email.matches(WSO2_EMAIL_PATTERN) {
            return <http:BadRequest>{
                body: {
                    message: string `${ERR_MSG_INVALID_WSO2_EMAIL} ${email}`
                }
            };
        }

        do {
            readonly & authorization:CustomJwtPayload userInfo = check ctx.getWithType(authorization:HEADER_USER_INFO);
            string jwt = check ctx.getWithType(authorization:INVOKER_TOKEN);
            if email != userInfo.email {
                boolean validateForSingleRole = authorization:validateForSingleRole(userInfo,
                        authorization:authorizedRoles.adminRoles);
                if !validateForSingleRole {
                    log:printWarn(string `The user ${userInfo.email} was not privileged to access the resource 
                        /leaves with email=${email.toString()}`);
                    return <http:Forbidden>{
                        body: {
                            message: ERR_MSG_UNAUTHORIZED_VIEW_LEAVE
                        }
                    };
                }
            }

            string[]? emails = (email is string) ? [email] : ();
            database:Leave[]|error leaves = database:getLeaves({emails, isActive, startDate, endDate});
            if leaves is error {
                fail error(ERR_MSG_LEAVES_RETRIEVAL_FAILED, leaves);
            }
            LeaveResponse[] leaveResponses = from database:Leave leave in leaves
                select check toLeaveEntity(leave, jwt);

            Leave[] leavesFinalResult = [];
            map<float> statsMap = {};
            float totalCount = 0.0;
            foreach LeaveResponse leaveResponse in leaveResponses {
                var {
                id,
                createdDate,
                leaveType,
                endDate: entityEndDate,
                isActive: entityIsActive,
                periodType,
                startDate: entityStartDate,
                email: entityEmail,
                isMorningLeave,
                numberOfDays
                } = leaveResponse;

                leavesFinalResult.push({
                    id,
                    createdDate,
                    leaveType,
                    endDate: entityEndDate,
                    isActive: entityIsActive,
                    periodType,
                    startDate: entityStartDate,
                    email: entityEmail,
                    isMorningLeave,
                    numberOfDays,
                    isCancelAllowed: checkIfLeavedAllowedToCancel(leaveResponse)
                });
                statsMap[leaveType] = statsMap.hasKey(leaveType) ?
                    statsMap.get(leaveType) + numberOfDays : numberOfDays;
                if leaveType !is database:LIEU_LEAVE {
                    totalCount += numberOfDays;
                }
            }
            statsMap[TOTAL_LEAVE_TYPE] = totalCount;
            return {
                leaves,
                stats: from [string, float] ['type, count] in statsMap.entries()
                    select {
                        'type,
                        count
                    }
            };

        } on fail error internalErr {
            log:printError(internalErr.message(), internalErr);
            return <http:InternalServerError>{
                body: {
                    message: internalErr.message()
                }
            };
        }
    }

    # Create a new leave.
    #
    # + ctx - HTTP request context
    # + payload - Request payload
    # + isValidationOnlyMode - Whether to validate the leave or create the leave
    # + return - Success response if the leave is created successfully, otherwise an error response
    resource function post leaves(http:RequestContext ctx, LeavePayload payload, boolean isValidationOnlyMode = false)
        returns CalculatedLeave|http:Ok|http:BadRequest|http:InternalServerError {

        do {
            readonly & authorization:CustomJwtPayload userInfo = check ctx.getWithType(authorization:HEADER_USER_INFO);
            string jwt = check ctx.getWithType(authorization:INVOKER_TOKEN);
            string email = userInfo.email;
            log:printInfo(string `Leave${isValidationOnlyMode ? " validation " : " "}request received from email: ${
                    email} with payload: ${payload.toString()}`);

            [time:Utc, time:Utc]|error validatedDateRange = validateDateRange(payload.startDate, payload.endDate);
            if validatedDateRange is error {
                log:printError(ERR_MSG_INVALID_DATE_FORMAT, validatedDateRange);
                return <http:BadRequest>{
                    body: {
                        message: ERR_MSG_INVALID_DATE_FORMAT
                    }
                };
            }
            // Day[] weekdaysFromRange = getWeekdaysFromRange(validatedDateRange[0], validatedDateRange[1]);
            LeaveInput input = {
                email,
                startDate: payload.startDate,
                endDate: payload.endDate,
                leaveType: payload.leaveType,
                periodType: payload.periodType,
                isMorningLeave: payload.isMorningLeave,
                emailRecipients: payload.emailRecipients,
                calendarEventId: payload.calendarEventId,
                comment: payload.comment,
                isPublicComment: payload.isPublicComment,
                emailSubject: payload.emailSubject
            };
            if isValidationOnlyMode {
                LeaveDetails|error validatedLeave = insertLeaveToDatabase(input, isValidationOnlyMode, jwt);
                if validatedLeave is error {
                    fail error(validatedLeave.message(), validatedLeave);
                }

                return {
                    workingDays: payload.periodType is database:HALF_DAY_LEAVE
                        ? 0.5
                        : <float>validatedLeave.effectiveDays.length(),
                    hasOverlap: false,
                    message: "Valid leave request"
                };
            }

            final readonly & email:EmailNotificationDetails emailContentForLeave = check email:generateContentForLeave(
                    jwt, email, payload
            );
            final readonly & string calendarEventId = createUuidForCalendarEvent();
            final readonly & string[]|error allRecipientsForUser = getAllEmailRecipientsForUser(
                    email,
                    payload.emailRecipients,
                    jwt
            );
            if allRecipientsForUser is error {
                fail error(allRecipientsForUser.message(), allRecipientsForUser);
            }
            final readonly & string? comment = payload.comment;

            payload.emailSubject = emailContentForLeave.subject;
            payload.calendarEventId = calendarEventId;

            LeaveDetails|error leave = insertLeaveToDatabase(input, isValidationOnlyMode, jwt);
            if leave is error {
                fail error(leave.message(), leave);
            }
            final readonly & LeaveResponse leaveResponse = {
                id: leave.id,
                startDate: leave.startDate,
                calendarEventId: leave.calendarEventId,
                periodType: leave.periodType,
                createdDate: leave.createdDate,
                leaveType: leave.leaveType,
                endDate: leave.endDate,
                location: leave.location,
                numberOfDays: leave.numberOfDays ?: 0.0,
                isActive: leave.isActive,
                email: leave.email,
                isMorningLeave: leave.isMorningLeave
            };
            log:printInfo(string `Submitted leave successfully. ID: ${leaveResponse.id}.`);

            future<error?> notificationFuture = start email:sendLeaveNotification(
                    emailContentForLeave,
                    allRecipientsForUser
            );
            _ = start createLeaveEventInCalendar(email, leaveResponse, calendarEventId);
            if comment is string && checkIfEmptyString(comment) {
                string[] commentRecipients = allRecipientsForUser;
                if !payload.isPublicComment {
                    commentRecipients = check getPrivateRecipientsForUser(
                            email,
                            payload.emailRecipients,
                            jwt
                    );
                }

                error? notificationResult = wait notificationFuture;
                if notificationResult is () {
                    // Does not send the additional comment notification if the main notification has failed
                    final email:EmailNotificationDetails contentForAdditionalComment =
                        email:generateContentForAdditionalComment(emailContentForLeave.subject, comment);
                    _ = start email:sendAdditionalComment(contentForAdditionalComment.cloneReadOnly(),
                            commentRecipients.cloneReadOnly());
                }
            }

            return <http:Ok>{
                body: {
                    message: "Leave submitted successfully"
                }
            };

        } on fail error internalErr {
            log:printError(internalErr.message(), internalErr);
            return <http:InternalServerError>{
                body: {
                    message: internalErr.message()
                }
            };
        }
    }

    # Cancel a leave.
    #
    # + leaveId - Leave ID
    # + ctx - Request context
    # + return - Cancelled leave on success, otherwise an error response
    resource function delete leaves/[int leaveId](http:RequestContext ctx)
        returns http:Ok|http:Forbidden|http:BadRequest|http:InternalServerError {

        do {
            readonly & authorization:CustomJwtPayload userInfo = check ctx.getWithType(authorization:HEADER_USER_INFO);
            string jwt = check ctx.getWithType(authorization:INVOKER_TOKEN);
            final database:Leave|error? leave = database:getLeave(leaveId);
            if leave is () {
                return <http:BadRequest>{
                    body: {
                        message: "Invalid leave ID!"
                    }
                };
            }
            if leave is error {
                fail error(ERR_MSG_LEAVE_RETRIEVAL_FAILED, leave);
            }

            LeaveResponse leaveResponse = check toLeaveEntity(leave, jwt);
            final string email = userInfo.email;
            if leaveResponse.email != email {
                boolean validateForSingleRole = authorization:validateForSingleRole(userInfo,
                        authorization:authorizedRoles.adminRoles);
                if !validateForSingleRole {
                    return <http:Forbidden>{
                        body: {
                            message: "You are not authorized to cancel this leave!"
                        }
                    };
                }
            }
            if !leaveResponse.isActive {
                return <http:BadRequest>{
                    body: {
                        message: "Leave is already cancelled!"
                    }
                };
            }

            any|error result = database:cancelLeave(leaveId);
            if result is error {
                fail error(result.message(), result);
            }
            database:Leave|error? cancelledLeave = database:getLeave(leaveId);
            if cancelledLeave is error? {
                fail error("Error occurred when fetching cancelled leave!", cancelledLeave);
            }

            LeaveDetails|error cancelledLeaveDetails = getLeaveEntityFromDbRecord(cancelledLeave, jwt, true);
            if cancelledLeaveDetails is error {
                fail error(cancelledLeaveDetails.message(), cancelledLeaveDetails);
            }

            email:EmailNotificationDetails generateContentForLeave = check email:generateContentForLeave(
                    jwt,
                    email,
                    leaveResponse,
                    isCancel = true,
                    emailSubject = cancelledLeaveDetails.emailSubject
            );
            string[] allRecipientsForUser = check getAllEmailRecipientsForUser(
                    email,
                    cancelledLeaveDetails.emailRecipients,
                    jwt
            );
            _ = start email:sendLeaveNotification(
                    generateContentForLeave.cloneReadOnly(),
                    allRecipientsForUser.cloneReadOnly()
            );

            if cancelledLeaveDetails.calendarEventId is () {
                log:printError(string `Calendar event ID is not available for leave with ID: ${leaveId}.`);
            } else {
                _ = start deleteLeaveEventFromCalendar(email, <string>cancelledLeaveDetails.calendarEventId);
            }

            return <http:Ok>{
                body: {
                    message: "Leave cancelled successfully"
                }
            };

        } on fail error internalErr {
            log:printError(internalErr.message(), internalErr);
            return <http:InternalServerError>{
                body: {
                    message: internalErr.message()
                }
            };
        }
    }

    # Get Application specific data required for initializing the leave form.
    #
    # + ctx - HTTP request context
    # + return - Form data related to leaves
    resource function get form\-data(http:RequestContext ctx) returns FormData|http:InternalServerError {

        do {
            authorization:CustomJwtPayload {email} = check ctx.getWithType(authorization:HEADER_USER_INFO);
            string jwt = check ctx.getWithType(authorization:INVOKER_TOKEN);
            final readonly & string[] emails = [email];
            final string startDate = getStartDateOfYear();
            final string endDate = getEndDateOfYear();
            final database:Leave[]|error leaves = database:getLeaves(
                    {emails, startDate, endDate, orderBy: database:DESC}
            );
            if leaves is error {
                fail error(ERR_MSG_LEAVES_RETRIEVAL_FAILED, leaves);
            }
            LeaveResponse[] leaveResponses = from database:Leave leave in leaves
                select check toLeaveEntity(leave, jwt);

            Employee & readonly employee = check employee:getEmployee(email, jwt);
            Employee {leadEmail, location} = employee;
            string[] emailRecipients = leaveResponses.length() > 0 ? leaveResponses[0].emailRecipients : [];
            string[] leadEmails = leadEmail == () ? [] : [leadEmail];
            LeavePolicy|error legallyEntitledLeave = getLegallyEntitledLeave(employee);
            if legallyEntitledLeave is error {
                fail error(employee:ERR_MSG_EMPLOYEES_RETRIEVAL_FAILED, legallyEntitledLeave);
            }

            return {
                emailRecipients,
                leadEmails,
                isLead: <boolean>employee.lead,
                location,
                legallyEntitledLeave,
                leaveReportContent: getLeaveReportContent(leaveResponses)
            };

        } on fail error internalErr {
            log:printError(internalErr.message(), internalErr);
            return <http:InternalServerError>{
                body: {
                    message: internalErr.message()
                }
            };
        }
    }

    # Fetch all the employees.
    #
    # + ctx - HTTP request context
    # + location - Employee location
    # + businessUnit - Employee business unit
    # + team - Employee team
    # + unit - Employee unit
    # + employeeStatuses - Employee statuses to filter the employees
    # + leadEmail - Manager email to filter the employees
    # + return - List of employee records
    resource function get employees(http:RequestContext ctx, string? location, string? businessUnit, string? team,
            string? unit, string[]? employeeStatuses, string? leadEmail) returns Employee[]|http:InternalServerError {

        do {
            string jwt = check ctx.getWithType(authorization:INVOKER_TOKEN);
            Employee[] & readonly employees = check employee:getEmployees(
                    jwt,
                    {
                        location,
                        businessUnit,
                        team,
                        unit,
                        status: employeeStatuses,
                        leadEmail
                    },
                    'limit = 1000,
                    offset = 0
            );

            Employee[] employeesToReturn = from Employee employee in employees
                select {
                    employeeId: employee.employeeId,
                    firstName: employee.firstName,
                    lastName: employee.lastName,
                    workEmail: employee.workEmail,
                    employeeThumbnail: employee.employeeThumbnail,
                    location: employee.location,
                    leadEmail: employee.leadEmail,
                    startDate: employee.startDate,
                    finalDayOfEmployment: employee.finalDayOfEmployment,
                    lead: employee.lead
                };

            return employeesToReturn;

        } on fail error internalErr {
            log:printError(internalErr.message(), internalErr);
            return <http:InternalServerError>{
                body: {
                    message: internalErr.message()
                }
            };
        }
    }

    # Fetch an employee by email.
    #
    # + ctx - HTTP request context
    # + return - The employee record
    resource function get employees/[string email](http:RequestContext ctx)
        returns Employee|http:InternalServerError|http:BadRequest {

        if !email.matches(WSO2_EMAIL_PATTERN) {
            return <http:BadRequest>{
                body: {
                    message: string `${ERR_MSG_INVALID_WSO2_EMAIL} ${email}`
                }
            };
        }

        do {
            string jwt = check ctx.getWithType(authorization:INVOKER_TOKEN);
            Employee & readonly employee = check employee:getEmployee(email, jwt);

            return {
                employeeId: employee.employeeId,
                firstName: employee.firstName,
                lastName: employee.lastName,
                workEmail: employee.workEmail,
                employeeThumbnail: employee.employeeThumbnail,
                location: employee.location,
                leadEmail: employee.leadEmail,
                startDate: employee.startDate,
                finalDayOfEmployment: employee.finalDayOfEmployment,
                lead: employee.lead
            };

        } on fail error internalErr {
            log:printError(internalErr.message(), internalErr);
            return <http:InternalServerError>{
                body: {
                    message: internalErr.message()
                }
            };
        }
    }

    # Fetch legally entitled leave for the given employee.
    #
    # + ctx - HTTP request context
    # + years - Years to fetch leave entitlement. Empty array will fetch leave entitlement for current year
    # + return - Leave entitlement
    resource function get employees/[string email]/leave\-entitlement(http:RequestContext ctx, int[]? years = ())
        returns LeaveEntitlement[]|http:BadRequest|http:Forbidden|http:InternalServerError {

        if !email.matches(WSO2_EMAIL_PATTERN) {
            return <http:BadRequest>{
                body: {
                    message: string `${ERR_MSG_INVALID_WSO2_EMAIL} ${email}`
                }
            };
        }

        do {
            readonly & authorization:CustomJwtPayload userInfo = check ctx.getWithType(authorization:HEADER_USER_INFO);
            string jwt = check ctx.getWithType(authorization:INVOKER_TOKEN);
            if email != userInfo.email {
                boolean validateForSingleRole = authorization:validateForSingleRole(userInfo,
                        authorization:authorizedRoles.adminRoles);
                if !validateForSingleRole {
                    log:printWarn(string `The user ${userInfo.email} was not privileged to access the${false ?
                                " admin " : " "}resource /leave-entitlement with email=${email.toString()}`);
                    return <http:Forbidden>{
                        body: {
                            message: ERR_MSG_UNAUTHORIZED_VIEW_LEAVE
                        }
                    };
                }
            }

            Employee & readonly employee = check employee:getEmployee(email, jwt);
            LeaveEntitlement[]|error leaveEntitlements = getLeaveEntitlement(employee, jwt, years ?: []);
            if leaveEntitlements is error {
                fail error("Error occurred while retrieving leave entitlement!", leaveEntitlements);
            }

            return leaveEntitlements;

        } on fail error internalErr {
            log:printError(internalErr.message(), internalErr);
            return <http:InternalServerError>{
                body: {
                    message: internalErr.message()
                }
            };
        }
    }

    # Fetch user calendar.
    #
    # + ctx - Request context
    # + startDate - Start date of the calendar
    # + endDate - End date of the calendar
    # + return - User calendar
    resource function get user\-calendar(http:RequestContext ctx, string startDate, string endDate)
        returns UserCalendarInformation|http:InternalServerError {

        do {
            authorization:CustomJwtPayload {email} = check ctx.getWithType(authorization:HEADER_USER_INFO);
            string jwt = check ctx.getWithType(authorization:INVOKER_TOKEN);
            UserCalendarInformation|http:InternalServerError|error userCalendarInformation =
                getUserCalendarInformation(email, startDate, endDate, jwt);
            if userCalendarInformation is error {
                return {
                    body: {
                        message: userCalendarInformation.message()
                    }
                };
            }

            return userCalendarInformation;

        } on fail error internalErr {
            log:printError(internalErr.message(), internalErr);
            return <http:InternalServerError>{
                body: {
                    message: internalErr.message()
                }
            };
        }
    }

    # Fetch report filters required for the reports UI.
    #
    # + employeeStatuses - Employee statuses to filter the employees
    # + return - Report filters
    resource function get report\-filters(http:RequestContext ctx, string[]? employeeStatuses, string[]? businessUnits,
            int[]? businessUnitIds) returns ReportFilters|http:BadRequest|http:InternalServerError {

        do {
            string jwt = check ctx.getWithType(authorization:INVOKER_TOKEN);
            employee:OrgStructure|error orgStructure = employee:getOrgStructure(
                    {employeeStatuses, businessUnits, businessUnitIds}, jwt);
            if orgStructure is error {
                fail error("Error occurred while retrieving organization structure data!", orgStructure);
            }

            Employee[] & readonly employees = check employee:getEmployees(jwt, {status: employeeStatuses});
            string[] countries = from Employee employee in employees
                let string country = employee.location ?: ""
                group by country
                select country;

            return {
                countries,
                orgStructure,
                employeeStatuses: [EMP_STATUS_ACTIVE, EMP_STATUS_LEFT, EMP_STATUS_MARKED_LEAVER]
            };

        } on fail error internalErr {
            log:printError(internalErr.message(), internalErr);
            return <http:InternalServerError>{
                body: {
                    message: internalErr.message()
                }
            };
        }

    }

    # Generate and fetch leave reports for admins and leads.
    #
    # + ctx - Request context
    # + payload - Request payload
    # + return - Leave report or lead-specific leave report
    resource function post leaves/report(http:RequestContext ctx, ReportPayload payload)
        returns ReportContent|http:Forbidden|http:InternalServerError {

        do {
            authorization:CustomJwtPayload {email, groups} = check ctx.getWithType(authorization:HEADER_USER_INFO);
            string jwt = check ctx.getWithType(authorization:INVOKER_TOKEN);

            boolean isAdmin = authorization:checkRoles(authorization:authorizedRoles.adminRoles, groups);
            Employee[] & readonly employees;

            employees = check employee:getEmployees(
                    jwt,
                    {
                        location: payload.location,
                        businessUnit: payload.businessUnit,
                        team: payload.department,
                        unit: payload.team,
                        status: payload.employeeStatuses,
                        leadEmail: isAdmin ? () : email
                    }
                );
            string[] emails = from Employee employee in employees
                select employee.workEmail ?: "";

            if !isAdmin && emails.length() == 0 {
                return <http:Forbidden>{
                    body: {
                        message: "You have not been assigned as a lead/manager to any employee!"
                    }
                };
            }

            final database:Leave[]|error leaves = database:getLeaves(
                    {emails, isActive: true, startDate: payload.startDate, endDate: payload.endDate}
            );
            if leaves is error {
                fail error(ERR_MSG_LEAVES_RETRIEVAL_FAILED, leaves);
            }

            LeaveResponse[] leaveResponses = from database:Leave leave in leaves
                select check toLeaveEntity(leave, jwt);

            return getLeaveReportContent(leaveResponses);

        } on fail error internalErr {
            log:printError(internalErr.message(), internalErr);
            return <http:InternalServerError>{
                body: {
                    message: internalErr.message()
                }
            };
        }
    }
}

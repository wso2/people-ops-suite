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
import timesheet_app.authorization;
import timesheet_app.database;
import timesheet_app.entity;

import ballerina/cache;
import ballerina/http;
import ballerina/log;

final cache:Cache userInfoCache = new (capacity = 100, evictionFactor = 0.2);

@display {
    label: "Timesheet Application",
    id: "hris/timesheet-application"
}
service http:InterceptableService / on new http:Listener(9090) {

    # Request interceptor.
    # + return - authorization:JwtInterceptor
    public function createInterceptors() returns http:Interceptor[] => [new authorization:JwtInterceptor()];

    # Get the user information of the invoker.
    #
    # + ctx - Request Context
    # + return - Internal Server Error or Employee information object
    resource function get user\-info(http:RequestContext ctx)
        returns EmployeeInformation|http:InternalServerError|http:BadRequest|http:Forbidden {

        authorization:CustomJwtPayload|error userInfo = ctx.getWithType(authorization:HEADER_USER_INFO);
        if userInfo is error {
            return <http:BadRequest>{
                body: {
                    message: "User information header not found!"
                }
            };
        }

        if !authorization:checkPermissions([authorization:authorizedRoles.employeeRole], userInfo.groups) {
            return <http:Forbidden>{
                body: {
                    message: "Insufficient privileges!"
                }
            };
        }

        entity:Employee|error employeeInfo = entity:fetchEmployeesBasicInfo(userInfo.email);
        if employeeInfo is error {
            string customError = string `Error occurred while retrieving user data: ${userInfo.email}!`;
            log:printError(customError, employeeInfo);
            return <http:InternalServerError>{
                body: {
                    message: customError
                }
            };
        }

        database:WorkPolicies|error workPolicies = database:getWorkPolicies(employeeInfo.company).ensureType();
        if workPolicies is error {
            string customError =
                string `Error occurred while retrieving work policy for ${userInfo.email} and ${employeeInfo.company}!`;
            log:printError(customError, workPolicies);
            return <http:InternalServerError>{
                body: {
                    message: customError
                }
            };
        }

        if workPolicies.isSystemActivated == false {
            return <http:Forbidden>{
                body: {
                    message: "System is not enabled for the user company"
                }
            };
        }

        int[] privileges = [EMPLOYEE_PRIVILEGE];
        if authorization:checkPermissions([authorization:authorizedRoles.adminRole], userInfo.groups) {
            privileges.push(HR_ADMIN_PRIVILEGE);
        }
        if authorization:checkPermissions([authorization:authorizedRoles.leadRole], userInfo.groups) {
            privileges.push(LEAD_PRIVILEGE);
        }

        return {
            employeeInfo,
            privileges,
            workPolicies
        };
    }

    # The resource function to get employees information.
    #
    # + ctx - The request context
    # + return - The employees information or an error
    resource function get employees(http:RequestContext ctx)
        returns entity:Employee[]|http:InternalServerError|http:BadRequest|http:Forbidden {

        authorization:CustomJwtPayload|error userInfo = ctx.getWithType(authorization:HEADER_USER_INFO);
        if userInfo is error {
            return <http:BadRequest>{
                body: {
                    message: "User information header not found!"
                }
            };
        }

        if !authorization:checkPermissions([authorization:authorizedRoles.employeeRole], userInfo.groups) {
            return <http:Forbidden>{
                body: {
                    message: "Insufficient privileges!"
                }
            };
        }

        entity:Employee[]|error employees = entity:getAllActiveEmployees();
        if employees is error {
            string customError = "Error occurred while retrieving employees!";
            log:printError(customError, employees);
            return <http:InternalServerError>{
                body: {
                    message: customError
                }
            };
        }
        return employees;
    }

    # Endpoint to save timesheet records of an employee.
    #
    # + recordPayload - Timesheet record payload
    # + employeeEmail - Email of the employee
    # + return - Created status or error status's
    isolated resource function post time\-logs/[string employeeEmail](http:RequestContext ctx,
            database:TimeLog[] recordPayload)
        returns http:InternalServerError|http:Created|http:BadRequest|http:Forbidden {

        authorization:CustomJwtPayload|error userInfo = ctx.getWithType(authorization:HEADER_USER_INFO);
        if userInfo is error {
            return <http:BadRequest>{
                body: {
                    message: "User information header not found!"
                }
            };
        }

        if !authorization:checkPermissions([authorization:authorizedRoles.employeeRole], userInfo.groups) {
            return <http:Forbidden>{
                body: {
                    message: "Insufficient privileges!"
                }
            };
        }

        if employeeEmail !== userInfo.email {
            return <http:Forbidden>{
                body: {
                    message: "You can not save time logs of another employee!"
                }
            };
        }

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

        string[] newRecordDates = [];
        foreach database:TimeLog newRecord in recordPayload {
            if newRecord.overtimeReason == "" && ((newRecord.overtimeDuration ?: 0d) > 0d) {
                string customError = "Overtime reason required for records with overtime!";
                log:printError(customError);
                return <http:InternalServerError>{
                    body: {
                        message: customError
                    }
                };
            }
            newRecord.overtimeStatus = (newRecord.overtimeReason is string)
                && ((newRecord.overtimeDuration ?: 0d) > 0d) ? database:PENDING : database:APPROVED;
            newRecordDates.push(newRecord.recordDate);
        }

        database:TimesheetCommonFilter filter = {
            employeeEmail,
            leadEmail: loggedInUser.managerEmail,
            status: (),
            recordsLimit: (),
            recordOffset: (),
            rangeStart: (),
            rangeEnd: (),
            recordDates: newRecordDates,
            companyName: (),
            recordIds: ()
        };

        database:TimeLog[]|error? existingRecords = database:getTimesheetRecords(filter);
        if existingRecords is error {
            string customError = "Error occurred while retrieving the existing timesheet records!";
            log:printError(customError, existingRecords);
            return <http:InternalServerError>{
                body: {
                    message: customError
                }
            };
        }

        string[] errorDuplicates = [];
        if existingRecords !is () && existingRecords.length() > 0 {
            foreach database:TimeLog existingRecord in existingRecords {
                if existingRecord.overtimeStatus != database:REJECTED {
                    errorDuplicates.push(existingRecord.recordDate);
                }
            }
            if errorDuplicates.length() > 0 {
                string customError =
                    string `Duplicated dates found ${string:'join(", ", ...errorDuplicates.map(r => r.toString()))}!`;
                return <http:BadRequest>{
                    body: {
                        message: customError
                    }
                };
            }

        }

        error|int[] insertResult = database:insertTimesheetRecords(recordPayload,
                loggedInUser.workEmail, loggedInUser.company, <string>loggedInUser.managerEmail);

        if insertResult is error {
            string customError = string `Error occurred while saving the records for ${loggedInUser.workEmail}!`;
            log:printError(customError, insertResult);
            return <http:InternalServerError>{
                body: {
                    message: customError
                }
            };
        }
        return http:CREATED;
    }

    # Endpoint to get time logs using the common filter.
    #
    # + 'limit - Limit of the response
    # + status - Status of the time logs
    # + rangeStart - Start date of the time logs
    # + rangeEnd - End date of the time logs
    # + offset - Offset of time logs to retrieve
    # + employeeEmail - Email of the employee to filter time logs
    # + return - time logs or an error
    isolated resource function get time\-logs(http:RequestContext ctx, string? employeeEmail, int? 'limit,
            string? leadEmail, database:TimesheetStatus? status, int? offset, string? rangeStart, string? rangeEnd)
        returns TimeSheetRecords|http:Forbidden|http:BadRequest|http:InternalServerError {

        authorization:CustomJwtPayload|error userInfo = ctx.getWithType(authorization:HEADER_USER_INFO);
        if userInfo is error {
            return <http:BadRequest>{
                body: {
                    message: "User information header not found!"
                }
            };
        }

        if !authorization:checkPermissions([authorization:authorizedRoles.employeeRole], userInfo.groups) {
            return <http:Forbidden>{
                body: {
                    message: "Insufficient privileges!"
                }
            };
        }

        database:TimesheetCommonFilter commonFilter = {
            employeeEmail: employeeEmail,
            leadEmail: leadEmail,
            status: status,
            recordsLimit: 'limit,
            recordOffset: offset,
            rangeStart: rangeStart,
            rangeEnd: rangeEnd,
            recordDates: (),
            companyName: (),
            recordIds: ()
        };

        int|error? totalRecordCount = database:getTotalRecordCount(commonFilter);
        if totalRecordCount is error {
            string customError = "Error occurred while retrieving the record count!";
            log:printError(customError, totalRecordCount);
            return <http:InternalServerError>{
                body: {
                    message: customError
                }
            };
        }

        database:TimeLog[]|error? timeLogs = database:getTimesheetRecords(commonFilter);
        if timeLogs is error {
            string customError = "Error occurred while retrieving the timeLogs!";
            log:printError(customError, timeLogs);
            return <http:InternalServerError>{
                body: {
                    message: customError
                }
            };
        }

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

        string|null emailToFilter = ();
        if authorization:checkPermissions([authorization:authorizedRoles.leadRole], userInfo.groups) {
            if userInfo.email !== employeeEmail {
                emailToFilter = userInfo.email;
            }
        }

        database:TimesheetCommonFilter infoFilter = {
            employeeEmail: emailToFilter is string ? () : employeeEmail,
            leadEmail: emailToFilter is string ? emailToFilter : (),
            status: (),
            recordsLimit: (),
            recordOffset: (),
            rangeStart: (),
            rangeEnd: (),
            recordDates: (),
            companyName: loggedInUser.company,
            recordIds: ()
        };
        database:TimesheetInfo|error? timesheetInfo = database:getTimesheetInfo(infoFilter);
        if timesheetInfo is error {
            string customError = "Error occurred while retrieving the timesheet information!";
            log:printError(customError, timesheetInfo);
            return <http:InternalServerError>{
                body: {
                    message: customError
                }
            };
        }

        return {
            totalRecordCount,
            timeLogs,
            timesheetInfo: timesheetInfo ?: ()
        };
    }

    # Endpoint to patch timesheet records.
    #
    # + recordPayload - TimeLogReview payload
    # + return - Ok status or error status's
    isolated resource function patch time\-logs(http:RequestContext ctx, database:TimeLogReview recordPayload)
        returns http:InternalServerError|http:Ok|http:BadRequest|http:Forbidden {

        authorization:CustomJwtPayload|error userInfo = ctx.getWithType(authorization:HEADER_USER_INFO);
        if userInfo is error {
            return <http:BadRequest>{
                body: {
                    message: "User information header not found!"
                }
            };
        }

        if !authorization:checkPermissions([authorization:authorizedRoles.leadRole], userInfo.groups) {
            return <http:Forbidden>{
                body: {
                    message: "Insufficient privileges!"
                }
            };
        }

        if recordPayload.overtimeStatus == database:REJECTED &&
            (recordPayload.overtimeRejectReason == "" || recordPayload.overtimeRejectReason is ()) {
            string customError = "Overtime rejection reason required for rejected records!";
            log:printError(customError);
            return <http:InternalServerError>{
                body: {
                    message: customError
                }
            };
        }

        error? timesheetRecords = database:updateTimesheetRecords(userInfo.email, recordPayload);
        if timesheetRecords is error {
            string customError = "Error occurred while updating the timesheet records!";
            log:printError(customError, timesheetRecords);
            return <http:InternalServerError>{
                body: {
                    message: customError
                }
            };
        }
        return http:OK;
    }

    # Endpoint to patch time log record of an employee.
    #
    # + recordPayload - TimesheetUpdate record payload
    # + return - Ok status or error status's
    isolated resource function patch employees/[string employeeEmail]/time\-log/[int recordId](http:RequestContext ctx,
            database:TimeLogUpdate recordPayload)
        returns http:InternalServerError|http:Ok|http:BadRequest|http:Forbidden {

        authorization:CustomJwtPayload|error userInfo = ctx.getWithType(authorization:HEADER_USER_INFO);
        if userInfo is error {
            return <http:BadRequest>{
                body: {
                    message: "User information header not found!"
                }
            };
        }

        if !authorization:checkPermissions([authorization:authorizedRoles.employeeRole], userInfo.groups) {
            return <http:Forbidden>{
                body: {
                    message: "Insufficient privileges!"
                }
            };
        }

        if employeeEmail !== userInfo.email {
            return <http:Forbidden>{
                body: {
                    message: "Employees not allowed to modify others time logs!"
                }
            };
        }

        if recordPayload.overtimeStatus !is () {
            return <http:Forbidden>{
                body: {
                    message: "Employees not allowed to modify time log status!"
                }
            };
        }

        error? timesheetRecords = database:updateTimesheetRecord(recordPayload, userInfo.email);
        if timesheetRecords is error {
            string customError = string `Error occurred while updating the ${employeeEmail} timesheet record!`;
            log:printError(customError, timesheetRecords);
            return <http:InternalServerError>{
                body: {
                    message: customError
                }
            };
        }
        return http:OK;
    }
}

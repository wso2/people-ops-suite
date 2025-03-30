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
import ballerina/sql;

final cache:Cache userInfoCache = new (capacity = 100, evictionFactor = 0.2);

@display {
    label: "Timesheet Application",
    id: "hris/timesheet-application"
}
service http:InterceptableService / on new http:Listener(9091) {

    # Request interceptor.
    # + return - authorization:JwtInterceptor
    public function createInterceptors() returns http:Interceptor[] => [new authorization:JwtInterceptor()];

    # Get the authorization levels of the invoker
    #
    # + ctx - Request Context
    # + return - Internal Server Error or Employee info object
    resource function get user\-info(http:RequestContext ctx) returns EmployeeInformation|http:InternalServerError|
        http:BadRequest|http:Forbidden {

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

        database:WorkPolicies|error workPolicies = database:getWorkPolicy(loggedInUser.company).ensureType();
        if workPolicies is error {
            string customError =
                string `Error occurred while retrieving work policy for ${userInfo.email} and ${loggedInUser.company}!`;
            log:printError(customError, workPolicies);
            return <http:InternalServerError>{
                body: {
                    message: customError
                }
            };
        }

        int[] privileges = [EMPLOYEE_PRIVILEGE];
        if authorization:checkPermissions([authorization:authorizedRoles.adminRole], userInfo.groups) {
            privileges.push(HR_ADMIN_PRIVILEGE);
        }
        if loggedInUser.lead == true {
            privileges.push(LEAD_PRIVILEGE);
        }

        return {
            employeeInfo: loggedInUser,
            privileges: privileges,
            workPolicies: workPolicies
        };
    }

    # The resource function to get all employees information.
    #
    # + ctx - The request context
    # + return - The employees information or an error
    resource function get meta\-employees(http:RequestContext ctx)
        returns entity:Employee[]|http:InternalServerError|http:BadRequest|http:Forbidden {

        authorization:CustomJwtPayload|error userInfo = ctx.getWithType(authorization:HEADER_USER_INFO);
        if userInfo is error {
            return <http:BadRequest>{
                body: {
                    message: "User information header not found!"
                }
            };
        }

        if !authorization:checkPermissions([authorization:authorizedRoles.employeeRole],
                userInfo.groups) {

            return <http:Forbidden>{
                body: {
                    message: "Insufficient privileges!"
                }
            };
        }

        entity:Employee[]|error employees = entity:getAllActiveEmployees();
        if employees is error {
            string customError = string `Error occurred while retrieving employees meta data!`;
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
    # + recordPayload - Timesheet records payload
    # + employeeEmail - Email of the employee to filter timesheet records
    # + return - A work policy or an error
    isolated resource function post timesheet\-records/[string employeeEmail](http:RequestContext ctx,
            database:TimeSheetRecord[] recordPayload)
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
        foreach var newRecord in recordPayload {
            newRecordDates.push(newRecord.recordDate);
        }

        database:TimesheetCommonFilter filter = {
            employeeEmail: employeeEmail,
            leadEmail: loggedInUser.managerEmail,
            status: (),
            recordsLimit: (),
            recordOffset: (),
            rangeStart: (),
            rangeEnd: (),
            recordDates: newRecordDates
        };

        database:TimeSheetRecord[]|error? existingRecords = database:getTimeSheetRecords(filter);
        if existingRecords is error {
            string customError = string `Error occurred while retrieving the existing timesheet records!`;
            log:printError(customError, existingRecords);
            return <http:InternalServerError>{
                body: {
                    message: customError
                }
            };
        }

        string[] duplicateRecords = [];
        if existingRecords !is () && existingRecords.length() > 0 {
            foreach var existingRecord in existingRecords {
                duplicateRecords.push(existingRecord.recordDate);
            }
            string customError =
                string `Duplicated dates found ${string:'join(", ", ...duplicateRecords.map(d => d.toString()))}`;
            log:printError(customError);
            return <http:BadRequest>{
                body: {
                    message: customError
                }
            };
        }

        sql:Error|sql:ExecutionResult[] timesheetInsertResult = database:insertTimesheetRecords(recordPayload,
                loggedInUser.workEmail, loggedInUser.company, <string>loggedInUser.managerEmail);

        if timesheetInsertResult is error {
            string customError = string `Error occurred while saving the records for ${loggedInUser.workEmail}!`;
            log:printError(customError, timesheetInsertResult);
            return <http:InternalServerError>{
                body: {
                    message: customError
                }
            };
        }
        return http:CREATED;
    }

    # Endpoint to get timesheet records using filters.
    #
    # + 'limit - Limit of the response
    # + status - Status of the timesheet records
    # + rangeStart - Start date of the timesheet records
    # + rangeEnd - End date of the timesheet records
    # + offset - Offset of the number of timesheet records to retrieve
    # + employeeEmail - Email of the employee to filter timesheet records
    # + return - A work policy or an error
    isolated resource function get timesheet\-records(http:RequestContext ctx, string? employeeEmail, int? 'limit,
            string? leadEmail, database:TimeSheetStatus? status, int? offset, string? rangeStart, string? rangeEnd)
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
            recordDates: ()
        };

        int|error? totalRecordCount = database:getTotalRecordCount(commonFilter);
        if totalRecordCount is error {
            string customError = string `Error occurred while retrieving the record count!`;
            log:printError(customError, totalRecordCount);
            return <http:InternalServerError>{
                body: {
                    message: customError
                }
            };
        }

        database:TimeSheetRecord[]|error? timesheetRecords = database:getTimeSheetRecords(commonFilter);
        if timesheetRecords is error {
            string customError = string `Error occurred while retrieving the timesheetRecords!`;
            log:printError(customError, timesheetRecords);
            return <http:InternalServerError>{
                body: {
                    message: customError
                }
            };
        }

        string|null leadEmailToFilter = ();
        if authorization:checkPermissions([authorization:authorizedRoles.leadRole], userInfo.groups) {
            if userInfo.email !== employeeEmail {
                leadEmailToFilter = userInfo.email;
            }
        }

        database:TimesheetCommonFilter infoFilter = {
            employeeEmail: leadEmailToFilter is string ? () : employeeEmail,
            leadEmail: leadEmailToFilter is string ? leadEmailToFilter : (),
            status: (),
            recordsLimit: (),
            recordOffset: (),
            rangeStart: (),
            rangeEnd: (),
            recordDates: ()
        };
        database:TimesheetInfo|error? timesheetInfo = database:getTimesheetInfo(infoFilter);
        if timesheetInfo is error {
            string customError = string `Error occurred while retrieving the timesheet information!`;
            log:printError(customError, timesheetInfo);
            return <http:InternalServerError>{
                body: {
                    message: customError
                }
            };
        }

        return {
            totalRecordCount: totalRecordCount,
            timesheetRecords: timesheetRecords,
            timesheetInfo: timesheetInfo ?: ()
        };
    }

    # Endpoint to save timesheet records of an employee.
    #
    # + recordPayload - Timesheet records payload
    # + return - A work policy or an error
    isolated resource function patch timesheet\-records(http:RequestContext ctx,
            database:TimesheetUpdate[] recordPayload)
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

        error? timesheetRecords = database:updateTimesheetRecords(userInfo.email, recordPayload);
        if timesheetRecords is error {
            string customError = string `Error occurred while updating the timesheet records!`;
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

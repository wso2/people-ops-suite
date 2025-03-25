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
// import timesheet_app.database;
import timesheet_app.entity;

import ballerina/cache;
import ballerina/http;
import ballerina/log;

final cache:Cache userInfoCache = new (capacity = 100, evictionFactor = 0.2);

@display {
    label: "Timesheet Application",
    id: "hris/timesheet-application"
}
service http:InterceptableService / on new http:Listener(9091) {

    # Request interceptor.
    # + return - authorization:JwtInterceptor
    public function createInterceptors() returns http:Interceptor[] => [new authorization:JwtInterceptor()];

    // # Fetch user information of the logged in users.
    // #
    // # + ctx - Request object
    // # + return - User info object|Error
    // resource function get user\-info(http:RequestContext ctx) returns entity:Employee|http:InternalServerError {
    //     // "requestedBy" is the email of the user access this resource.
    //     // interceptor set this value after validating the jwt.
    //     authorization:CustomJwtPayload|error userInfo = ctx.getWithType(authorization:HEADER_USER_INFO);
    //     if userInfo is error {
    //         return <http:InternalServerError>{
    //             body: {
    //                 message: "User information header not found!"
    //             }
    //         };
    //     }

    //     // Check cache for logged in user.
    //     if userInfoCache.hasKey(userInfo.email) {
    //         entity:Employee|error cachedUserInfo = userInfoCache.get(userInfo.email).ensureType();
    //         if cachedUserInfo is error {
    //             string customError = string `Error occurred while retrieving user data: ${userInfo.email}!`;
    //             log:printError(customError, cachedUserInfo);
    //             return <http:InternalServerError>{
    //                 body: {
    //                     message: customError
    //                 }
    //             };
    //         }
    //         return cachedUserInfo;
    //     }

    //     entity:Employee|error loggedInUser = entity:fetchEmployeesBasicInfo(userInfo.email);
    //     if loggedInUser is error {
    //         string customError = string `Error occurred while retrieving user data: ${userInfo.email}!`;
    //         log:printError(customError, loggedInUser);
    //         return <http:InternalServerError>{
    //             body: {
    //                 message: customError
    //             }
    //         };
    //     }

    //     error? cacheError = userInfoCache.put(userInfo.email, loggedInUser);
    //     if cacheError is error {
    //         log:printError(string `Error in updating the user cache for: ${userInfo.email}!`);

    //     }

    //     return loggedInUser;
    // }

    // # Fetch all samples from the database.
    // #
    // # + name - Name to filter
    // # + 'limit - Limit of the data
    // # + offset - Offset of the data
    // # + return - All samples|Error
    // isolated resource function get collections(http:RequestContext ctx, string? name, int? 'limit, int? offset)
    //     returns SampleCollection|http:Forbidden|http:BadRequest|http:InternalServerError {

    //     // "requestedBy" is the email of the user access this resource.
    //     // interceptor set this value after validating the jwt.
    //     authorization:CustomJwtPayload|error userInfo = ctx.getWithType(authorization:HEADER_USER_INFO);
    //     if userInfo is error {
    //         return <http:BadRequest>{
    //             body: {
    //                 message: "User information header not found!"
    //             }
    //         };
    //     }

    //     // [Start] Custom Resource level authorization.
    //     if !authorization:checkPermissions([authorization:authorizedRoles.employeeRole],
    //             userInfo.groups) {

    //         return <http:Forbidden>{
    //             body: {
    //                 message: "Insufficient privileges!"
    //             }
    //         };
    //     }
    //     // [End] Custom Resource level authorization.

    //     database:SampleCollection[]|error collections = database:fetchSampleCollections(name, 'limit, offset);
    //     if collections is error {
    //         string customError = string `Error occurred while retrieving the sample collections!`;
    //         log:printError(customError, collections);
    //         return <http:InternalServerError>{
    //             body: {
    //                 message: customError
    //             }
    //         };
    //     }

    //     return {
    //         count: collections.length(),
    //         collections: collections
    //     };
    // }

    // # Insert collections.
    // #
    // # + collection - New collection
    // # + return - Created|Forbidden|BadRequest|Error
    // resource function post collections(http:RequestContext ctx, database:AddSampleCollection collection)
    //     returns http:Created|http:Forbidden|http:BadRequest|http:InternalServerError {

    //     // "requestedBy" is the email of the user access this resource.
    //     // interceptor set this value after validating the jwt.
    //     authorization:CustomJwtPayload|error userInfo = ctx.getWithType(authorization:HEADER_USER_INFO);
    //     if userInfo is error {
    //         return <http:BadRequest>{
    //             body: {
    //                 message: "User information header not found!"
    //             }
    //         };
    //     }

    //     // [Start] Custom Resource level authorization.
    //     if !authorization:checkPermissions([authorization:authorizedRoles.headPeopleOperationsRole],
    //             userInfo.groups) {

    //         return <http:Forbidden>{
    //             body: {
    //                 message: "Insufficient privileges!"
    //             }
    //         };
    //     }
    //     // [End] Custom Resource level authorization.

    //     // Insert collection.
    //     int|error collectionId = database:addSampleCollection(collection, userInfo.email);
    //     if collectionId is error {
    //         string customError = string `Error occurred while adding sample collection!`;
    //         log:printError(customError, collectionId);
    //         return <http:InternalServerError>{
    //             body: {
    //                 message: customError
    //             }
    //         };
    //     }

    //     database:SampleCollection|error? addedSampleCollection = database:fetchSampleCollection(collectionId);

    //     // Handle : database read error.
    //     if addedSampleCollection is error {
    //         string customError = string `Error occurred while retrieving the added sample collection!`;
    //         log:printError(customError, addedSampleCollection);
    //         return <http:InternalServerError>{
    //             body: {
    //                 message: customError
    //             }
    //         };
    //     }

    //     // Handle : no record error.
    //     if addedSampleCollection is null {
    //         string customError = string `Added sample collection is no longer available to access!`;
    //         log:printError(customError);
    //         return <http:InternalServerError>{
    //             body: {
    //                 message: customError
    //             }
    //         };
    //     }

    //     return <http:Created>{
    //         body: addedSampleCollection
    //     };
    // }

    # Get the authorization levels of the invoker
    #
    # + ctx - Request Context
    # + return - Internal Server Error or Employee info object
    resource function get user\-info(http:RequestContext ctx) returns EmployeeWithPermissions|http:InternalServerError|
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

        WorkPolicy|error workPolicy = database:gteWorkPolicy(loggedInUser.company).ensureType();

        if workPolicy is error {
            string customError =
                string `Error occurred while retrieving work policy for ${userInfo.email} and ${loggedInUser.company}!`;
            log:printError(customError, workPolicy);
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
        if loggedInUser.jobBand !is () && loggedInUser.jobBand >= 7 {
            privileges.push(LEAD_PRIVILEGE);
        }

        EmployeeWithPermissions employee = {
            employeeId: loggedInUser.employeeId,
            workEmail: loggedInUser.workEmail,
            firstName: loggedInUser.firstName,
            lastName: loggedInUser.lastName,
            jobRole: loggedInUser.jobRole,
            employeeThumbnail: loggedInUser.employeeThumbnail,
            company: loggedInUser.company,
            managerEmail: loggedInUser.managerEmail,
            jobBand: loggedInUser.jobBand,
            privileges: privileges,
            workPolicy: workPolicy
        };

        return employee;
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
    isolated resource function get employees/timesheet\-records(http:RequestContext ctx, string? employeeEmail, int? 'limit,
            string leadEmail, database:TimeSheetStatus? status, int? offset, string? rangeStart, string? rangeEnd)
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

        database:TimesheetCommonFilter filter = {
            employeeEmail: employeeEmail,
            leadEmail: leadEmail,
            status: status,
            recordsLimit: 'limit,
            recordOffset: offset,
            rangeStart: rangeStart,
            rangeEnd: rangeEnd
        };

        database:OvertimeInformation|error? overtimeInfo = database:getTimesheetOTInfoOfEmployee(filter);

        if overtimeInfo is error {
            string customError = string `Error occurred while retrieving the record count!`;
            log:printError(customError, overtimeInfo);
            return <http:InternalServerError>{
                body: {
                    message: customError
                }
            };
        }

        database:TimeSheetRecord[]|error? timesheetRecords = database:getTimeSheetRecords(filter);

        if timesheetRecords is error {
            string customError = string `Error occurred while retrieving the timesheetRecords!`;
            log:printError(customError, timesheetRecords);
            return <http:InternalServerError>{
                body: {
                    message: customError
                }
            };
        }

        return {
            overtimeInfo: overtimeInfo,
            timesheetRecords: timesheetRecords
        };
    }

}

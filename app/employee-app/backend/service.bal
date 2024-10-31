// Copyright (c) 2024 WSO2 LLC. (http://www.wso2.org).
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
import employee_app.authorization;
import employee_app.database;
import employee_app.email;
import employee_app.types;

import ballerina/cache;
import ballerina/http;
import ballerina/log;
import ballerina/time;

configurable email:EmailAlertConfig offerEmailConfig = ?;

final cache:Cache userInfoCache = new ('capacity = types:CAPACITY, 'evictionFactor = types:EVICTION_FACTOR);
final cache:Cache orgStructureCache = new ('capacity = types:CAPACITY, 'evictionFactor = types:EVICTION_FACTOR);

@display {
    label: "Employee Application",
    id: "people-ops/employee-application"
}
service http:InterceptableService / on new http:Listener(9090) {

    # Request interceptor.
    # + return - authorization:JwtInterceptor
    public function createInterceptors() returns http:Interceptor[] {
        return [new authorization:JwtInterceptor()];
    }

    # Get basic information of a given active employee.
    #
    # + email - Email of the employee
    # + return - Basic information of the employee or an error
    resource function get employees/[string email]()
        returns types:Employee|http:BadRequest|http:InternalServerError|http:NotFound {

        if !email.matches(types:WSO2_EMAIL_PATTERN) {
            return <http:BadRequest>{
                body: {
                    message: string `Input email is not a valid WSO2 email address: ${email}`
                }
            };
        }
        types:Employee|error? employee;
        if userInfoCache.hasKey(email) {
            any|error cachedEmployee = userInfoCache.get(email);
            if cachedEmployee is types:Employee {
                return cachedEmployee;
            } else if cachedEmployee is cache:Error {
                log:printError("Error getting employee information", cachedEmployee);
            }
        }

        employee = database:getEmployee(email);
        if employee is error {
            string customError = string `Error getting employee basic information for ${email}!`;
            log:printError(customError, employee);
            return <http:InternalServerError>{
                body: {
                    message: customError
                }
            };
        }
        if employee is () {
            log:printDebug(string `${types:NOT_FOUND_CUSTOM_ERROR}: ${email}`);
            return <http:NotFound>{
                body: {
                    message: string `${types:NOT_FOUND_CUSTOM_ERROR}: ${email}`
                }
            };
        }

        return employee;
    }

    # Get basic information of employees.
    #
    # + filters - Filter objects containing the filter criteria for the query
    # + 'limit - The maximum number of employees to return
    # + offset - The number of employees to skip before starting to collect the result set
    # + return - Basic information of the employees or an error
    resource function post employees(types:EmployeeFilter? filters, int? 'limit, int? offset)
        returns types:Employee[]|http:BadRequest|http:InternalServerError|http:NotFound {

        types:Employee[]|error employees =
            database:getEmployees(filters ?: {}, 'limit ?: types:DEFAULT_LIMIT, offset ?: 0);
        if employees is error {
            string customError = "Error getting employee information!";
            log:printError(customError, employees);
            return <http:InternalServerError>{
                body: {
                    message: customError
                }
            };
        }
        return employees;
    }

    # Organization structure data retrieval.
    #
    # + return - Internal Server Error or Organization structure data
    resource function get org\-structure() returns types:OrgStructure|http:InternalServerError {

        if orgStructureCache.hasKey(types:ORG_STRUCTURE_CACHE_KEY) {
            any|error cacheOrg = orgStructureCache.get(types:ORG_STRUCTURE_CACHE_KEY);
            if cacheOrg is types:OrgStructure {
                return cacheOrg;
            }
            if cacheOrg is cache:Error {
                string customError = "Error retrieving employee from cache";
                log:printError(customError, cacheOrg);
            }
        }
        types:BusinessUnit[]|error businessUnits = database:getOrgDetails(
                filter = {},
                'limit = types:DEFAULT_LIMIT,
                offset = 0
            );
        if businessUnits is error {
            string customError = "Error getting business units";
            log:printError(customError, businessUnits);
            return <http:InternalServerError>{
                body: {
                    message: customError
                }
            };
        }

        types:Company[]|error companies = database:getCompanies(
                filter = {},
                'limit = types:DEFAULT_LIMIT,
                offset = 0
            );
        if companies is error {
            string customError = "Error getting companies";
            log:printError(customError, companies);
            return <http:InternalServerError>{
                body: {
                    message: customError
                }
            };
        }

        types:CareerFunction[]|error careerFunctions = database:getCareerFunctions(
                filter = {},
                'limit = types:DEFAULT_LIMIT,
                offset = 0
            );
        if careerFunctions is error {
            string customError = "Error getting career functions";
            log:printError(customError, careerFunctions);
            return <http:InternalServerError>{
                body: {
                    message: customError
                }
            };
        }

        types:OrgStructure orgStructure = {
            businessUnits: businessUnits,
            companies: companies,
            careerPaths: careerFunctions,
            employmentTypes: [types:PERMANENT, types:INTERNSHIP, types:CONSULTANCY]
        };
        var putResult = orgStructureCache.put(types:ORG_STRUCTURE_CACHE_KEY, orgStructure);
        if putResult is cache:Error {
            log:printError("Failed to put org structure in cache", putResult);
        }
        return orgStructure;
    }

    # Retrieve specific recruit data from the database.
    #
    # + return - recruit data or error response
    resource function get recruits/[int recruitId](http:RequestContext ctx)
        returns types:Recruit|http:InternalServerError {

        types:Recruit|error recruit = database:getRecruit(recruitId);
        if recruit is error {
            string customError = "Error getting recruit information";
            log:printError(customError, 'error = recruit, recruitId = recruitId);
            return <http:InternalServerError>{
                body: {
                    message: customError
                }
            };
        }
        return recruit;
    }

    # Retrieve all recruits data from the database.
    #
    # + statusArray - Array of recruit statuses to filter the data  
    # + 'limit - Limit of the data  
    # + offset - Offset of the data
    # + return - All Selected recruits data or error response
    resource function get recruits(database:RecruitStatus[]? statusArray, int? 'limit, int? offset)
        returns types:Recruit[]|http:InternalServerError {

        types:Recruit[]|error recruits = database:getRecruits(statusArray, 'limit, offset);
        if recruits is error {
            string customError = "Error getting recruit information";
            log:printError(customError, 'error = recruits);
            return <http:InternalServerError>{
                body: {
                    message: customError
                }
            };
        }
        return recruits;
    }

    # Retrieve compensations for a specific recruit's employment type and the company location.
    #
    # + recruitId - ID of the recruit  
    # + return - Compensation or error response
    resource function get recruits/[int recruitId]/compensation(http:RequestContext ctx)
        returns types:Compensation[]|http:Forbidden|http:InternalServerError {

        authorization:CustomJwtPayload|error userInfo = ctx.getWithType(authorization:HEADER_USER_INFO);
        if userInfo is error {
            string customError = "Error getting token from the header";
            log:printError(customError, 'error = userInfo);
            return <http:InternalServerError>{
                body: {
                    message: customError
                }
            };
        }
        if !authorization:checkRoles([authorization:authorizedRoles.recruitmentTeamRole], userInfo.groups) {
            return <http:Forbidden>{body: {message: "Insufficient privileges!"}};
        }
        types:Recruit|error recruit = database:getRecruit(recruitId);
        if recruit is error {
            string customError = "Error getting data for recruit";
            log:printError(customError, 'error = recruit, id = recruitId);
            return <http:InternalServerError>{
                body: {
                    message: string `${customError} ${recruitId}`
                }
            };
        }

        string:RegExp r = re `" "`;
        recruit.companyLocation = r.replaceAll(recruit.companyLocation, "");
        string compensationFilter = string `${types:OFFER_TEMPLATE_PREFIX}${recruit.employmentType}`;
        if recruit.employmentType == types:PERMANENT {
            compensationFilter = compensationFilter + string `${recruit.companyLocation}`;
        }
        if recruit.employmentType == types:INTERNSHIP || recruit.employmentType == types:CONSULTANCY {
            compensationFilter = compensationFilter + string `${types:OFFER_TEMPLATE_POSTFIX}`;
        }
        types:CompensationEmail|error compensationEmail = database:getCompensation(compensationFilter);
        if compensationEmail is error {
            string customError = "Error getting compensation email data";
            log:printError(customError, 'error = compensationEmail);
            return <http:InternalServerError>{
                body: {
                    message: customError
                }
            };
        }
        return compensationEmail.compensation;
    }

    # Add recruits data to the database.
    #
    # + recruit - Recruits to be added
    # + return - Recruits data insertion successful or error response
    resource function post recruits(http:RequestContext ctx, database:AddRecruitPayload recruit)
        returns http:Created|http:Forbidden|http:BadRequest|http:InternalServerError {

        authorization:CustomJwtPayload|error userInfo = ctx.getWithType(authorization:HEADER_USER_INFO);
        if userInfo is error {
            string customError = "Error getting token from the header";
            log:printError(customError, 'error = userInfo);
            return <http:InternalServerError>{
                body: {
                    message: customError
                }
            };
        }
        if !authorization:checkRoles([authorization:authorizedRoles.recruitmentTeamRole],
                userInfo.groups) {
            return <http:Forbidden>{body: {message: "Insufficient privileges!"}};
        }

        database:AddRecruitPayload {employmentType, dateOfJoin, probationEndDate, agreementEndDate} = recruit;
        time:Utc|time:Error dateOfJoinUtc = time:utcFromString(dateOfJoin + types:UTC_POSTFIX);
        if dateOfJoinUtc is time:Error {
            return <http:BadRequest>{
                body: {
                    message: "Invalid date of join format!"
                }
            };
        }
        if employmentType == types:PERMANENT {
            if probationEndDate !is string {
                return <http:BadRequest>{
                    body: {
                        message: "Probation end date is required for permanent employees!"
                    }
                };
            }
            time:Utc|time:Error probationEndDateUtc = time:utcFromString(probationEndDate + types:UTC_POSTFIX);
            if probationEndDateUtc is time:Error {
                return <http:BadRequest>{
                    body: {
                        message: "Invalid probation end date format!"
                    }
                };
            }
            if probationEndDateUtc < dateOfJoinUtc {
                return <http:BadRequest>{
                    body: {
                        message: "Probation end date should be after the date of join!"
                    }
                };
            }
        }
        if employmentType == types:INTERNSHIP || employmentType == types:CONSULTANCY {
            if agreementEndDate !is string {
                return <http:BadRequest>{
                    body: {
                        message: "Agreement end date is required for permanent and internship employees!"
                    }
                };
            }
            time:Utc|time:Error agreementEndDateUtc = time:utcFromString(agreementEndDate + types:UTC_POSTFIX);
            if agreementEndDateUtc is time:Error {
                return <http:BadRequest>{
                    body: {
                        message: "Invalid agreement end date format!"
                    }
                };
            }
            if agreementEndDateUtc < dateOfJoinUtc {
                return <http:BadRequest>{
                    body: {
                        message: "Agreement end date should be after the date of join!"
                    }
                };
            }
        }

        int|error employeeId = database:addRecruit(recruit, userInfo.email);
        if employeeId is error {
            string customError = "Error getting employee ID";
            log:printError(customError, 'error = employeeId, email = userInfo.email);
            return <http:InternalServerError>{
                body: {
                    message: string `${customError} for ${userInfo.email}`
                }
            };
        }
        return <http:Created>{
            body: {
                message: string `Successfully added the recruit data. Id : ${employeeId.toString()}!`
            }
        };
    }

    # Update recruit data.
    #
    # + recruitId - Recruit id of the recruit data to be updated
    # + recruit - Recruit data to be updated
    # + return - Recruit update successful or error response
    resource function patch recruits/[int recruitId](http:RequestContext ctx, types:UpdateRecruitPayload recruit)
        returns http:Ok|http:Forbidden|http:InternalServerError {

        authorization:CustomJwtPayload|error userInfo = ctx.getWithType(authorization:HEADER_USER_INFO);
        if userInfo is error {
            string customError = "Error getting token from the header";
            log:printError(customError, 'error = userInfo);
            return <http:InternalServerError>{
                body: {
                    message: customError
                }
            };
        }
        if !authorization:checkRoles([authorization:authorizedRoles.recruitmentTeamRole],
                userInfo.groups) {
            return <http:Forbidden>{body: {message: "Insufficient privileges!"}};
        }

        any|error result = database:updateRecruit({...recruit, recruitId}, userInfo.email);
        if result is error {
            string customError = "Error updating recruit in the database";
            log:printError(customError, 'error = result);
            return <http:InternalServerError>{
                body: {
                    message: customError
                }
            };
        }

        return <http:Ok>{
            body: {
                message: string `Successfully updated the recruits data. Id : ${recruitId}`
            }
        };
    }

    # Skip offer letter.
    #
    # + recruitId - ID of the recruit to skip the offer
    # + return - Skip offer letter successful or error response
    resource function post recruits/[int recruitId]/offer/skip(http:RequestContext ctx)
        returns http:Ok|http:Forbidden|http:InternalServerError {

        authorization:CustomJwtPayload|error userInfo = ctx.getWithType(authorization:HEADER_USER_INFO);
        if userInfo is error {
            string customError = "Error getting token from the header";
            log:printError(customError, 'error = userInfo);
            return <http:InternalServerError>{
                body: {
                    message: customError
                }
            };
        }
        if !authorization:checkRoles([authorization:authorizedRoles.recruitmentTeamRole],
                userInfo.groups) {
            return <http:Forbidden>{body: {message: "Insufficient privileges!"}};
        }

        types:Recruit|error recruit = database:getRecruit(recruitId);
        if recruit is error {
            string customError = "Error getting recruit data";
            log:printError(customError, 'error = recruit, id = recruitId);
            return <http:InternalServerError>{
                body: {
                    message: customError
                }
            };
        }
        if recruit.status != database:SELECTED {
            return <http:InternalServerError>{
                body: {
                    message: "The recruit is not in the selected status to skip the offer letter!"
                }
            };
        }

        any|error result = database:updateRecruit({status: database:OFFER_SENT, recruitId}, userInfo.email);
        if result is error {
            string customError = "Error updating recruit in the database";
            log:printError(customError, 'error = result);
            return <http:InternalServerError>{
                body: {
                    message: customError
                }
            };
        }

        return <http:Ok>{
            body: {
                message: string `Successfully skipped the offer letter for the recruit. Id : ${recruitId}`
            }
        };
    }

    # Sending the offer letter.
    #
    # + recruitId - ID of the recruit to send the offer
    # + return - Offer sent successfully or error response
    resource function post recruits/[int recruitId]/offer/send(http:RequestContext ctx)
        returns http:BadRequest|http:Forbidden|http:Ok|http:InternalServerError|http:NotFound {

        authorization:CustomJwtPayload|error userInfo = ctx.getWithType(authorization:HEADER_USER_INFO);
        if userInfo is error {
            string customError = "Error getting token from the header";
            log:printError(customError, 'error = userInfo);
            return <http:InternalServerError>{
                body: {
                    message: customError
                }
            };
        }
        if !authorization:checkRoles([authorization:authorizedRoles.recruitmentTeamRole],
                userInfo.groups) {
            return <http:Forbidden>{body: {message: "Insufficient privileges!"}};
        }

        types:Recruit|error recruit = database:getRecruit(recruitId);
        if recruit is error {
            string customError = "Error getting data for recruit";
            log:printError(customError, 'error = recruit, id = recruitId);
            return <http:InternalServerError>{
                body: {
                    message: string `${customError} ${recruitId}`
                }
            };
        }
        if recruit.status != database:SELECTED {
            return <http:BadRequest>{
                body: {
                    message: "The recruit is not in the status to send the offer!"
                }
            };
        }

        string compensationFilter = string `${types:OFFER_TEMPLATE_PREFIX}${recruit.employmentType}`;
        if recruit.employmentType == types:PERMANENT {
            string:RegExp r = re `" "`;
            string companyLocation = r.replaceAll(recruit.companyLocation, "");
            compensationFilter = compensationFilter + string `${companyLocation}`;
        }
        if recruit.employmentType == types:INTERNSHIP || recruit.employmentType == types:CONSULTANCY {
            compensationFilter = compensationFilter + string `${types:OFFER_TEMPLATE_POSTFIX}`;
        }

        types:CompensationEmail|error compensationEmail = database:getCompensation(compensationFilter);
        if compensationEmail is error {
            string customError = "Error getting compensation email data";
            log:printError(customError, 'error = compensationEmail);
            return <http:InternalServerError>{
                body: {
                    message: customError
                }
            };
        }
        string[] compensationKeys = from types:Compensation compensation in compensationEmail.compensation
            select compensation.key;
        string[] recruitCompensationKeys = from types:Compensation recruitCompensation in recruit.compensation
            select recruitCompensation.key;

        if compensationKeys != recruitCompensationKeys {
            return <http:BadRequest>{
                body: {
                    message: "The compensation keys are not matching with the recruit's compensation keys!"
                }
            };
        }
        types:Employee|error? senderInfo;
        if userInfoCache.hasKey(userInfo.email) {
            any|error cachedEmployee = userInfoCache.get(userInfo.email);
            if cachedEmployee is types:Employee {
                senderInfo = cachedEmployee;
            } else if cachedEmployee is cache:Error {
                string customError = "Error getting employee information";
                log:printError(customError, cachedEmployee);
            }
        }
        senderInfo = database:getEmployee(userInfo.email);
        if senderInfo is error {
            string customError = string `Error getting employee basic information for ${userInfo.email}`;
            log:printError(customError, senderInfo);
            return <http:InternalServerError>{
                body: {
                    message: customError
                }
            };
        }
        if senderInfo is () {
            log:printDebug(string `No active employee found for the email: ${userInfo.email}`);
            return http:NOT_FOUND;
        }

        any|error resultUpdatedCache = userInfoCache.put(userInfo.email, senderInfo);
        if resultUpdatedCache is error {
            string customError = "Error updating employee in user cache";
            log:printError(customError, 'error = resultUpdatedCache);
        }

        if recruit.employmentType is types:PERMANENT {
            types:Recruit {probationEndDate} = recruit;
            if probationEndDate !is string {
                return <http:BadRequest>{
                    body: {
                        message: "Pr obation end date is required for recruits in permanent employment type to send the offer!"

                    }
                };
            }
            map<string> keyValPairs = {
                RECEIVER_NAME: recruit.firstName,
                DESIGNATION: recruit.designation,
                DATE_OF_JOIN: recruit.dateOfJoin,
                REPORTS_TO: recruit.reportsTo,
                WORK_LOCATION: recruit.workLocation,
                PROBATION_PERIOD: string `${recruit.dateOfJoin} to ${probationEndDate}`,
                SENDER_NAME: string `${senderInfo.firstName ?: types:UNKNOWN} ${senderInfo.lastName ?: types:UNKNOWN}`
            };
            types:Recruit {compensation} = recruit;
            foreach types:Compensation compensationRecord in compensation {
                keyValPairs[compensationRecord.key] = compensationRecord.value;
            }

            any|error resultEmailNotification = email:processEmailNotification({
                frm: offerEmailConfig.'from,
                subject: offerEmailConfig.subject,
                to: [recruit.personalEmail],
                templateId: compensationEmail.emailTemplate,
                contentKeyValPairs: keyValPairs,
                attachments: recruit.offerDocuments ?: []
            });
            if resultEmailNotification is error {
                string customError = "Error processing email notification";
                log:printError(customError, 'error = resultEmailNotification);
                return <http:InternalServerError>{
                    body: {
                        message: customError
                    }
                };
            }
        } else if recruit.employmentType is types:INTERNSHIP {
            types:Recruit {agreementEndDate} = recruit;
            if agreementEndDate !is string {
                return <http:BadRequest>{
                    body: {
                        message: "Agreement end date is required for internship to send the offer!"
                    }
                };
            }

            map<string> keyValPairs = {
                RECEIVER_NAME: recruit.firstName,
                DATE_OF_JOIN: recruit.dateOfJoin,
                DURATION: string `${recruit.dateOfJoin} to ${agreementEndDate}`,
                TEAM_NAME: recruit.team
            };

            types:Recruit {compensation} = recruit;
            foreach types:Compensation compensationRecord in compensation {
                keyValPairs[compensationRecord.key] = compensationRecord.value;
            }
            any|error resultEmailNotification = email:processEmailNotification({
                frm: offerEmailConfig.'from,
                subject: offerEmailConfig.subject,
                to: [recruit.personalEmail],
                templateId: compensationEmail.emailTemplate,
                contentKeyValPairs: keyValPairs,
                attachments: recruit.offerDocuments ?: []
            });
            if resultEmailNotification is error {
                string customError = "Error processing email notification";
                log:printError(customError, 'error = resultEmailNotification);
                return <http:InternalServerError>{
                    body: {
                        message: customError
                    }
                };
            }
        } else if recruit.employmentType is types:CONSULTANCY {
            types:Recruit {agreementEndDate} = recruit;
            if agreementEndDate !is string {
                return <http:BadRequest>{
                    body: {
                        message: "Agreement end date is required for consultancy to send the offer!"
                    }
                };
            }
            map<string> keyValPairs = {
                RECEIVER_NAME: recruit.firstName,
                DESIGNATION: recruit.designation,
                DURATION: string `${recruit.dateOfJoin} to ${agreementEndDate}`,
                DATE_OF_JOIN: recruit.dateOfJoin,
                REPORTS_TO: recruit.managerEmail,
                WORK_LOCATION: recruit.officeLocation,
                SENDER_NAME: string `${senderInfo.firstName ?: types:UNKNOWN} ${senderInfo.lastName ?: types:UNKNOWN}`
            };
            types:Recruit {compensation} = recruit;
            foreach types:Compensation compensationRecord in compensation {
                keyValPairs[compensationRecord.key] = compensationRecord.value;
            }
            any|error resultEmailNotification = email:processEmailNotification({
                frm: offerEmailConfig.'from,
                subject: offerEmailConfig.subject,
                to: [recruit.personalEmail],
                templateId: compensationEmail.emailTemplate,
                contentKeyValPairs: keyValPairs,
                attachments: recruit.offerDocuments ?: []
            });

            if resultEmailNotification is error {
                string customError = "Error processing email notification";
                log:printError(customError, 'error = resultEmailNotification);
                return <http:InternalServerError>{
                    body: {
                        message: customError
                    }
                };
            }
        } else {
            return <http:BadRequest>{
                body: {
                    message: "Invalid employment type!"
                }
            };
        }

        any|error resultEmailNotification = database:updateRecruit(
            {recruitId, status: database:OFFER_SENT},
            userInfo.email
        );
        if resultEmailNotification is error {
            string customError = "Error processing email notification";
            log:printError(customError, 'error = resultEmailNotification);
            return <http:InternalServerError>{
                body: {
                    message: customError
                }
            };
        }
        return <http:Ok>{
            body: {
                message: string `Successfully sent the offer letter for the recruit Id : ${recruitId}`
            }
        };
    }

    # Approve | Reject offer.
    #
    # + recruitId - Id of the recruit to approve/reject the offer letter
    # + action - Approve/Reject action
    # + reason - Reason for the rejection if so
    # + return - Offer Letter action results or error response
    resource function post recruits/[int recruitId]/offer/[types:Action action](http:RequestContext ctx,
            types:ActionReason? reason) returns http:Ok|http:BadRequest|http:Forbidden|http:InternalServerError {

        authorization:CustomJwtPayload|error userInfo = ctx.getWithType(authorization:HEADER_USER_INFO);
        if userInfo is error {
            string customError = "Error getting invoker details!";
            log:printError(customError, 'error = userInfo);
            return <http:InternalServerError>{
                body: {
                    message: customError
                }
            };
        }
        if !authorization:checkRoles([authorization:authorizedRoles.recruitmentTeamRole],
                userInfo.groups) {

            return <http:Forbidden>{body: {message: "Insufficient privileges!"}};
        }

        string rejectionReason = "";
        database:RecruitStatus recruitStatus;
        if action === types:ACCEPT {
            recruitStatus = database:OFFER_ACCEPTED;
        } else if action === types:REJECT {
            recruitStatus = database:OFFER_REJECTED;
            if reason is () {
                return <http:BadRequest>{
                    body: {
                        message: "Rejection reason is required to reject the offer!"
                    }
                };
            }
            rejectionReason = reason.rejectionReason;
        } else {
            return <http:BadRequest>{
                body: {
                    message: "Invalid action!"
                }
            };
        }
        types:Recruit|error recruit = database:getRecruit(recruitId);
        if recruit is error {
            string customError = "Error getting data for recruit!";
            log:printError(customError, 'error = recruit, id = recruitId);
            return <http:InternalServerError>{
                body: {
                    message: string `${customError} ${recruitId}`
                }
            };
        }
        if recruit.status != database:OFFER_SENT {
            return <http:BadRequest>{
                body: {
                    message: string `Recruit is not in the state to ${action} the offer!`
                }
            };
        }

        any|error result = database:updateRecruit(
                {recruitId, status: recruitStatus, additionalComments: rejectionReason},
                updatedBy = userInfo.email
            );
        if result is error {
            string customError = "Error updating recruit in the database!";
            log:printError(customError, 'error = result);
            return <http:InternalServerError>{
                body: {
                    message: customError
                }
            };
        }
        return <http:Ok>{
            body: {
                message: string `Successfully ${action}ed the offer for the recruit.`
            }
        };
    }

    # Send the hiring details email.
    #
    # + recruitId - Id of the recruit
    # + hiringDetails - Hiring details payload
    # + return - Hiring details email sent successfully or error response
    resource function post recruits/[int recruitId]/hiring\-details/send(http:RequestContext ctx,
            types:HiringDetailsPayload hiringDetails)
                returns http:BadRequest|http:Forbidden|http:Ok|http:InternalServerError|http:NotFound {

        authorization:CustomJwtPayload|error userInfo = ctx.getWithType(authorization:HEADER_USER_INFO);
        if userInfo is error {
            string customError = "Error getting invoker details!";
            log:printError(customError, 'error = userInfo);
            return <http:InternalServerError>{
                body: {
                    message: customError
                }
            };
        }
        if !authorization:checkRoles([authorization:authorizedRoles.recruitmentTeamRole], userInfo.groups) {
            return <http:Forbidden>{body: {message: "Insufficient privileges!"}};
        }

        types:Recruit|error recruit = database:getRecruit(recruitId);
        if recruit is error {
            string customError = "Error getting data for recruit!";
            log:printError(customError, 'error = recruit, id = recruitId);
            return <http:InternalServerError>{
                body: {
                    message: string `${customError} ${recruitId}`
                }
            };
        }
        if recruit.status != database:OFFER_ACCEPTED {
            return <http:BadRequest>{
                body: {
                    message: "The recruit is not in the required status to send the hiring details!"
                }
            };
        }

        types:Employee|error? senderInfo;
        if userInfoCache.hasKey(userInfo.email) {
            any|error result = userInfoCache.get(userInfo.email);
            if result is error {
                log:printError("Error getting cached data for employee!", 'error = result, email = userInfo.email);
            }
            senderInfo = result.ensureType();
        }
        senderInfo = database:getEmployee(userInfo.email);
        if senderInfo is error {
            string customError = string `Error getting employee information`;
            log:printError(customError, senderInfo);
            return <http:InternalServerError>{
                body: {
                    message: string `${customError} for ${userInfo.email}!`
                }
            };
        }
        if senderInfo is () {
            log:printDebug(string `No active employee found for the email: ${userInfo.email}`);
            return http:NOT_FOUND;
        }
        any|error resultUpdatedCache = userInfoCache.put(userInfo.email, senderInfo);
        if resultUpdatedCache is error {
            string customError = "Error updating employee in user cache";
            log:printError(customError, 'error = resultUpdatedCache);
        }

        map<string> keyValPairs = {
            RECEIVER_NAME: recruit.firstName,
            SENDER_NAME: string `${senderInfo.firstName ?: types:UNKNOWN} ${senderInfo.lastName ?: types:UNKNOWN}`,
            SENDER_TITLE: senderInfo.designation ?: types:UNKNOWN
        };

        any|error resultEmailNotification = email:processEmailNotification({
            frm: offerEmailConfig.'from,
            subject: offerEmailConfig.subject,
            to: [recruit.personalEmail],
            templateId: "employeeOnboardCommon",
            contentKeyValPairs: keyValPairs,
            attachments: hiringDetails.documents
        });
        if resultEmailNotification is error {
            string customError = "Error processing email notification";
            log:printError(customError, 'error = resultEmailNotification);
            return <http:InternalServerError>{
                body: {
                    message: customError
                }
            };
        }

        any|error resultUpdateRecruit = database:updateRecruit(
            {recruitId, status: database:REQUEST_HIRING_DETAILS},
            userInfo.email
        );
        if resultUpdateRecruit is error {
            string customError = "Error updating recruit in the database";
            log:printError(customError, 'error = resultUpdateRecruit);
            return <http:InternalServerError>{
                body: {
                    message: customError
                }
            };
        }

        return <http:Ok>{
            body: {
                message: string `Successfully sent the hiring details email for the recruit. ${recruit.personalEmail}`
            }
        };
    }

    # Mark hiring details received.
    #
    # + recruitId - Id of the recruit  
    # + return - Hiring details action results or error response
    resource function post recruits/[int recruitId]/hiring\-details/received(http:RequestContext ctx)
        returns http:BadRequest|http:Forbidden|http:Ok|http:InternalServerError {

        authorization:CustomJwtPayload|error userInfo = ctx.getWithType(authorization:HEADER_USER_INFO);
        if userInfo is error {
            string customError = "Error getting token from the header";
            log:printError(customError, 'error = userInfo);
            return <http:InternalServerError>{
                body: {
                    message: customError
                }
            };
        }
        if !authorization:checkRoles([authorization:authorizedRoles.recruitmentTeamRole], userInfo.groups) {
            return <http:Forbidden>{body: {message: "Insufficient privileges!"}};
        }

        types:Recruit|error recruit = database:getRecruit(recruitId);
        if recruit is error {
            string customError = "Error getting recruit from the database";
            log:printError(customError, 'error = recruit);
            return <http:InternalServerError>{
                body: {
                    message: customError
                }
            };
        }
        if recruit.status != database:REQUEST_HIRING_DETAILS {
            return <http:BadRequest>{
                body: {
                    message: "The recruit is not in the required status to mark hiring details received!"
                }
            };
        }

        any|error resultUpdateRecruit = database:updateRecruit(
            {recruitId, status: database:HIRING_DETAILS_RECEIVED},
            userInfo.email
        );
        if resultUpdateRecruit is error {
            string customError = "Error updating recruit in the database";
            log:printError(customError, 'error = resultUpdateRecruit);
            return <http:InternalServerError>{
                body: {
                    message: customError
                }
            };
        }
        return <http:Ok>{
            body: {
                message: string `Successfully marked the recruit ${recruit.personalEmail} as hiring details received`
            }
        };
    }

    # Send the employee contract.
    #
    # + recruitId - Id of the recruit  
    # + return - Contract sent successfully or error response
    resource function post recruits/[int recruitId]/contract/send(http:RequestContext ctx)
        returns http:BadRequest|http:Forbidden|http:Ok|http:InternalServerError {

        authorization:CustomJwtPayload|error userInfo = ctx.getWithType(authorization:HEADER_USER_INFO);
        if userInfo is error {
            string customError = "Error getting token from the header";
            log:printError(customError, 'error = userInfo);
            return <http:InternalServerError>{
                body: {
                    message: customError
                }
            };
        }
        if !authorization:checkRoles([authorization:authorizedRoles.recruitmentTeamRole], userInfo.groups) {
            return <http:Forbidden>{body: {message: "Insufficient privileges!"}};
        }

        types:Recruit|error recruit = database:getRecruit(recruitId);
        if recruit is error {
            string customError = "Error getting recruit from the database";
            log:printError(customError, 'error = recruit);
            return <http:InternalServerError>{
                body: {
                    message: customError
                }
            };
        }
        if recruit.status != database:HIRING_DETAILS_RECEIVED {
            return <http:BadRequest>{
                body: {
                    message: "The recruit is not in the required status to send the contract!"
                }
            };
        }

        any|error resultUpdateRecruit = database:updateRecruit(
            {recruitId: recruitId, status: database:CONTRACT_SENT},
            userInfo.email
        );
        if resultUpdateRecruit is error {
            string customError = "Error updating recruit in the database";
            log:printError(customError, 'error = resultUpdateRecruit);
            return <http:InternalServerError>{
                body: {
                    message: customError
                }
            };
        }
        return <http:Ok>{
            body: {
                message: string `Successfully sent the contract for the recruit ${recruit.personalEmail}`
            }
        };
    }

    # Accept | Reject contract.
    #
    # + recruitId - Id of the recruit to accept/reject the contract
    # + action - Accept/Reject action
    # + reason - Reason for the rejection if so
    # + return - Contract action results or error response
    resource function post recruits/[int recruitId]/contract/[types:Action action](http:RequestContext ctx,
            types:ActionReason? reason) returns http:Ok|http:BadRequest|http:Forbidden|http:InternalServerError {

        authorization:CustomJwtPayload|error userInfo = ctx.getWithType(authorization:HEADER_USER_INFO);
        if userInfo is error {
            string customError = "Error getting token from the header";
            log:printError(customError, 'error = userInfo);
            return <http:InternalServerError>{
                body: {
                    message: customError
                }
            };
        }
        if !authorization:checkRoles([authorization:authorizedRoles.recruitmentTeamRole],
                userInfo.groups) {

            return <http:Forbidden>{body: {message: "Insufficient privileges!"}};
        }

        string rejectionReason = "";
        database:RecruitStatus recruitStatus;
        if action === types:ACCEPT {
            recruitStatus = database:CONTRACT_ACCEPTED;
        } else if action === types:REJECT {
            recruitStatus = database:CONTRACT_REJECTED;
            if reason is () {
                return <http:BadRequest>{
                    body: {
                        message: "Rejection reason is required to reject the contract!"
                    }
                };
            }
            rejectionReason = reason.rejectionReason;
        } else {
            return <http:BadRequest>{body: {message: "Invalid action!"}};
        }

        types:Recruit|error recruit = database:getRecruit(recruitId);
        if recruit is error {
            string customError = "Error getting recruit from the database";
            log:printError(customError, 'error = recruit);
            return <http:InternalServerError>{
                body: {
                    message: customError
                }
            };
        }
        if recruit.status != database:CONTRACT_SENT {
            return <http:BadRequest>{
                body: {
                    message: string `The recruit is not in the state to ${action} the contract!`
                }
            };
        }

        any|error resultUpdateRecruit = database:updateRecruit(
                {recruitId, status: recruitStatus, additionalComments: rejectionReason},
                updatedBy = userInfo.email
            );
        if resultUpdateRecruit is error {
            string customError = "Error updating recruit in the database";
            log:printError(customError, 'error = resultUpdateRecruit);
            return <http:InternalServerError>{
                body: {
                    message: customError
                }
            };
        }
        return <http:Ok>{
            body: {
                message: string `Successfully ${action}ed the contract for the recruitId.`
            }
        };
    }

    # Acknowledge employee onboarding.
    #
    # + recruitId - Id of the recruit 
    # + return - Hiring details action results or error response
    resource function post recruits/[int recruitId]/acknowledge(http:RequestContext ctx)
        returns http:BadRequest|http:Forbidden|http:Ok|http:InternalServerError {

        authorization:CustomJwtPayload|error userInfo = ctx.getWithType(authorization:HEADER_USER_INFO);
        if userInfo is error {
            string customError = "Error getting token from the header";
            log:printError(customError, 'error = userInfo);
            return <http:InternalServerError>{
                body: {
                    message: customError
                }
            };
        }
        if !authorization:checkRoles([authorization:authorizedRoles.recruitmentTeamRole],
                userInfo.groups) {

            return <http:Forbidden>{body: {message: "Insufficient privileges!"}};
        }

        types:Recruit|error recruit = database:getRecruit(recruitId);
        if recruit is error {
            string customError = "Error getting recruit from the database";
            log:printError(customError, 'error = recruit);
            return <http:InternalServerError>{
                body: {
                    message: customError
                }
            };
        }
        if recruit.status != database:CONTRACT_ACCEPTED {
            return <http:BadRequest>{
                body: {
                    message: "The recruit is not in the required status to acknowledge the profile creation!"
                }
            };
        }

        any|error resultUpdateRecruit = database:updateRecruit(
            {recruitId, status: database:HIRING_MANAGER_ACKNOWLEDGED},
            userInfo.email
        );
        if resultUpdateRecruit is error {
            string customError = "Error updating recruit in the database";
            log:printError(customError, 'error = resultUpdateRecruit);
            return <http:InternalServerError>{
                body: {
                    message: customError
                }
            };
        }
        return <http:Ok>{
            body: {
                message:
                    string `Successfully acknowledge the profile creation for the recruit ${recruit.personalEmail}`
            }
        };
    }

    # Retrieve the App privileges of the logged in user.
    #
    # + ctx - Request object
    # + return - Internal Server Error or Employee Privileges object
    resource function get user\-info(http:RequestContext ctx)
        returns types:Employee|http:BadRequest|http:InternalServerError|http:NotFound {

        authorization:CustomJwtPayload|error userInfo = ctx.getWithType(authorization:HEADER_USER_INFO);
        if userInfo is error {
            string customError = "Error getting token from the header";
            log:printError(customError, 'error = userInfo);
            return <http:InternalServerError>{
                body: {
                    message: customError
                }
            };
        }
        if userInfoCache.hasKey(userInfo.email) {
            any|error cachedEmployee = userInfoCache.get(userInfo.email);
            if cachedEmployee is types:Employee {
                return cachedEmployee;
            }

            if cachedEmployee is cache:Error {
                string customError = "Error getting employee information";
                log:printError(customError, cachedEmployee);
            }
        }

        types:Employee|error? user = database:getEmployee(userInfo.email);
        if user is error {
            string customError = string `Error getting employee basic information for ${userInfo.email}`;
            log:printError(customError, user);
            return <http:InternalServerError>{
                body: {
                    message: customError
                }
            };
        }
        if user is () {
            log:printDebug(string `No active employee found for the email: ${userInfo.email}`);
            return http:NOT_FOUND;
        }
        any|error resultUpdatedCache = userInfoCache.put(userInfo.email, user);
        if resultUpdatedCache is error {
            string customError = "Error updating employee in user cache";
            log:printError(customError, 'error = resultUpdatedCache);
        }
        return user;
    }
}

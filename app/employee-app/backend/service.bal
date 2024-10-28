//
// Copyright (c) 2005-2024, WSO2 LLC. (http://www.wso2.org) All Rights Reserved.
//
// WSO2 Inc. licenses this file to you under the Apache License,
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
// 
import employee_app.authorization;
import employee_app.database;
import employee_app.email;
import employee_app.types;

import ballerina/cache;
import ballerina/http;
import ballerina/log;
import ballerina/regex;
import ballerina/time;

configurable email:EmailAlertConfig offerEmailConfig = ?;

final cache:Cache userInfoCache = new (capacity = 100, evictionFactor = 0.2);
final cache:Cache orgStructureCache = new (capacity = 100, evictionFactor = 0.2);

@display {
    label: "Employee Application",
    id: "hris/employee-application"
}
service http:InterceptableService / on new http:Listener(9090) {

    # Request interceptor.
    # + return - authorization:JwtInterceptor
    public function createInterceptors() returns [authorization:JwtInterceptor] {
        return [new authorization:JwtInterceptor()];
    }

    # Get basic information of a given active employee.
    #
    # + email - Email of the employee
    # + return - Basic information of the employee or an error
    resource function get employees/[string email]()
        returns types:Employee|http:BadRequest|http:InternalServerError|http:NotFound|error {

        if !email.matches(types:WSO2_EMAIL) {
            return <http:BadRequest>{
                body: {
                    message: string `Input email is not a valid WSO2 email address: ${email}`
                }
            };
        }
        types:Employee|error? employee;
        if userInfoCache.hasKey(email) {
            return userInfoCache.get(email).ensureType();
        }

        employee = database:getEmployee(email);
        if employee is error {
            string customError = string `Error getting employee basic information for ${email}`;
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
            string customError = "Error getting employee basic information for employees";
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
    resource function get org\-structure() returns types:OrgStructure|error {

        if orgStructureCache.hasKey("orgStructure") {
            return <types:OrgStructure>check orgStructureCache.get("orgStructure");
        }

        types:OrgStructure orgStructure = {
            businessUnits: check database:getOrgDetails(filter = {}, 'limit = types:DEFAULT_LIMIT, offset = 0),
            companies: check database:getCompanies(filter = {}, 'limit = types:DEFAULT_LIMIT, offset = 0),
            careerPaths: check database:getCareerFunctions(filter = {}, 'limit = types:DEFAULT_LIMIT, offset = 0),
            employmentTypes: [types:PERMANENT, types:INTERNSHIP, types:CONSULTANCY]
        };
        check orgStructureCache.put("orgStructure", orgStructure);
        return orgStructure;
    }

    # Retrieve specific recruit data from the database.
    #
    # + return - recruit data or error response
    resource function get recruits/[int recruitId](http:RequestContext ctx)
        returns types:Recruit|http:Forbidden|error => check database:getRecruit(recruitId);

    # Retrieve all recruits data from the database.
    #
    # + statusArray - Array of recruit statuses to filter the data  
    # + 'limit - Limit of the data  
    # + offset - Offset of the data
    # + return - All Selected recruits data or error response
    resource function get recruits(database:RecruitStatus[]? statusArray, int? 'limit, int? offset)
        returns types:Recruit[]|error => check database:getRecruits(statusArray, 'limit, offset);

    # Retrieve compensations for a specific recruit's employment type and the company location.
    #
    # + recruitId - ID of the recruit  
    # + return - Compensation or error response
    resource function get recruits/[int recruitId]/compensation(http:RequestContext ctx)
        returns types:Compensation[]|http:Forbidden|error {

        authorization:CustomJwtPayload userInfo = check ctx.getWithType(authorization:HEADER_USER_INFO);
        if !authorization:checkRoles([authorization:authorizedRoles.recruitmentTeamRole],
                userInfo.groups) {
            return <http:Forbidden>{body: {message: "Insufficient privileges!"}};
        }

        types:Recruit {employmentType, companyLocation} = check database:getRecruit(recruitId);
        companyLocation = regex:replaceAll(companyLocation, " ", "");
        string compensationFilter = string `${types:OFFER_TEMPLATE_PREFIX}${employmentType}`;
        if employmentType == types:PERMANENT {
            compensationFilter = compensationFilter + string `${companyLocation}`;
        }
        if employmentType == types:INTERNSHIP || employmentType == types:CONSULTANCY {
            compensationFilter = compensationFilter + string `${types:OFFER_TEMPLATE_POSTFIX}`;
        }
        types:CompensationEmail {compensation} = check database:getCompensation(compensationFilter);

        return compensation;
    }

    # Add recruits data to the database.
    #
    # + recruit - Recruits to be added
    # + return - Recruits data insertion successful or error response
    resource function post recruits(http:RequestContext ctx, database:AddRecruitPayload recruit)
        returns http:Created|http:Forbidden|http:BadRequest|error {

        authorization:CustomJwtPayload userInfo = check ctx.getWithType(authorization:HEADER_USER_INFO);
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

        int employeeId = check database:addRecruit(recruit, userInfo.email);
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
        returns http:Ok|http:Forbidden|error {

        authorization:CustomJwtPayload userInfo = check ctx.getWithType(authorization:HEADER_USER_INFO);
        if !authorization:checkRoles([authorization:authorizedRoles.recruitmentTeamRole],
                userInfo.groups) {
            return <http:Forbidden>{body: {message: "Insufficient privileges!"}};
        }

        _ = check database:updateRecruit({...recruit, recruitId}, userInfo.email);
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
        returns http:Ok|http:Forbidden|error {

        authorization:CustomJwtPayload userInfo = check ctx.getWithType(authorization:HEADER_USER_INFO);
        if !authorization:checkRoles([authorization:authorizedRoles.recruitmentTeamRole],
                userInfo.groups) {
            return <http:Forbidden>{body: {message: "Insufficient privileges!"}};
        }

        types:Recruit recruit = check database:getRecruit(recruitId);
        if recruit.status != database:SELECTED {
            return error("The recruit is not in the selected status to skip the offer letter!");
        }
        _ = check database:updateRecruit({status: database:OFFER_SENT, recruitId}, userInfo.email);
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
        returns http:BadRequest|http:Forbidden|http:Ok|http:InternalServerError|http:NotFound|error {

        authorization:CustomJwtPayload userInfo = check ctx.getWithType(authorization:HEADER_USER_INFO);
        if !authorization:checkRoles([authorization:authorizedRoles.recruitmentTeamRole],
                userInfo.groups) {
            return <http:Forbidden>{body: {message: "Insufficient privileges!"}};
        }

        types:Recruit recruit = check database:getRecruit(recruitId);
        if recruit.status != database:SELECTED {
            return <http:BadRequest>{
                body: {
                    message: "The recruit is not in the status to send the offer!"
                }
            };
        }

        string compensationFilter = string `${types:OFFER_TEMPLATE_PREFIX}${recruit.employmentType}`;
        if recruit.employmentType == types:PERMANENT {
            string companyLocation = regex:replaceAll(recruit.companyLocation, " ", "");
            compensationFilter = compensationFilter + string `${companyLocation}`;
        }
        if recruit.employmentType == types:INTERNSHIP || recruit.employmentType == types:CONSULTANCY {
            compensationFilter = compensationFilter + string `${types:OFFER_TEMPLATE_POSTFIX}`;
        }

        types:CompensationEmail compensationEmail = check database:getCompensation(compensationFilter);
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
            senderInfo = check userInfoCache.get(userInfo.email).ensureType();
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

        check userInfoCache.put(userInfo.email, senderInfo);
        if recruit.employmentType is types:PERMANENT {
            types:Recruit {probationEndDate} = recruit;
            if probationEndDate !is string {
                return error(
                    "Probation end date is required for recruits in permanent employment type to send the offer!"
                );
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
            _ = check email:processEmailNotification({
                frm: offerEmailConfig.'from,
                subject: offerEmailConfig.subject,
                to: [recruit.personalEmail],
                templateId: compensationEmail.emailTemplate,
                contentKeyValPairs: keyValPairs,
                attachments: recruit.offerDocuments ?: []
            });
        } else if recruit.employmentType is types:INTERNSHIP {
            types:Recruit {agreementEndDate} = recruit;
            if agreementEndDate !is string {
                return error("Agreement end date is required for internship to send the offer!");
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
            _ = check email:processEmailNotification({
                frm: offerEmailConfig.'from,
                subject: offerEmailConfig.subject,
                to: [recruit.personalEmail],
                templateId: compensationEmail.emailTemplate,
                contentKeyValPairs: keyValPairs,
                attachments: recruit.offerDocuments ?: []
            });
        } else if recruit.employmentType is types:CONSULTANCY {
            types:Recruit {agreementEndDate} = recruit;
            if agreementEndDate !is string {
                return error("Agreement end date is required for consultancy to send the offer!");
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
            _ = check email:processEmailNotification({
                frm: offerEmailConfig.'from,
                subject: offerEmailConfig.subject,
                to: [recruit.personalEmail],
                templateId: compensationEmail.emailTemplate,
                contentKeyValPairs: keyValPairs,
                attachments: recruit.offerDocuments ?: []
            });
        } else {
            return error("Invalid employment type!");
        }

        _ = check database:updateRecruit({recruitId, status: database:OFFER_SENT}, userInfo.email);
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
            types:ActionReason? reason) returns http:Ok|http:BadRequest|http:Forbidden|error {

        authorization:CustomJwtPayload userInfo = check ctx.getWithType(authorization:HEADER_USER_INFO);
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
            return error(string `Invalid action!`);
        }
        types:Recruit {status} = check database:getRecruit(recruitId);
        if status != database:OFFER_SENT {
            return <http:BadRequest>{
                body: {
                    message: string `Recruit is not in the state to ${action} the offer!`
                }
            };
        }
        _ = check database:updateRecruit(
                {recruitId: recruitId, status: recruitStatus, additionalComments: rejectionReason},
                updatedBy = userInfo.email
            );
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
                returns http:BadRequest|http:Forbidden|http:Ok|http:InternalServerError|http:NotFound|error {

        authorization:CustomJwtPayload userInfo = check ctx.getWithType(authorization:HEADER_USER_INFO);
        if !authorization:checkRoles([authorization:authorizedRoles.recruitmentTeamRole], userInfo.groups) {
            return <http:Forbidden>{body: {message: "Insufficient privileges!"}};
        }

        types:Recruit recruit = check database:getRecruit(recruitId);
        if recruit.status != database:OFFER_ACCEPTED {
            return <http:BadRequest>{
                body: {
                    message: "The recruit is not in the required status to send the hiring details!"
                }
            };
        }

        types:Employee|error? senderInfo;
        if userInfoCache.hasKey(userInfo.email) {
            senderInfo = check userInfoCache.get(userInfo.email).ensureType();
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
        check userInfoCache.put(userInfo.email, senderInfo);

        map<string> keyValPairs = {
            RECEIVER_NAME: recruit.firstName,
            SENDER_NAME: string `${senderInfo.firstName ?: types:UNKNOWN} ${senderInfo.lastName ?: types:UNKNOWN}`,
            SENDER_TITLE: senderInfo.designation ?: types:UNKNOWN
        };
        _ = check email:processEmailNotification({
            frm: offerEmailConfig.'from,
            subject: offerEmailConfig.subject,
            to: [recruit.personalEmail],
            templateId: "employeeOnboardCommon",
            contentKeyValPairs: keyValPairs,
            attachments: hiringDetails.documents
        });
        _ = check database:updateRecruit(
            {recruitId: recruitId, status: database:REQUEST_HIRING_DETAILS},
            userInfo.email
        );

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
        returns http:BadRequest|http:Forbidden|http:Ok|error {

        authorization:CustomJwtPayload userInfo = check ctx.getWithType(authorization:HEADER_USER_INFO);
        if !authorization:checkRoles([authorization:authorizedRoles.recruitmentTeamRole],
                userInfo.groups) {

            return <http:Forbidden>{body: {message: "Insufficient privileges!"}};
        }

        types:Recruit recruit = check database:getRecruit(recruitId);
        if recruit.status != database:REQUEST_HIRING_DETAILS {
            return <http:BadRequest>{
                body: {
                    message: "The recruit is not in the required status to mark hiring details received!"
                }
            };
        }

        _ = check database:updateRecruit(
            {recruitId: recruitId, status: database:HIRING_DETAILS_RECEIVED},
            userInfo.email
        );
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
        returns http:BadRequest|http:Forbidden|http:Ok|error {

        authorization:CustomJwtPayload userInfo = check ctx.getWithType(authorization:HEADER_USER_INFO);
        if !authorization:checkRoles([authorization:authorizedRoles.recruitmentTeamRole], userInfo.groups) {
            return <http:Forbidden>{body: {message: "Insufficient privileges!"}};
        }

        types:Recruit recruit = check database:getRecruit(recruitId);
        if recruit.status != database:HIRING_DETAILS_RECEIVED {
            return <http:BadRequest>{
                body: {
                    message: "The recruit is not in the required status to send the contract!"
                }
            };
        }

        _ = check database:updateRecruit({recruitId: recruitId, status: database:CONTRACT_SENT}, userInfo.email);
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
            types:ActionReason? reason) returns http:Ok|http:BadRequest|http:Forbidden|error {

        authorization:CustomJwtPayload userInfo = check ctx.getWithType(authorization:HEADER_USER_INFO);
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
            return error(string `Invalid action!`);
        }

        types:Recruit {status} = check database:getRecruit(recruitId);
        if status != database:CONTRACT_SENT {
            return <http:BadRequest>{
                body: {
                    message: string `The recruit is not in the state to ${action} the contract!`
                }
            };
        }

        _ = check database:updateRecruit(
                {recruitId: recruitId, status: recruitStatus, additionalComments: rejectionReason},
                updatedBy = userInfo.email
            );
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
        returns http:BadRequest|http:Forbidden|http:Ok|error {

        authorization:CustomJwtPayload userInfo = check ctx.getWithType(authorization:HEADER_USER_INFO);
        if !authorization:checkRoles([authorization:authorizedRoles.recruitmentTeamRole],
                userInfo.groups) {

            return <http:Forbidden>{body: {message: "Insufficient privileges!"}};
        }

        types:Recruit recruit = check database:getRecruit(recruitId);
        if recruit.status != database:CONTRACT_ACCEPTED {
            return <http:BadRequest>{
                body: {
                    message: "The recruit is not in the required status to acknowledge the profile creation!"
                }
            };
        }

        _ = check database:updateRecruit(
            {recruitId: recruitId, status: database:HIRING_MANAGER_ACKNOWLEDGED},
            userInfo.email
        );
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
        returns types:Employee|http:BadRequest|http:InternalServerError|http:NotFound|error {

        authorization:CustomJwtPayload userInfo = check ctx.getWithType(authorization:HEADER_USER_INFO);
        if userInfoCache.hasKey(userInfo.email) {
            return check userInfoCache.get(userInfo.email).ensureType();
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
        check userInfoCache.put(userInfo.email, user);
        return user;
    }
}

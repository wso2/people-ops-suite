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
import leave_service.authorization;
import leave_service.database;
import leave_service.employee;

import ballerina/http;
import ballerina/log;

@display {
    label: "Leave Backend Service",
    id: "people-ops/leave-application"
}
service http:InterceptableService / on new http:Listener(9090) {

    # Request interceptor.
    # + return - authorization:JwtInterceptor
    public function createInterceptors() returns http:Interceptor[] {
        return [new authorization:JwtInterceptor()];
    }

    function init() returns error? {
        log:printInfo("Leave application backend service started.");
    }

    # Get Application specific data required for initializing the leave form.
    #
    # + ctx - HTTP request context
    # + req - HTTP Request
    # + return - Return application specific form data
    resource function get form\-data(http:RequestContext ctx, http:Request req)
        returns FormData|http:InternalServerError {

        do {
            authorization:CustomJwtPayload {email} = check ctx.getWithType(authorization:HEADER_USER_INFO);
            string|error jwt = req.getHeader(authorization:JWT_ASSERTION_HEADER);
            if jwt is error {
                fail error(ERR_MSG_NO_JWT_TOKEN_PRESENT);
            }
            final readonly & string[] emails = [email];
            final string startDate = getStartDateOfYear();
            final string endDate = getEndDateOfYear();
            final database:Leave[]|error leaveResponse = database:getLeaves(
                    {emails, startDate, endDate, orderBy: database:DESC}
            );
            if leaveResponse is error {
                log:printError(ERR_MSG_LEAVES_RETRIEVAL_FAILED, leaveResponse);
                fail error(ERR_MSG_NO_JWT_TOKEN_PRESENT);
            }
            LeaveResponse[] leaves = from database:Leave leave in leaveResponse
                select check toLeaveEntity(leave, jwt.toString());

            Employee & readonly|error employee = employee:getEmployee(email, jwt);
            if employee is error {
                log:printError(employee:ERR_MSG_EMPLOYEE_RETRIEVAL_FAILED, employee);
                fail error(employee:ERR_MSG_EMPLOYEE_RETRIEVAL_FAILED);
            }

            Employee {leadEmail, location} = employee;
            string[] emailRecipients = leaves.length() > 0 ? leaves[0].emailRecipients : [];
            string[] leadEmails = leadEmail == () ? [] : [leadEmail];
            LeavePolicy|error legallyEntitledLeave = getLegallyEntitledLeave(employee);
            if legallyEntitledLeave is error {
                log:printError(employee:ERR_MSG_EMPLOYEES_PROCESSING_FAILED, legallyEntitledLeave);
                fail error(employee:ERR_MSG_EMPLOYEES_RETRIEVAL_FAILED, legallyEntitledLeave);
            }

            return {
                emailRecipients,
                leadEmails,
                isLead: <boolean>employee.lead,
                location,
                legallyEntitledLeave,
                leaveReportContent: getLeaveReportContent(leaves)
            };
        }
        on fail error internalErr {
            return <http:InternalServerError>{
                body: {
                    message: internalErr.message()
                }
            };
        }

    }

    # Fetch all the employees.
    #
    # + location - Employee location  
    # + businessUnit - Employee business unit 
    # + department - Employee department
    # + team - Employee team
    # + employeeStatuses - Employee statuses to filter the employees
    # + leadEmail - Manager email to filter the employees
    # + return - Return list of employee records
    resource function get employees(string? location, string? businessUnit, string? department, string? team,
            string[]? employeeStatuses, string? leadEmail, http:Request req)
        returns Employee[]|http:InternalServerError {

        do {
            string|error jwt = req.getHeader(authorization:JWT_ASSERTION_HEADER);
            if jwt is error {
                fail error(ERR_MSG_NO_JWT_TOKEN_PRESENT, jwt);
            }

            Employee[] & readonly|error employees = employee:getEmployees(
                    jwt,
                    {
                        location,
                        businessUnit,
                        team: department,
                        unit: team,
                        status: employeeStatuses,
                        leadEmail
                    },
                    'limit = 1000,
                    offset = 0
            );
            if employees is error {
                log:printError(employee:ERR_MSG_EMPLOYEES_RETRIEVAL_FAILED, employees);
                fail error(employee:ERR_MSG_EMPLOYEES_RETRIEVAL_FAILED, employees);
            }

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
        }
        on fail error internalErr {
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
    # + email - Employee email
    # + return - Return the employee record
    resource function get employees/[string email](http:Request req)
        returns Employee|http:InternalServerError|http:BadRequest {

        if !email.matches(WSO2_EMAIL_PATTERN) {
            return <http:BadRequest>{
                body: {
                    message: string `Input email is not a valid WSO2 email address: ${email}`
                }
            };
        }

        do {
            string|error jwt = req.getHeader(authorization:JWT_ASSERTION_HEADER);
            if jwt is error {
                fail error(ERR_MSG_NO_JWT_TOKEN_PRESENT, jwt);
            }
            Employee & readonly|error employee = employee:getEmployee(email, jwt);
            if employee is error {
                log:printError(string `${employee:ERR_MSG_EMPLOYEE_RETRIEVAL_FAILED} Email: ${email}.`, employee);
                fail error(employee:ERR_MSG_EMPLOYEE_RETRIEVAL_FAILED, employee);
            }
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
        }
        on fail error internalErr {
            log:printError(internalErr.message(), internalErr);
            return <http:InternalServerError>{
                body: {
                    message: internalErr.message()
                }
            };
        }
    }

}

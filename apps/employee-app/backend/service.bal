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
import employee_service.authorization;
import employee_service.database;

import ballerina/http;
import ballerina/log;

@display {
    label: "Employee Backend Service",
    id: "people-ops/employee-application"
}
service http:InterceptableService / on new http:Listener(9090) {

    # Request interceptor.
    # + return - authorization:JwtInterceptor
    public function createInterceptors() returns http:Interceptor[] => [new authorization:JwtInterceptor()];

    function init() returns error? => log:printInfo("Employee application backend service started.");

    # Get basic information of a given active employee.
    #
    # + email - Email of the employee
    # + return - Basic information of the employee or an error
    resource function get employees/[string email]()
        returns Employee|http:BadRequest|http:InternalServerError|http:NotFound {

        if !email.matches(WSO2_EMAIL_PATTERN) {
            return <http:BadRequest>{
                body: {
                    message: string `Input email is not a valid WSO2 email address: ${email}`
                }
            };
        }

        Employee|error? employee = database:getEmployee(email);
        if employee is error {
            string errorMsg = string `Error getting employee information for ${email}!`;
            log:printError(errorMsg, employee);
            return <http:InternalServerError>{
                body: {
                    message: errorMsg
                }
            };
        }
        if employee is () {
            string errorMsg = "No active/marked leaver employee found for the email";
            log:printDebug(string `${errorMsg}: ${email}`);
            return <http:NotFound>{
                body: {
                    message: string `${errorMsg}: ${email}`
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
    resource function post employees/search(EmployeeFilter? filters, int? 'limit, int? offset)
        returns Employee[]|http:InternalServerError {

        Employee[]|error employees =
            database:getEmployees(filters ?: {}, 'limit ?: DEFAULT_LIMIT, offset ?: DEFAULT_OFFSET);
        if employees is error {
            string errorMsg = "Error getting employee information!";
            log:printError(errorMsg, employees);
            return <http:InternalServerError>{
                body: {
                    message: errorMsg
                }
            };
        }
        return employees;
    }

    # Get organization structure from business units, team and units.
    #
    # + filter - Filter objects containing the filter criteria for the query as request body
    # + 'limit - The maximum number of organization records to return
    # + offset - The number of organization records to skip before starting to collect the result set
    # + return - Organization structure or an error
    resource function post org\-structure(orgStructureFilter filter, int? 'limit, int? offset)
        returns OrgStructure|http:InternalServerError {

        OrgStructure|error orgStructure = database:getOrgStructure(filter, 'limit = DEFAULT_LIMIT,
                offset = DEFAULT_OFFSET);
        if orgStructure is error {
            string errorMsg = string `Error getting organization structure!`;
            log:printError(errorMsg, orgStructure);
            return <http:InternalServerError>{
                body: {
                    message: errorMsg
                }
            };
        }
        return orgStructure;
    }
}

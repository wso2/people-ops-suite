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
import ballerina/cache;
import ballerina/http;
import ballerina/log;

isolated cache:Cache hrisEmployeeCache = new (
    'defaultMaxAge = CACHE_DEFAULT_MAX_AGE,
    'cleanupInterval = CACHE_CLEANUP_INTERVAL
);

# Get Employee from HRIS by email with caching or employee service.
#
# + email - Employee email
# + token - JWT token
# + return - Return Employee entity or error
public isolated function getEmployee(string email, string token)
    returns readonly & Employee|error {

    lock {
        any|cache:Error cachedEmployee = hrisEmployeeCache.get(email);
        if cachedEmployee is readonly & Employee {
            return cachedEmployee;
        }
    }

    http:Response employeeResponse = check employeeClient->/employees/[email].get({"x-jwt-assertion": token});
    json|error employeeJsonResponse = employeeResponse.getJsonPayload();
    if employeeJsonResponse is error {
        return error(ERR_MSG_EMPLOYEE_PROCESSING_FAILED, employeeJsonResponse);
    }
    final readonly & EmployeeResponse|error employee = employeeJsonResponse.cloneWithType();
    if employee is error {
        return error(ERR_MSG_EMPLOYEE_PROCESSING_FAILED, employee);
    }

    lock {
        cache:Error? cachingErr = hrisEmployeeCache.put(email, employee);
        if cachingErr is cache:Error {
            log:printError(string `Error with hris employee cache when pushing email: ${email}.`);
        }
    }

    return toEmployee(employee);
}

# Get Employees from HRIS by filters with employee service.
#
# + token - JWT token
# + filters - Array of Filter objects containing the filter criteria for the query
# + 'limit - The maximum number of employees to return
# + offset - The number of employees to skip before starting to collect the result set
# + return - Return an array of Employee entity or error
public isolated function getEmployees(
        string token,
        EmployeeFilter filters = {},
        int 'limit = DEFAULT_LIMIT,
        int offset = DEFAULT_OFFSET
) returns readonly & Employee[]|error {

    http:Response employeesResponse = check employeeClient->/employees/search.post(
        filters,
        {"x-jwt-assertion": token.toString()},
        'limit = 'limit,
        offset = offset
    );
    json|error employeesJsonResponse = employeesResponse.getJsonPayload();
    if employeesJsonResponse is error {
        return error(ERR_MSG_EMPLOYEES_PROCESSING_FAILED, employeesJsonResponse);
    }
    final readonly & EmployeeResponse[]|error employees = employeesJsonResponse.fromJsonWithType();
    if employees is error {
        return error(ERR_MSG_EMPLOYEES_PROCESSING_FAILED, employees);
    }

    return from EmployeeResponse empResp in employees
        select toEmployee(empResp);
}

public isolated function getEmployeeLocation(string email, string token) returns string|error {

    readonly & Employee|error employee = getEmployee(email, token);
    if employee is error {
        return error(employee.message(), employee);
    }
    string? location = employee.location;
    if location is () {
        return error(string `${ERR_MSG_EMPLOYEE_LOCATION_NOT_FOUND}`);
    }

    return location;
}

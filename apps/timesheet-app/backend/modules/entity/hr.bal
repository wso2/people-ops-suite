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
import ballerina/cache;
import ballerina/log;

configurable int hrEntityCacheCapacity = 1000;
configurable decimal hrEntityCacheDefaultMaxAge = 1800.0;
configurable decimal hrEntityCacheCleanupInterval = 900.0;
configurable int hrEntityRequestBatchSize = 100;

isolated cache:Cache cache = new ({
    capacity: hrEntityCacheCapacity,
    defaultMaxAge: hrEntityCacheDefaultMaxAge,
    cleanupInterval: hrEntityCacheCleanupInterval
});

# Fetch Employee Data.
#
# + workEmail - WSO2 email address
# + return - Employee | Error
public isolated function fetchEmployeesBasicInfo(string workEmail) returns Employee|error {
    string document = string `
        query employeeQuery ($workEmail: String!) {
            employee(email: $workEmail) {
                employeeId,
                workEmail,
                firstName,
                lastName,
                jobRole,
                employeeThumbnail,
                company,
                managerEmail,
                lead
            }
        }
    `;

    EmployeeResponse|error response = hrClient->execute(document, {workEmail});
    if response is error {
        return response;
    }
    return response.data.employee;
}

# This function returns the list of employees in the organization.
#
# + return - An array of employees in the organization or an error if the employees retrieval is unsuccessful
public isolated function getAllActiveEmployees() returns Employee[]|error {
    string[] allowedEmployeeTypes = getAuthorizedEmployeeTypes();
    string[] allowedEmployeeStatusTypes = getAuthorizedEmployeeStatusTypes();
    final string GET_EMPLOYEES_DOCUMENT = string `
        query getAllEmployees($filter: EmployeeFilter!, $limit: Int, $offset: Int) {
            employees(filter: $filter, limit: $limit, offset: $offset) {
                firstName
                lastName
                workEmail
                company
                managerEmail
                employeeThumbnail
            }
        }
    `;
    lock {
        any|cache:Error cachedEmployees = cache.get(CACHE_EMPLOYEES);
        if cachedEmployees is readonly & Employee[] {
            return cachedEmployees;
        }
        Employee[] employees = [];
        EmployeeFilter filter = {
            employeeStatus: allowedEmployeeStatusTypes.cloneReadOnly(),
            employmentType: allowedEmployeeTypes.cloneReadOnly()
        };
        boolean fetchMore = true;
        while fetchMore {
            GetEmployeesResponse result = check hrClient->execute(GET_EMPLOYEES_DOCUMENT, {
                filter,
                'limit: hrEntityRequestBatchSize,
                offset: employees.length()
            });
            employees.push(...result.data.employees);
            fetchMore = result.data.employees.length() > 0;
        }
        cache:Error? cachePut = cache.put(CACHE_EMPLOYEES, employees.cloneReadOnly());
        if cachePut is cache:Error {
            log:printWarn("Error occurred while caching the employees.", cachePut);
        }
        foreach Employee employee in employees {
            string cacheKey = string `${CACHE_EMPLOYEE}_${employee.workEmail}`;
            Employee & readonly roEmployee = employee.cloneReadOnly();
            cachePut = cache.put(cacheKey, roEmployee);
            if cachePut is cache:Error {
                log:printWarn("Error occurred while caching the employee.", cachePut);
            }
        }
        return employees.cloneReadOnly();
    }
}

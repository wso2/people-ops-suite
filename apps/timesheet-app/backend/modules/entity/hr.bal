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
public isolated function fetchEmployeeBasicInfo(string workEmail) returns Employee|error {
    string document = string `
        query employeeQuery ($workEmail: String!) {
            employee(email: $workEmail) {
                employeeId
                workEmail
                firstName
                lastName
                jobRole
                employeeThumbnail
                lead
                company
                managerEmail
            }
        }
    `;

    EmployeeResponse|error response = hrClient->execute(document, {workEmail});
    if response is error {
        return response;
    }
    return response.data.employee;
}

# Retrieve Employee Data.
#
# + managerEmail - Optional field of the lead email
# + return - Employee Info Array
public isolated function getEmployees(string? managerEmail = ()) returns EmployeeBasic[]|error {

    EmployeeFilter filter = {
        employeeStatus: getAuthorizedEmployeeStatusTypes().cloneReadOnly(),
        employmentType: getAuthorizedEmployeeTypes().cloneReadOnly()
    };

    if managerEmail is string {
        filter.managerEmail = managerEmail;
    }

    string document = string `query getAllEmployees($filter: EmployeeFilter!, $limit: Int, $offset: Int) {
        employees(filter: $filter, limit: $limit, offset: $offset) {
            workEmail
            firstName
            lastName
            employeeThumbnail
            managerEmail
        }
    }`;

    EmployeeBasic[] employees = [];
    boolean fetchMore = true;
    while fetchMore {
        EmployeesResponse response = check hrClient->execute(
            document,
            {filter: filter, 'limit: DEFAULT_LIMIT, offset: employees.length()}
        );
        employees.push(...response.data.employees);
        fetchMore = response.data.employees.length() > 0;
    }
    return employees;
}

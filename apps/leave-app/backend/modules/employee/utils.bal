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

# Helper function to map EmployeeResponse to Employee.
#
# + response - Employee response
# + return - Return Employee entity
public isolated function toEmployee(EmployeeResponse response) returns readonly & Employee {
    return {
        employeeId: response.employeeId,
        firstName: response.firstName,
        lastName: response.lastName,
        workEmail: response.workEmail,
        startDate: response.startDate,
        employeeThumbnail: response.employeeThumbnail,
        location: response.location,
        leadEmail: response.leadEmail,
        finalDayOfEmployment: response.finalDayOfEmployment,
        lead: response.lead
    };
}

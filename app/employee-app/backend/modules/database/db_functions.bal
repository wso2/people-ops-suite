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

# Get basic information about a given active employee.
#
# + email - Email of the employee
# + return - Returns the basic information of the employee or an error
public isolated function getEmployee(string email) returns Employee|error? {

    DBEmployee|error result = databaseClient->queryRow(getEmployeeQuery(email));
    if result is error {
        string errorMsg = string `An error occurred when retrieving employee data of ${email} !`;
        return error(errorMsg, result);
    }
    Employee employee = {
        employeeId: result.employeeId,
        workEmail: result.workEmail,
        firstName: result.firstName,
        lastName: result.lastName,
        employeeThumbnail: result.employeeThumbnail,
        location: result.location,
        startDate: result.startDate,
        leadEmail: result.leadEmail,
        finalDayOfEmployment: result.finalDayOfEmployment,
        employeeStatus: result.employeeStatus,
        designation: result.designation,
        employmentType: result.employmentType,
        team: result.team,
        businessUnit: result.businessUnit,
        unit: result.unit,
        jobBand: result.jobBand,
        lead: result.lead == 1
    };
    return employee;
}

# Get basic information about given employees.
#
# + filters - Filter objects containing the filter criteria for the query
# + limit - Number of records to retrieve
# + offset - Number of records to offset
# + return - Returns the basic information of employees or an error
public isolated function getEmployees(EmployeeFilter filters, int 'limit, int offset)
    returns Employee[]|error {

    stream<DBEmployee, error?> resultStream = databaseClient->query(getEmployeesQuery(filters, 'limit, offset));
    return from DBEmployee dbEmployeeInfo in resultStream
        select {
            employeeId: dbEmployeeInfo.employeeId,
            workEmail: dbEmployeeInfo.workEmail,
            firstName: dbEmployeeInfo.firstName,
            lastName: dbEmployeeInfo.lastName,
            employeeThumbnail: dbEmployeeInfo.employeeThumbnail,
            location: dbEmployeeInfo.location,
            startDate: dbEmployeeInfo.startDate,
            leadEmail: dbEmployeeInfo.leadEmail,
            finalDayOfEmployment: dbEmployeeInfo.finalDayOfEmployment,
            employeeStatus: dbEmployeeInfo.employeeStatus,
            designation: dbEmployeeInfo.designation,
            employmentType: dbEmployeeInfo.employmentType,
            team: dbEmployeeInfo.team,
            businessUnit: dbEmployeeInfo.businessUnit,
            unit: dbEmployeeInfo.unit,
            jobBand: dbEmployeeInfo.jobBand,
            lead: dbEmployeeInfo.lead == 1
        };
}

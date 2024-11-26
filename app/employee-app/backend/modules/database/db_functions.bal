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
import ballerina/sql;

# Get distinct employee locations from given employee status.
#
# + employeeStatuses - List of employee statuses to consider
# + return - Distinct employee locations or an error
public isolated function getDistinctEmployeeLocations(EmployeeStatus[]? employeeStatuses)
    returns string[]|error {

    stream<EmployeeLocation, error?> resultStream = databaseClient->query(
        getDistinctEmployeeLocationsQuery(employeeStatuses)
    );
    return check from EmployeeLocation empLocation in resultStream
        select empLocation.location;
}

# Get basic information about a given active employee.
#
# + email - Email of the employee
# + return - Basic information of the employee or an error
public isolated function getEmployee(string email) returns Employee|error? {

    EmployeeDb|error result = databaseClient->queryRow(getEmployeeQuery(email));
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
# + 'limit - Number of records to retrieve
# + offset - Number of records to offset
# + return - Basic information of employees or an error
public isolated function getEmployees(EmployeeFilter filters, int 'limit, int offset)
    returns Employee[]|error {

    stream<EmployeeDb, error?> resultStream = databaseClient->query(getEmployeesQuery(filters, 'limit, offset));
    return from EmployeeDb EmployeeDbInfo in resultStream
        select {
            employeeId: EmployeeDbInfo.employeeId,
            workEmail: EmployeeDbInfo.workEmail,
            firstName: EmployeeDbInfo.firstName,
            lastName: EmployeeDbInfo.lastName,
            employeeThumbnail: EmployeeDbInfo.employeeThumbnail,
            location: EmployeeDbInfo.location,
            startDate: EmployeeDbInfo.startDate,
            leadEmail: EmployeeDbInfo.leadEmail,
            finalDayOfEmployment: EmployeeDbInfo.finalDayOfEmployment,
            employeeStatus: EmployeeDbInfo.employeeStatus,
            designation: EmployeeDbInfo.designation,
            employmentType: EmployeeDbInfo.employmentType,
            team: EmployeeDbInfo.team,
            businessUnit: EmployeeDbInfo.businessUnit,
            unit: EmployeeDbInfo.unit,
            jobBand: EmployeeDbInfo.jobBand,
            lead: EmployeeDbInfo.lead == 1
        };
}

# Retrieve organizational structure.
#
# + filter - Filter objects containing the filter criteria for the query
# + 'limit - Number of records to retrieve
# + offset - Number of records to offset
# + return - List of business units
public isolated function getOrgStructure(orgStructureFilter filter, int 'limit, int offset)
    returns OrgStructure|error {

    OrgStructure orgStructure = {
        businessUnits: []
    };
    stream<BusinessUnitDb, sql:Error?> resultStream = databaseClient->query(
        getOrgStructureQuery(filter, 'limit, offset)
    );
    error? businessUnitResult = from BusinessUnitDb bu in resultStream
        do {
            Team[]|error teams = bu.teams.fromJsonStringWithType();
            if teams is error {
                return error(string `An error occurred when retrieving teams data of ${bu.name} !`, teams);
            }
            orgStructure.businessUnits.push({
                id: bu.id,
                name: bu.name,
                teams
            });
        };
    if businessUnitResult is sql:Error {
        return error(string `An error occurred when retrieving business unit details!`, businessUnitResult);
    }
    return orgStructure;
}

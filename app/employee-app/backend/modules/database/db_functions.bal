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
import employee_app.types;

import ballerina/log;
import ballerina/sql;

# Insert a new recruit.
#
# + recruit - Recruit data
# + createdBy - Person who created the recruit
# + return - Recruit id or error
public isolated function addRecruit(AddRecruitPayload recruit, string createdBy) returns int|error {

    sql:ExecutionResult|sql:Error executionResults = databaseClient->execute(addRecruitQuery(recruit, createdBy));
    if executionResults is sql:Error {
        string customError = string `An error occurred while adding the recruit!`;
        log:printError(customError, executionResults);
        return error(customError);
    }
    return <int>executionResults.lastInsertId;
}

# Retrieve career function data from HRIS.
#
# + filter - Criteria to filter the data  
# + limit - Number of records to retrieve
# + offset - Number of records to offset
# + return - List of career functions
public isolated function getCareerFunctions(CareerFunctionFilter filter, int 'limit, int offset)
    returns CareerFunction[]|error {

    CareerFunction[] careerFunctions = [];
    stream<DBCareerFunction, sql:Error?> resultStream = databaseClient->query(getCareerFunctionsQuery(
        filter = filter, 'limit = 'limit, offset = offset));
    error? iterateError = from DBCareerFunction careerFunction in resultStream
        do {
            Designation[]|error designations;
            string resDesignations = careerFunction.designations ?: "";
            if resDesignations == "" {
                designations = [];
            } else {
                designations = check resDesignations.fromJsonStringWithType();
            }

            if designations is error {
                string errorMsg = string `An error occurred when retrieving designations data of ${
                    careerFunction.careerFunction
                } !`;
                log:printError(errorMsg, designations);
                return error(errorMsg);
            }
            careerFunctions.push({
                id: careerFunction.id,
                careerFunction: careerFunction.careerFunction,
                designations: designations
            });
        };
    if iterateError is sql:Error {
        string errorMsg = string `An error occurred when retrieving career function data!`;
        log:printError(errorMsg, iterateError);
        return error(errorMsg);
    }
    return careerFunctions;
}

# Retrieve compensation data of a given filter.
#
# + filter - Filter to retrieve the compensation data
# + return - Compensation data or error
public isolated function getCompensation(string filter) returns types:CompensationEmail|error {

    CompensationEmail|error compensationRecord = databaseClient->queryRow(getCompensationQuery(filter));
    if compensationRecord is error {
        if compensationRecord is sql:Error && compensationRecord is sql:NoRowsError {
            return error(string `No matching compensation data found for ${filter}!`);
        }
        string customError = string `Error occurred while retrieving the compensation data for ${filter}!`;
        log:printError(customError, compensationRecord);
        return error(customError);
    }

    types:Compensation[]|error compensation = compensationRecord.keyValuePairs.fromJsonStringWithType();
    if compensation is error {
        string customError = string `Error occurred while converting compensation data for ${filter}!`;
        log:printError(customError, compensation);
        return error(customError);
    }
    if (compensation.length() == 0) {
        error customError = error(string `No matching compensation data found for ${filter}`);
        return customError;
    }

    return {emailTemplate: compensationRecord.emailTemplate, compensation};
}

# Retrieve companies under from HRIS.
#
# + filter - Criteria to filter the data  
# + 'limit - Number of records to retrieve  
# + offset - Number of records to offset
# + return - List of companies
public isolated function getCompanies(CompanyFilter filter, int 'limit, int offset)
    returns Company[]|error {

    stream<DBCompany, sql:Error?> resultStream = databaseClient->query(getCompaniesQuery(filter, 'limit, offset));
    Company[] companies = [];
    error? iterateError = from DBCompany company in resultStream
        do {
            Office[]|error offices = company.offices.fromJsonStringWithType();
            if offices is error {
                string errorMsg = string `An error occurred when retrieving offices data of ${company.company} !`;
                log:printError(errorMsg, offices);
                return error(errorMsg);
            }
            companies.push({
                id: company.id,
                company: company.company,
                location: company.location,
                offices: offices
            });
        };
    if iterateError is sql:Error {
        if iterateError is sql:NoRowsError {
            return [];
        }
        string errorMsg = string `An error occurred when retrieving companies!`;
        log:printError(errorMsg, iterateError);
        return error(errorMsg);
    }
    return companies;
}

# Get basic information about a given active employee.
#
# + email - Email of the employee
# + return - Returns the basic information of the employee or an error
public isolated function getEmployee(string email) returns Employee|error? {

    DBEmployee|error result = databaseClient->queryRow(getEmployeeQuery(email));
    if result is error {
        return ();
    }
    if result is DBEmployee {
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
}

# Get basic information about given employees.
#
# + filters - Filter objects containing the filter criteria for the query
# + limit - Number of records to retrieve
# + offset - Number of records to offset
# + return - Returns the basic information of employees or an error
public isolated function getEmployees(types:EmployeeFilter filters, int 'limit, int offset)
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

# Retrieve Organizational details from HRIS.
#
# + filter - Criteria to filter the data  
# + limit - Number of records to retrieve
# + offset - Number of records to offset
# + return - List of business units
public isolated function getOrgDetails(OrgDetailsFilter filter, int 'limit, int offset)
    returns BusinessUnit[]|error {

    BusinessUnit[] businessUnits = [];
    stream<DBBusinessUnit, sql:Error?> resultStream = databaseClient->query(getOrgDetailsQuery(
        filter = filter, 'limit = 'limit, offset = offset));
    error? iterateError = from DBBusinessUnit bu in resultStream
        do {
            Department[]|error departments = bu.departments.fromJsonStringWithType();
            if departments is error {
                string errorMsg = string `An error occurred when retrieving departments data of ${
                    bu.businessUnit} !`;
                log:printError(errorMsg, departments);
                return error(errorMsg);
            }
            businessUnits.push({
                id: bu.id,
                businessUnit: bu.businessUnit,
                departments: departments
            });

        };
    if iterateError is sql:Error {
        string errorMsg = string `An error occurred when retrieving organization details!`;
        log:printError(errorMsg, iterateError);
        return error(errorMsg);
    }
    return businessUnits;
}

# Retrieve data of a specific recruit.
#
# + recruitId - Id of the recruitId to retrieve
# + return - Filtered recruitId or error
public isolated function getRecruit(int recruitId) returns types:Recruit|error {

    Recruit|error result = databaseClient->queryRow(getRecruitQuery(recruitId));
    if result is error {
        if (result is sql:Error && result is sql:NoRowsError) {
            return error(string `No matching recruit found : ${recruitId}!`);
        }
        string customError = string `Error occurred while retrieving the recruit data for ${recruitId}!`;
        log:printError(customError, result);
        return error(customError);
    }

    Recruit {compensation, offerDocuments} = result;
    types:Compensation[]|error compensations = [];
    if compensation is string {
        compensations = compensation.fromJsonStringWithType();
    }
    if compensations is error {
        string customError = string `Error occurred while retrieving the compensation data for ${recruitId}!`;
        log:printError(customError, compensations);
        return error(customError);
    }

    types:Document[]|error convertedOfferDocuments = [];
    if offerDocuments is string {
        convertedOfferDocuments = offerDocuments.fromJsonStringWithType();
    }
    if convertedOfferDocuments is error {
        string customError = string `Error occurred while retrieving the offer documents data for ${recruitId} !`;
        log:printError(customError, convertedOfferDocuments);
        return error(customError);
    }

    return {
        recruitId: result.recruitId,
        firstName: result.firstName,
        lastName: result.lastName,
        gender: result.gender,
        personalEmail: result.personalEmail,
        wso2Email: result.wso2Email,
        contactNumber: result.contactNumber,
        employmentType: result.employmentType,
        careerFunctionId: result.careerFunctionId,
        careerFunction: result.careerFunction,
        jobBand: result.jobBand,
        designation: result.designation,
        companyId: result.companyId,
        company: result.company,
        companyLocation: result.companyLocation,
        officeId: result.officeId,
        office: result.office,
        officeLocation: result.officeLocation,
        workLocation: result.workLocation,
        businessUnitId: result.businessUnitId,
        businessUnit: result.businessUnit,
        departmentId: result.departmentId,
        department: result.department,
        teamId: result.teamId,
        team: result.team,
        subTeamId: result.subTeamId,
        subTeam: result.subTeam,
        managerEmail: result.managerEmail,
        reportsTo: result.reportsTo,
        dateOfJoin: result.dateOfJoin,
        probationEndDate: result.probationEndDate,
        agreementEndDate: result.agreementEndDate,
        compensation: compensations,
        offerDocuments: convertedOfferDocuments,
        additionalComments: result.additionalComments,
        status: result.status,
        createdBy: result.createdBy,
        createdOn: result.createdOn,
        updatedBy: result.updatedBy,
        updatedOn: result.updatedOn
    };
}

# Retrieve a specific recruit data.
#
# + statusArray - Recruit statuses to filter the recruits  
# + 'limit - Limit of the number of recruit to retrieve
# + offset - Offset of the number of recruit to retrieve
# + return - List of recruit or error
public isolated function getRecruits(RecruitStatus[]? statusArray, int? 'limit, int? offset)
    returns types:Recruit[]|error {

    types:Recruit[] recruits = [];
    stream<Recruit, error?> resultStream = databaseClient->query(getRecruitsQuery(statusArray, 'limit, offset));
    error? e = from Recruit recruit in resultStream
        do {
            Recruit {compensation, offerDocuments} = recruit;
            types:Compensation[]|error compensations = [];
            if compensation is string {
                compensations = compensation.fromJsonStringWithType();
            }
            if compensations is error {
                string customError = string `Error occurred while retrieving the compensation data for 
                        ${recruit.personalEmail} !`;

                log:printError(customError, compensations);
                return error(customError);
            }

            types:Document[]|error convertedOfferDocuments = [];
            if offerDocuments is string {
                convertedOfferDocuments = offerDocuments.fromJsonStringWithType();
            }

            if convertedOfferDocuments is error {
                string customError = string `Error occurred while retrieving the offer documents data for 
                        ${recruit.personalEmail} !`;
                log:printError(customError, convertedOfferDocuments);
                return error(customError);
            }

            recruits.push({
                recruitId: recruit.recruitId,
                firstName: recruit.firstName,
                lastName: recruit.lastName,
                gender: recruit.gender,
                personalEmail: recruit.personalEmail,
                wso2Email: recruit.wso2Email,
                contactNumber: recruit.contactNumber,
                employmentType: recruit.employmentType,
                careerFunctionId: recruit.careerFunctionId,
                careerFunction: recruit.careerFunction,
                jobBand: recruit.jobBand,
                designation: recruit.designation,
                companyId: recruit.companyId,
                company: recruit.company,
                companyLocation: recruit.companyLocation,
                officeId: recruit.officeId,
                office: recruit.office,
                officeLocation: recruit.officeLocation,
                workLocation: recruit.workLocation,
                businessUnitId: recruit.businessUnitId,
                businessUnit: recruit.businessUnit,
                departmentId: recruit.departmentId,
                department: recruit.department,
                teamId: recruit.teamId,
                team: recruit.team,
                subTeamId: recruit.subTeamId,
                subTeam: recruit.subTeam,
                managerEmail: recruit.managerEmail,
                reportsTo: recruit.reportsTo,
                dateOfJoin: recruit.dateOfJoin,
                agreementEndDate: recruit.agreementEndDate,
                probationEndDate: recruit.probationEndDate,
                compensation: compensations,
                offerDocuments: convertedOfferDocuments,
                additionalComments: recruit.additionalComments,
                status: recruit.status,
                createdBy: recruit.createdBy,
                createdOn: recruit.createdOn,
                updatedBy: recruit.updatedBy,
                updatedOn: recruit.updatedOn
            });
        };
    if e is error {
        string customError = string `Error occurred while retrieving the recruit data !`;
        log:printError(customError, e);
        return error(customError);
    }
    return recruits;
}

# Update data of a selected recruit.
#
# + recruit - Recruit payload  
# + updatedBy - Person who update the recruit
# + return - Execution success result or error
public isolated function updateRecruit(UpdateRecruitPayload recruit, string updatedBy)
    returns sql:ExecutionResult|error {

    if recruit.entries().length() == 0 {
        return error(string `No data to update the recruit : ${recruit.recruitId} !`);
    }
    sql:ExecutionResult|sql:Error executionResult = databaseClient->execute(updateRecruitQuery(recruit, updatedBy));
    if executionResult is sql:Error {
        string customError = string `Error occurred while updating the recruit data  of ${recruit.recruitId} !`;
        log:printError(customError, executionResult);
        return error(customError);
    }
    if (executionResult.affectedRowCount == 0) {
        return error(string `No recruit were to update from id : ${recruit.recruitId} !`);
    }
    
    return executionResult;
}

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
import ballerina/sql;

# Common build query to retrieve the employee/employees.
#
# + return - sql:ParameterizedQuery - Select query for the employee table
isolated function getCommonEmployeeQuery() returns sql:ParameterizedQuery => `
    SELECT
        e.employee_id,
        e.employee_first_name,
        e.employee_last_name,
        e.employee_thumbnail,
        e.employee_work_email,
        e.employee_location,
        e.employee_lead,
        e.employee_status,
        e.employee_start_date,
        e.employee_final_day_of_employment,
        hbu.business_unit_name,
        ht.team_name,
        hu.unit_name,
        hd.designation,
        hd.designation_job_band,
        het.employment_type_name,
        if(hd.designation_job_band >= 7,TRUE,FALSE)
        AS "lead"
    FROM hris_employee e
    LEFT JOIN 
        hris_business_unit hbu ON e.employee_business_unit_id = hbu.business_unit_id
    LEFT JOIN 
        hris_team ht ON e.employee_team_id = ht.team_id
    LEFT JOIN 
        hris_unit hu ON e.employee_unit_id = hu.unit_id
    LEFT JOIN 
        hris_designation hd ON e.employee_designation_id = hd.designation_id
    LEFT JOIN 
        hris_employment_type het ON e.employee_employment_type_id = het.employment_type_id
`;

# Build query to retrieve the employee from the active or marked leaver status and email.
#
# + email - Email of the employee
# + return - sql:ParameterizedQuery - Select query for the employee table
isolated function getEmployeeQuery(string email) returns sql:ParameterizedQuery {

    sql:ParameterizedQuery mainQuery = getCommonEmployeeQuery();
    sql:ParameterizedQuery finalQuery = sql:queryConcat(
        mainQuery,
        ` WHERE (e.employee_status = ${ACTIVE} OR e.employee_status = ${MARKED\ LEAVER}) AND e.employee_work_email = ${email}`
    );
    return finalQuery;
}

# Build query to retrieve the employees.
#
# + filters - Filter objects containing the filter criteria for the query
# + 'limit - The maximum number of employees to return
# + offset - The number of employees to skip before starting to collect the result set
# + return - sql:ParameterizedQuery - Select query for the employee table
isolated function getEmployeesQuery(EmployeeFilter filters, int 'limit, int offset)
    returns sql:ParameterizedQuery {

    sql:ParameterizedQuery mainQuery = getCommonEmployeeQuery();
    EmployeeFilter {
        status,
        employmentType
    } = filters;
    sql:ParameterizedQuery[] filterQueries = [];
    if status is string[] && status.length() > 0 {
        filterQueries.push(sql:queryConcat(`e.employee_status IN (`, sql:arrayFlattenQuery(status), `)`));
    }
    if filters.location is string {
        filterQueries.push(sql:queryConcat(`e.employee_location = ${filters.location}`));
    }
    if filters.businessUnit is string {
        filterQueries.push(sql:queryConcat(`hbu.business_unit_name = ${filters.businessUnit}`));
    }
    if filters.team is string {
        filterQueries.push(sql:queryConcat(`ht.team_name = ${filters.team}`));
    }
    if filters.unit is string {
        filterQueries.push(sql:queryConcat(`hu.unit_name = ${filters.unit}`));
    }
    if filters.leadEmail is string {
        filterQueries.push(sql:queryConcat(`e.employee_lead = ${filters.leadEmail}`));
    }
    if filters.designation is string {
        filterQueries.push(sql:queryConcat(`hd.designation = ${filters.designation}`));
    }
    if employmentType is string[] && employmentType.length() > 0 {
        filterQueries.push(sql:queryConcat(`het.employment_type_name IN (`,
        sql:arrayFlattenQuery(employmentType), `)`));
    }
    if filters.lead is boolean {
        sql:ParameterizedQuery leadQuery = <boolean>filters.lead ?
            `hd.designation_job_band >= 7` : `hd.designation_job_band < 7`;
        filterQueries.push(leadQuery);
    }
    sql:ParameterizedQuery finalQuery = buildSqlSelectQuery(mainQuery, filterQueries);

    finalQuery = sql:queryConcat(finalQuery, ` ORDER BY e.employee_id DESC
        LIMIT ${'limit} OFFSET ${offset}`);

    return finalQuery;
}

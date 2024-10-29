//
// Copyright (c) 2024, WSO2 LLC.
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

import ballerina/sql;

# Build query to add a recruit.
#
# + recruit - The recruit to be added
# + createdBy - The user who is adding the recruit
# + return - sql:ParameterizedQuery - Insert query for the recruit table
isolated function addRecruitQuery(AddRecruitPayload recruit, string createdBy) returns sql:ParameterizedQuery =>
`
    INSERT INTO hris_recruit
    (
        recruit_first_name,
        recruit_last_name,
        recruit_gender,
        recruit_personal_email,
        recruit_wso2_email,
        recruit_contact_number,
        recruit_employment_type,
        recruit_career_function,
        recruit_business_unit,
        recruit_department,
        recruit_team,
        recruit_sub_team,
        recruit_job_band,
        recruit_date_of_join,
        recruit_probation_end_date,
        recruit_agreement_end_date,
        recruit_company,
        recruit_office,
        recruit_work_location,
        recruit_reports_to,
        recruit_manager_email,
        recruit_status,
        recruit_created_by,
        recruit_updated_by
    )
    VALUES
    (
        ${recruit.firstName},
        ${recruit.lastName},
        ${recruit.gender},
        ${recruit.personalEmail},
        ${recruit.wso2Email},
        ${recruit.contactNumber},
        ${recruit.employmentType},
        ${recruit.careerFunction},
        ${recruit.businessUnit},
        ${recruit.department},
        ${recruit.team},
        ${recruit.subTeam},
        ${recruit.jobBand},
        ${recruit.dateOfJoin},
        ${recruit.probationEndDate},
        ${recruit.agreementEndDate},
        ${recruit.company},
        ${recruit.office},
        ${recruit.workLocation},
        ${recruit.reportsTo},
        ${recruit.managerEmail},
        ${SELECTED},
        ${createdBy},
        ${createdBy}
    )
`;

# Build SQL query to retrieve Career function data.
#
# + filter - Criteria to filter the data  
# + limit - Number of records to retrieve
# + offset - Number of records to offset
# + return - Get Career Functions Query
public isolated function getCareerFunctionsQuery(CareerFunctionFilter filter, int 'limit, int offset)
    returns sql:ParameterizedQuery {

    sql:ParameterizedQuery sqlQuery = ` 
        SELECT 
            career_function_id as id,
            career_function as careerFunction,
            (
                SELECT 
                    JSON_ARRAYAGG(JSON_OBJECT(
                        'designation', designation,
                        'jobBand', designation_job_band,
                        'id', designation_id
                    ))
                FROM 
                    hris_designation hd
                WHERE 
                    hd.career_function_id = cf.career_function_id
                    AND
                    hd.designation_is_active = 1
            ) as designations
        FROM 
            hris_career_function cf
    `;

    int[]? idArray = filter.careerFunctionIds;
    string[]? careerFunctionTitlesArray = filter.careerFunctions;
    sql:ParameterizedQuery[] filterQueries = [];
    addFilterCondition(filterQueries, `cf.career_function_id`, idArray);
    addFilterCondition(filterQueries, `cf.career_function`, careerFunctionTitlesArray);
    sqlQuery = buildSqlSelectQuery(sqlQuery, filterQueries);
    sqlQuery = sql:queryConcat(sqlQuery, ` LIMIT ${'limit} OFFSET ${offset}`);

    return sqlQuery;
}

# Common build query to retrieve the employee/employees.
#
# + return - sql:ParameterizedQuery - Select query for the employee table
isolated function getCommonEmployeeQuery() returns sql:ParameterizedQuery =>
`
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

# Common build query to retrieve the recruit/recuits.
#
# + return - sql:ParameterizedQuery - Select query for the employee table
isolated function getCommonRecruitQuery() returns sql:ParameterizedQuery =>
`
    SELECT 
        e.recruit_Id,
        e.recruit_first_name,
        e.recruit_last_name,
        e.recruit_gender,
        e.recruit_personal_email,
        e.recruit_wso2_email,
        e.recruit_contact_number,
        e.recruit_employment_type,
        e.recruit_career_function,
        cf.career_function,
        e.recruit_business_unit,
        bu.business_unit_name,
        e.recruit_department,
        dept.department_name,
        e.recruit_team,
        t.team_name,
        e.recruit_sub_team,
        st.sub_team_name,
        e.recruit_job_band,
        d.designation,
        e.recruit_date_of_join,
        e.recruit_probation_end_date,
        e.recruit_agreement_end_date,
        e.recruit_company,
        c.company_name,
        c.company_location,
        e.recruit_office,
        o.office_name,
        o.office_location,
        e.recruit_work_location,
        e.recruit_reports_to,
        e.recruit_manager_email,
        e.recruit_compensation,
        e.recruit_offer_documents,
        e.recruit_additional_comments,
        e.recruit_status,
        e.recruit_created_by,
        e.recruit_created_on,
        e.recruit_updated_by,
        e.recruit_updated_on
    FROM 
        hris_recruit e
	LEFT JOIN
		hris_career_function cf
        ON 
        e.recruit_career_function = cf.career_function_id
	LEFT JOIN
		hris_designation d
        ON
        e.recruit_job_band = d.designation_job_band AND d.career_function_id = cf.career_function_id
	LEFT JOIN
		hris_company c
        ON 
        e.recruit_company = c.company_id
	LEFT JOIN
		hris_office o
        ON
        e.recruit_office = o.office_id
	LEFT JOIN
		hris_business_unit bu
        ON
        e.recruit_business_unit = bu.business_unit_id
	LEFT JOIN
		hris_department dept
        ON
        e.recruit_department = dept.department_id
	LEFT JOIN
		hris_team t
        ON 
        e.recruit_team = t.team_id
	LEFT JOIN
		hris_sub_team st
        ON
        e.recruit_sub_team = st.sub_team_id
`;

# Build SQL query to retrieve company data.
#
# + filter - Criteria to filter the data  
# + 'limit - Number of records to retrieve  
# + offset - Number of records to offset
# + return - Get Companies Query
public isolated function getCompaniesQuery(CompanyFilter filter, int 'limit, int offset)
    returns sql:ParameterizedQuery {
    sql:ParameterizedQuery sqlQuery = `
        SELECT 
            company_id,
            company_name,
            company_location,
            (
                SELECT 
                    JSON_ARRAYAGG(JSON_OBJECT(
                        'id', office_id,
                        'office' , office_name,
                        'location', office_location
                        )
                    )
                FROM 
                    hris_office o 
                WHERE 
                    o.company_id = c.company_id
                    AND
                    o.office_is_active = 1
            ) as offices
        FROM 
            hris.hris_company c
        WHERE 
            c.company_is_active = 1
    `;
    CompanyFilter {ids, companies, locations} = filter;
    sql:ParameterizedQuery[] filterQueries = [];
    addFilterCondition(filterQueries, `c.company_id`, ids);
    addFilterCondition(filterQueries, `c.company_name`, companies);
    addFilterCondition(filterQueries, `c.company_location`, locations);
    sqlQuery = buildSqlSelectQuery(sqlQuery, filterQueries);
    sqlQuery = sql:queryConcat(sqlQuery, ` LIMIT ${'limit} OFFSET ${offset}`);

    return sqlQuery;
}

# Build query to retrieve compensation data for given filter.
#
# + filter - Compensation filter
# + return - sql:ParameterizedQuery - Select query for the compensation data
isolated function getCompensationQuery(string filter) returns sql:ParameterizedQuery =>
`
    SELECT 
        email_template_name as emailTemplate,
	    email_template_key_value_pairs as keyValuePairs
    FROM 
        hris.hris_email_template
    WHERE
        email_template_name = ${filter}
        AND
        email_template_app_name = ${APP_NAME};
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
    sql:ParameterizedQuery[] filterQueries = [`SUBSTRING_INDEX(e.employee_work_email, '@', -1) = ${WSO2_DOMAIN}`];
    addFilterCondition(filterQueries, `e.employee_status`, status);
    addFilterCondition(filterQueries, `e.employee_location`, filters.location);
    addFilterCondition(filterQueries, `hbu.business_unit_name`, filters.businessUnit);
    addFilterCondition(filterQueries, `ht.team_name`, filters.team);
    addFilterCondition(filterQueries, `hu.unit_name`, filters.unit);
    addFilterCondition(filterQueries, `e.employee_lead`, filters.leadEmail);
    addFilterCondition(filterQueries, `hd.designation`, filters.designation);
    addFilterCondition(filterQueries, `het.employment_type_name`, employmentType);
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

# Build SQL query to retrieve People HR data.
#
# + filter - Criteria to filter the data  
# + limit - Number of records to retrieve
# + offset - Number of records to offset
# + return - Get Employee Details Query
public isolated function getOrgDetailsQuery(OrgDetailsFilter filter, int 'limit, int offset)
    returns sql:ParameterizedQuery {
    sql:ParameterizedQuery sqlQuery =
    `
        SELECT 
            business_unit_id,
            business_unit_name,
            (
                SELECT
                    JSON_ARRAYAGG(JSON_OBJECT(
                        'id', d.team_id,
                        'department' , d.team_name,
                        'teams', (
                                    SELECT 
                                        JSON_ARRAYAGG(JSON_OBJECT(
                                            'id',t.unit_id,
                                            'team',t.unit_name,
                                            'subTeams',(
                                                            SELECT
                                                                JSON_ARRAYAGG(JSON_OBJECT(
                                                                    'id' , st.sub_unit_id,
                                                                    'subTeam', st.sub_unit_name
                                                                    ))
                                                            FROM
                                                                hris_sub_unit st
                                                                RIGHT JOIN
                                                                (SELECT * FROM hris_business_unit_team_unit_sub_unit WHERE business_unit_team_unit_sub_unit_is_active = 1) budtst
                                                                ON st.sub_unit_id = budtst.sub_unit_id
                                                            WHERE budtst.business_unit_team_unit_id = budt.business_unit_team_unit_id
                                            )
                                        ))
                                    FROM 
                                        hris_unit t
                                        RIGHT JOIN
                                        (SELECT * FROM hris_business_unit_team_unit WHERE business_unit_team_unit_is_active = 1) budt
                                        ON t.unit_id = budt.unit_id
                                    WHERE budt.business_unit_team_id = bud.business_unit_team_id
                        )
                    ))
                FROM 
                    hris_team d
                    RIGHT JOIN
                    (SELECT * FROM hris_business_unit_team WHERE business_unit_team_is_active = 1) bud
                    ON d.team_id = bud.team_id
                WHERE bud.business_unit_id = bu.business_unit_id
            ) AS departments
        FROM 
            hris_business_unit bu
        WHERE
            bu.business_unit_id IN (SELECT distinct(business_unit_id) FROM hris_business_unit_team WHERE business_unit_team_is_active = 1)
    `;
    OrgDetailsFilter {
        businessUnitIds,
        businessUnits
    } = filter;
    sql:ParameterizedQuery[] filterQueries = [];
    addFilterCondition(filterQueries, `bu.business_unit_id`, businessUnitIds);
    addFilterCondition(filterQueries, `bu.business_unit_name`, businessUnits);
    sqlQuery = buildSqlSelectQuery(sqlQuery, filterQueries);
    sqlQuery = sql:queryConcat(sqlQuery, ` LIMIT ${'limit} OFFSET ${offset}`);

    return sqlQuery;
}

# Build query to retrieve specific recruit based on the recruit id.
#
# + recruitId - Recruit id to filter
# + return - sql:ParameterizedQuery - Select query for the recruit table
isolated function getRecruitQuery(int recruitId) returns sql:ParameterizedQuery {

    sql:ParameterizedQuery mainQuery = getCommonRecruitQuery();
    sql:ParameterizedQuery finalQuery = sql:queryConcat(
        mainQuery,
        ` WHERE e.recruit_Id = ${recruitId}`
    );
    return finalQuery;
}

# Build query to retrieve recruits.
#
# + statusArray - Recruit statuses to filter  
# + 'limit - limit of the query (default 1000)  
# + offset - offset of the query
# + return - sql:ParameterizedQuery - Select query for the employee table
isolated function getRecruitsQuery(HiringStatus[]? statusArray, int? 'limit, int? offset)
    returns sql:ParameterizedQuery {

    sql:ParameterizedQuery mainQuery = getCommonRecruitQuery();
    sql:ParameterizedQuery[] filterQueries = [];
    addFilterCondition(filterQueries, `e.recruit_status`, statusArray);
    sql:ParameterizedQuery finalQuery = buildSqlSelectQuery(mainQuery, filterQueries);
    if 'limit is int {
        finalQuery = sql:queryConcat(finalQuery, ` LIMIT ${'limit}`);
        if offset is int {
            finalQuery = sql:queryConcat(finalQuery, ` OFFSET ${offset}`);
        }
    } else {
        finalQuery = sql:queryConcat(finalQuery, ` LIMIT 1000`);
    }

    return finalQuery;
}

# Build query to update the selected recruit.
#
# + recruit - The recruit to be updated  
# + updatedBy - Person who is updating the recruit
# + return - sql:ParameterizedQuery - Update query for the recruit table
isolated function updateRecruitQuery(UpdateRecruitPayload recruit, string updatedBy) returns sql:ParameterizedQuery {

    sql:ParameterizedQuery mainQuery = `
        UPDATE 
            hris_recruit
        SET
    `;
    sql:ParameterizedQuery subQuery = `
        WHERE recruit_Id = ${recruit.recruitId}
    `;

    sql:ParameterizedQuery[] filterQueries = [];
    addFilterCondition(filterQueries, `recruit_first_name`, recruit.firstName);
    addFilterCondition(filterQueries, `recruit_last_name`, recruit.lastName);
    addFilterCondition(filterQueries, `recruit_gender`, recruit.gender);
    addFilterCondition(filterQueries, `recruit_personal_email`, recruit.personalEmail);
    addFilterCondition(filterQueries, `recruit_wso2_email`, recruit.wso2Email);
    addFilterCondition(filterQueries, `recruit_contact_number`, recruit.contactNumber);
    addFilterCondition(filterQueries, `recruit_employment_type`, recruit.employmentType);
    addFilterCondition(filterQueries, `recruit_career_function`, recruit.careerFunction);
    addFilterCondition(filterQueries, `recruit_business_unit`, recruit.businessUnit);
    addFilterCondition(filterQueries, `recruit_department`, recruit.department);
    addFilterCondition(filterQueries, `recruit_team`, recruit.team);
    addFilterCondition(filterQueries, `recruit_sub_team`, recruit.subTeam);
    addFilterCondition(filterQueries, `recruit_job_band`, recruit.jobBand);
    addFilterCondition(filterQueries, `recruit_date_of_join`, recruit.dateOfJoin);
    addFilterCondition(filterQueries, `recruit_date_of_join`, recruit.dateOfJoin);
    addFilterCondition(filterQueries, `recruit_agreement_end_date`, recruit.agreementEndDate);
    addFilterCondition(filterQueries, `recruit_probation_end_date`, recruit.agreementEndDate);
    addFilterCondition(filterQueries, `recruit_company`, recruit.company);
    addFilterCondition(filterQueries, `recruit_office`, recruit.office);
    addFilterCondition(filterQueries, `recruit_work_location`, recruit.workLocation);
    addFilterCondition(filterQueries, `recruit_manager_email`, recruit.managerEmail);
    addFilterCondition(filterQueries, `recruit_compensation`, recruit.compensation);
    addFilterCondition(filterQueries, `recruit_offer_documents`, recruit.offerDocuments);
    addFilterCondition(
        filterQueries,
        `recruit_additional_comments`,
        recruit.additionalComments
    );
    addFilterCondition(filterQueries, `recruit_status`, recruit.status);
    filterQueries.push(`recruit_updated_by = ${updatedBy}`);
    mainQuery = buildSqlUpdateQuery(mainQuery, filterQueries);

    return sql:queryConcat(mainQuery, subQuery);
}

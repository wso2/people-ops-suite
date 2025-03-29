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
import ballerina/sql;

# Build query to add a sample collection.
#
# + sampleCollection - sample collection to be added
# + createdBy - The user who is adding the sample collection
# + return - sql:ParameterizedQuery - Insert query for the sample collection table
isolated function addSampleCollectionQuery(AddSampleCollection sampleCollection, string createdBy)
    returns sql:ParameterizedQuery =>
`
    INSERT INTO sample_collection
    (
        sample_collection_name,
        sample_collection_created_by,
        sample_collection_updated_by
    )
    VALUES
    (
        ${sampleCollection.name},
        ${createdBy},
        ${createdBy}
    )
`;

# Build query to retrieve sample collections.
#
# + name - Name to filter
# + 'limit - Limit of the data
# + offset - offset of the query
# + return - sql:ParameterizedQuery - Select query for the sample_collection table
isolated function getSampleCollectionsQuery(string? name, int? 'limit, int? offset) returns sql:ParameterizedQuery {
    sql:ParameterizedQuery mainQuery = `
            SELECT
                sample_collection_id AS 'id',
                sample_collection_name AS 'name',
                sample_collection_created_on AS 'createdOn',
                sample_collection_created_by AS 'createdBy',
                sample_collection_updated_on AS 'updatedOn',
                sample_collection_updated_by AS 'updatedBy'
            FROM
                sample_schema.sample_collection
    `;

    // Setting the filters based on the sample collection object.
    sql:ParameterizedQuery[] filters = [];

    if name is string {
        filters.push(sql:queryConcat(`sample_collection_name LIKE `, `${name}`));
    }

    mainQuery = buildSqlSelectQuery(mainQuery, filters);

    // Setting the limit and offset.
    if 'limit is int {
        mainQuery = sql:queryConcat(mainQuery, ` LIMIT ${'limit}`);
        if offset is int {
            mainQuery = sql:queryConcat(mainQuery, ` OFFSET ${offset}`);
        }
    } else {
        mainQuery = sql:queryConcat(mainQuery, ` LIMIT 100`);
    }

    return mainQuery;
}

# Build query to retrieve sample collection.
#
# + id - Identification of the sample collection
# + return - sql:ParameterizedQuery - Select query for the sample_collection table
isolated function getSampleCollectionQuery(int id) returns sql:ParameterizedQuery =>
`
    SELECT
        sample_collection_id AS 'id',
        sample_collection_name AS 'name',
        sample_collection_created_on AS 'createdOn',
        sample_collection_created_by AS 'createdBy',
        sample_collection_updated_on AS 'updatedOn',
        sample_collection_updated_by AS 'updatedBy'
    FROM
        sample_schema.sample_collection
    WHERE
        sample_collection_id = ${id}
`;

# Query to retrieve work policies.
#
# + companyName - Company name to filter
# + return - Select query for the work policies
isolated function getWorkPolicyQuery(string companyName) returns sql:ParameterizedQuery =>
`
    SELECT
        ot_hours_per_year AS 'otHoursPerYear',
        working_hours_per_day AS 'workingHoursPerDay',
        lunch_hours_per_day AS 'lunchHoursPerDay'
    FROM
        hris_timesheet_work_policies
    WHERE
        company_name = ${companyName};
`;

# Query to retrieve the timesheet records of an employee.
#
# + filter - Filter type for the  records
# + return - Select query for the work policies
isolated function getTimeSheetRecordsOfEmployee(TimesheetCommonFilter filter) returns sql:ParameterizedQuery {
    sql:ParameterizedQuery mainQuery = `
    SELECT
        tr.ts_record_id AS recordId,
        tr.ts_employee_email AS employeeEmail,
        tr.ts_record_date AS recordDate,
        tr.ts_clock_in AS clockInTime,
        tr.ts_clock_out AS clockOutTime,
        tr.ts_lunch_included AS isLunchIncluded,
        tr.ts_ot_hours AS overtimeDuration,
        tr.ts_ot_reason AS overtimeReason,
        tr.ts_ot_rejection_reason AS overtimeRejectReason,
        tr.ts_ot_status AS overtimeStatus
    FROM
        hris_timesheet_records tr
    `;
    sql:ParameterizedQuery[] filters = [];
    if filter.employeeEmail is string {
        filters.push(sql:queryConcat(`tr.ts_employee_email = `, `${filter.employeeEmail}`));
    }
    if filter.recordDates is string[] {
        filters.push(sql:queryConcat(`tr.ts_record_date IN (`, sql:arrayFlattenQuery(filter.recordDates ?: []), `)`));
    }
    if filter.status is TimeSheetStatus {
        filters.push(sql:queryConcat(`tr.ts_ot_status =  `, `${filter.status}`));
    }
    if filter.rangeStart is string && filter.rangeEnd is string {
        filters.push(sql:queryConcat(`tr.ts_record_date BETWEEN ${filter.rangeStart} `, ` AND ${filter.rangeEnd}`));
    }
    if filter.leadEmail is string {
        filters.push(sql:queryConcat(`tr.ts_lead_email =  `, `${filter.leadEmail}`));
    }
    mainQuery = buildSqlSelectQuery(mainQuery, filters);
    if filter.recordsLimit is int {
        mainQuery = sql:queryConcat(mainQuery, ` LIMIT ${filter.recordsLimit}`);
        if filter.recordOffset is int {
            mainQuery = sql:queryConcat(mainQuery, ` OFFSET ${filter.recordOffset}`);
        }
    } else {
        mainQuery = sql:queryConcat(mainQuery, ` LIMIT 100`);
    }
    return mainQuery;
}

# Query to retrieve the timesheet records count of an employee.
#
# + filter - Filter type for the records
# + return - Select query for the work policies
isolated function getTotalRecordCountQuery(TimesheetCommonFilter filter) returns sql:ParameterizedQuery {
    sql:ParameterizedQuery mainQuery = `
        SELECT
            COUNT(*) AS totalRecords
        FROM
            hris_timesheet_records
    `;

    sql:ParameterizedQuery[] filters = [];
    if filter.employeeEmail is string {
        filters.push(sql:queryConcat(`ts_employee_email = `, `${filter.employeeEmail}`));
    }
    if filter.status is TimeSheetStatus {
        filters.push(sql:queryConcat(`ts_ot_status = `, `${filter.status}`));
    }
    if filter.leadEmail is string {
        filters.push(sql:queryConcat(`ts_lead_email =  `, `${filter.leadEmail}`));
    }
    mainQuery = buildSqlSelectQuery(mainQuery, filters);
    return mainQuery;
}

# Query to insert the timesheet records of an employee.
#
# + timesheetRecords - Filter type for the records
# + employeeEmail - Email of the employee
# + companyName - Name of the company
# + leadEmail - Email of the lead
# + return - Insert query for the timesheet records
isolated function insertTimesheetRecordsQuery(TimeSheetRecord[] timesheetRecords, string employeeEmail,
        string companyName, string leadEmail) returns sql:ParameterizedQuery[] =>
            from TimeSheetRecord timesheetRecord in timesheetRecords
let TimeSheetRecord {recordDate, clockInTime, clockOutTime, isLunchIncluded, overtimeDuration, overtimeReason,
            overtimeStatus} = timesheetRecord
select `
        INSERT INTO hris_timesheet_records (
            ts_employee_email,
            ts_record_date,
            ts_company_name,
            ts_clock_in,
            ts_clock_out,
            ts_lunch_included,
            ts_ot_hours,
            ts_ot_reason,
            ts_lead_email,
            ts_ot_status,
            ts_created_by,
            ts_updated_by
        )
        VALUES (
            ${employeeEmail},
            ${recordDate},
            ${companyName},
            ${clockInTime},
            ${clockOutTime},
            ${isLunchIncluded},
            ${overtimeDuration},
            ${overtimeReason},
            ${leadEmail},
            ${overtimeStatus},
            ${employeeEmail},
            ${employeeEmail}
        );
    `;

# Query to retrieve timesheet information of employee.
#
# + filter - Filter type for the  records
# + return - Select query for the timesheet information
isolated function getTimesheetInfoQuery(TimesheetCommonFilter filter) returns sql:ParameterizedQuery {
    sql:ParameterizedQuery mainQuery = `
    SELECT
        COUNT(*) AS totalRecords,
        SUM(CASE
            WHEN ts_ot_status = ${PENDING} THEN 1
            ELSE 0
        END) AS pendingRecords,
        SUM(CASE
            WHEN ts_ot_status = ${REJECTED} THEN 1
            ELSE 0
        END) AS rejectedRecords,
        SUM(CASE
            WHEN ts_ot_status = ${APPROVED} THEN 1
            ELSE 0
        END) AS approvedRecords,
        COALESCE(SUM(CASE
                    WHEN ts_ot_status = ${APPROVED} THEN ts_ot_hours
                    ELSE 0
                END),
                0) AS totalOvertimeTaken,
        (SELECT
                ot_hours_per_year
            FROM
                hris_timesheet_work_policies
            WHERE
                company_name = (SELECT
                        ts_company_name
                    FROM
                        hris_timesheet_records
                    LIMIT 1)) - COALESCE(SUM(CASE
                    WHEN ts_ot_status = ${APPROVED} THEN ts_ot_hours
                    ELSE 0
                END),
                0) AS overtimeLeft
    FROM
        hris_timesheet_records
`;
    sql:ParameterizedQuery[] filters = [];
    if filter.employeeEmail is string {
        filters.push(sql:queryConcat(`hris_timesheet_records.ts_employee_email = `, `${filter.employeeEmail}`));
    }
    if filter.leadEmail is string {
        filters.push(sql:queryConcat(`hris_timesheet_records.ts_lead_email =  `, `${filter.leadEmail}`));
    }
    mainQuery = buildSqlSelectQuery(mainQuery, filters);
    return mainQuery;
}

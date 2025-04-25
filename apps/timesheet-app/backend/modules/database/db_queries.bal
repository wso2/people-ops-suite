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

# Query to retrieve work policies.
#
# + companyName - Company name to filter
# + return - Select query for the work policies
isolated function getWorkPoliciesQuery(string companyName) returns sql:ParameterizedQuery =>
`
    SELECT
        ot_hours_per_year AS 'otHoursPerYear',
        working_hours_per_day AS 'workingHoursPerDay',
        lunch_hours_per_day AS 'lunchHoursPerDay',
        system_activated AS 'isSystemActivated'
    FROM
        timesheet_work_policies
    WHERE
        company_name = ${companyName};
`;

# Query to retrieve the timesheet records of an employee.
#
# + filter - Filter type for the  records
# + return - Select query timesheet records
isolated function getTimesheetRecordsOfEmployee(TimesheetCommonFilter filter) returns sql:ParameterizedQuery {
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
        timesheet_records tr
    `;
    sql:ParameterizedQuery[] filters = [];
    if filter.employeeEmail is string {
        filters.push(sql:queryConcat(`tr.ts_employee_email = `, `${filter.employeeEmail}`));
    }
    if filter.recordDates is string[] {
        filters.push(sql:queryConcat(`tr.ts_record_date IN (`, sql:arrayFlattenQuery(filter.recordDates ?: []), `)`));
    }
    if filter.recordIds is int[] {
        filters.push(sql:queryConcat(`tr.ts_record_id IN (`, sql:arrayFlattenQuery(filter.recordIds ?: []), `)`));
    }
    if filter.status is TimesheetStatus {
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
        mainQuery = sql:queryConcat(mainQuery, ` LIMIT 400`);
    }
    return mainQuery;
}

# Query to retrieve the timesheet record count of an employee.
#
# + filter - Filter type for the records
# + return - Select query to get total count of timesheet records
isolated function getTotalRecordCountQuery(TimesheetCommonFilter filter) returns sql:ParameterizedQuery {
    sql:ParameterizedQuery mainQuery = `
        SELECT
            COUNT(*) AS totalRecords
        FROM
            timesheet_records
    `;
    sql:ParameterizedQuery[] filters = [];
    if filter.employeeEmail is string {
        filters.push(sql:queryConcat(`ts_employee_email = `, `${filter.employeeEmail}`));
    }
    if filter.status is TimesheetStatus {
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
# + timesheetRecords - TimeLog record to be inserted
# + employeeEmail - Email of the employee
# + companyName - Name of the company
# + leadEmail - Email of the lead
# + return - Insert query for the timesheet records
isolated function insertTimesheetRecordsQuery(TimeLog[] timesheetRecords, string employeeEmail,
        string companyName, string leadEmail) returns sql:ParameterizedQuery[] =>

            from TimeLog timesheetRecord in timesheetRecords
let TimeLog {recordDate, clockInTime, clockOutTime, isLunchIncluded, overtimeDuration, overtimeReason,
overtimeStatus} = timesheetRecord
select `
        INSERT INTO timesheet_records (
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

# Query to retrieve timesheet information.
#
# + filter - Filter type for the  records
# + return - Select query for the timesheet information
isolated function getTimesheetInfoQuery(TimesheetCommonFilter filter) returns sql:ParameterizedQuery {
    sql:ParameterizedQuery mainQuery = `
    SELECT
        COALESCE(COUNT(*), 0) AS totalRecords,
        COALESCE(SUM(CASE
                    WHEN ts_ot_status = ${PENDING} THEN 1
                    ELSE 0
                END),
                0) AS pendingRecords,
        COALESCE(SUM(CASE
                    WHEN ts_ot_status = ${REJECTED} THEN 1
                    ELSE 0
                END),
                0) AS rejectedRecords,
        COALESCE(SUM(CASE
                    WHEN ts_ot_status = ${APPROVED} THEN 1
                    ELSE 0
                END),
                0) AS approvedRecords,
        COALESCE(SUM(CASE
                    WHEN ts_ot_status = ${APPROVED} THEN ts_ot_hours
                    ELSE 0
                END),
                0) AS totalOvertimeTaken,
        COALESCE((SELECT
                        ot_hours_per_year
                    FROM
                        timesheet_work_policies
                    WHERE
                        company_name LIKE ${filter.companyName}),
                0) - COALESCE(SUM(CASE
                    WHEN ts_ot_status = ${APPROVED} THEN ts_ot_hours
                    ELSE 0
                END),
                0) AS overtimeLeft
    FROM
        timesheet_records
    `;
    sql:ParameterizedQuery[] filters = [];
    if filter.employeeEmail is string {
        filters.push(sql:queryConcat(`timesheet_records.ts_employee_email = `, `${filter.employeeEmail}`));
    }
    if filter.leadEmail is string {
        filters.push(sql:queryConcat(`timesheet_records.ts_lead_email =  `, `${filter.leadEmail}`));
    }
    mainQuery = buildSqlSelectQuery(mainQuery, filters);
    return mainQuery;
}

# Query to update a timesheet record.
#
# + updateRecord - Update record type of the timesheet record
# + invokerEmail - Email of the invoker
# + return - Update query for a timesheet record
isolated function updateTimesheetRecordQuery(TimeLogUpdate updateRecord, string invokerEmail)
    returns sql:ParameterizedQuery {

    sql:ParameterizedQuery updateQuery = `
    UPDATE timesheet_records SET
`;
    updateQuery = sql:queryConcat(updateQuery, `ts_clock_in = COALESCE(${updateRecord.clockInTime}, ts_clock_in),`);
    updateQuery = sql:queryConcat(updateQuery, `ts_clock_out = COALESCE(${updateRecord.clockOutTime}, ts_clock_out),`);
    updateQuery = sql:queryConcat(updateQuery, `ts_lunch_included = COALESCE(${updateRecord.isLunchIncluded},
            ts_lunch_included),`);
    updateQuery = sql:queryConcat(updateQuery, `ts_ot_hours = COALESCE(${updateRecord.overtimeDuration}, ts_ot_hours),`);
    updateQuery = sql:queryConcat(updateQuery, `ts_ot_reason = COALESCE(${updateRecord.overtimeReason}, ts_ot_reason),`);
    updateQuery = sql:queryConcat(updateQuery, `ts_ot_rejection_reason = COALESCE(${updateRecord.overtimeRejectReason},
            ts_ot_rejection_reason),`);
    updateQuery = sql:queryConcat(updateQuery, `ts_ot_status = COALESCE(${updateRecord.overtimeStatus}, ts_ot_status),`);
    updateQuery = sql:queryConcat(updateQuery, `ts_updated_by = COALESCE(${invokerEmail}, ts_updated_by)
        WHERE ts_record_id = ${updateRecord.recordId}`);
    return updateQuery;
}

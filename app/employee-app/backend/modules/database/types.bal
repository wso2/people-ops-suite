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
import ballerinax/mysql;

# Business unit record.
public type BusinessUnit record {|
    # Id of the business unit
    int id;
    # Title of the business unit
    string name;
    # List of teams
    Team[]? teams;
|};

# [Database] Business unit data.
public type BusinessUnitDb record {|
    # Id of the business unit
    @sql:Column {name: "business_unit_id"}
    int id;
    # Title of the business unit
    @sql:Column {name: "business_unit_name"}
    string name;
    # List of teams
    string teams;
|};

# [Database] connection pool.
type ConnectionPool record {|
    # Maximum number of open connections
    int maxOpenConnections;
    # Maximum lifetime of a connection
    decimal maxConnectionLifeTime;
    # Minimum number of open connections
    int minIdleConnections;
|};

# [Database] Employee basic information record to get lead type as int.
# Duplicated record with one field change(int? lead) had created due to below issue in ballerina 2201.8.6. 
# Issue: https://github.com/ballerina-platform/ballerina-library/issues/7297
public type DBEmployee record {|
    # Id of the employee
    @sql:Column {name: "employee_id"}
    string employeeId;
    # Employee work email
    @sql:Column {name: "employee_work_email"}
    string workEmail;
    # Employee first name
    @sql:Column {name: "employee_first_name"}
    string? firstName;
    # Employee last name
    @sql:Column {name: "employee_last_name"}
    string? lastName;
    # Employee thumbnail
    @sql:Column {name: "employee_thumbnail"}
    string? employeeThumbnail;
    # Employee location
    @sql:Column {name: "employee_location"}
    string? location;
    # Employee start date
    @sql:Column {name: "employee_start_date"}
    string? startDate;
    # Lead of the employee
    @sql:Column {name: "employee_lead"}
    string? leadEmail;
    # Final day of employment of the employee
    @sql:Column {name: "employee_final_day_of_employment"}
    string? finalDayOfEmployment;
    # Status of the employee
    @sql:Column {name: "employee_status"}
    EmployeeStatus? employeeStatus;
    # Designation of the employee
    @sql:Column {name: "designation"}
    string? designation;
    # Employment type of the employee
    @sql:Column {name: "employment_type_name"}
    string? employmentType;
    # Employee is a lead or not
    int? lead;
    # Team of the employee
    @sql:Column {name: "team_name"}
    string? team;
    # Bussiness unit of the employee
    @sql:Column {name: "business_unit_name"}
    string? businessUnit;
    # Unit of the employee
    @sql:Column {name: "unit_name"}
    string? unit;
    # Job band of the employee
    @sql:Column {name: "designation_job_band"}
    int? jobBand;
|};

# [Entity] Designation.
public type Designation record {|
    # Id of the designation
    int id;
    # Title of the designation
    string designation;
    # Job band of the designation
    int jobBand;
|};

# [Database] Employee type.
public type Employee record {|
    # Id of the employee
    @sql:Column {name: "employee_id"}
    string employeeId;
    # First name of the employee
    @sql:Column {name: "employee_first_name"}
    string? firstName;
    # Last name of the employee
    @sql:Column {name: "employee_last_name"}
    string? lastName;
    # Work email of the employee
    @sql:Column {name: "employee_work_email"}
    string? workEmail;
    # Start date of the employee
    @sql:Column {name: "employee_start_date"}
    string? startDate;
    # Thumbnail image of the employee
    @sql:Column {name: "employee_thumbnail"}
    string? employeeThumbnail;
    # Location of the employee
    @sql:Column {name: "employee_location"}
    string? location;
    # Designation of the employee
    @sql:Column {name: "designation"}
    string? designation;
    # Business unit name of the employee
    @sql:Column {name: "business_unit_name"}
    string? businessUnit;
    # Team name of the employee
    @sql:Column {name: "team_name"}
    string? team;
    # Unit name of the employee
    @sql:Column {name: "unit_name"}
    string? unit;
    # Lead of the employee
    @sql:Column {name: "employee_lead"}
    string? leadEmail;
    # Employee is a lead or not
    boolean? lead;
    # Job band of the employee
    @sql:Column {name: "designation_job_band"}
    int? jobBand;
    # EPF of the employee
    @sql:Column {name: "employee_epf"}
    string? employeeEpf?;
    # Title of the employee
    @sql:Column {name: "employee_title"}
    string? employeeTitle?;
    # Personal email of the employee
    @sql:Column {name: "employee_personal_email"}
    string? personalEmail?;
    # Gender of the employee
    @sql:Column {name: "employee_gender"}
    string? gender?;
    # Personal phone number of the employee
    @sql:Column {name: "employee_personal_phone_number"}
    string? personalPhoneNumber?;
    # Work phone number of the employee
    @sql:Column {name: "employee_work_phone_number"}
    string? workPhoneNumber?;
    # Last promoted date of the employee
    @sql:Column {name: "employee_last_promoted_date"}
    string? lastPromotedDate?;
    # Company name of the employee
    @sql:Column {name: "company_name"}
    string? company?;
    # Career function of the employee
    @sql:Column {name: "career_function"}
    string? careerFunction?;
    # Sub unit name of the employee
    @sql:Column {name: "sub_unit_name"}
    string? subUnit?;
    # Additional lead of the employee
    @sql:Column {name: "employee_additional_lead"}
    string? additionalLead?;
    # Employment type of the employee
    @sql:Column {name: "employment_type_name"}
    string? employmentType?;
    # Resignation date of the employee
    @sql:Column {name: "employee_resignation_date"}
    string? resignationDate?;
    # Resignation reason of the employee
    @sql:Column {name: "employee_resignation_reason"}
    string? resignationReason?;
    # Final day in office of the employee
    @sql:Column {name: "employee_final_day_in_office"}
    string? finalDayInOffice?;
    # Final day of employment of the employee
    @sql:Column {name: "employee_final_day_of_employment"}
    string? finalDayOfEmployment;
    # Status of the employee
    @sql:Column {name: "employee_status"}
    string? employeeStatus;
    # Relocation status of the employee
    @sql:Column {name: "employee_relocation_status"}
    string? relocationStatus?;
    # Subordinate count of the employee
    @sql:Column {name: "employee_subordinate_count"}
    int? subordinateCount?;
    # Created by
    @sql:Column {name: "employee_created_by"}
    string? createdBy?;
    # Created on
    @sql:Column {name: "employee_created_on"}
    string? createdOn?;
    # Updated by
    @sql:Column {name: "employee_updated_by"}
    string? updatedBy?;
    # Updated on
    @sql:Column {name: "employee_updated_on"}
    string? updatedOn?;
|};

# Employee filter record.
public type EmployeeFilter record {|
    # Employee location
    string? location = ();
    # Employee business unit
    string? businessUnit = ();
    # Employee designation
    string? designation = ();
    # Employee employment type
    string[]? employmentType = ();
    # Employee lead email
    string? leadEmail = ();
    # Employee statuses
    string[]? status = ();
    # Employee team
    string? team = ();
    # Employee unit
    string? unit = ();
    # Employee is a lead or not
    boolean? lead = ();
|};

# [Configurable] database configs.
type DatabaseConfig record {|
    # Database User 
    string user;
    # Database Password
    string password;
    # Database Name
    string database;
    # Database Host
    string host;
    # Database port
    int port;
    # Database connection pool
    ConnectionPool connectionPool;
|};

# Database config record.
type HRISDatabaseConfig record {|
    *DatabaseConfig;
    # Additional configurations related to the MySQL database connection
    mysql:Options? options;
|};

# [Query Filter] Organization structure filter record.
public type orgStructureFilter record {|
    # Id of the business unit
    int[]? businessUnitIds = ();
    # Name of the business unit
    string[]? businessUnits = ();
    # Employee statuses
    string[]? employeeStatuses = ();
|};

# OrgStructure record.
public type OrgStructure record {|
    # Organization structure with business units, team, units, and subunits
    BusinessUnit[] businessUnits;
|};

# Sub unit record.
public type SubUnit record {|
    # Id of the subunit
    int id;
    # Name of the subunit
    string name;
|};

# Team record.
public type Team record {|
    # Id of the team
    int id;
    # Name of the team
    string name;
    # List of units
    Unit[]? units;
|};

# Unit record.
public type Unit record {|
    # Id of the unit
    int id;
    # Name of the unit
    string name;
    # List of subunits
    SubUnit[]? subUnits;
|};

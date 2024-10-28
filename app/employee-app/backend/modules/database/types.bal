//
// Copyright (c) 2005-2010, WSO2 Inc. (http://www.wso2.org) All Rights Reserved.
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

# Add employee payload.
public type AddRecruitPayload record {|
    # First name of the employee
    string firstName;
    # Last name of the employee
    string lastName;
    # Gender of the employee
    string gender;
    # Personal email of the employee
    string personalEmail;
    # WSO2 email of the employee, if ex-employee
    string? wso2Email = ();
    # Contact number of the employee
    string contactNumber;
    # Employment type of the employee
    string employmentType;
    # Career function of the employee
    int careerFunction;
    # Business unit of the employee
    int businessUnit;
    # Department of the employee
    int department;
    # Team of the employee
    int team;
    # Sub team of the employee
    int? subTeam = ();
    # Job band of the employee
    int jobBand;
    # Join date of the employee
    string dateOfJoin;
    # End date of the probation period (Required if employment type is 'Permanent')
    string? probationEndDate = ();
    # End date of the agreement (Required if employment type is 'Internship' or 'Consultancy')
    string? agreementEndDate = ();
    # Company of joining
    int company;
    # Office of joining
    int office;
    # Work location of the employee
    string workLocation;
    # Reporting manager of the employee
    string reportsTo;
    # Manager of the employee
    string managerEmail;
|};

# [Entity] Business Unit.
public type BusinessUnit record {|
    # Id of the business unit
    int id;
    # Title of the business unit
    string businessUnit;
    # List of departments
    Department[]? departments;
|};

# [Entity] Career Function.
public type CareerFunction record {|
    # Id of the career function
    int id;
    # Title of the career function
    string careerFunction;
    # List of designations
    Designation[] designations;
|};

# [Query Filter] Career function entity filters.
public type CareerFunctionFilter record {|
    # List of career function ids 
    int[]? careerFunctionIds = ();
    # List of career function titles
    string[]? careerFunctions = ();
|};

# [Entity] Company.
public type Company record {|
    # Id of the company
    int id;
    # Name of the company
    string company;
    # Location of the company
    string location;
    # List of offices
    Office[] offices;
|};

# Compensation record.
public type Compensation record {|
    # Compensation type
    string key;
    # Compensation value
    string value;
    # Type of the value
    CompensationType 'type;
|};

# [Database]Compensation Email type.
type CompensationEmail record {
    # Email template Id
    string emailTemplate;
    # Compensation key value pairs
    string keyValuePairs;
};

# [Query Filter] Company entity filters.
public type CompanyFilter record {|
    # Ids of the companies
    int[]? ids = ();
    # Names of the companies
    string[]? companies = ();
    # Locations of the companies
    string[]? locations = ();
|};

# [Database] Business Unit.
public type DBBusinessUnit record {|
    # Id of the business unit
    @sql:Column {name: "business_unit_id"}
    int id;
    # Title of the business unit
    @sql:Column {name: "business_unit_name"}
    string businessUnit;
    # List of departments
    string departments;
|};

# [Entity] Career Function with string designations.
public type DBCareerFunction record {|
    # Id of the career function
    int id;
    # Title of the career function
    string careerFunction;
    # List of designations
    string? designations;
|};

# [Database] Company.
public type DBCompany record {|
    # Id of the company
    @sql:Column {name: "company_id"}
    int id;
    # Name of the company
    @sql:Column {name: "company_name"}
    string company;
    # Location of the company
    @sql:Column {name: "company_location"}
    string location;
    # List of offices
    string offices;
|};

# [Database]Employee basic information record to get lead type as int.
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

# [Entity] Department.
public type Department record {|
    # Id of the department
    int id;
    # Title of the department
    string department;
    # List of teams
    Team[]? teams;
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

# Document record.
public type Document record {
    # Name of the document
    string contentName;
    # Document type 
    string contentType;
    # Document content byte array
    byte[] attachment;
};

# [Database] Employee type.
public type Employee record {
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
};

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

# [Entity] Office.
public type Office record {|
    # Id of the office
    int id;
    # Name of the office
    string office;
    # Location of the office
    string location;
|};

# [Configurable] HRIS database configs.
type HRISDatabaseConfig record {|
    # Database User 
    string dbUser;
    # Database Password
    string dbPassword;
    # Database Name
    string dbName;
    # Database Host
    string dbHost;
    # Maximum number of open connections
    int maxOpenConnections;
    # Maximum lifetime of a connection
    decimal maxConnectionLifeTime;
    # Minimum number of open connections
    int minIdleConnections;
|};

# Main update employee payload.
public type MainUpdateRecruitPayload record {|
    # First name of the employee
    string? firstName = ();
    # Last name of the employee
    string? lastName = ();
    # Gender of the employee
    string? gender = ();
    # Personal email of the employee
    string? personalEmail = ();
    # WSO2 email of the employee, if ex-employee
    string? wso2Email = ();
    # Contact number of the employee
    string? contactNumber = ();
    # Employment type of the employee
    string? employmentType = ();
    # Career function of the employee
    int? careerFunction = ();
    # Business unit of the employee
    int? businessUnit = ();
    # Department of the employee
    int? department = ();
    # Team of the employee
    int? team = ();
    # Sub team of the employee
    int? subTeam = ();
    # Job band of the employee
    int? jobBand = ();
    # Join date of the employee
    string? dateOfJoin = ();
    # End date of the probation period (Required if employment type is 'Permanent')
    string? probationEndDate = ();
    # End date of the agreement (Required if employment type is 'Internship' or 'Consultancy')
    string? agreementEndDate = ();
    # Company of joining
    int? company = ();
    # Office of joining
    int? office = ();
    # Work location of the employee
    string? workLocation = ();
    # Reporting manager of the employee
    string? reportsTo = ();
    # Manager of the employee
    string? managerEmail = ();
    # Compensation details of the employee
    Compensation[]? compensation = ();
    # Offer documents of the employee
    Document[]? offerDocuments = ();
    # Additional comments
    string? additionalComments = ();
|};

# [Query Filter] Organization data filters.
public type OrgDetailsFilter record {|
    # Id of the business unit
    int[]? businessUnitIds = ();
    # Name of the business unit
    string[]? businessUnits = ();
|};

# [Database]Recruit type.
public type Recruit record {
    # Id of the recruit
    @sql:Column {name: "recruit_Id"}
    int recruitId;
    # First name of the employee
    @sql:Column {name: "recruit_first_name"}
    string firstName;
    # Last name of the employee
    @sql:Column {name: "recruit_last_name"}
    string lastName;
    # employee's gender
    @sql:Column {name: "recruit_gender"}
    string gender;
    # Personal email of the employee
    @sql:Column {name: "recruit_personal_email"}
    string personalEmail;
    # WSO2 email of the employee if ex employee
    @sql:Column {name: "recruit_wso2_email"}
    string? wso2Email;
    # Contact number of the employee
    @sql:Column {name: "recruit_contact_number"}
    string contactNumber;
    # Employment type of the employee
    @sql:Column {name: "recruit_employment_type"}
    string employmentType;
    # Career function id of the employee
    @sql:Column {name: "recruit_career_function"}
    int careerFunctionId;
    # Career function of the employee
    @sql:Column {name: "career_function"}
    string careerFunction;
    # Job band of joining
    @sql:Column {name: "recruit_job_band"}
    int jobBand;
    # Designation of joining
    @sql:Column {name: "designation"}
    string designation;
    # Company id of joining
    @sql:Column {name: "recruit_company"}
    int companyId;
    # Company of joining
    @sql:Column {name: "company_name"}
    string company;
    # Location of the company
    @sql:Column {name: "company_location"}
    string companyLocation;
    # Office id of joining
    @sql:Column {name: "recruit_office"}
    int officeId;
    # Office of joining
    @sql:Column {name: "office_name"}
    string office;
    # Office location of joining
    @sql:Column {name: "office_location"}
    string officeLocation;
    # Work location of the employee
    @sql:Column {name: "recruit_work_location"}
    string workLocation;
    # Business unit id of joining
    @sql:Column {name: "recruit_business_unit"}
    int businessUnitId;
    # Business unit of joining
    @sql:Column {name: "business_unit_name"}
    string businessUnit;
    # Department id of joining
    @sql:Column {name: "recruit_department"}
    int departmentId;
    # Department of joining
    @sql:Column {name: "department_name"}
    string department;
    # Team id of joining
    @sql:Column {name: "recruit_team"}
    int teamId;
    # Team of joining
    @sql:Column {name: "team_name"}
    string team;
    # Sub team id of joining if exists
    @sql:Column {name: "recruit_sub_team"}
    int? subTeamId;
    # Sub team of joining if exists
    @sql:Column {name: "sub_team_name"}
    string? subTeam;
    # Manager email of the employee
    @sql:Column {name: "recruit_manager_email"}
    string managerEmail;
    # Reports to email of the employee
    @sql:Column {name: "recruit_reports_to"}
    string reportsTo;
    # Date of joining
    @sql:Column {name: "recruit_date_of_join"}
    string dateOfJoin;
    # End date of the probation period
    @sql:Column {name: "recruit_probation_end_date"}
    string? probationEndDate;
    # End date of the agreement
    @sql:Column {name: "recruit_agreement_end_date"}
    string? agreementEndDate;
    # Compensation details of the employee
    @sql:Column {name: "recruit_compensation"}
    string? compensation;
    # Offer related documents
    @sql:Column {name: "recruit_offer_documents"}
    string? offerDocuments;
    # Additional comments
    @sql:Column {name: "recruit_additional_comments"}
    string? additionalComments;
    # Status of the employee
    @sql:Column {name: "recruit_status"}
    string status;
    # Created by
    @sql:Column {name: "recruit_created_by"}
    string createdBy;
    # Created on
    @sql:Column {name: "recruit_created_on"}
    string createdOn;
    # Updated by
    @sql:Column {name: "recruit_updated_by"}
    string updatedBy;
    # Updated on
    @sql:Column {name: "recruit_updated_on"}
    string updatedOn;
};

# [Entity] Sub Team.
public type SubTeam record {|
    # Id of the sub team
    int id;
    # Title of the sub team
    string subTeam;
|};

# [Entity] Team.
public type Team record {|
    # Id of the team
    int id;
    # Title of the team
    string team;
    # List of sub teams
    SubTeam[]? subTeams;
|};

# Update recruit payload.
public type UpdateRecruitPayload record {|
    *MainUpdateRecruitPayload;
    # RecruitId ID
    int recruitId;
    # Status to be updated
    RecruitStatus status?;
|};

# Filter types to be added to filter query array.
type FilterValue boolean|int|string|RecruitStatus|int[]|string[]|Compensation[]|Document[]|HiringStatus[];

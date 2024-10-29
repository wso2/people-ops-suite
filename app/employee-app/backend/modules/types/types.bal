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

# Action payload type.
public type ActionReason record {
    # Reason for the offer rejection
    string rejectionReason;
};

# Business unit.
public type BusinessUnit record {
    # Id of the business unit
    int id;
    # Name of the business unit
    string businessUnit;
    # Departments of the business unit
    Department[]? departments;
};

# Career function.
public type CareerFunction record {
    # Id of the career function
    int id;
    # Title of the career function
    string careerFunction;
    # Designations of the career function
    Designation[]? designations;
};

# Company.
public type Company record {
    # Id of the company
    int id;
    # Name of the company
    string company;
    # Location of the company
    string location;
    # List of offices
    Office[] offices;
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

# Compensation record.
public type Compensation record {|
    # Compensation type
    string key;
    # Compensation value
    string value;
    # Type of the value
    CompensationType 'type;
|};

# Compensation Email type.
public type CompensationEmail record {
    # Email template Id
    string emailTemplate;
    # Compensation key value pairs
    Compensation[] compensation;
};

# Department.
public type Department record {|
    # Id of the department
    int id;
    # Name of the department
    string department;
    # Teams of the department
    Team[]? teams;
|};

# Designation.
public type Designation record {
    # Id of the designation
    int id;
    # Title of the designation
    string designation;
    # Job band of the designation
    int jobBand;
};

#  Document record.
public type Document record {
    # Name of the document
    string contentName;
    # Document type 
    string contentType;
    # Document content byte array
    byte[] attachment;
};

# Employee type.
public type Employee record {
    # Id of the employee
    string employeeId;
    # First name of the employee
    string? firstName;
    # Last name of the employee
    string? lastName;
    # Work email of the employee
    string? workEmail;
    # Start date of the employee
    string? startDate;
    # Thumbnail image of the employee
    string? employeeThumbnail;
    # Location of the employee
    string? location;
    # Designation of the employee
    string? designation;
    # Business unit name of the employee
    string? businessUnit;
    # Team name of the employee
    string? team;
    # Unit name of the employee
    string? unit;
    # Lead of the employee
    string? leadEmail;
    # Final day of employment of the employee
    string? finalDayOfEmployment;
    # Status of the employee
    string? employeeStatus;
    # Employee is a lead or not
    boolean? lead;
    # Job band of the employee
    int? jobBand;
    # EPF of the employee
    string? employeeEpf?;
    # Title of the employee
    string? employeeTitle?;
    # Personal email of the employee
    string? personalEmail?;
    # Gender of the employee
    string? gender?;
    # Personal phone number of the employee
    string? personalPhoneNumber?;
    # Work phone number of the employee
    string? workPhoneNumber?;
    # Last promoted date of the employee
    string? lastPromotedDate?;
    # Company name of the employee
    string? company?;
    # Career function of the employee
    string? careerFunction?;
    # Sub unit name of the employee
    string? subUnit?;
    # Additional lead of the employee
    string? additionalLead?;
    # Relocation status of the employee
    string? relocationStatus?;
    # Employment type of the employee
    string? employmentType?;
    # Resignation date of the employee
    string? resignationDate?;
    # Resignation reason of the employee
    string? resignationReason?;
    # Final day in office of the employee
    string? finalDayInOffice?;
    # Subordinate count of the employee
    int? subordinateCount?;
    # Created by
    string? createdBy?;
    # Created on
    string? createdOn?;
    # Updated by
    string? updatedBy?;
    # Updated on
    string? updatedOn?;
};

# Employee filter record.
public type EmployeeFilter record {|
    # Employee location
    string? location = ();
    # Employee business unit
    string? businessUnit = ();
    # Employee unit
    string? unit = ();
    # Employee team
    string? team = ();
    # Employee statuses
    string[]? status = ();
    # Employee lead email
    string? leadEmail = ();
    # Employee designation
    string? designation = ();
    # Employee employment type
    string[]? employmentType = ();
    # Employee is a lead or not
    boolean? lead = ();
|};

# Hiring details payload.
public type HiringDetailsPayload record {|
    # Documents for the hiring details email
    Document[] documents;
|};

# Office.
public type Office record {
    # Id of the office
    int id;
    # Name of the office
    string office;
    # Location of the office
    string location;
};

# Organization structure.
public type OrgStructure record {|
    # Business units of the organization
    BusinessUnit[] businessUnits;
    # Career paths of the organization
    CareerFunction[] careerPaths;
    # Companies of the organization
    Company[] companies;
    # Employment types
    string[] employmentTypes;
|};

# Recruit type.
public type Recruit record {
    # Id of the recruit
    int recruitId;
    # First name of the employee
    string firstName;
    # Last name of the employee
    string lastName;
    # employee's gender
    string gender;
    # Personal email of the employee
    string personalEmail;
    # WSO2 email of the employee if ex employee
    string? wso2Email;
    # Contact number of the employee
    string contactNumber;
    # Employment type of the employee
    string employmentType;
    # Career function id of the employee
    int careerFunctionId;
    # Career function of the employee
    string careerFunction;
    # Job band of joining
    int jobBand;
    # Designation of joining
    string designation;
    # Company id of joining
    int companyId;
    # Company of joining
    string company;
    # Location of the company
    string companyLocation;
    # Office id of joining
    int officeId;
    # Office of joining
    string office;
    # Office location of joining
    string officeLocation;
    # Work location of the employee
    string workLocation;
    # Business unit id of joining
    int businessUnitId;
    # Business unit of joining
    string businessUnit;
    # Department id of joining
    int departmentId;
    # Department of joining
    string department;
    # Team id of joining
    int teamId;
    # Team of joining
    string team;
    # Sub team id of joining if exists
    int? subTeamId;
    # Sub team of joining if exists
    string? subTeam;
    # Manager email of the employee
    string managerEmail;
    # Reports to email of the employee
    string reportsTo;
    # Date of joining
    string dateOfJoin;
    # End date of the probation period
    string? probationEndDate;
    # End date of the agreement
    string? agreementEndDate;
    # Compensation details of the employee
    Compensation[] compensation;
    # Offer related documents
    Document[]? offerDocuments;
    # Additional comments
    string? additionalComments;
    # Status of the employee
    string status;
    # Created by
    string createdBy;
    # Created on
    string createdOn;
    # Updated by
    string updatedBy;
    # Updated on
    string updatedOn;
};

# SubTeam.
public type SubTeam record {
    # Id of the sub team
    int id;
    # Name of the sub team
    string subTeam;
};

# Team.
public type Team record {
    # Id of the team
    int id;
    # Name of the team
    string team;
    # Sub teams of the team
    SubTeam[]? subTeams;
};

# Update employee payload.
public type UpdateRecruitPayload record {|
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

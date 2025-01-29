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

# [Configurable] Choreo OAuth2 application configuration.
type ChoreoApp record {|
    # OAuth2 token endpoint
    string tokenUrl;
    # OAuth2 client ID
    string clientId;
    # OAuth2 client secret
    string clientSecret;
|};

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

# Employee type.
public type Employee record {|
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
    # Lead of the employee
    string? leadEmail;
    # Final day of employment of the employee
    string? finalDayOfEmployment;
    # Employee is a lead or not
    boolean? lead;
|};

# Employee response type.
public type EmployeeResponse record {
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

# Organization structure filter record.
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

# Business unit record.
public type BusinessUnit record {|
    # Id of the business unit
    int id;
    # Title of the business unit
    string name;
    # List of teams
    Team[]? teams;
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

# Sub unit record.
public type SubUnit record {|
    # Id of the subunit
    int id;
    # Name of the subunit
    string name;
|};

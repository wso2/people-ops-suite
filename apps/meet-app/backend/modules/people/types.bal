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

# [Configurable] OAuth2 entity application configuration.
type Oauth2Config record {|
    # OAuth2 token endpoint
    string tokenUrl;
    # OAuth2 client ID
    string clientId;
    # OAuth2 client secret
    string clientSecret;
|};

# Retry config for the graphql client.
public type GraphQlRetryConfig record {|
    # Retry count
    int count = RETRY_COUNT;
    # Retry interval
    decimal interval = RETRY_INTERVAL;
    # Retry backOff factor
    float backOffFactor = RETRY_BACKOFF_FACTOR;
    # Retry max interval
    decimal maxWaitInterval = RETRY_MAX_INTERVAL;
|};

// Get employee graphQL service Responses.
# Employee.
public type Employee record {|
    # Id of the employee
    string employeeId;
    # Email of the employee
    string workEmail;
    # First name of the employee
    string firstName;
    # Last name of the employee
    string lastName;
    # Job role
    string jobRole;
    # Thumbnail of the employee
    string? employeeThumbnail;
    # Business unit  of the host
    string? businessUnit;
    # Team of the host
    string? team;
    # Sub team of the host 
    string? subTeam;
    # Unit  of the host
    string? unit;
|};

# Employee data.
type EmployeeData record {
    # Employee
    Employee employee;
};

# Employee response.
type EmployeeResponse record {
    # Employee data
    EmployeeData data;
};

# The EmployeeFilter record type represents the filter criteria for the employees.
public type EmployeeFilter record {|
    # The employee statuses
    string[]? employeeStatus?;
    # The employment types
    string[]? employmentType?;
    # The employee email
    string[]? emails?;
|};

# Basic employee information.
public type EmployeeBasic record {|
    # First name of the employee
    string firstName;
    # Last name of the employee
    string lastName;
    # Email of the employee
    string workEmail;
    # Thumbnail of the employee
    string? employeeThumbnail = ();
    # Department of the employee
    string? team = ();
    # Team of the employee
    string? subTeam = ();
|};

# Employees data.
type EmployeesData record {
    # Array of employees
    EmployeeBasic[] employees;
};

# Employees response.
type EmployeesResponse record {
    # Employees data
    EmployeesData data;
};

# Org details response.
type OrgDetailsResponse record {
    # Org details data
    BusinessUnits data;
};

# Business Units.
type BusinessUnits record {
    # Business unit
    BusinessUnit[] orgDetails;
};

# Business Unit.
public type BusinessUnit record {
    # Id of the business unit
    int id;
    # Title of the business unit
    string businessUnit;
    # List of departments
    Department[]? departments;
};

# Department.
public type Department record {
    # Id of the department
    int id;
    # Title of the department
    string department;
    # List of teams
    Team[]? teams;
};

# Team.
public type Team record {
    # Id of the team
    int id;
    # Title of the team
    string team;
    # List of sub teams
    SubTeam[]? subTeams;
};

# Sub Team.
public type SubTeam record {
    # Id of the sub team
    int id;
    # Title of the sub team
    string subTeam;
};

# Organization data filters.
public type OrgDetailsFilter record {|
    # Id of the business unit
    int[]? businessUnitIds = ();
    # Name of the business unit
    string[]? businessUnits = ();
|};

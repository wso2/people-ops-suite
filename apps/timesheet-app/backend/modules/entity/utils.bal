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
configurable string[] employeeTypes = [];
configurable string[] allowedEmployeeStatusTypes = [];

# This function get and validate the authorized employee types from the configuration.
#
# + return - Array of authorized employee types or default employee types [PERMANENT, CONSULTANCY]
public isolated function getAuthorizedEmployeeTypes() returns string[] {
    string[] defaultEmployeeTypes = [
        ADVISORY\ CONSULTANT,
        CONSULTANCY,
        INTERNSHIP,
        PART\ TIME\ CONSULTANCY,
        PERMANENT,
        PROBATION
    ];
    string[] authorizedTypes = [];
    if employeeTypes.length() > 0 {
        foreach string employeeType in employeeTypes {
            if defaultEmployeeTypes.some(definedType => definedType == employeeType) {
                authorizedTypes.push(employeeType);
            }
        }
        if authorizedTypes.length() > 0 {
            return authorizedTypes;
        }
    }
    return [PERMANENT, CONSULTANCY, PROBATION];
}

# This function get and validate the authorized employee status types from the configuration.
#
# + return - Array of authorized employee status types or default employee types [Active, Marked Leaver]
public isolated function getAuthorizedEmployeeStatusTypes() returns string[] {
    string[] defaultEmployeeStatusTypes = [
        EmployeeStatusMarkedLeaver,
        EmployeeStatusActive,
        EmployeeStatusLeft
    ];
    string[] authorizedStatusTypes = [];
    if allowedEmployeeStatusTypes.length() > 0 {
        foreach string employeeStatusType in allowedEmployeeStatusTypes {
            if defaultEmployeeStatusTypes.some(definedType => definedType == employeeStatusType) {
                authorizedStatusTypes.push(employeeStatusType);
            }
        }
        if authorizedStatusTypes.length() > 0 {
            return authorizedStatusTypes;
        }
    }
    return [EmployeeStatusActive, EmployeeStatusMarkedLeaver];
}

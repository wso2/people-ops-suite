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

# User info custom type for Asgardeo token.
public type CustomJwtPayload record {|
    # User email
    string email;
    # User groups
    string[] groups;
|};

# Application specific role mapping.
public type AppRoles record {|
    # Role for the employee
    string employeeRole;
    # Role for the people operations admins
    string adminRole;
    # Role for the lead of a team
    string leadRole;
|};

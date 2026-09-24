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
public type CustomJwtPayload record {
    # User email 
    string email;
    # User groups
    string[] groups;
};

# Application specific role mapping.
public type AppRoles record {|
    # Role for the employee
    string SALES_TEAM;
    # Role for the head of people operations
    string SALES_ADMIN;
|};

# Choreo backend-JWT (x-jwt-assertion) signature validation configuration. This is Choreo's
# own gateway-signed JWT, not an Asgardeo-issued token.
public type AuthConfig record {|
    # Expected `iss` claim "
    string JWTIssuer;
    # Accepted `aud` claim(s): one client ID, or several separated by commas when more than one
    # client calls this backend (e.g. "<meet-app-webapp-id>, <one-wso2-id>"). A token passes if
    # its `aud` matches ANY of them. A plain string rather than string[] on purpose: Choreo's
    # configuration form cannot store an array for this field, so one text value is the only
    # form that survives it.
    string? JWTAudience = ();
    # Choreo's own gateway JWKS endpoint for this org
    
    string JWKSEndPoint;
|};

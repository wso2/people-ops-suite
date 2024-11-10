// Copyright (c) 2024 WSO2 LLC. (http://www.wso2.org).
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
import ballerina/http;
import ballerina/jwt;
import ballerina/log;

// Allowed user roles of the API
configurable string[] userRoles = ?;
// Allowed admin roles of the API
public configurable string[] adminRoles = ?;

# To handle authorization for each resource function invocation.
public isolated service class JwtInterceptor {

    *http:RequestInterceptor;

    isolated resource function default [string... path](http:RequestContext ctx, http:Request req)
        returns http:NextService|http:Unauthorized|http:BadRequest|http:Forbidden|http:InternalServerError|error? {

        final string method = req.method;
        if method == http:OPTIONS {
            return ctx.next();
        }
        string|error idToken = req.getHeader(JWT_ASSERTION_HEADER);
        if idToken is error {
            return <http:BadRequest>{
                body: {
                    message: "x-jwt-assertion header does not exist!"
                }
            };
        }

        CustomJwtPayload|error decodeUserInfo = decodeJwt(idToken);
        if decodeUserInfo is error {
            string errorMsg = "Error in decoding JWT!";
            log:printError(errorMsg, decodeUserInfo);
            return <http:InternalServerError>{
                body: {
                    message: errorMsg
                }
            };
        }
        readonly & CustomJwtPayload readonlyDecodeUserInfo = decodeUserInfo.cloneReadOnly();

        // Commented this out as roles are not being sent in the token exchange flow
        // Checks if the user is authorized to access the API
        // boolean|error userIsAuthorized = security:validateForSingleRole(jwt, userRoles);
        // if userIsAuthorized != true {
        //     security:logUnauthorizedUserAccess(jwt.email, req.rawPath, false);
        //     return <types:Forbidden>{
        //         body: {message: types:NO_PRIVILEGES_ERROR}
        //     };
        // }

        final boolean isAdminOnlyPath = checkIfAdminOnlyPath(path, method);
        if isAdminOnlyPath {
            boolean|error userIsAdmin = validateForSingleRole(readonlyDecodeUserInfo, adminRoles);
            if userIsAdmin != true {
                string errorMsg = string `The user ${decodeUserInfo.email} was not privileged to access the${true ? " admin " : " "}resource ${req.rawPath}`;
                log:printWarn(errorMsg);
                return <http:Forbidden>{
                    body: {message: errorMsg}
                };
            }
        }
        ctx.set(HEADER_USER_INFO, readonlyDecodeUserInfo);
        return ctx.next();
    }
}

# Check if path is only valid for admin users
#
# + path - Resource path
# + method - Request HTTP method
# + return - Boolean if path is only valid for admin users
public isolated function checkIfAdminOnlyPath(string[] path, string method) returns boolean {
    if path.length() > 0 {
        final string resourcePath = path[0];
        if adminPathToAllowedMethods.hasKey(resourcePath) {
            string[] allowedMethods = adminPathToAllowedMethods.get(resourcePath);
            return allowedMethods.indexOf(method) !is ();
        }
    }

    return false;
}

# Decode the JWT.
#
# + key - Asgardeo ID token
# + return - User email OR Error OR HTTP Response
public isolated function decodeJwt(string key) returns CustomJwtPayload|error {

    [jwt:Header, jwt:Payload]|jwt:Error result = jwt:decode(key);
    if result is jwt:Error {
        return result;
    }
    CustomJwtPayload|error userInfo = result[1].cloneWithType();
    return userInfo;
}

# Check if the logged in user has at least one required role in the groups claim.
#
# + jwt - JWT token, type: AsgardeoJwt
# + expectedRoles - expected roles to be in the jwt
# + return - true if jwt contains at least one role, false otherwise
public isolated function validateForSingleRole(readonly & CustomJwtPayload jwt, string[] expectedRoles) returns boolean
    => expectedRoles.length() == 0 || expectedRoles.some(
        isolated function(string expectedRole) returns boolean =>
            jwt.groups.indexOf(expectedRole) !is ()
    );

// Copyright (c) 2025, WSO2 LLC. (https://www.wso2.com). All Rights Reserved.
//
// This software is the property of WSO2 LLC. and its suppliers, if any.
// Dissemination of any information or reproduction of any material contained
// herein in any form is strictly forbidden, unless permitted by WSO2 expressly.
// You may not alter or remove any copyright or other notice from copies of this content.
import ballerina/http;
import ballerina/jwt;
import ballerina/log;

public configurable AppRoles authorizedRoles = ?;

# To handle authorization for each resource function invocation.
public isolated service class JwtInterceptor {

    *http:RequestInterceptor;

    isolated resource function default [string... path](http:RequestContext ctx, http:Request req)
        returns http:NextService|http:Forbidden|http:InternalServerError|error? {

        string|error idToken = req.getHeader(JWT_ASSERTION_HEADER);
        if idToken is error {
            string errorMsg = "Missing authentication details in the request!";
            log:printError(errorMsg, idToken);
            return <http:InternalServerError>{
                body: {
                    message: errorMsg
                }
            };
        }

        CustomJwtPayload|error decodedUserInfo = decodeJwt(idToken);
        if decodedUserInfo is error {
            string errorMsg = "Error while extracting user information!";
            log:printError(errorMsg, decodedUserInfo);
            return <http:InternalServerError>{
                body: {
                    message: errorMsg
                }
            };
        }

        boolean isAuthorized = checkPrivileges(decodedUserInfo);
        if !isAuthorized {
            string errorMsg = "Insufficient privileges!";
            log:printError(errorMsg);
            return <http:Forbidden>{
                body: {
                    message: errorMsg
                }
            };
        }

        ctx.set(HEADER_USER_INFO, decodedUserInfo);
        return ctx.next();
    }
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

# Checks if the user belongs to any of the authorized groups.
#
# + userInfo - `CustomJwtPayload` object containing the user's email and groups
# + return - Returns true if the user is authorized Otherwise, false
public isolated function checkPrivileges(CustomJwtPayload userInfo) returns boolean {

    foreach anydata role in authorizedRoles.toArray() {
        if userInfo.groups.some(r => r == role) {
            return true;
        }
    }
    return false;
}

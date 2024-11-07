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

public configurable AppRoles authorizedRoles = ?;

# To handle authorization for each resource function invocation.
public isolated service class JwtInterceptor {

    *http:RequestInterceptor;
    isolated resource function default [string... path](http:RequestContext ctx, http:Request req)
        returns http:NextService|http:Unauthorized|http:BadRequest|http:Forbidden|http:InternalServerError|error? {
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

        CustomJwtPayload|error userInfo = checkGroups(decodeUserInfo);
        if userInfo is error {
            string errorMsg = "Insufficient privileges!";
            log:printError(errorMsg, userInfo);
            return <http:Forbidden>{
                body: {
                    message: errorMsg
                }
            };
        }

        ctx.set(HEADER_USER_INFO, userInfo);
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

public isolated function checkGroups(CustomJwtPayload userInfo) returns CustomJwtPayload|error {
    foreach anydata role in authorizedRoles.toArray() {
        if userInfo.groups.some(r => r == role) {
            return {
                email: userInfo.email,
                groups: userInfo.groups
            };
        }
    }
    return userInfo;
}

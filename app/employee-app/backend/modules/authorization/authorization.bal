//
// Copyright (c) 2005-2024, WSO2 LLC.
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
import ballerina/http;
import ballerina/jwt;
import ballerina/log;

public configurable AppRoles authorizedRoles = ?;

# To handle authorization for each resource function invocation.
public isolated service class JwtInterceptor {

    *http:RequestInterceptor;
    isolated resource function default [string... path](http:RequestContext ctx, http:Request req)
        returns http:NextService|http:Unauthorized|http:BadRequest|http:Forbidden|error? {
        string|error idToken = req.getHeader(JWT_ASSERTION_HEADER);
        if idToken is error {
            return <http:BadRequest>{
                body: {
                    message: "x-jwt-assertion header does not exist!"
                }
            };
        }

        CustomJwtPayload|http:Unauthorized|http:Forbidden userInfo = check decodeJwt(idToken);
        if userInfo is http:Unauthorized|http:Forbidden {
            return userInfo;
        }
        ctx.set(HEADER_USER_INFO, userInfo);
        return ctx.next();
    }
}

# Decode the JWT.
#
# + key - Asgardeo ID token
# + return - User email OR Error OR HTTP Response
public isolated function decodeJwt(string key) returns http:Forbidden|http:Unauthorized|CustomJwtPayload|error {

    [jwt:Header, jwt:Payload] [_, payload] = check jwt:decode(key);
    CustomJwtPayload|error userInfo = payload.cloneWithType(CustomJwtPayload);

    if userInfo is error {
        log:printError("JWT payload type mismatch or validation error during token decoding.", userInfo);
        return <http:Unauthorized>{body: {message: userInfo.message()}};
    }
    foreach anydata role in authorizedRoles.toArray() {
        if userInfo.groups.some(r => r === role) {
            return {
                email: userInfo.email,
                groups: userInfo.groups
            };
        }
    }
    log:printError("Authorization failed due to insufficient privileges.",
        email = userInfo.email,
        authorizedRoles = authorizedRoles,
        userRoles = userInfo.groups
    );
    return <http:Forbidden>{body: {message: "Insufficient privileges!"}};
}

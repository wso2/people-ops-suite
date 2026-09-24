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
import ballerina/http;
import ballerina/jwt;
import ballerina/log;

public configurable AppRoles authorizedRoles = ?;

# x-jwt-assertion is Choreo's own backend JWT -- signed by the Choreo gateway itself, not
# by Asgardeo and JWTIssuer is the fixed literal that Choreo stamps on every backend JWT. JWTAudience is
# left unset unless this component's "End User Token Audiences" has been explicitly configured in Choreo
configurable readonly & AuthConfig authConfig = ?;

function buildJwtValidatorConfig() returns jwt:ValidatorConfig {
    jwt:ValidatorConfig validatorConfig = {
        issuer: authConfig.JWTIssuer,
        clockSkew: 60d,
        signatureConfig: {
            jwksConfig: {url: authConfig.JWKSEndPoint}
        }
    };
    
    // One audience or several. With a list, jwt:validate passes a token whose `aud` matches
    // ANY entry -- which is what lets two different clients (the meet-app webapp and One
    // WSO2, each with its own client ID) call this one backend. Blank entries are dropped, and
    // nothing left means no audience check at all, exactly as an unset value did before.
    string|string[]? audience = authConfig.JWTAudience;
    string[] audiences = [];
    if audience is string {
        audiences = [audience];
    } else if audience is string[] {
        audiences = audience;
    }
    string[] accepted = from string entry in audiences
        where entry.trim() != ""
        select entry.trim();
    if accepted.length() == 1 {
        validatorConfig.audience = accepted[0];
    } else if accepted.length() > 1 {
        validatorConfig.audience = accepted;
    } else if audience is string[] {
        // Treated as unset, like a blank string -- but said out loud: a list that filters to
        // nothing is almost certainly a misconfiguration, and failing closed instead would
        // reject every request (jwt:validate refuses all tokens against an empty audience list).
        log:printWarn("JWTAudience is set to a list with no usable entries; the audience check is DISABLED.");
    }
    return validatorConfig;
}

final readonly & jwt:ValidatorConfig jwtValidatorConfig = buildJwtValidatorConfig().cloneReadOnly();

# To handle authorization for each resource function invocation.
public isolated service class JwtInterceptor {

    *http:RequestInterceptor;

    isolated resource function default [string... path](http:RequestContext ctx, http:Request req)
        returns http:NextService|http:Forbidden|http:Unauthorized|http:InternalServerError|error? {

        
        string|error idToken = req.getHeader(JWT_ASSERTION_HEADER);
        if idToken is error {
            string errorMsg = "Missing invoker info header!";
            log:printError(errorMsg, idToken);
            return <http:InternalServerError>{
                body: {
                    message: errorMsg
                }
            };
        }

        jwt:Payload|jwt:Error validationResult = jwt:validate(idToken, jwtValidatorConfig);
        if validationResult is jwt:Error {
            string errorMsg = "JWT validation failed!";
            log:printError(errorMsg, validationResult);
            return <http:Unauthorized>{body: {message: "Invalid token!"}};
        }

        CustomJwtPayload|error userInfo = validationResult.cloneWithType(CustomJwtPayload);
        if userInfo is error {
            string errorMsg = "Malformed Invoker info object!";
            log:printError(errorMsg, userInfo);
            return <http:InternalServerError>{body: {message: errorMsg}};
        }

        foreach anydata role in authorizedRoles.toArray() {
            if userInfo.groups.some(r => r === role) {
                ctx.set(HEADER_USER_INFO, userInfo);
                return ctx.next();
            }
        }

        log:printError(
                string `${userInfo.email} is missing required permissions, only has ${userInfo.groups.toBalString()}`);

        return <http:Forbidden>{body: {message: "Insufficient privileges!"}};
    }
}

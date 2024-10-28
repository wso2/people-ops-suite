//
// Copyright (c) 2005-2010, WSO2 Inc. (http://www.wso2.org) All Rights Reserved.
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
import ballerina/log;

configurable string appUUID = ?;

# Send an email alert via the email service.
#
# + payload - Payload for the email service
# + return - Response from the email service
public isolated function processEmailNotification(EmailRecord payload) returns error? {

    payload.appUuid = appUUID;
    http:Response|http:ClientError response = emailClient->/send\-smtp\-email.post(payload);
    if response is http:ClientError {
        string customError = string `Client Error occurred while sending the email !`;
        log:printError(string `${customError} : ${response.message()}`);
        return error(customError);
    }
    if response.statusCode != 200 {
        string customError = string `Error occurred while sending the email !`;
        log:printError(string `${customError} : ${(check response.getJsonPayload()).toJsonString()}!`);
        return error(customError);
    }
    log:printInfo("Email sent successfully to " + payload.to.toString());
}

// Copyright (c) 2024 WSO2 LLC. (https://www.wso2.com).
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
import ballerina/log;
import ballerinax/mysql;
import ballerinax/mysql.driver as _;

configurable DatabaseConfig databaseConfig = ?;

# Function to create Leave DB connection.
#
# + return - If success returns mysql DB client or error
public isolated function initializeLeaveClient() returns mysql:Client|error {
    LeaveDatabaseConfig leaveDBConfig = {
        ...databaseConfig,
        options: {
            ssl: {
                mode: mysql:SSL_REQUIRED
            },
            connectTimeout: 10
        }
    };

    mysql:Client|error mysqlClient = check new (...leaveDBConfig);

    if mysqlClient is error {
        log:printError(mysqlClient.toBalString());
        return error("Error in connecting to the leave database!");
    }
    return mysqlClient;
}

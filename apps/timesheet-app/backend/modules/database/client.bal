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
import ballerinax/java.jdbc;
import ballerinax/mysql;
import ballerinax/mysql.driver as _;

# Database Client Configuration.
configurable DatabaseConfig databaseConfig = ?;

DatabaseClientConfig databaseClientConfig = {
    ...databaseConfig,
    options: {
        ssl: {
            mode: mysql:SSL_REQUIRED
        },
        connectTimeout: 10
    }
};

function initSampleDbClient() returns mysql:Client|error
=> new (...databaseClientConfig);

# Database Client.
final jdbc:Client databaseClient = check initSampleDbClient();

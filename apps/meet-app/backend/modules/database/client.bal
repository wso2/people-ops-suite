// Copyright (c) 2025, WSO2 LLC. (https://www.wso2.com). All Rights Reserved.
//
// This software is the property of WSO2 LLC. and its suppliers, if any.
// Dissemination of any information or reproduction of any material contained
// herein in any form is strictly forbidden, unless permitted by WSO2 expressly.
// You may not alter or remove any copyright or other notice from copies of this content.
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

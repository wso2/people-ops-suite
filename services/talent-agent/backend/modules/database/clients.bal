// Copyright (c) 2023, WSO2 LLC. (http://www.wso2.com). All Rights Reserved.
// 
// This software is the property of WSO2 LLC. and its suppliers, if any.
// Dissemination of any information or reproduction of any material contained
// herein in any form is strictly forbidden, unless permitted by WSO2 expressly.
// You may not alter or remove any copyright or other notice from copies of this content.

import ballerinax/mysql;
import ballerinax/mysql.driver as _;

configurable DatabaseConfig dbConfig = ?;

final mysql:Client dbClient = check new (
    dbConfig.hostname,
    dbConfig.username,
    dbConfig.password,
    dbConfig.database,
    options = {
        socketTimeout: SOCKET_TIMEOUT,
        serverTimezone: SERVER_TIMEZONE,
        ssl: {
            mode: mysql:SSL_PREFERRED
        }
    },
    connectionPool = {
        maxOpenConnections: MAX_OPEN_CONNECTIONS,
        minIdleConnections: MIN_IDLE_CONNECTIONS,
        maxConnectionLifeTime: MAX_CONNECTION_LIFE_TIME
    }
);

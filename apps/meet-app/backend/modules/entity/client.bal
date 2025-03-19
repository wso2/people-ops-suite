// Copyright (c) 2024, WSO2 LLC. (https://www.wso2.com). All Rights Reserved.
//
// This software is the property of WSO2 LLC. and its suppliers, if any.
// Dissemination of any information or reproduction of any material contained
// herein in any form is strictly forbidden, unless permitted by WSO2 expressly.
// You may not alter or remove any copyright or other notice from copies of this content.
import ballerina/graphql;

configurable string hrEntityBaseUrl = ?;
configurable GraphQlRetryConfig retryConfig = ?;
configurable Oauth2Config oauthConfig = ?;

# Hr Entity -> GraphQL Service Credentials.
@display {
    label: "HR Entity GraphQL Service",
    id: "hris/entity-graphql-service"
}

final graphql:Client hrClient = check new (hrEntityBaseUrl, {
    auth: {
        ...oauthConfig
    },
    retryConfig: {
        ...retryConfig
    }
});

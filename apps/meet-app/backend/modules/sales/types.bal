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

# [Configurable] OAuth2 entity application configuration.
type Oauth2Config record {|
    # OAuth2 token endpoint
    string tokenUrl;
    # OAuth2 client ID
    string clientId;
    # OAuth2 client secret
    string clientSecret;
|};

# Retry config for the graphql client.
public type GraphQlRetryConfig record {|
    # Retry count
    int count = RETRY_COUNT;
    # Retry interval
    decimal interval = RETRY_INTERVAL;
    # Retry backOff factor
    float backOffFactor = RETRY_BACKOFF_FACTOR;
    # Retry max interval
    decimal maxWaitInterval = RETRY_MAX_INTERVAL;
|};

# The CustomerFilter record type represents the filter criteria for fetching customers.
public type CustomersFilter record {|
    # customerStatuses to filter customers
    string[] customerStatuses;
|};

# Basic Customer information.
public type CustomerBasic record {|
    # ID of the customer
    string id;
    # Name of the customer
    string name;
|};

# Customers data.
type CustomersData record {
    # Array of customers
    CustomerBasic[] customers;
};

# Customers response.
type CustomersResponse record {
    # Customers data
    CustomersData data;
};

# The ContactFilter record type represents the filter criteria for fetching contacts.
public type ContactFilter record {|
    # Account ID to filter contacts
    string accountId;
|};

# Basic Contact information.
public type ContactBasic record {|
    # Name of the contact
    string name;
    # Email of the contact
    string email;
|};

# Contacts data.
type ContactsData record {
    # Array of contacts
    ContactBasic[] contacts;
};

# Contacts response.
type ContactsResponse record {
    # Customers data
    ContactsData data;
};

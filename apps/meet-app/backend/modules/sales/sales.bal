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

# Retrieve all Active Customers.
#
# + return - Customers Array
public isolated function getCustomers() returns CustomerBasic[]|error {

    // Fetch only active customers to avoid exceeding the SOQL offset limit (max 2000).
    CustomersFilter filter = {
        customerStatuses: ["Customer"]
    };

    string document = string `query getCustomers($filter: CustomersFilter!, $isRealTime: Boolean!, 
        $includeSubscriptions: Boolean!, $includePartners: Boolean!, $includeOpportunities: Boolean!, 
        $limit: Int, $offset: Int) {
        customers(filter: $filter, isRealTime: $isRealTime, includeSubscriptions: $includeSubscriptions,
            includePartners: $includePartners, includeOpportunities: $includeOpportunities,
            limit: $limit, offset: $offset) {
            id name
        }
    }`;

    CustomerBasic[] customers = [];
    boolean fetchMore = true;
    while fetchMore {
        CustomersResponse response = check salesClient->execute(
            document,
            {
            filter: filter,
            isRealTime: true,
            includeSubscriptions: false,
            includePartners: false,
            includeOpportunities: false,
            'limit: DEFAULT_LIMIT,
            offset: customers.length()
        }
        );
        customers.push(...response.data.customers);
        fetchMore = response.data.customers.length() > 0;
    }
    return customers;
}

# Retrieves all contacts for a given customer ID.
#
# + customerId - Customer Id
# + return - Contact | Error
public isolated function getContacts(string customerId) returns ContactBasic[]|error {
    ContactFilter filter = {
        accountId: customerId
    };

    string document = string `query getContacts($filter: ContactFilter!, $limit: Int, $offset: Int) {
        contacts(filter: $filter, limit: $limit, offset: $offset) {
            name email
        }
    }`;

    ContactBasic[] contacts = [];
    boolean fetchMore = true;
    while fetchMore {
        ContactsResponse response = check salesClient->execute(
            document,
            {
            filter: filter,
            'limit: DEFAULT_LIMIT,
            offset: contacts.length()
        }
        );
        contacts.push(...response.data.contacts);
        fetchMore = response.data.contacts.length() > 0;
    }
    return contacts;
}

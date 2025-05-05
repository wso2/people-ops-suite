// Copyright (c) 2025, WSO2 LLC. (https://www.wso2.com). All Rights Reserved.
//
// This software is the property of WSO2 LLC. and its suppliers, if any.
// Dissemination of any information or reproduction of any material contained
// herein in any form is strictly forbidden, unless permitted by WSO2 expressly.
// You may not alter or remove any copyright or other notice from copies of this content.

# User authorization data.
type OAuth2App readonly & record {|
    # OAuth2 token endpoint URL
    string tokenUrl;
    # OAuth2 client ID
    string clientId;
    # OAuth2 client secret
    string clientSecret;
|};

# User response.
public type UserResponse record {|
    # User ID
    string id;
    # Username
    string userName;
    # Names
    record {|
        # Given name
        string givenName;
        # Family name
        string familyName;
        json...;
    |} name;
    json...;
|};

# Resource record.
type ResourceResponse record {|
    *UserResponse;
    string...;
|};

# User info record.
public type User record {|
    # User ID
    string id;
    # Username
    string userName;
    # Name
    Name name;
    json...;
|};

# Email information record.
public type Email record {|
    # Email address of the user
    string value;
    # Indicates whether this email is the primary email
    boolean primary;
|};

# Name details record.
public type Name record {|
    # Given (first) name of the user
    string givenName;
    # Family (last) name of the user
    string familyName;
    json...;
|};

# WSO2-specific schema record.
public type Wso2Schema record {|
    # Indicates whether the user is required to set a password
    boolean askPassword;
    # Indicates whether the user account is disabled
    boolean accountDisabled;
    # Custom attributes associated with the user
    json? customs;
    # Indicates whether the user's email should be verified
    boolean verifyEmail;
    # Organization the user belongs to
    string organization;
    # Country of the user
    string country;
    # Job title of the user
    string jobtitle;
    # State or region of the user
    string state;
    # Indicates whether the user account has been migrated
    boolean is_migrated;
|};

# Phone number information record.
public type PhoneNumber record {|
    # Type of phone number (e.g., mobile, home, work)
    string 'type;
    # Phone number value
    string value;
|};

# SCIM user information record.
public type ScimUser record {|
    # List of email addresses associated with the user
    Email[] emails;
    # Name details of the user
    Name name;
    # Unique username used for authentication
    string userName;
    # WSO2-specific schema containing additional attributes
    Wso2Schema urn\:scim\:wso2\:schema;
    # List of phone numbers associated with the user
    PhoneNumber[] phoneNumbers;
    # List of schemas associated with the user
    string[] schemas;
|};

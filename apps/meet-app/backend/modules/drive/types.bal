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
    # OAuth2 refresh URL
    string refreshUrl;
    # OAuth2 refresh token
    string refreshToken;
    # OAuth2 client ID
    string clientId;
    # OAuth2 client secret
    string clientSecret;
|};

# Retry config for the calendar client.
public type DriveRetryConfig record {|
    # Retry count
    int count = RETRY_COUNT;
    # Retry interval
    decimal interval = RETRY_INTERVAL;
    # Retry backOff factor
    float backOffFactor = RETRY_BACKOFF_FACTOR;
    # Retry max interval
    decimal maxWaitInterval = RETRY_MAX_INTERVAL;
|};

# Drive permission payload.
public type DrivePermissionPayload record {|
    # Role of the permission
    DrivePermissionRole role;
    # Type of the permission
    DrivePermissionType 'type;
    # Email address of the user
    string emailAddress?;
|};

# Drive permission response.
public type DrivePermissionResponse record {|
    # Role assigned
    DrivePermissionRole role;
    # Kind of the resource (always "drive#permission")
    string kind;
    # Type of the permission
    DrivePermissionType 'type;
    # Unique ID of the permission
    string id;
|};

# DrivePermissionRole enum.
public enum DrivePermissionRole {
    OWNER = "owner",
    EDITOR = "writer",
    COMMENTER = "commenter",
    VIEWER = "reader"
};

# DrivePermissionType enum.
public enum DrivePermissionType {
    USER = "user",
    GROUP = "group",
    DOMAIN = "domain",
    ANYONE = "anyone"
}

# Represents a single file object from Drive.
public type DriveFile record {|
    # Unique ID of the file
    string id;
    # Name of the file
    string name;
|};

# Drive search response.
public type DriveSearchResponse record {|
    # List of files found
    DriveFile[] files;
    # Token for the next page of results (if any)
    string nextPageToken?;
|};

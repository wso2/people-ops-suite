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
import ballerina/http;

# The header used to set/get user information in requests.
public const HEADER_USER_INFO = "user-info";

# The header used to transmit the JWT assertion token.
public const JWT_ASSERTION_HEADER = "x-jwt-assertion";

# The header used to get the JWT assertion token.
public const INVOKER_TOKEN = "invoker-token";

// Authorization related constants
public final map<string[]> & readonly adminPathToAllowedMethods = {
    "holidays": [http:POST, http:PUT, http:DELETE, http:PATCH],
    "generate-report": [http:GET, http:POST, http:PUT, http:DELETE, http:PATCH]
};


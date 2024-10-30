// Copyright (c) 2024, WSO2 LLC.
//
// WSO2 Inc. licenses this file to you under the Apache License,
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

# Default limit.
public const DEFAULT_LIMIT = 1000;

# Recruit related constants.
public const OFFER_TEMPLATE_POSTFIX = "All";
public const OFFER_TEMPLATE_PREFIX = "employeeOffer";
public const UTC_POSTFIX = "T00:00:00Z";
public const UNKNOWN = "Unknown";

# Organization structure cache key.
public const ORG_STRUCTURE_CACHE_KEY = "orgStructure";

# Common not found error message.
public const NOT_FOUND_CUSTOM_ERROR = "No active/marked leaver employee found for the email";

# RegeExp to check the wso2 email.
public final string:RegExp WSO2_EMAIL_PATTERN = re `^[a-zA-Z0-9._%+-]+@wso2\.com$`;

# Cache parameters related constants.
public const CAPACITY = 100;
public const EVICTION_FACTOR = 0.2;

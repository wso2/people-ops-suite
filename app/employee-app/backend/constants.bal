// Copyright (c) 2024 WSO2 LLC. (http://www.wso2.org).
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

# Default limit.
public const DEFAULT_LIMIT = 1000;
public const DEFAULT_OFFSET = 0;

# RegeExp to check the wso2 email.
public final string:RegExp WSO2_EMAIL_PATTERN = re `^[a-zA-Z0-9._%+-]+@wso2\.com$`;

# Cache parameters related constants.
public const CACHE_CAPACITY = 100;
public const CACHE_EVICTION_FACTOR = 0.2;

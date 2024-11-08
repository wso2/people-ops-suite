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
import ballerina/lang.regexp;

public const JWT_CONTEXT_KEY = "JWT_CONTEXT_KEY";
public const TOTAL_LEAVE_TYPE = "total";
public const TOTAL_EXCLUDING_LIEU_LEAVE_TYPE = "totalExLieu";

// Errors
public const ERR_MSG_EFFECTIVE_DAYS_FAILED = "Error when getting effective days!";
public const ERR_MSG_INVALID_DATE_FORMAT = "Invalid date. Date string should be in ISO 8601 format!";
public const ERR_MSG_LEGALLY_ENTITLED_LEAVE_RETRIEVAL_FAILED = 
    "Error occurred while retrieving legally entitled leaves.";
public const ERR_MSG_LEAVES_RETRIEVAL_FAILED = "Error occurred while retrieving leaves!";
public const ERR_MSG_NO_JWT_TOKEN_PRESENT = "x-jwt-assertion header does not exist!";
public const ERR_MSG_END_DATE_BEFORE_START_DATE = "End date cannot be before start date!";

// Regex
final regexp:RegExp & readonly REGEX_DATE_YYYY_MM_DD = re `^\d{4}-\d{2}-\d{2}`;

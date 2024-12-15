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

public const JWT_CONTEXT_KEY = "JWT_CONTEXT_KEY";
public const TOTAL_LEAVE_TYPE = "total";
public const TOTAL_EXCLUDING_LIEU_LEAVE_TYPE = "totalExLieu";
public const decimal DAY_IN_SECONDS = 86400;
public final readonly & EmployeeStatus[] DEFAULT_EMPLOYEE_STATUSES = [EMP_STATUS_ACTIVE, EMP_STATUS_MARKED_LEAVER];
public final map<string> & readonly TIMEZONE_OFFSET_MAP = {
    "Australia": "+10:00",
    "Brazil": "-03:00",
    "Canada": "-05:00",
    "US": "-07:00",
    "Sri Lanka": "+05:30",
    "UK": "+01:00",
    "Argentina": "-03:00",
    "Mexico": "-06:00",
    "Columbia": "-05:00",
    "Saudi Arabia": "+03:00",
    "Germany": "+01:00",
    "Greece": "+02:00",
    "France": "+01:00",
    "Netherland": "+01:00",
    "Spain": "+02:00",
    "India": "+05:30",
    "New Zealand": "+12:00",
    "Singapore": "+08:00"
};

// Errors
public const ERR_MSG_EFFECTIVE_DAYS_FAILED = "Error when getting effective days!";
public const ERR_MSG_EMPLOYEE_LOCATION_RETRIEVAL_FAILED = "Error occurred while retrieving employee location!";
public const ERR_MSG_HOLIDAYS_RETRIEVAL_FAILED = "Error occurred while retrieving holidays!";
public const ERR_MSG_INVALID_DATE_FORMAT = "Invalid date. Date string should be in ISO 8601 format!";
public const ERR_MSG_LEGALLY_ENTITLED_LEAVE_RETRIEVAL_FAILED =
    "Error occurred while retrieving legally entitled leaves!";
public const ERR_MSG_LEAVE_IN_INVALID_STATE = "Leave is in an invalid state!";
public const ERR_MSG_LEAVE_OVERLAPS_WITH_EXISTING_LEAVE = "Leave overlaps with existing leave(s)!";
public const ERR_MSG_LEAVES_RETRIEVAL_FAILED = "Error occurred while retrieving leaves!";
public const ERR_MSG_LEAVE_RETRIEVAL_FAILED = "Error occurred while retrieving the leave!";
public const ERR_MSG_LEAVE_SHOULD_BE_AT_LEAST_ONE_WORKING_DAY =
    "Leave requests should contain at least one working day!";
public const ERR_MSG_LEAVE_SHOULD_BE_AT_LEAST_ONE_WEEKDAY = "Leave requests should contain at least one weekday!";
public const ERR_MSG_NO_JWT_TOKEN_PRESENT = "x-jwt-assertion header does not exist!";
public const ERR_MSG_END_DATE_BEFORE_START_DATE = "End date cannot be before start date!";
public const ERR_MSG_UNAUTHORIZED_VIEW_LEAVE = "You are not authorized to view the requested leaves!";
public const ERR_MSG_INVALID_WSO2_EMAIL = "Input email is not a valid WSO2 email address!";

// Regex
final string:RegExp & readonly REGEX_DATE_YYYY_MM_DD = re `^\d{4}-\d{2}-\d{2}`;
final string:RegExp & readonly REGEX_DATE_YYYY_MM_DD_T_HH_MM_SS = re `^\d{4}-\d{2}-\d{2}T\d{2}:\d{2}:\d{2}Z$`;
final string:RegExp & readonly REGEX_DATE_YYYY_MM_DD_T_HH_MM_SS_SSS = re `^\d{4}-\d{2}-\d{2}T\d{2}:\d{2}:\d{2}.\d+Z`;
final string:RegExp & readonly REGEX_EMPTY_STRING = re `^\s*$`;
public final string:RegExp WSO2_EMAIL_PATTERN = re `^[a-zA-Z0-9._%+-]+@wso2\.com$`;

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

public const ALERT_HEADER = "Leave Submission/Cancellation";
public const APP_NAME_DEV = "Leave Backend Service (Development)";
public const APP_NAME = "Leave Backend Service";

// Regex
final string:RegExp & readonly REGEX_DATE_YYYY_MM_DD = re `^\d{4}-\d{2}-\d{2}`;
final string:RegExp & readonly REGEX_EMAIL_DOMAIN = re `^[a-zA-Z][a-zA-Z0-9_\-\.]+@ws[o|0]2\.com$`;

const JANUARY = 1;
const FEBRUARY = 2;
const MARCH = 3;
const APRIL = 4;
const MAY = 5;
const JUNE = 6;
const JULY = 7;
const AUGUST = 8;
const SEPTEMBER = 9;
const OCTOBER = 10;
const NOVEMBER = 11;
const DECEMBER = 12;

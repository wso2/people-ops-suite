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
import ballerina/lang.regexp;
import ballerina/time;

# Get Civil date from a string in ISO 8601 format. This date will be timezone independent.
#
# + date - String date in ISO 8601 format
# + return - Return Civil date or error for validation failure
public isolated function getCivilDateFromString(string date) returns time:Civil|error {

    time:Civil|time:Error civilDate = time:civilFromString(getTimestampFromDateString(date));
    if civilDate is error {
        return error(civilDate.message(), code = http:STATUS_BAD_REQUEST);
    }
    return civilDate;
}

# Get timestamp from a string in ISO 8601 format. This date will be timezone independent.
#
# + date - String date in ISO 8601 format
# + return - Return timestamp
public isolated function getTimestampFromDateString(string date) returns string {

    string timestamp = date;
    if regexp:find(REGEX_DATE_YYYY_MM_DD, date) is regexp:Span {
        timestamp = date.substring(0, 10) + "T00:00:00Z";
    }
    return timestamp;
}

# Convert timestamp (ex: 2023-01-01T00:00:00Z) to email date string (ex:Sun, 1 Jan 2023).
#
# + timestamp - Timestamp string
# + return - Email date string
public isolated function getEmailDateStringFromTimestamp(string timestamp) returns string {

    time:Civil|error civilDateFromString = getCivilDateFromString(timestamp);
    if civilDateFromString is time:Civil {
        int year = civilDateFromString.year;
        string dayOfWeek = civilDateFromString.dayOfWeek.toString();
        string month = getMonthString(<Month>civilDateFromString.month).substring(0, 3);
        match civilDateFromString.dayOfWeek {
            0 => {
                dayOfWeek = "Sun,";
            }
            1 => {
                dayOfWeek = "Mon,";
            }
            2 => {
                dayOfWeek = "Tue,";
            }
            3 => {
                dayOfWeek = "Wed,";
            }
            4 => {
                dayOfWeek = "Thu,";
            }
            5 => {
                dayOfWeek = "Fri,";
            }
            6 => {
                dayOfWeek = "Sat,";
            }
        }

        return string `${dayOfWeek} ${civilDateFromString.day} ${month} ${year}`;
    }

    return timestamp;
}

# Get month string from month enum.
#
# + month - Month enum
# + return - Return month string
isolated function getMonthString(readonly & Month month) returns string {

    match month {
        JANUARY => {
            return "January";
        }
        FEBRUARY => {
            return "February";
        }
        MARCH => {
            return "March";
        }
        APRIL => {
            return "April";
        }
        MAY => {
            return "May";
        }
        JUNE => {
            return "June";
        }
        JULY => {
            return "July";
        }
        AUGUST => {
            return "August";
        }
        SEPTEMBER => {
            return "September";
        }
        OCTOBER => {
            return "October";
        }
        NOVEMBER => {
            return "November";
        }
        DECEMBER => {
            return "December";
        }
        _ => {
            return month.toString();
        }
    }
}

# Validates and if required, corrects the email addresses in the given emails list.
#
# + emailsList - List of email addresses to validate
# + return - List of valid email addresses
public isolated function getValidEmailRecipientsFromList(string[] emailsList) returns string[] {

    map<()> validEmailsMap = {};
    string:RegExp commaRegex = re `,`;
    foreach string email in emailsList {
        string[] emailCommaSplitList = commaRegex.split(email);

        foreach var emailToValidate in emailCommaSplitList {
            string trimmedEmailToValidate = emailToValidate.trim();
            if isWso2Email(trimmedEmailToValidate) {
                validEmailsMap[trimmedEmailToValidate] = ();
            }
        }
    }
    return validEmailsMap.keys();
}

# Generate the email subject with the application name prefixed.
#
# + subject - Email subject
# + return - Prefixed email subject
isolated function getPrefixedEmailSubject(string subject) returns string => string `[${appName}] - ${subject}`;

# Validate if the given email is a WSO2 email address (has wso2.com or ws02.com domains).
#
# + email - email address to be validated
# + return - true or false
public isolated function isWso2Email(string email) returns boolean =>
    regexp:isFullMatch(REGEX_EMAIL_DOMAIN, email.toLowerAscii());

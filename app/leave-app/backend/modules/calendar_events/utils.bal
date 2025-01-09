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
import ballerina/lang.regexp;
import ballerina/log;
import ballerina/time;

# Get Civil date from a string in ISO 8601 format. This date will be timezone independent.
#
# + date - String date in ISO 8601 format
# + return - Return Civil date or error for validation failure
isolated function getCivilDateFromString(string date) returns time:Civil|error {
    time:Civil|time:Error civilDate = time:civilFromString(getTimestampFromDateString(date));
    if civilDate is error {
        return error(ERR_MSG_INVALID_DATE_FORMAT, civilDate);
    }

    return civilDate;
}

# Generates a list of Day records for each day within a specified date range.
#
# + startDate - The start date as a time:Utc timestamp
# + endDate - The end date as a time:Utc timestamp
# + return - An array of Day records representing each day within the date range or an error
public isolated function getDaysFromRange(time:Utc startDate, time:Utc endDate) returns Day[]|error {

    Day[] days = [];
    time:Utc utcToCheck = startDate;
    while utcToCheck <= endDate {
        days.push({date: time:utcToString(utcToCheck)});
        utcToCheck = time:utcAddSeconds(utcToCheck, 86400);
    }
    return days;
}

# Generates a list of Day records for each day within a date range specified as strings.
#
# + startDate - The start date as a string in a valid date format
# + endDate - The end date as a string in a valid date format
# + return - An array of Day records representing each day within the date range or an error
public isolated function getDaysFromStringRange(string startDate, string endDate) returns Day[]|error {

    time:Utc startUtc = check getUtcDateFromString(startDate);
    time:Utc endUtc = check getUtcDateFromString(endDate);
    return getDaysFromRange(startUtc, endUtc);
}

# Get end date of a given year or current year.
#
# + date - Date to consider
# + return - End date of year
public isolated function getEndDateOfYear(string|time:Utc? date = ()) returns string|error {
    if date is string {
        time:Civil civilDate = check getCivilDateFromString(date);
        int year = civilDate.year;
        return string `${year}-12-31T00:00:00Z`;
    } else {
        time:Utc utcDate = date ?: time:utcNow();
        time:Civil civilDate = time:utcToCivil(utcDate);
        int year = civilDate.year;
        return string `${year}-12-31T00:00:00Z`;
    }
}

isolated function getHolidaysFromEvents(Event[] events, string country) returns Holiday[]|error {
    // map<string> eventIdToCountry = {};
    Holiday[] holidays = [];
    foreach var event in events {
        string? startDate = event?.'start.date;
        string? endDate = event?.end.date;
        if startDate is string && endDate is string {
            Day[] days = check getDaysFromStringRange(startDate, endDate);
            // Start date and end date are not the same for a one day event. End date states the next day.
            if days.length() <= 2 {
                holidays.push({
                    id: event.id,
                    title: event.summary,
                    date: getTimestampFromDateString(startDate),
                    country
                });
            } else {
                // Ignore last date as it is one day after the event.
                foreach int i in 0 ... days.length() - 2 {
                    holidays.push({
                        id: event.id,
                        title: event.summary,
                        date: days[i].date,
                        country
                    });
                }
            }
        }
    }

    return holidays;
}

public isolated function getNumberOfDaysFromStringRange(string startDate, string endDate) returns int|error {
    time:Utc startUtc = check getUtcDateFromString(startDate);
    time:Utc endUtc = check getUtcDateFromString(endDate);

    time:Seconds seconds = time:utcDiffSeconds(endUtc, startUtc);
    return <int>(seconds / 86400).floor();
}

# Get start date of a given year or current year.
#
# + date - Date to consider
# + return - Start date of year
public isolated function getStartDateOfYear(string|time:Utc? date = ()) returns string|error {
    if date is string {
        time:Civil civilDate = check getCivilDateFromString(date);
        int year = civilDate.year;
        return string `${year}-01-01T00:00:00Z`;
    } else {
        time:Utc utcDate = date ?: time:utcNow();
        time:Civil civilDate = time:utcToCivil(utcDate);
        int year = civilDate.year;
        return string `${year}-01-01T00:00:00Z`;
    }
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

# Get UTC date from a string in ISO 8601 format. This date will be timezone independent.
#
# + date - String date in ISO 8601 format
# + return - Return UTC date or error for validation failure
public isolated function getUtcDateFromString(string date) returns time:Utc|error {
    string timestamp = getTimestampFromDateString(date);
    time:Utc|time:Error utcDate = time:utcFromString(timestamp);
    if utcDate is time:Error {
        log:printError(string `${ERR_MSG_INVALID_DATE_FORMAT} Date: ${date} Timestamp: ${timestamp}`);
        return error(ERR_MSG_INVALID_DATE_FORMAT, utcDate);
    }

    return utcDate;
}

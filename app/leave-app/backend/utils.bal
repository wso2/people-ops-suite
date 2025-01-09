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
import leave_service.calendar_events;
import leave_service.database;
import leave_service.employee;

import ballerina/http;
import ballerina/lang.regexp;
import ballerina/log;
import ballerina/regex;
import ballerina/time;

configurable string[] defaultRecipients = [];

# Checks if a passed string is an empty.
#
# + stringToCheck - String to be checked
# + return - Whether the string is empty or not
public isolated function checkIfEmptyString(string stringToCheck) returns boolean {

    if stringToCheck.length() == 0 {
        return true;
    }

    return regexp:isFullMatch(REGEX_EMPTY_STRING, stringToCheck);
}

# Function to check if a given date is a weekday (Monday to Friday).
#
# + date - Date to check
# + return - Returns true if the date is a weekday, false otherwise
public isolated function checkIfWeekday(time:Civil|time:Utc date) returns boolean {

    time:Civil civil = date is time:Utc ? time:utcToCivil(date) : date;
    return !(civil.dayOfWeek == time:SATURDAY || civil.dayOfWeek == time:SUNDAY);
}

# Inserts a leave record into the database or validates leave details based on the provided input.
#
# + input - The leave input details as a `database:LeaveInput` record
# + isValidationOnlyMode - A flag indicating whether to only validate the leave (`true`) or 
# insert the leave into the database (`false`)
# + token - The authentication token for accessing employee details
# + return - Returns a `LeaveDetails` record if successful, or an error otherwise
public isolated function insertLeaveToDatabase(database:LeaveInput input, boolean isValidationOnlyMode, string token)
    returns LeaveDetails|error {

    LeaveDetails[]|error? leaveDetails = calculateLeaveDetails(input, token);
    if leaveDetails is LeaveDetails[] {
        return error(ERR_MSG_LEAVE_OVERLAPS_WITH_EXISTING_LEAVE);
    }
    if !isValidationOnlyMode {
        string|error location = employee:getEmployeeLocation(input.email, token);
        if location is error {
            return location;
        }
        LeaveDay[]|error effectiveLeaveDaysFromLeave = getEffectiveLeaveDaysFromLeave(input, token);
        if effectiveLeaveDaysFromLeave is error {
            return effectiveLeaveDaysFromLeave;
        }
        float numDaysForLeave = getNumberOfDaysFromLeaveDays(effectiveLeaveDaysFromLeave);

        database:Leave|error createdLeave = database:insertLeave(input, numDaysForLeave, location);
        if createdLeave is error {
            return createdLeave;
        }
        LeaveDetails|error leaveDetailsNotValidationMode = getLeaveEntityFromDbRecord(createdLeave, token);
        if leaveDetailsNotValidationMode is error {
            return leaveDetailsNotValidationMode;
        }
        return leaveDetailsNotValidationMode;
    }
    string|error employeeLocation = employee:getEmployeeLocation(input.email, token);
    if employeeLocation is error {
        return employeeLocation;
    }

    LeaveDetails validatedLeave = {
        calendarEventId: (),
        createdDate: "",
        leaveType: check input.leaveType.cloneWithType(),
        endDate: input.endDate,
        id: 0,
        isActive: false,
        periodType: check input.periodType.cloneWithType(),
        startDate: input.startDate,
        email: input.email,
        isMorningLeave: input.isMorningLeave,
        location: employeeLocation
    };

    LeaveDay[]|error effectiveLeaveDaysFromLeave = getEffectiveLeaveDaysFromLeave(input, token);
    if effectiveLeaveDaysFromLeave is error {
        return effectiveLeaveDaysFromLeave;
    }
    validatedLeave.effectiveDays = effectiveLeaveDaysFromLeave;
    validatedLeave.numberOfDays = getNumberOfDaysFromLeaveDays(effectiveLeaveDaysFromLeave);
    return validatedLeave;
}

# Retrieves all unique email recipients for a user, including default recipients, their lead's email, and 
# user-added recipients.
#
# + email - The user's email address
# + userAddedRecipients - A list of additional email addresses specified by the user
# + token - The authentication token required to access employee details
# + return - Returns a readonly array of unique email addresses or an error if the process fails
public isolated function getAllEmailRecipientsForUser(string email, string[] userAddedRecipients, string token)
    returns readonly & string[]|error {

    map<true> recipientMap = {
        [email]: true
    };
    foreach string defaultRecipient in defaultRecipients {
        recipientMap[defaultRecipient] = true;
    }

    readonly & Employee employee = check employee:getEmployee(email, token);
    recipientMap[<string>employee.leadEmail] = true;
    foreach string recipient in userAddedRecipients {
        recipientMap[recipient] = true;
    }

    return recipientMap.keys().cloneReadOnly();
}

# Get Civil date from a string in ISO 8601 format. This date will be timezone independent.
#
# + date - String date in ISO 8601 format
# + return - Return Civil date or error for validation failure
public isolated function getCivilDateFromString(string date) returns time:Civil|error {

    time:Civil|time:Error civilDate = time:civilFromString(getTimestampFromDateString(date));
    if civilDate is error {
        return error(
            civilDate.message(),
            externalMessage = ERR_MSG_INVALID_DATE_FORMAT,
            code = http:STATUS_BAD_REQUEST
        );
    }
    return civilDate;
}

# Get the date string in ISO 8601 format from timestamp.
#
# + timestamp - Timestamp
# + return - String date in ISO 8601 format
public isolated function getDateStringFromTimestamp(string timestamp) returns string {

    if regexp:isFullMatch(REGEX_DATE_YYYY_MM_DD_T_HH_MM_SS, timestamp) ||
        regexp:isFullMatch(REGEX_DATE_YYYY_MM_DD_T_HH_MM_SS_SSS, timestamp) {
        return timestamp.substring(0, 10);
    }

    return timestamp;
}

# Get the effective leave days for a given leave input, factoring in holidays and working days.
#
# + leaveInput - Leave input record
# + token - JWT token
# + return - An array of `LeaveDay` records with calculated effective leave days or an error if the calculation fails
public isolated function getEffectiveLeaveDaysFromLeave(database:LeaveInput leaveInput, string token)
    returns LeaveDay[]|error {

    string|error location = employee:getEmployeeLocation(leaveInput.email, token);
    if location is error {
        return location;
    }

    [time:Utc, time:Utc] [startDateUtc, endDateUtc] = check validateDateRange(leaveInput.startDate, leaveInput.endDate);
    database:Day[] weekdaysFromRange = getWeekdaysFromRange(startDateUtc, endDateUtc);
    database:Holiday[] holidaysInRange = check calendar_events:getHolidaysForCountry(
            location,
            leaveInput.startDate,
            leaveInput.endDate
    );
    database:Day[] workingDaysAfterHolidays = getWorkingDaysAfterHolidays(weekdaysFromRange, holidaysInRange);
    LeaveDay[] leaveDays = [];
    foreach database:Day {date} in workingDaysAfterHolidays {
        LeaveDay leaveDay = {
            date,
            'type: <database:LeaveType>leaveInput.leaveType,
            isMorningLeave: leaveInput.isMorningLeave,
            periodType: <database:LeavePeriodType>leaveInput.periodType
        };
        leaveDays.push(leaveDay);
    }

    return leaveDays;
}

# Get end date of a given year or current year.
#
# + date - Date to consider
# + year - Year to consider when date is not passed
# + return - End date of year
public isolated function getEndDateOfYear(time:Utc? date = (), int? year = ()) returns string =>
    string `${year ?: time:utcToCivil(date ?: time:utcNow()).year}-12-31T00:00:00Z`;

# Get Leave entity from the given DB record.
#
# + dbLeave - DB leave record
# + token - JWT token
# + fetchEffectiveDays - Should affected days be fetched
# + return - Return Leave entity
public isolated function getLeaveEntityFromDbRecord(database:Leave dbLeave, string token,
        boolean fetchEffectiveDays = false) returns LeaveDetails|error {

    database:Leave {
        id,
        email,
        startDate,
        endDate,
        isActive,
        leaveType,
        periodType,
        createdDate,
        startHalf,
        copyEmailList,
        calendarEventId,
        numberOfDays,
        location,
        emailId,
        emailSubject
    } = dbLeave;
    database:LeaveType entityLeaveType;
    database:LeavePeriodType entityLeavePeriodType;
    database:LeaveType|error clonedLeaveType = leaveType.ensureType();
    if clonedLeaveType is error {
        log:printWarn(
                string `Detected unsupported leave type: ${leaveType.toString()}. Leave ID: ${id.toString()}.`,
                clonedLeaveType
        );
        entityLeaveType = database:CASUAL_LEAVE;
    } else {
        entityLeaveType = clonedLeaveType;
    }

    database:LeavePeriodType|error clonedLeavePeriodType = periodType.ensureType();
    if clonedLeavePeriodType is error {
        log:printWarn(
                string `Detected unsupported leave period type: ${periodType.toString()}. Leave ID: ${id.toString()}.`,
                clonedLeavePeriodType
        );
        entityLeavePeriodType = database:MULTIPLE_DAYS_LEAVE;
    } else {
        entityLeavePeriodType = clonedLeavePeriodType;
    }

    string[] emailRecipients = copyEmailList == () || copyEmailList.length() == 0 ?
        [] : regex:split(copyEmailList, ",");

    string|error empLocation = employee:getEmployeeLocation(email, token);
    if empLocation is error {
        return empLocation;
    }
    LeaveDetails leaveDetails = {
        id,
        startDate: getTimestampFromDateString(startDate),
        endDate: getTimestampFromDateString(endDate),
        isActive: isActive ?: false,
        leaveType: entityLeaveType,
        email,
        periodType: entityLeavePeriodType,
        isMorningLeave: startHalf is () ? () : startHalf == 0,
        createdDate: createdDate is string ? getTimestampFromDateString(createdDate) : "",
        emailRecipients,
        calendarEventId,
        emailId,
        numberOfDays,
        location: location is string && location.length() > 0 ? location : empLocation,
        emailSubject
    };

    if fetchEffectiveDays {
        database:LeaveDay[]|error effectiveLeaveDaysFromLeave =
            getEffectiveLeaveDaysFromLeave(
                {
                    email,
                    startDate: leaveDetails.startDate,
                    endDate: leaveDetails.endDate,
                    leaveType: leaveDetails.leaveType,
                    periodType: leaveDetails.periodType,
                    isMorningLeave: leaveDetails.isMorningLeave
                },
                token
            );
        if effectiveLeaveDaysFromLeave is error {
            return effectiveLeaveDaysFromLeave;
        }
        leaveDetails.effectiveDays = effectiveLeaveDaysFromLeave;
    }

    return leaveDetails;
}

# Get the Leave Entity record from the given DB record.
#
# + dbLeaves - DB leave records
# + token - JWT token
# + fetchEffectiveDays - Should effective days be fetched
# + failOnError - Should the function fail on error
# + return - Return Leave entity
public isolated function getLeaveEntitiesFromDbRecords(database:Leave[] dbLeaves, string token,
        boolean fetchEffectiveDays = false, boolean failOnError = false) returns LeaveDetails[]|error {

    LeaveDetails[] leaves = [];
    foreach database:Leave dbLeave in dbLeaves {
        do {
            LeaveDetails|error leave = getLeaveEntityFromDbRecord(dbLeave, token, fetchEffectiveDays);
            if leave is error {
                return leave;
            }
            leaves.push(leave);
        } on fail error err {
            if failOnError {
                log:printError(string `Error occurred while getting leave entities from DB records. Record ID: ${dbLeave.id}.`, err);
                return error(string `Error occurred while getting leave entities from DB records`);
            }

            log:printWarn(string `Skipped Error. Error occurred while getting leave entities from DB records. Record ID: ${dbLeave.id}.`, err);
        }
    }

    return leaves;
}

# Get start date of a given year or current year.
#
# + date - Date to consider
# + year - Year to consider when date is not passed
# + return - Start date of year
public isolated function getStartDateOfYear(time:Utc? date = (), int? year = ()) returns string =>
    string `${year ?: time:utcToCivil(date ?: time:utcNow()).year}-01-01T00:00:00Z`;

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

# Calculates the total number of leave days based on the leave periods.
#
# + leaveDays - An array of `LeaveDay` records representing the leave days to be calculated
# + return - The total number of days as a `float`
public isolated function getNumberOfDaysFromLeaveDays(LeaveDay[] leaveDays) returns float {

    float numberOfDays = 0.0;
    from LeaveDay leaveDay in leaveDays
    do {
        numberOfDays += (leaveDay.periodType is database:HALF_DAY_LEAVE ? 0.5 : 1.0);
    };

    return numberOfDays;
}

# Retrieves the private email recipients for a given user.
#
# + email - The email of the user for whom private recipients are to be determined
# + userAddedRecipients - A list of additional recipients added by the user
# + token - The authorization token to retrieve user details
# + return - A readonly array of private email recipients or an error if the operation fails
public isolated function getPrivateRecipientsForUser(string email, string[] userAddedRecipients, string token)
    returns readonly & string[]|error {

    map<true> recipientMap = {
        [email]: true
    };
    readonly & Employee employee = check employee:getEmployee(email, token);
    recipientMap[<string>employee.leadEmail] = true;
    foreach string recipient in userAddedRecipients {
        recipientMap[recipient] = true;
    }
    foreach string defaultRecipient in defaultRecipients {
        if recipientMap.hasKey(defaultRecipient) {
            _ = recipientMap.remove(defaultRecipient);
        }
    }

    return recipientMap.keys().cloneReadOnly();
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

# Function to get the weekdays within a date range.
#
# + startDate - Start date 
# + endDate - End date
# + return - Return Utc array of weekdays
public isolated function getWeekdaysFromRange(time:Utc startDate, time:Utc endDate) returns database:Day[] {

    database:Day[] weekdays = [];
    time:Utc utcToCheck = startDate;
    while utcToCheck <= endDate {
        if checkIfWeekday(utcToCheck) {
            weekdays.push({date: time:utcToString(utcToCheck)});
        }
        utcToCheck = time:utcAddSeconds(utcToCheck, 86400);
    }

    return weekdays;
}

# Function to get the workdays after holidays.
#
# + weekdays - Weekdays
# + holidays - holidays
# + return - Return Utc array of weekdays
public isolated function getWorkingDaysAfterHolidays(database:Day[] weekdays, database:Holiday[] holidays)
    returns database:Day[] {

    map<database:Day> workingDaysMap = {};
    foreach database:Day weekday in weekdays {
        string weekdayDate = getTimestampFromDateString(weekday.date);
        workingDaysMap[weekdayDate] = weekday;
    }
    foreach database:Holiday holiday in holidays {
        string holidayDate = getTimestampFromDateString(holiday.date);
        if workingDaysMap.hasKey(holidayDate) {
            _ = workingDaysMap.remove(holidayDate);
        }
    }

    return workingDaysMap.toArray();
}

# Get Leave entity from the given DB record.
#
# + leave - DB leave record 
# + token - JWT token
# + fetchEffectiveDays - Should affected days be fetched
# + return - LeaveResponse object containing the processed leave details or an error if processing fails
public isolated function toLeaveEntity(database:Leave leave, string token, boolean fetchEffectiveDays = true)
    returns LeaveResponse|error {

    database:Leave {
        id,
        email,
        startDate,
        endDate,
        isActive,
        leaveType,
        periodType,
        createdDate,
        copyEmailList,
        calendarEventId,
        numberOfDays,
        location,
        emailId,
        emailSubject
    } = leave;
    database:LeaveType entityLeaveType;
    database:LeavePeriodType entityLeavePeriodType;
    database:LeaveType|error clonedLeaveType = leaveType.ensureType();
    if clonedLeaveType is error {
        log:printWarn(
                string `Detected unsupported leave type: ${leaveType.toString()}. Leave ID: ${id.toString()}.`,
                clonedLeaveType
        );
        entityLeaveType = database:CASUAL_LEAVE;
    } else {
        entityLeaveType = clonedLeaveType;
    }

    database:LeavePeriodType|error clonedLeavePeriodType = periodType.ensureType();
    if clonedLeavePeriodType is error {
        log:printWarn(
                string `Detected unsupported leave period type: ${periodType.toString()}. Leave ID: ${id.toString()}.`,
                clonedLeavePeriodType
        );
        entityLeavePeriodType = database:MULTIPLE_DAYS_LEAVE;
    } else {
        entityLeavePeriodType = clonedLeavePeriodType;
    }
    string:RegExp regPattern = re `,`;
    string[] emailRecipients = copyEmailList == () || copyEmailList.length() == 0
        ? []
        : regPattern.split(copyEmailList);
    readonly & string[] readonlyEmailRecipients = emailRecipients.cloneReadOnly();

    boolean? isMorningLeave = (leave.startHalf == 0) ? true : (leave.startHalf == 1 ? false : ());
    database:LeaveDay[] effectiveLeaveDaysFromLeave = [];
    if fetchEffectiveDays {
        database:LeaveDay[]|error effectiveDays = getEffectiveLeaveDaysFromLeave(
                {
                    email,
                    startDate: startDate,
                    endDate: endDate,
                    leaveType: entityLeaveType,
                    periodType: entityLeavePeriodType,
                    isMorningLeave: isMorningLeave
                }, token);

        if effectiveDays is error {
            return error(ERR_MSG_EFFECTIVE_DAYS_FAILED, effectiveDays);
        }

        effectiveLeaveDaysFromLeave = <database:LeaveDay[]>effectiveDays;
    }
    database:LeaveDay[] & readonly readonlyEffectiveLeaveDaysFromLeave = effectiveLeaveDaysFromLeave.cloneReadOnly();

    return {
        id,
        startDate,
        endDate,
        isActive: isActive ?: false,
        leaveType: entityLeaveType,
        periodType: entityLeavePeriodType,
        isMorningLeave,
        email,
        createdDate: createdDate is string ? getTimestampFromDateString(createdDate) : "",
        emailRecipients: readonlyEmailRecipients,
        effectiveDays: readonlyEffectiveLeaveDaysFromLeave,
        calendarEventId,
        numberOfDays: numberOfDays ?: 0.0,
        location,
        emailId,
        emailSubject
    };
}

# Date range validation function.
#
# + startDate - Start date of the range
# + endDate - End date of the range
# + return - Returns UTC start and end dates or error for validation failure
public isolated function validateDateRange(string startDate, string endDate) returns [time:Utc, time:Utc]|error {

    do {
        time:Utc startUtc = check getUtcDateFromString(startDate);
        time:Utc endUtc = check getUtcDateFromString(endDate);
        if startUtc > endUtc {
            return error(ERR_MSG_END_DATE_BEFORE_START_DATE);
        }

        return [startUtc, endUtc];

    } on fail error err {
        return error(err.message());
    }
}

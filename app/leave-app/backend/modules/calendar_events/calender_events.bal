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
import ballerina/cache;
import ballerina/http;
import ballerina/log;

isolated cache:Cache holidaysCache = new (
    'defaultMaxAge = CACHE_DEFAULT_MAX_AGE,
    'cleanupInterval = CACHE_CLEANUP_INTERVAL
);
isolated map<map<Holiday[]>> countryToYearToHolidays = {};

# Calls the Google Calendar API to create event.
#
# + email - User email 
# + payload - Event payload
# + return - Event ID if returned or error
public isolated function createEvent(string email, EventPayload payload) returns string|error? {

    CreatedMessage response = check eventClient->/events/[email].post(payload, {
        "x-jwt-assertion": "x-jwt-assertion"
    });
    return response.id;
}

# Calls the Google Calendar API to Delete event.
#
# + email - User email 
# + eventId - Event ID
# + return - Error or nil
public isolated function deleteEvent(string email, string eventId) returns error? {

    http:Response response = check eventClient->/events/[email]/[eventId].delete({
        "x-jwt-assertion": "x-jwt-assertion"
    });
    if response.statusCode != http:STATUS_OK {
        return error(string `Event deletion unsuccessful. Status code: ${response.statusCode}.`);
    }
}

# Fetch holidays for a country.
#
# + country - Country  
# + startDateOfYear - Start date of year  
# + endDateOfYear - End date of year
# + return - Holidays list or error
isolated function fetchHolidaysForCountry(string country, string startDateOfYear, string endDateOfYear)
    returns Holiday[]|error {

    log:printInfo(string `Fetching holidays for country: ${country}.`);
    worker HolidaysWorker returns Holiday[]|error {
        Holiday[] holidaysFromEvents = [];
        lock {
            HolidayGroup[] holidayGroups = check eventClient->/holidays(countries = [country], startTimeMin = startDateOfYear, startTimeMax = endDateOfYear);
            Event[] holidays = [];
            if holidayGroups.length() != 0 {
                holidays = holidayGroups[0].holidays;
            }

            holidaysFromEvents = check getHolidaysFromEvents(holidays.cloneReadOnly(), country);
            countryToYearToHolidays[country][startDateOfYear] = holidaysFromEvents.cloneReadOnly();

        }

        lock {
            any|cache:Error holidaysInCache = holidaysCache.get(country);
            if holidaysInCache is cache:Error {
                _ = check holidaysCache.put(country, true);
            }
        }
        return holidaysFromEvents.cloneReadOnly();
    }

    return wait HolidaysWorker;
}

# Get holidays of a country.
#
# + country - Country 
# + startDate - Start date 
# + endDate - End date
# + return - Holidays list or error
public isolated function getHolidaysForCountry(string country, string? startDate = (), string? endDate = ())
    returns Holiday[]|error {

    final string startDateOfYear = check getStartDateOfYear(startDate);
    final string endDateOfYear = check getEndDateOfYear(endDate);

    Holiday[]? holidaysToReturn = ();
    lock {
        int daysInRange = check getNumberOfDaysFromStringRange(startDateOfYear, endDateOfYear);
        if countryToYearToHolidays.hasKey(country) && daysInRange < 365 {
            map<Holiday[]> dateToHolidays = countryToYearToHolidays.get(country);
            if dateToHolidays.hasKey(startDateOfYear) {
                Holiday[] get = dateToHolidays.get(startDateOfYear);
                holidaysToReturn = get.cloneReadOnly();
            }
        }
    }

    if holidaysToReturn is () {
        return fetchHolidaysForCountry(country, startDateOfYear, endDateOfYear);
    }
    boolean shouldFetch = false;
    lock {
        if !holidaysCache.hasKey(country) {
            shouldFetch = true;
        }
    }
    if shouldFetch {
        _ = start fetchHolidaysForCountry(country, startDateOfYear, endDateOfYear);
    }

    return holidaysToReturn;
}

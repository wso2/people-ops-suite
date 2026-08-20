// Copyright (c) 2026 WSO2 LLC. (https://www.wso2.com).
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
import meet_app.database;
import meet_app.people;

import ballerina/cache;

# Narrows the result of a JSON field access to an array, without propagating errors.
#
# Field access on a `json` value yields `json|error`, and the value behind an existing key
# may not be an array at all. Both cases degrade to an empty array here so a missing or
# malformed field never fails the caller.
#
# + value - Result of a JSON field access
# + return - The value when it is a `json[]`, otherwise an empty array
isolated function toJsonArray(json|error value) returns json[] => value is json[] ? value : [];

# Aggregates meeting statistics by Account Manager and their respective Regional Teams.
#
# + startDate - The start of the analysis range
# + endDate - The end of the analysis range
# + region - Region filter
# + return - A JSON object containing `regionalStats` and `amStats` arrays, sorted by count or an error.
isolated function getPeopleAnalytics(string startDate, string endDate , string? region) returns json|error {

    // Get Raw Counts per Host from Database
    database:MeetingHostStat[] hostStats = check database:getMeetingCountsByHost(startDate, endDate , region );
    if hostStats.length() == 0 {
        return {"regionalStats": [], "amStats": [], "toStats": []};
    }

    // Fetch Employee Details
    string[] emails = from var stat in hostStats
        select stat.host;

    people:EmployeeBasic[] employees = check people:getEmployees(emails);
    map<people:EmployeeBasic> empMap = {};
    foreach var emp in employees {
        empMap[emp.workEmail] = emp;
    }
    map<int> subTeamCounts = {};
    json[] amStatsList = [];
    json[] toStatsList = [];

    foreach var stat in hostStats {
        people:EmployeeBasic? emp = empMap[stat.host];
        string subTeamName = "Unknown";
        string amName = stat.host;

        if emp is people:EmployeeBasic {
            subTeamName = emp.subTeam ?: "Unknown";
            amName = string `${emp.firstName} ${emp.lastName}`;
        }

        // Aggregate Team Counts
        int currentTeamCount = subTeamCounts.hasKey(subTeamName) ? subTeamCounts.get(subTeamName) : 0;
        subTeamCounts[subTeamName] = currentTeamCount + stat.count;
        if stat.team == salesDesignations.teamNameOfAccountManager {
            amStatsList.push({
                "name": amName,
                "value": stat.count,
                "email": stat.host
            });
        }
        if stat.team == salesDesignations.teamNameOfTechnicalOfficer {
            toStatsList.push({
                "name": amName,
                "value": stat.count,
                "email": stat.host
            });
        }
    }
    json[] regionalStatsList = [];
    foreach var [team, count] in subTeamCounts.entries() {
        regionalStatsList.push({"name": team, "value": count});
    }

    json[] sortedRegional = from var item in regionalStatsList
        order by <int>check item.value descending
        select item;

    json[] sortedAm = from var item in amStatsList
        order by <int>check item.value descending
        select item;

    json[] sortedTo = from var item in toStatsList
        order by <int>check item.value descending
        select item;

    return {
        "regionalStats": sortedRegional,
        "amStats": sortedAm,
        "toStats": sortedTo
    };
}

# Retrieve the employee data 
#
# + email - Employee email
# + cache - Cached array
# + return - UserInfoResponse | Employee | error
isolated function getEmployeeInfo(string email, cache:Cache cache) returns UserInfoResponse|people:Employee|error {
    // Check if the employees are already cached.
    if cache.hasKey(email) {
        UserInfoResponse|error cachedUserInfo = cache.get(email).ensureType();
        if cachedUserInfo is UserInfoResponse {
            return cachedUserInfo;
        }
    }
    // Fetch the user information from the people service.
    return people:fetchEmployeesBasicInfo(email);
}

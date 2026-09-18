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

# Headings Meet uses to divide its combined document.
#
# Meet writes ONE Google Doc per meeting holding three sections, each introduced by an
# emoji heading: "Quick notes" (a condensed summary), "Full notes" (the same meeting
# written out properly), and "Transcript". The transcript and smartNotes API resources
# both point at this same document.
const string NOTES_QUICK_HEADING = "\u{270D}\u{FE0F} Quick notes";
const string NOTES_FULL_HEADING = "\u{1F4DD} Full notes";
const string NOTES_TRANSCRIPT_HEADING = "\u{1F4D6} Transcript";

# Google's own prompts and surveys, not content anyone asked for.
#
# Matched on a PREFIX rather than exactly, because the survey and tip wording drifts: a
# feedback prompt that changes by a word should still be dropped rather than reappearing
# in the middle of someone's meeting notes. Every entry here is long and specific enough
# that no sentence a person would write starts with it.
final readonly & string[] NOTES_CHROME_PREFIXES = [
    "Please rate the new",
    "Want to see more?",
    "Tip: You can always access",
    "You should review Gemini's notes",
    "How is the quality of these specific notes?"
];

# Google's document navigation labels.
#
# Matched by REMOVAL rather than by equality or by prefix, because neither simpler rule
# survives the real documents. Prefix-matching eats content -- "Notes" would delete "Notes
# from the customer: ..." and "Meeting records" would delete "Meeting records are kept for
# seven years". Exact-matching misses the nav row, which arrives as one line of several
# labels run together and varies by which artifacts the meeting produced: "Meeting records
# Transcript Recording" on a call with both, fewer labels on a call with one.
#
# So a line is chrome only when NOTHING is left after every label is taken out of it. That
# drops the row whatever order or subset it uses, and keeps any line carrying real words.
final readonly & string[] NOTES_CHROME_LABELS = [
    "Meeting records",
    "Smart notes",
    "Transcript",
    "Recording",
    "Notes"
];

# A bare date line, e.g. "Sep 16, 2026".
final readonly & string:RegExp NOTES_DATE_LINE = re `^[A-Z][a-z]{2} \d{1,2}, \d{4}$`;

# The document's own title line, e.g. "Meeting Sep 16, 2026 at 15:34 IST".
final readonly & string:RegExp NOTES_TITLE_LINE = re `^Meeting .* at \d{1,2}:\d{2}.*$`;

# Reduces Meet's combined document to the notes a person actually wants to read.

# DEGRADES GRACEFULLY throughout: every cut is conditional on its marker being found, so
# a document Google has since restructured comes back longer rather than empty. Showing a
# little too much beats showing nothing because a heading moved.
#
# + text - The exported document
# + return - Just the notes, ready to render
isolated function notesWithoutTranscript(string text) returns string {
    string notes = text;

    int? transcriptAt = notes.indexOf(NOTES_TRANSCRIPT_HEADING);
    if transcriptAt is int {
        notes = notes.substring(0, transcriptAt);
    }

    int? fullAt = notes.indexOf(NOTES_FULL_HEADING);
    if fullAt is int {
        notes = notes.substring(fullAt + NOTES_FULL_HEADING.length());
    }

    string[] kept = [];
    foreach string line in re `\n`.split(notes) {
        string trimmed = line.trim();

        if trimmed == NOTES_QUICK_HEADING || trimmed == NOTES_FULL_HEADING {
            continue;
        }
        if NOTES_DATE_LINE.isFullMatch(trimmed) || NOTES_TITLE_LINE.isFullMatch(trimmed) {
            continue;
        }

        // Chrome if the line is made of nothing but navigation labels -- see the note on
        // NOTES_CHROME_LABELS for why this is removal rather than a comparison.
        string residue = trimmed;
        foreach string label in NOTES_CHROME_LABELS {
            residue = withoutAll(residue, label);
        }
        boolean isChrome = trimmed != "" && residue.trim() == "";
        foreach string prefix in NOTES_CHROME_PREFIXES {
            if trimmed.startsWith(prefix) {
                isChrome = true;
                break;
            }
        }
        if isChrome {
            continue;
        }

        // Runs of blank lines collapse to one. The document is generously spaced for a
        // full page; in a side panel that spacing reads as the notes having ended.
        if trimmed == "" && kept.length() > 0 && kept[kept.length() - 1] == "" {
            continue;
        }
        kept.push(trimmed == "" ? "" : line);
    }
    return string:'join("\n", ...kept).trim();
}

# Removes every occurrence of a literal fragment from a string.
#
# Deliberately not a regular expression: the fragments are Google's own label text, and
# treating them as patterns would make a stray character in a future label match far more
# than intended.
#
# + text - The string to strip
# + fragment - The literal to remove, every time it occurs
# + return - `text` with every occurrence removed
isolated function withoutAll(string text, string fragment) returns string {
    string result = text;
    int? at = result.indexOf(fragment);
    while at is int {
        result = result.substring(0, at) + result.substring(at + fragment.length());
        at = result.indexOf(fragment);
    }
    return result;
}

// Copyright (c) 2025 WSO2 LLC. (https://www.wso2.com).
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

# Splits a comma-separated config value into its entries, trimmed and de-duplicated.
#
# Brackets and quotes are dropped before splitting, so a value written as `["a","b"]` -- what
# Choreo's configuration form saves when someone tries to enter an array -- reads the same as
# `a, b`. Group names and client IDs never contain those characters, so a single value is
# unaffected.
#
# + value - Raw config value
# + return - The entries, and whether an empty entry (e.g. a stray comma) was skipped
public isolated function splitConfigList(string value) returns [string[], boolean] {
    string[] entries = [];
    boolean hadEmptyEntry = false;
    foreach string part in re `,`.split(re `[\[\]"']`.replaceAll(value, "")) {
        string entry = part.trim();
        if entry == "" {
            hadEmptyEntry = true;
        } else if entries.indexOf(entry) == () {
            entries.push(entry);
        }
    }
    return [entries, hadEmptyEntry];
}

# Checks whether the user belongs to at least one of the allowed groups.
#
# + allowedGroups - Groups that grant the role
# + userGroups - Groups the user belongs to
# + return - True if any user group is in the allowed list
public isolated function hasAnyGroup(readonly & string[] allowedGroups, string[] userGroups) returns boolean {
    return userGroups.some(g => allowedGroups.indexOf(g) !is ());
}

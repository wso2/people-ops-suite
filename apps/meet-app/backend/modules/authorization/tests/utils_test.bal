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
import ballerina/test;

@test:Config {}
function splitConfigListSingleValue() {
    test:assertEquals(splitConfigList("wso2-everyone"), [["wso2-everyone"], false]);
}

@test:Config {}
function splitConfigListCommaSeparated() {
    test:assertEquals(splitConfigList(" sales-team , sales-leads,sales-team "), [["sales-team", "sales-leads"], false]);
}

@test:Config {}
function splitConfigListArrayForm() {
    // What Choreo's form saves when an array is entered.
    test:assertEquals(splitConfigList("[\"sales-team\",\"sales-leads\"]"), [["sales-team", "sales-leads"], false]);
}

@test:Config {}
function splitConfigListEmptyEntries() {
    test:assertEquals(splitConfigList("sales-team,,"), [["sales-team"], true]);
    test:assertEquals(splitConfigList(""), [[], true]);
}

@test:Config {}
function hasAnyGroupMatches() {
    test:assertTrue(hasAnyGroup(["sales-team", "sales-leads"], ["wso2-everyone", "sales-leads"]));
}

@test:Config {}
function hasAnyGroupNoMatch() {
    test:assertFalse(hasAnyGroup(["sales-team"], ["wso2-everyone"]));
    test:assertFalse(hasAnyGroup([], ["sales-team"]));
    test:assertFalse(hasAnyGroup(["sales-team"], []));
}

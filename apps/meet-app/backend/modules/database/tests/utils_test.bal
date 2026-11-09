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
import ballerina/test;

@test:Config
function testToDbDateTimeDropsTheFraction() {
    test:assertEquals(toDbDateTime("2026-10-01T10:20:05.123456Z"), "2026-10-01 10:20:05");
}

@test:Config
function testToDbDateTimeConvertsAnOffsetToUtc() {
    test:assertEquals(toDbDateTime("2026-10-01T15:50:05+05:30"), "2026-10-01 10:20:05");
}

@test:Config
function testToDbDateTimeLeavesUnknownTimesEmpty() {
    test:assertEquals(toDbDateTime(()), ());
    test:assertEquals(toDbDateTime(""), ());
    test:assertEquals(toDbDateTime("not a time"), ());
}

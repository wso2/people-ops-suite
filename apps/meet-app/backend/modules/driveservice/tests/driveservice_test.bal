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

// meet-app must read drive-service's resolve response both before and after drive-service
// starts sending the part's call and times, so either can be deployed first.

@test:Config
function testResolveResponseWithoutPartFields() returns error? {
    json older = {spaceName: "spaces/s1", fileId: "f1"};
    RecordingInfoResponse info = check older.cloneWithType();
    test:assertEquals(info.fileId, "f1");
    test:assertEquals(info?.startTime, ());
}

@test:Config
function testResolveResponseWithPartFields() returns error? {
    json newer = {
        spaceName: "spaces/s1",
        fileId: "f2",
        conferenceRecordName: "conferenceRecords/c1",
        startTime: "2026-10-01T10:20:00.123Z",
        endTime: "2026-10-01T10:45:00Z"
    };
    TranscriptInfoResponse info = check newer.cloneWithType();
    test:assertEquals(info?.conferenceRecordName, "conferenceRecords/c1");
    test:assertEquals(info?.startTime, "2026-10-01T10:20:00.123Z");
}

// Why the fields are declared at all: the record is closed, so an undeclared field is refused.
@test:Config
function testResolveResponseRefusesUndeclaredField() {
    json unexpected = {spaceName: "spaces/s1", fileId: "f1", somethingNew: "x"};
    SmartNotesInfoResponse|error info = unexpected.cloneWithType();
    test:assertTrue(info is error);
}

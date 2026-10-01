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

# Test that the watch recognises Echo meetings by the add-on's shared marker or the older addOn type.
@test:Config {groups: ["calendar-watch"]}
function isEchoMeetingTest() {
    json addOnEvent = {conferenceData: {conferenceSolution: {key: {'type: "addOn"}}}};
    test:assertTrue(isEchoMeeting(addOnEvent), "addOn conference should be tracked");

    json armedMeetEvent = {
        conferenceData: {conferenceSolution: {key: {'type: "hangoutsMeet"}}},
        extendedProperties: {shared: {echo_armed: "true"}}
    };
    test:assertTrue(isEchoMeeting(armedMeetEvent), "hangoutsMeet with echo_armed should be tracked");

    json plainMeetEvent = {conferenceData: {conferenceSolution: {key: {'type: "hangoutsMeet"}}}};
    test:assertFalse(isEchoMeeting(plainMeetEvent), "plain hangoutsMeet should be skipped");

    json privateMarkerEvent = {
        conferenceData: {conferenceSolution: {key: {'type: "hangoutsMeet"}}},
        extendedProperties: {'private: {echo_armed: "true"}}
    };
    test:assertFalse(isEchoMeeting(privateMarkerEvent), "only the SHARED marker counts");

    json falseMarkerEvent = {
        conferenceData: {conferenceSolution: {key: {'type: "hangoutsMeet"}}},
        extendedProperties: {shared: {echo_armed: "false"}}
    };
    test:assertFalse(isEchoMeeting(falseMarkerEvent), "echo_armed must be exactly \"true\"");

    json noConferenceEvent = {summary: "lunch"};
    test:assertFalse(isEchoMeeting(noConferenceEvent), "event without a conference should be skipped");
}

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
import meet_app.calendar;

import ballerina/log;
import ballerina/task;
import ballerina/uuid;

// Google's own docs for Events.watch are explicit that there's no "renew" call -- a
// channel just has to be replaced with a brand new one (a fresh channelId) before it
// expires, and don't publicly document the exact expiration length. Renewing daily is
// comfortably inside any reasonable limit, and re-registering is a cheap, harmless
// operation -- there's no downside to doing it more often than strictly necessary.
configurable string calendarWatchWebhookUrl = ?;
configurable decimal calendarWatchRenewalIntervalSeconds = 86400;
configurable string calendarWatchChannelIdPrefix = ?;

class CalendarWatchRenewalJob {
    *task:Job;

    public function execute() {
        string channelId = string `${calendarWatchChannelIdPrefix}-${uuid:createType4AsString()}`;
        string webhookUrl = string `${calendarWatchWebhookUrl}/calendar-watch`;
        error? result = calendar:watchCalendar(webhookUrl, channelId, calendarWatchToken);
        if result is error {
            log:printError("Scheduled Calendar watch renewal failed.", result);
        }
    }
}

function init() returns error? {
    _ = check task:scheduleJobRecurByFrequency(new CalendarWatchRenewalJob(), calendarWatchRenewalIntervalSeconds);
}

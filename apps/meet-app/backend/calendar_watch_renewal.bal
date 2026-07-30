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
import ballerina/time;
import ballerina/uuid;

// Google's own docs for Events.watch don't publish a fixed channel lifetime -- rather than
// guess at a fixed renewal interval, each registration returns its own real expiration
// time, and this job reschedules itself based on that actual value every time.
configurable string calendarWatchWebhookUrl = ?;
configurable string calendarWatchChannelIdPrefix = ?;

// How long before a channel's real expiration to renew it, and how soon to retry if a
// renewal attempt itself fails.
const decimal RENEWAL_SAFETY_MARGIN_SECONDS = 3600;
const decimal RETRY_DELAY_SECONDS = 300;

// The currently-active channel's details, so the next renewal can stop it before
// registering its replacement -- otherwise the old channel would keep running alongside
// the new one until it eventually expired on its own. Kept as a single isolated record
// (rather than two separate variables) since Ballerina won't let one 'lock' block touch
// more than one independently-isolated module-level variable at a time.
isolated (readonly & record {|string channelId; string resourceId;|})? currentChannel = ();

class CalendarWatchRenewalJob {
    *task:Job;

    public function execute() {
        // Register the replacement before stopping the old channel -- stopping first would
        // leave no active watch at all if this registration then failed, until the retry
        // succeeded. Registering first preserves the brief overlap Google's docs recommend
        // when replacing a channel.
        string channelId = string `${calendarWatchChannelIdPrefix}-${uuid:createType4AsString()}`;
        string webhookUrl = string `${calendarWatchWebhookUrl}/calendar-watch`;
        calendar:WatchChannelResponse|error result = calendar:watchCalendar(webhookUrl, channelId, calendarWatchToken);
        if result is error {
            log:printError("Scheduled calendar watch renewal failed; retrying soon.", result);
            scheduleRenewal(RETRY_DELAY_SECONDS);
            return;
        }

        (readonly & record {|string channelId; string resourceId;|})? channelToStop;
        lock {
            channelToStop = currentChannel;
            currentChannel = {channelId: result.channelId, resourceId: result.resourceId}.cloneReadOnly();
        }
        if channelToStop is record {|string channelId; string resourceId;|} {
            error? stopResult = calendar:stopWatchChannel(channelToStop.channelId, channelToStop.resourceId);
            if stopResult is error {
                log:printError("Failed to stop the previous calendar watch channel; it'll just expire on its own.",
                        stopResult);
            }
        }

        int|error expirationEpochMillis = int:fromString(result.expiration);
        if expirationEpochMillis is error {
            log:printError("Calendar watch channel expiration wasn't a valid number; retrying in a day.",
                    expirationEpochMillis);
            scheduleRenewal(86400);
            return;
        }

        decimal secondsUntilExpiration = <decimal>expirationEpochMillis / 1000.0d - <decimal>time:utcNow()[0];
        decimal delaySeconds = secondsUntilExpiration - RENEWAL_SAFETY_MARGIN_SECONDS;
        // Never schedule sooner than the retry delay, even if the safety margin would
        // otherwise put the next run in the past (a very short-lived channel) or absurdly
        // soon.
        if delaySeconds < RETRY_DELAY_SECONDS {
            delaySeconds = RETRY_DELAY_SECONDS;
        }
        scheduleRenewal(delaySeconds);
    }
}

isolated function scheduleRenewal(decimal delaySeconds) {
    time:Utc nextRun = time:utcAddSeconds(time:utcNow(), delaySeconds);
    time:Civil nextRunCivil = time:utcToCivil(nextRun);
    task:JobId|task:Error scheduleResult = task:scheduleOneTimeJob(new CalendarWatchRenewalJob(), nextRunCivil);
    if scheduleResult is task:Error {
        log:printError("Failed to schedule the next calendar watch renewal.", scheduleResult);
    }
}

function init() returns error? {
    scheduleRenewal(0);
}

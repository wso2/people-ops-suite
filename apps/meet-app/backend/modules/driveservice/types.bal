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

# [Configurable] OAuth2 entity application configuration.
type Oauth2Config record {|
    # OAuth2 token endpoint
    string tokenUrl;
    # OAuth2 client ID
    string clientId;
    # OAuth2 client secret
    string clientSecret;
|};

# Retry config for the drive-service client.
public type DriveServiceRetryConfig record {|
    # Retry count
    int count = RETRY_COUNT;
    # Retry interval
    decimal interval = RETRY_INTERVAL;
    # Retry backOff factor
    float backOffFactor = RETRY_BACKOFF_FACTOR;
    # Retry max interval
    decimal maxWaitInterval = RETRY_MAX_INTERVAL;
|};

# Response from resolving a recording to its space and Drive file.
#
# + spaceName - Resource name of the Meet space (e.g. `spaces/abc123`)
# + fileId - Drive file ID of the recording
public type RecordingInfoResponse record {|
    string spaceName;
    string fileId;
|};

# Response from resolving a transcript to its space and Drive (Google Doc) file.
#
# + spaceName - Resource name of the Meet space (e.g. `spaces/abc123`)
# + fileId - Drive file ID (Google Doc) of the transcript
public type TranscriptInfoResponse record {|
    string spaceName;
    string fileId;
|};

# Response from resolving smart notes to its space and Drive (Google Doc) file, separate
# from the transcript's.
#
# + spaceName - Resource name of the Meet space (e.g. `spaces/abc123`)
# + fileId - Drive file ID (Google Doc) of the smart notes
public type SmartNotesInfoResponse record {|
    string spaceName;
    string fileId;
|};

# Outcome of granting access to one email.
#
# + email - The email a grant was attempted for
# + granted - Whether the grant succeeded
# + 'error - Failure reason, if it didn't
public type GrantResult record {|
    string email;
    boolean granted;
    string 'error?;
|};

# Response from a grant-access request.
#
# + results - Per-email outcome
public type GrantAccessResponse record {|
    GrantResult[] results;
|};

# One utterance in a transcript, ready for a UI to render and seek to.
#
# + speaker - Participant's display name, resolved by drive-service from the conference's
# participant list; falls back to the participant resource name when Meet had no name
# + text - What was said
# + offsetSeconds - Where the line sits in the RECORDING, which is what a player seeks to.
# Approximate: see drive-service's ListTranscript for the anchor it rests on
# + startTime - Absolute instant the line began, kept so a caller that knows better where
# the recording started can redo the arithmetic
# + endTime - Absolute instant the line ended
public type TranscriptLine record {|
    string speaker;
    string text;
    decimal offsetSeconds;
    string startTime;
    string endTime;
|};

# A whole conversation.
#
# + lines - The utterances, in order
public type TranscriptResponse record {|
    TranscriptLine[] lines;
|};

# A Google Doc's contents as plain text.
#
# + text - The document body
public type DocumentTextResponse record {|
    string text;
|};

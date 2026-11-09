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

# Response from resolving a recording, transcript or smart notes to its space and Drive file.
#
# A call can produce several of each -- every stop and restart is a new part -- so drive-service
# also says which call the part belongs to and when the part itself ran. Those three are
# optional: an older drive-service does not send them, and these closed records would refuse
# any field they did not declare, so they must be declared before drive-service sends them.
#
# + spaceName - Resource name of the Meet space (e.g. `spaces/abc123`)
# + fileId - Drive file ID (an MP4 for a recording, a Google Doc otherwise)
# + conferenceRecordName - The call, e.g. `conferenceRecords/abc123`
# + startTime - When this part started, RFC 3339; empty when Meet has not set it
# + endTime - When this part ended, RFC 3339; empty when Meet has not set it
public type ArtifactInfoResponse record {|
    string spaceName;
    string fileId;
    string conferenceRecordName?;
    string startTime?;
    string endTime?;
|};

# Response from resolving a recording to its space and Drive file.
public type RecordingInfoResponse ArtifactInfoResponse;

# Response from resolving a transcript to its space and Drive (Google Doc) file.
public type TranscriptInfoResponse ArtifactInfoResponse;

# Response from resolving smart notes to its space and Drive (Google Doc) file, separate
# from the transcript's.
public type SmartNotesInfoResponse ArtifactInfoResponse;

# One finished part of a call, from drive-service's space listing.
#
# + name - Meet's resource name, e.g. `conferenceRecords/abc/recordings/xyz`
# + fileId - Drive file ID
# + startTime - When the part started, RFC 3339; empty when unknown
# + endTime - When the part ended, RFC 3339; empty when unknown
public type Artifact record {|
    string name;
    string fileId;
    string startTime;
    string endTime;
|};

# One call on a Meet space and every finished part it produced.
#
# + conferenceRecordName - The call, e.g. `conferenceRecords/abc`
# + startTime - When the call started, RFC 3339
# + endTime - When the call ended, RFC 3339; empty while it runs
# + recordings - Its recordings
# + transcripts - Its transcripts
# + smartNotes - Its smart notes; may share a Google Doc with a transcript
public type CallArtifacts record {|
    string conferenceRecordName;
    string startTime;
    string endTime;
    Artifact[] recordings;
    Artifact[] transcripts;
    Artifact[] smartNotes;
|};

# drive-service's answer for a space's calls.
#
# + calls - The calls in the window
public type SpaceArtifactsResponse record {|
    CallArtifacts[] calls;
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

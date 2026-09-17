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

// Mints the short-lived tokens drive-service accepts on its streaming route.
//
// WHY A TOKEN AT ALL: a browser's `<video src="...">` makes a plain GET and cannot attach an
// Authorization header, so the Choreo gateway sees no credential and drive-service's normal
// protection is unavailable to it. The credential has to travel in the URL instead.
//
// THIS SERVICE OWNS THE DECISION. drive-service holds the Google credential and streams
// bytes; it has no idea what a meeting is or who may see one. That rule -- host, internal
// participant, or Sales admin -- lives here, beside the meeting row, and a token is simply
// that decision written down in a form drive-service can check without asking.
//
// THE FORMAT IS A CONTRACT with internal/playback/token.go in drive-service. Both sides
// build the same signing input; changing field order, separators, or the length-prefixing
// on either side invalidates every live token and silently breaks playback. The Go tests
// there pin the same properties these do.
import ballerina/crypto;
import ballerina/lang.array;
import ballerina/time;

# Token layout: b64url(fileId).b64url(subject).expiryUnix.b64url(mac)
const string SEPARATOR = ".";

# Base64url WITHOUT padding, matching Go's base64.RawURLEncoding.
#
# Ballerina's array:toBase64 emits standard base64 (`+`, `/`, `=` padding); the URL-safe
# alphabet swaps the first two and drops the third. Done by hand because there is no
# raw-url variant in the standard library, and a `+` reaching a query string would be
# decoded as a space by the receiver.
isolated function toBase64Url(byte[] input) returns string {
    string encoded = array:toBase64(input);
    string out = "";
    foreach string:Char c in encoded {
        if c == "+" {
            out += "-";
        } else if c == "/" {
            out += "_";
        } else if c != "=" {
            out += c;
        }
    }
    return out;
}

# The exact byte string both sides MAC over.
#
# Each variable-length field is prefixed with its BYTE length so the fields cannot be
# re-split: without it a file id ending in the separator could be made to sign identically
# to a different (fileId, subject) pair. `.toBytes().length()` rather than `.length()`
# because Go's `len()` counts bytes, and a non-ASCII subject would otherwise disagree
# across the two implementations.
isolated function signingInput(string fileId, string subject, int expiry) returns byte[] {
    string input = string `${fileId.toBytes().length()}:${fileId}|` +
        string `${subject.toBytes().length()}:${subject}|${expiry}`;
    return input.toBytes();
}

# Mints a token permitting `fileId` to be streamed to `subject` for `ttlSeconds`.
#
# On the TTL: playback is not one request but many range requests -- the browser buffers
# ahead and every seek is a new one. A token that expires mid-viewing therefore does not
# fail cleanly: what is already buffered keeps playing and the next range request is
# refused, which reaches the viewer as an unexplained stall. So this wants hours, not
# minutes, comfortably exceeding the longest recording anyone might sit through. The
# exposure that buys is narrow, because the token names one file and one person who was
# already entitled to it.
#
# + fileId - Drive file id of the recording
# + subject - Work email of the person the token is for
# + signingSecret - Shared with drive-service's PLAYBACK_SIGNING_SECRET
# + ttlSeconds - How long the token stays valid
# + return - The token, or an error if the HMAC could not be computed
public isolated function mintToken(string fileId, string subject, string signingSecret, int ttlSeconds)
    returns string|error {

    int expiry = time:utcNow()[0] + ttlSeconds;
    byte[] mac = check crypto:hmacSha256(signingInput(fileId, subject, expiry), signingSecret.toBytes());

    return string:'join(SEPARATOR,
        toBase64Url(fileId.toBytes()),
        toBase64Url(subject.toBytes()),
        expiry.toString(),
        toBase64Url(mac)
    );
}

# Builds the URL a `<video>` element can be pointed at.
#
# + baseUrl - drive-service's base URL, no trailing slash
# + fileId - Drive file id of the recording
# + token - A token minted for that same file
# + return - The full streaming URL
public isolated function playbackUrl(string baseUrl, string fileId, string token) returns string =>
    string `${baseUrl}/files/${fileId}/content?token=${token}`;

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

import ballerina/crypto;
import ballerina/test;

// CROSS-LANGUAGE CONTRACT.
//
// This service mints playback tokens; drive-service (Go) verifies them. The two share no
// code, so the only thing keeping them compatible is that both build the same signing
// input. This MAC was computed independently with openssl:
//
//   printf '8:file-abc|10:a@wso2.com|1800000000' \
//     | openssl dgst -sha256 -hmac 's3cret-shared' -binary | openssl base64 -A
//
// drive-service's internal/playback/token_test.go pins the SAME token and asserts it
// verifies there. Change field order, separators or the length prefixes on either side and
// one of the two fails -- rather than playback breaking silently in an environment nobody
// is watching.
@test:Config {}
function testSigningInputMatchesTheReferenceMac() returns error? {
    byte[] mac = check crypto:hmacSha256(
            signingInput("file-abc", "a@wso2.com", 1800000000),
            "s3cret-shared".toBytes());

    test:assertEquals(toBase64Url(mac), "LuBh3enleq6AUK7EzE45kO2G6lFltPgrAxudhUkP9-E",
            "signing input drifted from drive-service's — playback would break");
}

// The full token, exactly as drive-service expects to receive it.
@test:Config {}
function testTokenLayoutMatchesTheReference() returns error? {
    byte[] mac = check crypto:hmacSha256(
            signingInput("file-abc", "a@wso2.com", 1800000000),
            "s3cret-shared".toBytes());
    string token = string:'join(SEPARATOR,
            toBase64Url("file-abc".toBytes()),
            toBase64Url("a@wso2.com".toBytes()),
            "1800000000",
            toBase64Url(mac));

    test:assertEquals(token,
            "ZmlsZS1hYmM.YUB3c28yLmNvbQ.1800000000.LuBh3enleq6AUK7EzE45kO2G6lFltPgrAxudhUkP9-E");
}

// Base64url, not standard base64: a '+' reaching a query string is decoded as a space by
// the receiver, and '=' padding has to go for the same reason.
@test:Config {}
function testBase64UrlHasNoPaddingOrUnsafeCharacters() {
    // 0xFB 0xFF encodes to "+/8=" in standard base64 -- every character this must replace.
    string encoded = toBase64Url([0xFB, 0xFF]);
    test:assertEquals(encoded, "-_8");
    test:assertFalse(encoded.includes("+"));
    test:assertFalse(encoded.includes("/"));
    test:assertFalse(encoded.includes("="));
}

// Length prefixes stop a file id containing the separator from being re-split into a
// different (fileId, subject) pair that signs identically.
@test:Config {}
function testSeparatorInFieldsDoesNotCollide() returns error? {
    byte[] a = check crypto:hmacSha256(signingInput("file.abc", "sub", 1), "k".toBytes());
    byte[] b = check crypto:hmacSha256(signingInput("file", "abc.sub", 1), "k".toBytes());
    test:assertNotEquals(toBase64Url(a), toBase64Url(b));
}

// A minted token must be shaped the way the verifier splits it: four parts, expiry third.
@test:Config {}
function testMintProducesFourParts() returns error? {
    string token = check mintToken("file-abc", "a@wso2.com", "s3cret-shared", 3600);
    string[] parts = re `\.`.split(token);
    test:assertEquals(parts.length(), 4, "token must have four dot-separated parts");
}

@test:Config {}
function testPlaybackUrlShape() {
    test:assertEquals(
            playbackUrl("https://apis-stg-internal.wso2.com/x/drive-service/v1.0", "file-abc", "tok"),
            "https://apis-stg-internal.wso2.com/x/drive-service/v1.0/files/file-abc/content?token=tok");
}

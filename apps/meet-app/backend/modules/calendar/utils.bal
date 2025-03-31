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

# Replace the ${creatorEmail} placeholder with a mailto link.
#
# + message - Message with the creator email placeholder
# + creatorEmail - Event creator Email
# + return - Updated message with the creator email replaced by a mailto link
public isolated function replaceCreatorEmail(string message, string creatorEmail) returns string {
    // Regex pattern to find the ${creatorEmail} placeholder
    string:RegExp pattern = re `\$\{creatorEmail\}`;

    // Replace ${creatorEmail} with <a href="mailto:creatorEmail">creatorEmail</a>
    string result = pattern.replace(message, string `<a href="mailto:${creatorEmail}">${creatorEmail}</a>`);
    return result;
}

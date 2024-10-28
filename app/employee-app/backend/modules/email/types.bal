//
// Copyright (c) 2005-2024, WSO2 LLC.
//
// WSO2 Inc. licenses this file to you under the Apache License,
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
// 
import employee_app.types;

# [Configurable] Email configuration record.
public type EmailAlertConfig record {|
    # Sender email address
    string 'from;
    # Name of the sender
    string fromName?;
    # Email subject
    string subject;
|};

# [Configurable] Email alerting service configuration record.
public type EmailAlertOfferConfig record {|
    # Authorized app UUID provided by the Email service
    string uuid;
    # Sender email address
    string 'from;
    # ID of the email template
    string templateId;
|};

# Payload of the email alerting service.
public type EmailRecord record {
    # Application uuid
    string appUuid = "";
    # Recipient email(s) as string array
    string[] to;
    # CC'ed recipient email(s) as string array
    string[] cc = [];
    # Sender email
    string frm = "";
    # Email subject
    string subject;
    # Template id of the email body
    string templateId;
    # Content as key value pairs (keys are not case sensitive). Eg: {HEADER: "header", BODY: "This is the body"}
    map<string> contentKeyValPairs;
    # Attachments
    types:Document[] attachments = [];
};

# [Configurable] Sender configuration record.
public type SenderDetail record {|
    # Sender's name
    string name;
    # Sender's title
    string title;
|};

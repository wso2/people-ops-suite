// Copyright (c) 2024 WSO2 LLC. (https://www.wso2.com).
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
import leave_service.database;
import leave_service.employee;

# [Configurable] Choreo OAuth2 application configuration.
type ChoreoApp record {|
    # OAuth2 token endpoint
    string tokenUrl;
    # OAuth2 client ID
    string clientId;
    # OAuth2 client secret
    string clientSecret;
|};

# [Configurable] Email alerting service configuration record.
#
# + uuid - Authorized app UUID provided by the Email service
# + from - Email sender
# + templateId - ID of the email template
public type EmailAlertConfig record {|
    string uuid;
    string 'from;
    string templateId;
|};

# Email notification details record.
public type EmailNotificationDetails record {|
    # Email subject
    string subject;
    # Email body
    string body;
|};

# Employee record.
public type Employee record {|
    *employee:Employee;
|};

public type Month JANUARY|FEBRUARY|MARCH|APRIL|MAY|JUNE|JULY|AUGUST|SEPTEMBER|OCTOBER|NOVEMBER|DECEMBER;

# Payload for leave creation.
public type LeavePayload record {|
    *database:LeavePayload;
|};

# Leave entity record.
public type LeaveResponse record {|
    *database:LeaveResponse;
|};

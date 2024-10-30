// Copyright (c) 2024, WSO2 LLC.
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

# [Enum] Compensation type.
public enum CompensationType {
    NUMBER,
    CURRENCY,
    DATE,
    TEXT
}

# [Enum] Employee status.
public enum EmployeeStatus {
    ACTIVE = "Active",
    LEFT = "Left",
    MARKED\ LEAVER = "Marked leaver"
}

# [Enum] Gender
public enum Gender {
    FEMALE,
    MALE,
    OTHER
}

# [Enum] Employee Hiring Status.
public enum HiringStatus {
    SELECTED,
    OFFER_SENT,
    OFFER_ACCEPTED,
    OFFER_REJECTED,
    REQUEST_HIRING_DETAILS,
    HIRING_DETAILS_RECEIVED,
    CONTRACT_SENT,
    CONTRACT_REJECTED,
    CONTRACT_ACCEPTED,
    HIRING_MANAGER_ACKNOWLEDGED,
    GSHEET_ADDED,
    ONBOARDING_COMPLETED
}

# [Enum] Process Status.
public enum RecruitStatus {
    SELECTED,
    OFFER_SENT,
    OFFER_ACCEPTED,
    OFFER_REJECTED,
    REQUEST_HIRING_DETAILS,
    HIRING_DETAILS_RECEIVED,
    CONTRACT_SENT,
    CONTRACT_REJECTED,
    CONTRACT_ACCEPTED,
    HIRING_MANAGER_ACKNOWLEDGED,
    GSHEET_ADDED,
    ONBOARDING_COMPLETED
}

# [Enum] Role.
public enum Role {
    EMPLOYEE_APP_HIRING_MANAGER
}

//
// Copyright (c) 2005-2024, WSO2 LLC. (http://www.wso2.org) All Rights Reserved.
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

# [Enum] Actions.
public enum Action {
    ACCEPT = "accept",
    REJECT = "reject"
}

# [Enum] Compensation type.
public enum CompensationType {
    NUMBER,
    CURRENCY,
    DATE,
    TEXT
}

# [Enum] Employee Fields.
public enum EmployeeField {
    EMPLOYEE_ID = "employeeId",
    EMPLOYEE_EPF = "employeeEpf",
    EMPLOYEE_TITLE = "employeeTitle",
    FIRST_NAME = "firstName",
    LAST_NAME = "lastName",
    WORK_EMAIL = "workEmail",
    PERSONAL_EMAIL = "personalEmail",
    GENDER = "gender",
    PERSONAL_PHONE_NUMBER = "personalPhoneNumber",
    WORK_PHONE_NUMBER = "workPhoneNumber",
    START_DATE = "startDate",
    THUMBNAIL = "thumbnail",
    LAST_PROMOTED_DATE = "lastPromotedDate",
    COMPANY = "company",
    LOCATION = "location",
    CAREER_FUNCTION = "careerFunction",
    DESIGNATION = "designation",
    BUSINESS_UNIT = "businessUnit",
    TEAM = "team",
    UNIT = "unit",
    SUB_UNIT = "subUnit",
    EMPLOYEE_LEAD = "employeeLead",
    ADDITIONAL_LEAD = "additionalLead",
    EMPLOYMENT_TYPE = "employmentType",
    RESIGNATION_DATE = "resignationDate",
    RESIGNATION_REASON = "resignationReason",
    FINAL_DAY_IN_OFFICE = "finalDayInOffice",
    FINAL_DAY_OF_EMPLOYMENT = "finalDayOfEmployment",
    EMPLOYEE_STATUS = "employeeStatus",
    RELOCATION_STATUS = "relocationStatus",
    SUBORDINATE_COUNT = "subordinateCount",
    CREATED_BY = "createdBy",
    CREATED_ON = "createdOn",
    UPDATED_BY = "updatedBy",
    UPDATED_ON = "updatedOn"
}

# Employee status.
enum EmployeeStatus {
    ACTIVE = "Active",
    LEFT = "Left",
    MARKED\ LEAVER = "Marked leaver"
}

# [Enum] Employment type.
public enum EmploymentType {
    PERMANENT,
    INTERNSHIP,
    CONSULTANCY
}

# [Enum] Filter Function.
public enum FilterFunction {
    NONE = "",
    EQUALS = "Equals",
    CONTAINS = "Contains",
    STARTS_WITH = "Starts With",
    ENDS_WITH = "Ends With",
    GREATER_THAN = "Greater Than",
    LESS_THAN = "Less Than",
    BEFORE = "Before",
    AFTER = "After"
}

# [Enum] Sort Direction.
public enum SortDirection {
    ASC = "asc",
    DESC = "desc"
}

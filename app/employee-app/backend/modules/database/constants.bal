//
// Copyright (c) 2005-2010, WSO2 Inc. (http://www.wso2.org) All Rights Reserved.
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

const fieldMappings = {
    "employeeId": "e.employee_id",
    "employeeEpf": "e.employee_epf",
    "employeeTitle": "e.employee_title",
    "firstName": "e.employee_first_name",
    "lastName": "e.employee_last_name",
    "workEmail": "e.employee_work_email",
    "personalEmail": "e.employee_personal_email",
    "gender": "e.employee_gender",
    "personalPhoneNumber": "e.employee_personal_phone_number",
    "workPhoneNumber": "e.employee_work_phone_number",
    "startDate": "e.employee_start_date",
    "thumbnail": "e.employee_thumbnail",
    "lastPromotedDate": "e.employee_last_promoted_date",
    "company": "c.company_name",
    "location": "e.employee_location",
    "careerFunction": "cf.career_function",
    "designation": "d.designation",
    "businessUnit": "bu.business_unit_name",
    "team": "t.team_name",
    "unit": "u.unit_name",
    "subUnit": "su.sub_unit_name",
    "employeeLead": "e.employee_lead",
    "additionalLead": "e.employee_additional_lead",
    "employmentType": "et.employment_type_name",
    "resignationDate": "e.employee_resignation_date",
    "resignationReason": "e.employee_resignation_reason",
    "finalDayInOffice": "e.employee_final_day_in_office",
    "finalDayOfEmployment": "e.employee_final_day_of_employment",
    "employeeStatus": "e.employee_status",
    "relocationStatus": "e.employee_relocation_status",
    "subordinateCount": "e.employee_subordinate_count",
    "createdBy": "e.employee_created_by",
    "createdOn": "e.employee_created_on",
    "updatedBy": "e.employee_updated_by",
    "updatedOn": "e.employee_updated_on"
};

const functionMappings = {
    [EQUALS] : "=",
    [GREATER_THAN] : ">",
    [LESS_THAN] : "<",
    [CONTAINS] : "LIKE",
    [STARTS_WITH] : "LIKE",
    [ENDS_WITH] : "LIKE",
    [BEFORE] : "<",
    [AFTER] : ">"
};

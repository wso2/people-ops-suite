// Copyright (c) 2024 WSO2 LLC. (http://www.wso2.org).
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

public const JWT_ASSERTION_HEADER = "x-jwt-assertion";

// Errors
public const ERR_MSG_EMPLOYEE_PROCESSING_FAILED = "Error occurred while processing employee.";
public const ERR_MSG_EMPLOYEES_PROCESSING_FAILED = "Error occurred while processing employees.";
public const ERR_MSG_NO_JWT_TOKEN_PRESENT = "x-jwt-assertion header does not exist!";
public const ERR_MSG_EMPLOYEE_LOCATION_NOT_FOUND = "Employee location not found.";
public const ERR_MSG_EMPLOYEE_RETRIEVAL_FAILED = "Error occurred while retrieving employee.";
public const ERR_MSG_EMPLOYEES_RETRIEVAL_FAILED = "Error occurred while retrieving employes.";

// Database query related constants
public const DEFAULT_LIMIT = 1000;
public const DEFAULT_OFFSET = 10;

// Cache related constants
public const CACHE_DEFAULT_MAX_AGE = 1800.0d;
public const CACHE_CLEANUP_INTERVAL = 900.0d;

// Copyright (c) 2023, WSO2 LLC. (http://www.wso2.com). All Rights Reserved.
// 
// This software is the property of WSO2 LLC. and its suppliers, if any.
// Dissemination of any information or reproduction of any material contained
// herein in any form is strictly forbidden, unless permitted by WSO2 expressly.
// You may not alter or remove any copyright or other notice from copies of this content.

import CVScoreService.types;

import ballerina/log;
import ballerina/sql;

public isolated function getResumesByIdRange(int startId, int endId) returns types:Resume[]|error {

    sql:ParameterizedQuery query = `SELECT * FROM candidate_resumes WHERE id >= ${startId} AND id <= ${endId}`;
    stream<types:Resume, sql:Error?> resultStream = dbClient->query(query);

    types:Resume[] resumes =
        check from var 'resume in resultStream
        select 'resume;

    log:printDebug("Successfully retrieved transactions.");
    return resumes;
}

public isolated function getProjectsByIdRange(int startId, int endId) returns types:Project[]|error {

    sql:ParameterizedQuery query = `SELECT id, projects FROM candidate_resumes WHERE id >= ${startId} AND id <= ${endId}`;
    stream<types:Project, sql:Error?> resultStream = dbClient->query(query);

    types:Project[] projects =
        check from var 'project in resultStream
        select 'project;

    log:printDebug("Successfully retrieved transactions.");
    return projects;
}

public isolated function insertCandidate(types:Candidate data) returns int|error {
    // Construct the parameterized query for inserting candidate data
    sql:ParameterizedQuery query = `
        INSERT INTO candidate_resumes (
            full_name, email, phone, address, country,
            professional_links, skills, interests, languages,
            certifications, educations, experiences, projects
        ) VALUES (
            ${data.personal_info.full_name},
            ${data.personal_info.email},
            ${data.personal_info.phone},
            ${data.personal_info.address},
            ${data.personal_info.country},
            ${data.professional_links.toJsonString()},
            ${data.skills.toJsonString()},
            ${data.interests.toJsonString()},
            ${data.languages.toJsonString()},
            ${data.certifications.toJsonString()},
            ${data.educations.toJsonString()},
            ${data.experiences.toJsonString()},
            ${data.projects.toJsonString()}
        )
    `;
    
    // Execute the query and get the result
    sql:ExecutionResult result = check dbClient->execute(query);
    
    // Log success message
    log:printInfo("Candidate data inserted successfully with ID: " + result.lastInsertId.toString());
    
    // Return the last inserted ID
    return <int>result.lastInsertId;
}
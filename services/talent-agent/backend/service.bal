// Copyright (c) 2023, WSO2 LLC. (http://www.wso2.com). All Rights Reserved.
// 
// This software is the property of WSO2 LLC. and its suppliers, if any.
// Dissemination of any information or reproduction of any material contained
// herein in any form is strictly forbidden, unless permitted by WSO2 expressly.
// You may not alter or remove any copyright or other notice from copies of this content.

import ballerina/io;
import ballerina/http;

import CVScoreService.database;
import CVScoreService.types;

service http:Service / on new http:Listener(9096) {
    resource function post resumes(json[] resumes) returns string {
        foreach json resume in resumes {
            types:Candidate|error castedResume = resume.cloneWithType(types:Candidate);
            if castedResume is types:Candidate {
                int|error result = database:insertCandidate(castedResume);
                if result is error {
                    io:println("Error inserting candidate: ", result.toString());
                }
            } else {
                continue;
            }
        }
        return "Candidates inserted successfully.";
    }

    resource function get get_score(int startId, int endId, string[] prompts) returns http:Response | error | string {
        types:Project[]|error resumes = database:getProjectsByIdRange(startId, endId);
        http:Client|error ai = check new("http://127.0.0.1:8000");
        
        if resumes is types:Project[] && ai is http:Client {
            json|error resumesJson = resumes.cloneWithType(json);
            
            if resumesJson is json {
                map<json> request = {
                    "candidates": resumesJson,
                    "prompts": prompts
                };

                http:Request req = new;
                req.setJsonPayload(request);
                req.setHeader("Content-Type", "application/json");
                
                http:Response|error response = ai->post("/get_scores", request.toJson(), mediaType = "application/json");
                return response;
            }
        }
        return "";
    }
}

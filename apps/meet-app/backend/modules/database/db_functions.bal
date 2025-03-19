// Copyright (c) 2024, WSO2 LLC. (https://www.wso2.com). All Rights Reserved.
//
// This software is the property of WSO2 LLC. and its suppliers, if any.
// Dissemination of any information or reproduction of any material contained
// herein in any form is strictly forbidden, unless permitted by WSO2 expressly.
// You may not alter or remove any copyright or other notice from copies of this content.
import ballerina/sql;

# Fetch sample collections.
#
# + name - Name to filter  
# + 'limit - Limit of the response  
# + offset - Offset of the number of sample collection to retrieve
# + return - List of sample collections|Error
public isolated function fetchSampleCollections(string? name, int? 'limit, int? offset) returns SampleCollection[]|error {
    stream<SampleCollection, error?> resultStream = databaseClient->
            query(getSampleCollectionsQuery(name, 'limit, offset));

    SampleCollection[] sampleCollections = [];
    check from SampleCollection sampleCollection in resultStream
        do {
            sampleCollections.push(sampleCollection);
        };

    return sampleCollections;
}

# Fetch specific sample collection.
#
# + id - Identification of the sample collection
# + return - Sample collections|Error, if so
public isolated function fetchSampleCollection(int id) returns SampleCollection|error? {
    SampleCollection|sql:Error sampleCollection = databaseClient->queryRow(getSampleCollectionQuery(id));

    if sampleCollection is sql:Error && sampleCollection is sql:NoRowsError {
        return;
    }
    return sampleCollection;
}

# Insert sample collection.
#
# + sampleCollection - Sample collection payload
# + createdBy - Person who created the sample collection
# + return - Id of the sample collection|Error
public isolated function addSampleCollection(AddSampleCollection sampleCollection, string createdBy) returns int|error {
    sql:ExecutionResult|error executionResults = databaseClient->execute(addSampleCollectionQuery(sampleCollection, createdBy));
    if executionResults is error {
        return executionResults;
    }

    return <int>executionResults.lastInsertId;
}

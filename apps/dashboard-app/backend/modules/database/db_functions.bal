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

    return from SampleCollection sampleCollection in resultStream
        select {
            ...sampleCollection
        };
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

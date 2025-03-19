// Copyright (c) 2024, WSO2 LLC. (https://www.wso2.com). All Rights Reserved.
//
// This software is the property of WSO2 LLC. and its suppliers, if any.
// Dissemination of any information or reproduction of any material contained
// herein in any form is strictly forbidden, unless permitted by WSO2 expressly.
// You may not alter or remove any copyright or other notice from copies of this content.
import ballerina/sql;

# Build query to add a sample collection.
#
# + sampleCollection - sample collection to be added
# + createdBy - The user who is adding the sample collection
# + return - sql:ParameterizedQuery - Insert query for the sample collection table
isolated function addSampleCollectionQuery(AddSampleCollection sampleCollection, string createdBy)
    returns sql:ParameterizedQuery =>
`
    INSERT INTO sample_collection
    (
        sample_collection_name, 
        sample_collection_created_by, 
        sample_collection_updated_by
    )
    VALUES
    (
        ${sampleCollection.name}, 
        ${createdBy}, 
        ${createdBy}
    )
`;

# Build query to retrieve sample collections.
#
# + name - Name to filter  
# + 'limit - Limit of the data  
# + offset - offset of the query
# + return - sql:ParameterizedQuery - Select query for the sample_collection table
isolated function getSampleCollectionsQuery(string? name, int? 'limit, int? offset) returns sql:ParameterizedQuery {
    sql:ParameterizedQuery mainQuery = `
            SELECT 
                sample_collection_id AS 'id',
                sample_collection_name AS 'name',
                sample_collection_created_on AS 'createdOn',
                sample_collection_created_by AS 'createdBy',
                sample_collection_updated_on AS 'updatedOn',
                sample_collection_updated_by AS 'updatedBy'
            FROM 
                sample_schema.sample_collection
    `;

    // Setting the filters based on the sample collection object.
    sql:ParameterizedQuery[] filters = [];

    if name is string {
        filters.push(sql:queryConcat(`sample_collection_name LIKE `, `${name}`));
    }

    mainQuery = buildSqlSelectQuery(mainQuery, filters);

    // Setting the limit and offset.
    if 'limit is int {
        mainQuery = sql:queryConcat(mainQuery, ` LIMIT ${'limit}`);
        if offset is int {
            mainQuery = sql:queryConcat(mainQuery, ` OFFSET ${offset}`);
        }
    } else {
        mainQuery = sql:queryConcat(mainQuery, ` LIMIT 1000`);
    }

    return mainQuery;
}

# Build query to retrieve sample collection.
#
# + id - Identification of the sample collection
# + return - sql:ParameterizedQuery - Select query for the sample_collection table
isolated function getSampleCollectionQuery(int id) returns sql:ParameterizedQuery =>
`
    SELECT 
        sample_collection_id AS 'id',
        sample_collection_name AS 'name',
        sample_collection_created_on AS 'createdOn',
        sample_collection_created_by AS 'createdBy',
        sample_collection_updated_on AS 'updatedOn',
        sample_collection_updated_by AS 'updatedBy'
    FROM 
        sample_schema.sample_collection
    WHERE
        sample_collection_id = ${id}
`;

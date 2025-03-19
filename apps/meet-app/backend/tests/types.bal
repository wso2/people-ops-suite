// Copyright (c) 2024, WSO2 LLC. (https://www.wso2.com). All Rights Reserved.
//
// This software is the property of WSO2 LLC. and its suppliers, if any.
// Dissemination of any information or reproduction of any material contained
// herein in any form is strictly forbidden, unless permitted by WSO2 expressly.
// You may not alter or remove any copyright or other notice from copies of this content. 

# Response type of post collection.
type PostCollectionResponseData record {|
    # Id of the collection
    int id;
    # Name
    string name;
    # Timestamp, when created
    string createdOn;
    # Person, who created
    string createdBy;
    # Timestamp, when updated
    string updatedOn;
    # Person, who updates
    string updatedBy;
|};

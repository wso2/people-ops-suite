-- Copyright (c) 2025 WSO2 LLC. (https://www.wso2.com).

-- WSO2 LLC. licenses this file to you under the Apache License,
-- Version 2.0 (the "License"); you may not use this file except
-- in compliance with the License.
-- You may obtain a copy of the License at

-- http://www.apache.org/licenses/LICENSE-2.0

-- Unless required by applicable law or agreed to in writing,
-- software distributed under the License is distributed on an
-- "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY
-- KIND, either express or implied.  See the License for the
-- specific language governing permissions and limitations
-- under the License.


CREATE SCHEMA `sample_schema` ;

USE `sample_schema`;

CREATE TABLE `sample_collection` (
  `sample_collection_id` int NOT NULL AUTO_INCREMENT,
  `sample_collection_name` blob,
  `sample_collection_created_on` timestamp(6) NOT NULL DEFAULT CURRENT_TIMESTAMP(6),
  `sample_collection_created_by` varchar(100) NOT NULL,
  `sample_collection_updated_on` timestamp(6) NOT NULL DEFAULT CURRENT_TIMESTAMP(6) ON UPDATE CURRENT_TIMESTAMP(6),
  `sample_collection_updated_by` varchar(100) NOT NULL,
  PRIMARY KEY (`sample_collection_id`)
);

LOCK TABLES `sample_collection` WRITE;
INSERT INTO `sample_collection` VALUES (1,_binary 'Collection 1','2024-07-03 10:19:09.236415','user@wso2.com','2024-07-03 10:19:09.236415','user@wso2.com'),(2,_binary 'Collection 2','2024-07-03 10:19:09.238862','user@wso2.com','2024-07-03 10:19:09.238862','user@wso2.com'),(3,_binary 'Collection 3','2024-07-03 10:19:09.239927','user@wso2.com','2024-07-03 10:19:09.239927','user@wso2.com'),(4,_binary 'Collection 4','2024-07-03 10:19:09.241920','user@wso2.com','2024-07-03 10:19:09.241920','user@wso2.com'),(5,_binary 'Collection 5','2024-07-03 10:19:09.243051','user@wso2.com','2024-07-03 10:19:09.243051','user@wso2.com');
UNLOCK TABLES;

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
INSERT INTO `sample_collection` VALUES (1,_binary 'Collection 1','2024-07-03 10:19:09.236415','user@wso2.com','2024-07-03 10:19:09.236415','user@wso2.com@wso2.com'),(2,_binary 'Collection 2','2024-07-03 10:19:09.238862','user@wso2.com','2024-07-03 10:19:09.238862','user@wso2.com'),(3,_binary 'Collection 3','2024-07-03 10:19:09.239927','user@wso2.com','2024-07-03 10:19:09.239927','user@wso2.com'),(4,_binary 'Collection 4','2024-07-03 10:19:09.241920','user@wso2.com','2024-07-03 10:19:09.241920','user@wso2.com'),(5,_binary 'Collection 5','2024-07-03 10:19:09.243051','user@wso2.com','2024-07-03 10:19:09.243051','user@wso2.com');
UNLOCK TABLES;

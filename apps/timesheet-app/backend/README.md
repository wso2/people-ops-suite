# Internal App Backend

## Version: 1

### /user\-info

#### GET

##### Summary:

Retrieve the logged in user's details.

##### Parameters

| Name | Located in | Description | Required | Schema |
| ---- | ---------- | ----------- | -------- | ------ |
| -    | -          | -           | -        | -      |

##### Responses

<table>
  <thead>
    <tr>
      <th>Code</th>
      <th>Description</th>
    </tr>
  </thead>
  <tbody>
    <tr>
      <td> 200 </td><td> Ok <br/>
  
  ```json
  {
    "employeeId": "LK01",
    "workEmail": "user@wso2.com",
    "firstName": "Jon",
    "lastName": "Smith",
    "jobRole": "Software Engineer",
    "employeeThumbnail": "https://abc.com"
  }
  ```
  </td>
    </tr>
    <tr>
      <td> 500 </td><td> Internal Server Error <br/>
  
  ```json
  {
    "message": "Error occurred while retrieving user data: user@wso2.com"
  }
  ```
  </td>
    </tr>
    </tr>
    <tr>
      <td> 400 </td><td> Bad Request <br/>
  
  ```json
  {
    "message": "assertion header does not exist!"
  }
  ```
  </td>
    </tr>
  </tbody>
</table>

### /collections

#### GET

##### Summary:

Fetch all the collections based on the filter criteria.

##### Parameters

| Name   | Located in | Description             | Required | Schema |
| ------ | ---------- | ----------------------- | -------- | ------ |
| name   | query      | Name of the collection. | No       | string |
| limit  | query      | Limit for the list.     | No       | int    |
| offset | query      | Offset for the list.    | No       | int    |

##### Responses

<table>
  <thead>
    <tr>
      <th>Code</th>
      <th>Description</th>
    </tr>
  </thead>
  <tbody>
    <tr>
      <td> 200 </td><td> Ok <br/>
  
  ```json
  {
    "count": 2,
    "collections": [
        {
            "id": 1,
            "name": "Collection 1",
            "createdOn": "2024-07-03 10:19:09.236415",
            "createdBy": "user@wso2.com",
            "updatedOn": "2024-07-11 06:10:24.148038",
            "updatedBy": "user@wso2.com"
        },
        {
            "id": 2,
            "name": "Collection 2",
            "createdOn": "2024-07-03 10:19:09.238862",
            "createdBy": "user@wso2.com",
            "updatedOn": "2024-07-03 10:19:09.238862",
            "updatedBy": "user@wso2.com"
        }
    ]
}
  ```
  </td>
    <tr>
      <td> 500 </td><td> Internal Server Error <br/>
  
  ```json
  {
    "message": "Error occurred while retrieving user data: user@wso2.com"
  }
  ```
  </td>
    </tr>
    </tr>
    <tr>
      <td> 400 </td><td> Bad Request <br/>
  
  ```json
  {
    "message": "assertion header does not exist!"
  }
  ```
  </td>
    </tr>
    <tr>
      <td> 403 </td><td> Forbidden <br/>
  
  ```json
  {
    "message": "Insufficient privileges!"
  }
  ```
  </td>
    </tr>
  </tbody>
</table>

### /collections

#### POST

##### Summary:

Create a new collection in the system.

##### Parameters

<table>
<thead>
  <tr>
    <th>Name</th>
    <th>Located in</th>
    <th>Description</th>
    <th>Required</th>
    <th>Schema</th>
  </tr>
</thead>
<tbody>
  <tr>
    <td>Input</td>
    <td>Payload</td>
    <td>Collection create type.</td>
    <td>Yes</td>
    <td>

```json
{
  "name": "Collection 5"
}
```

  </td>
    </tr>
  </tbody>
</table>

##### Responses

<table>
  <thead>
    <tr>
      <th>Code</th>
      <th>Description</th>
    </tr>
  </thead>
  <tbody>
    <tr>
      <td>201</td>
      <td>Created<br/>
  
  ```json
  {
    "id": 6,
    "name": "Collection 5",
    "createdOn": "2024-07-11 06:37:03.190918",
    "createdBy": "user@wso2.com",
    "updatedOn": "2024-07-11 06:37:03.190918",
    "updatedBy": "user@wso2.com"
  }
  ```
  </td>
    </tr>
    <tr>
      <td> 500 </td><td> Internal Server Error <br/>
  
  ```json
  {
    "message": "Error occurred while adding sample collection!"
  }
  ```
  </td>
    </tr>
    </tr>
    <tr>
      <td> 400 </td><td> Bad Request <br/>
  
  ```json
  {
    "message": "assertion header does not exist!"
  }
  ```
  </td>
    </tr>
    <tr>
      <td> 403 </td><td> Forbidden <br/>
  
  ```json
  {
    "message": "Insufficient privileges!"
  }
  ```
  </td>
    </tr>
  </tbody>
</table>

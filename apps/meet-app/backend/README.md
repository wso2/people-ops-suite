# Meet App Backend

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
    "workEmail": "user1@example.com",
    "firstName": "User",
    "lastName": "1",
    "jobRole": "Software Engineer",
    "employeeThumbnail": "https://example.com/thumbnails/user",
    "privileges": [
      123,
      456
    ]
  }
  ```
  </td>
    </tr>
    <tr>
      <td> 500 </td><td> Internal Server Error <br/>
  
  ```json
  {
    "message": "Error occurred while retrieving user data: user1@example.com"
  }
  ```
  </td>
    </tr>
    </tr>
  </tbody>
</table>

### /employees

#### GET

##### Summary:

Retrieve the list of internal employees.

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
  [
    {
      "firstName": "John",
      "lastName": "Doe",
      "workEmail": "john.doe@example.com",
      "employeeThumbnail": "https://example.com/thumbnails/john_doe"
    },
    {
      "firstName": "Jane",
      "lastName": "Smith",
      "workEmail": "jane.smith@example.com",
      "employeeThumbnail": "https://example.com/thumbnails/jane_smith"
    }
  ]

````
</td>
  </tr>
  <tr>
    <td> 500 </td><td> Internal Server Error <br/>

```json
{
  "message": "Error occurred while retrieving employees!"
}
````

  </td>
    </tr>
    </tr>
  </tbody>
</table>

### /meetings/types

#### GET

##### Summary:

Fetch the meeting types.

##### Parameters

| Name   | Located in | Description         | Required | Schema |
| ------ | ---------- | ------------------- | -------- | ------ |
| domain | query      | Name of the domain. | Yes      | string |

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
    "domain": "Sales",
    "types": [
        "Discovery Call",
        "Technical Call",
        "Demo Call",
        "POC Call",
        "Legal Chat",
        "Procurement Chat",
        "Pricing chat"
    ]
  }
  ```
  </td>
    <tr>
      <td> 500 </td><td> Internal Server Error <br/>
  
  ```json
  {
    "message": "Error occurred while retrieving the meeting types!"
  }
  ```
  </td>
    </tr>
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

### /meetings

#### POST

##### Summary:

Create a new meeting.

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
    <td>createCalendarEventRequest</td>
    <td>body</td>
    <td>Calendar event details</td>
    <td>Yes</td>
    <td>

```json
{
  "title": "Sample Meet",
  "description": "Sample Meet Description",
  "startTime": "2025-03-31T12:00:00.000Z",
  "endTime": "2025-03-31T13:00:00.000Z",
  "timeZone": "Asia/Colombo",
  "internalParticipants": ["user1@example.com"],
  "externalParticipants": ["user2@example.com"]
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
      <td> 200 </td><td> Ok <br/>

```json
{
  "message": "Meeting created successfully.",
  "meetingId": 123
}
```

</td>
  <tr>
    <td> 500 </td><td> Internal Server Error <br/>

```json
{
  "message": "Error occurred while creating the calendar event!"
}
```

  </td>
    </tr>
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

### /meetings

#### GET

##### Summary:

Fetch meetings based on filters.

##### Parameters

| Name                 | Located in | Description                          | Required | Schema |
| -------------------- | ---------- | ------------------------------------ | -------- | ------ |
| title                | query      | Title of the meeting to filter       | No       | string |
| host                 | query      | Host of the meeting                  | No       | string |
| startTime            | query      | Start time to filter                 | No       | string |
| endTime              | query      | End time to filter                   | No       | string |
| internalParticipants | query      | Participants to filter               | No       | string |
| limit                | query      | Limit the number of records returned | No       | int    |
| offset               | query      | Offset for pagination                | No       | int    |

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
  "meetings": [
    {
      "meetingId": 1,
      "title": "Sales Discovery Call",
      "googleEventId": "abcd1234",
      "host": "user1@example.com",
      "startTime": "2025-04-01 05:00:00",
      "endTime": "2025-04-01 06:00:00",
      "internalParticipants": ["user2@example.com", "user3@example.com"],
      "meetingStatus": "Active",
      "timeStatus": "Upcoming"
    },
    {
      "meetingId": 2,
      "title": "Technical Demo",
      "googleEventId": "abcd5678",
      "host": "user1@example.com",
      "startTime": "2025-04-01 06:00:00",
      "endTime": "2025-04-01 07:00:00",
      "internalParticipants": "user2@example.com",
      "meetingStatus": "ACTIVE",
      "timeStatus": "UPCOMING"
    }
  ]
  }
  ````
</td>
  <tr>
    <td> 500 </td><td> Internal Server Error <br/>

```json
{
  "message": "Error occurred while retrieving the meetings!"
}
```

  </td>
    </tr>
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

### /meetings/{meetingId}/attachments

#### GET

##### Summary:

Get attachments for a specific meeting.

##### Parameters

| Name      | Located in | Description           | Required | Schema |
| --------- | ---------- | --------------------- | -------- | ------ |
| meetingId | path       | The ID of the meeting | Yes      | int    |

##### Behavior

When this endpoint is called, the meeting host is granted editor access to the recording, if a recording is included in the attachments.

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
    "attachments": [
      {
        "fileUrl": "https://drive.google.com/open?id=exampleid1",
        "title": "Sales Discovery Call - User - 2025/03/06 13:00 GMT+05:30 - Recording",
        "mimeType": "video/mp4",
        "iconLink": "https://drive-thirdparty.googleusercontent.com/32/type/video/mp4",
        "fileId": "fileId1"
      },
      {
        "fileUrl": "https://drive.google.com/open?id=https://drive.google.com/open?id=exampleid2",
        "title": "Technical Demo - User - 2025/03/06 13:00 GMT+05:30 - Notes by Gemini",
        "mimeType": "application/vnd.google-apps.document",
        "iconLink": "https://drive-thirdparty.googleusercontent.com/32/type/application/vnd.google-apps.document",
        "fileId": "fileId2"
      }
    ]
  }
  ````

</td>
  <tr>
    <td> 500 </td><td> Internal Server Error <br/>

```json
{
  "message": "Error occurred while fetching the attachments!"
}
```

  </td>
    </tr>
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

### /meetings/{meetingId}

#### DELETE

##### Summary:

Delete a meeting by its ID.

##### Parameters

| Name      | Located in | Description                     | Required | Schema |
| --------- | ---------- | ------------------------------- | -------- | ------ |
| meetingId | path       | The ID of the meeting to delete | Yes      | int    |

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
      "message": "Calendar event deleted successfully."
````

</td>
  <tr>
    <td> 500 </td><td> Internal Server Error <br/>

```json
{
  "message": "Error occurred while deleting the meeting!"
}
```

  </td>
    </tr>
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

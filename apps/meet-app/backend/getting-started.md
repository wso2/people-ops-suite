## Getting Started

1. Clone the repo.

2. Rename following files

   - `config.toml.local` -> `config.toml`
   - `/tests/config.toml.local` -> `/tests/config.toml`

3. Add relevant configurations.

4. Set up the database locally using.

   - /resources/database.sql

5. Or connect to the dev database.

## Configuration samples

```toml
# App Configurations.
[meet_app]
    port = <Port number>

# Calendar Configurations.
[meet_app.calendar]
    calendarBaseUrl = "<Calendar Event Service URL>"
    calendarId = "<Calendar Account>"
    disclaimerMessage = "<Disclaimer Message>"
    [meet_app.calendar.oauthConfig]
        tokenUrl = "<Refresh URL>"
        clientId = "<Client ID of the Asgardeo app>"
        clientSecret = "<Client secret of the Asgardeo app>"

    [meet_app.calendar.retryConfig]
        count = 3
        interval = 3.0
        backOffFactor = 2.0
        maxWaitInterval = 20.0

# Entity Configurations.
[meet_app.entity]
    hrEntityBaseUrl = "<Entity URL>"
    [meet_app.entity.oauthConfig]
        tokenUrl = "<Refresh URL>"
        clientId = "<Client ID of the Asgardeo app>"
        clientSecret = "<Client secret of the Asgardeo app>"

    [meet_app.entity.retryConfig]
        count = <Retry count: 3>
        interval = <Retry interval: 3.0>
        backOffFactor = <Backoff factor: 2.0>
        maxWaitInterval = <Max waiting interval: 20.0>

# Database Configurations.
[meet_app.database.dbConfig]
    host = "<Database host>"
    user = "<Database user name>"
    password = "<Database password>"
    database = "<Schema name>"
    port = <Database port>
    [meet_app.database.dbConfig.connectionPool]
        maxOpenConnections = <Maximum open connections: 10>
        maxConnectionLifeTime = <Maximum connection lifetime: 100.0>
        minIdleConnections= <Maximum idle connections: 3>
    [meet_app.database.dbConfig.options]
        connectTimeout = <Connection timeout in: 10.0>
    [meet_app.database.dbConfig.options.ssl]
        mode = "PREFERRED"

# Authorization Configurations.
[meet_app.authorization.authorizedRoles]
    SALES_TEAM  = "<Asgardeo role mapped to this application role>"
    SALES_ADMIN = "<Asgardeo role mapped to this application role>"
```

## Execute

1. Add the required configurations for

   - config.toml

2. Make sure your local Ballerina version matches with the Ballerina version in the Ballerina.toml. Then you can simply run the service by

```ballerina
    bal run
```

## Test

You can write ballerina tests to test the code. You can find more details about the Ballerina tests [here](https://ballerina.io/learn/test-ballerina-code/test-a-simple-function/).
To run the test you need to have an Asgardeo ID token.

You can get a token from the sample Asgardeo app or using the webapp-template itself.

1. Get a token and configure it in,

   - /tests/Config.toml

```toml
    [meet_app]
    jwtKey = ""
```

## Important<sup style="color:red">\*</sup>

### Once you have updated the code,

1. Please make a copy of the `Config.toml` file.

2. Rename it `Config.toml.local` and remove all configs.

   Since we are not pushing the `config.toml` file to source control, this will keep track of the new configurations.

3. Set the `/test/config.toml` and `/test/config.toml.local` files. This is important when you have updated the configurations.

4. Write ballerina test cases for the new changes.

5. Run tests

   `bal test`

6. Generate the test report.

   `bal test --test-report`

7. Generate the code coverage report.

   `bal test --test-report --code-coverage`

8. Ensure all the tests are passed, before pushing the code to source control.

9. Ensure at least 80% test code coverage.

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
        count = <Retry count: 3>
        interval = <Retry interval: 3.0>
        backOffFactor = <Backoff factor: 2.0>
        maxWaitInterval = <Max waiting interval: 20.0>

# HR Entity Configurations.
[meet_app.people]
    hrEntityBaseUrl = "<HR Entity URL>"
    [meet_app.people.oauthConfig]
        tokenUrl = "<Refresh URL>"
        clientId = "<Client ID of the Asgardeo app>"
        clientSecret = "<Client secret of the Asgardeo app>"

    [meet_app.people.retryConfig]
        count = <Retry count: 3>
        interval = <Retry interval: 3.0>
        backOffFactor = <Backoff factor: 2.0>
        maxWaitInterval = <Max waiting interval: 20.0>

# Sales Entity Configurations.
[meet_app.sales]
    salesEntityBaseUrl = "<Sales Entity URL>"
    [meet_app.sales.oauthConfig]
        tokenUrl = "<Refresh URL>"
        clientId = "<Client ID of the Asgardeo app>"
        clientSecret = "<Client secret of the Asgardeo app>"

    [meet_app.sales.retryConfig]
        count = <Retry count: 3>
        interval = <Retry interval: 3.0>
        backOffFactor = <Backoff factor: 2.0>
        maxWaitInterval = <Max waiting interval: 20.0>

# Drive Configurations.
[meet_app.drive]
    driveBaseUrl = "<Drive Service URL>"
    [meet_app.drive.oauthConfig]
        refreshUrl = "<Refresh URL>"
        clientId = "<Client ID of the app>"
        clientSecret = "<Client secret of the app>"
        refreshToken = "<Refresh Token>"

    [meet_app.drive.retryConfig]
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

# Support Team Contacts
[meet_app.appConfig]
    # List of support teams and their corresponding email addresses.
    # Each entry must include:
    #   - team: The name of the support team.
    #   - email: The email address for the team.
    supportTeamEmails = [
        { team = "<Team name, e.g., Technical Issues>", email = "<Team email address>" },
        { team = "<Team name, e.g., Security Concerns>", email = "<Team email address>" },
        { team = "<Team name, e.g., Sales Enablement Matters>", email = "<Team email address>" }
    ]
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

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

import Grid from "@mui/material/Grid";
import { Container, Box } from "@mui/material";
import StateWithImage from "@component/ui/StateWithImage";

interface ErrorHandlerProps {
  message: string | null;
}

const ErrorHandler = (props: ErrorHandlerProps) => {
  return (
    <Box
      sx={{
        paddingX: 2,
        paddingY: 5,
      }}
    >
      <Container maxWidth="md">
        <Grid
          container
          direction="column"
          justifyContent="center"
          alignItems="center"
          gap={2}
        >
          <Grid item xs={12}>
            <img
              alt="logo"
              width="150"
              height="auto"
              src={require("@assets/images/wso2-logo.svg").default}
            />
          </Grid>
          <Grid item xs={12}>
            <StateWithImage
              message={
                props.message || "Something went wrong! Please try again later."
              }
              imageUrl={require("@assets/images/not-found.svg").default}
            />
          </Grid>
        </Grid>
      </Container>
    </Box>
  );
};

export default ErrorHandler;

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
import { Container, alpha, Paper, useTheme } from "@mui/material";
import { ErrorHandlerProps } from "@utils/types";
import StateWithImage from "@component/ui/StateWithImage";

const ErrorHandler = (props: ErrorHandlerProps) => {
  const theme = useTheme();
  return (
    <Paper
      variant="elevation"
      elevation={4}
      sx={{
        background: alpha(
          theme.palette.primary.main,
          theme.palette.action.hoverOpacity
        ),
        display: "flex",
        justifyContent: "center",
        borderRadius: 2,
        paddingY: 5,
        position: "relative",
        top: "15vh",
        m: "auto",
        maxWidth: "40vw",
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
              src={require("../../assets/images/wso2-logo.svg").default}
            ></img>
          </Grid>
          <Grid item xs={12}>
            <StateWithImage
              message={
                props.message || "Something went wrong! Please try again later."
              }
              imageUrl={require("../../assets/images/not-found.svg").default}
            />
          </Grid>
        </Grid>
      </Container>
    </Paper>
  );
};

export default ErrorHandler;

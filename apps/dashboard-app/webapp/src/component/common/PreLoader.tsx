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
import { Box, Container, LinearProgress, Typography } from "@mui/material";
import type { PreLoaderProps } from "@utils/types";

const PreLoader = (props: PreLoaderProps) => {
  return (
    <Box
      sx={{
        background: (theme) => theme.palette.background.default,
        display: "flex",
        flexDirection: "column",
        justifyContent: "center",
        height: "100vh",
      }}
    >
      <Container maxWidth="md">
        <Box>
          <Grid
            container
            direction="column"
            justifyContent="center"
            alignItems="center"
            spacing={2}
          >
            <Grid item xs={12}>
              {props.isLoading && (
                <LinearProgress
                  sx={{
                    width: "150px",
                  }}
                />
              )}
            </Grid>
            <Grid item xs={12}>
              <Typography
                variant="inherit"
                sx={{
                  fontSize: "14px",
                  fontWeight: 500,
                  color: (theme) =>
                    theme.palette.mode === "light"
                      ? theme.palette.common.black
                      : theme.palette.common.white,
                }}
              >
                {props.message}
              </Typography>
            </Grid>
          </Grid>
        </Box>
      </Container>
    </Box>
  );
};

export default PreLoader;

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
import { APP_NAME } from "@config/config";
import StateWithImage from "@component/ui/StateWithImage";
import { Box, Container, Paper, alpha, useTheme } from "@mui/material";
import CircularProgress, { circularProgressClasses, CircularProgressProps } from "@mui/material/CircularProgress";

interface PreLoaderProps {
  message: string | null;
  hideLogo?: boolean;
  isLoading?: boolean;
}

function CustomCircularProgress(props: CircularProgressProps) {
  return (
    <Box sx={{ position: "relative" }}>
      <CircularProgress
        variant="determinate"
        sx={{
          color: (theme) => theme.palette.grey[800],
        }}
        size={40}
        thickness={4}
        {...props}
        value={100}
      />
      <CircularProgress
        variant="indeterminate"
        disableShrink
        sx={{
          color: (theme) => theme.palette.primary.main,
          animationDuration: "550ms",
          position: "absolute",
          left: 0,
          [`& .${circularProgressClasses.circle}`]: {
            strokeLinecap: "round",
          },
        }}
        size={40}
        thickness={4}
        {...props}
      />
    </Box>
  );
}

const PreLoader = (props: PreLoaderProps) => {
  const theme = useTheme();
  return (
    <Paper
      elevation={4}
      sx={{
        background: alpha(theme.palette.primary.main, theme.palette.action.hoverOpacity),
        display: "flex",
        justifyContent: "center",
        borderRadius: 2,
        paddingY: 5,
        position: "relative",
        top: 60,
        m: "auto",
        maxWidth: "40vw",
      }}
    >
      <Container maxWidth="md">
        <Grid container direction="column" justifyContent="center" alignItems="center" gap={2}>
          <Grid item xs={12}>
            {!props.hideLogo && (
              <img alt="logo" width="150" height="auto" src={require("@assets/images/wso2-logo.svg").default} />
            )}
          </Grid>
          <Grid item xs={12}>
            <StateWithImage
              message={"Loading " + APP_NAME + " Data..."}
              imageUrl={require("@assets/images/loading.svg").default}
            />
          </Grid>
          <Grid item xs={12}>
            {props.isLoading && <CustomCircularProgress />}
          </Grid>
        </Grid>
      </Container>
    </Paper>
  );
};

export default PreLoader;

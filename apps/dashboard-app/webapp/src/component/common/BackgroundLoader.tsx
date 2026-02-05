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

import Backdrop from "@mui/material/Backdrop";
import CircularProgress from "@mui/material/CircularProgress";
import { Typography } from "@mui/material";
import LinearProgress, {
  LinearProgressProps,
} from "@mui/material/LinearProgress";
import Box from "@mui/material/Box";

const BackgroundLoader = (props: {
  open: boolean;
  message: string | null;
  linearProgress?: {
    total: number;
    completed: number;
    action?: () => void;
  };
}) => {
  return (
    <Backdrop
      sx={{
        color: "#fff",
        zIndex: (theme) => theme.zIndex.drawer + 1,
        display: "flex",
        flexDirection: "column",
      }}
      open={props.open}
    >
      {!props.linearProgress && (
        <>
          <CircularProgress color="inherit" />
          <Typography variant="h5" sx={{ marginTop: "20px" }}>
            {props.message}
          </Typography>
        </>
      )}
      {props.linearProgress && (
        <Box sx={{ width: "40%" }}>
          <LinearProgressWithLabel
            value={
              (props.linearProgress.completed / props.linearProgress.total) *
              100
            }
          />
          <Typography variant="h5" sx={{ marginTop: "20px" }}>
            {props.message}
          </Typography>
        </Box>
      )}
    </Backdrop>
  );
};

function LinearProgressWithLabel(
  props: LinearProgressProps & { value: number }
) {
  return (
    <Box sx={{ display: "flex", alignItems: "center" }}>
      <Box sx={{ width: "100%", mr: 1 }}>
        <LinearProgress variant="determinate" {...props} />
      </Box>
      <Box sx={{ minWidth: 35 }}>
        <Typography variant="body2" color="text.secondary">{`${Math.round(
          props.value
        )}%`}</Typography>
      </Box>
    </Box>
  );
}

export default BackgroundLoader;

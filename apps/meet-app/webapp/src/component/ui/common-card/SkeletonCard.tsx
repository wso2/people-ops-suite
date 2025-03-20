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

import {
  Avatar,
  Grid,
  Paper,
  Skeleton,
  Stack,
  Typography,
} from "@mui/material";
import EmailIcon from "@mui/icons-material/Email";
import LocationOnIcon from "@mui/icons-material/LocationOn";
import CallIcon from "@mui/icons-material/Call";

const SkeletonCard = () => {
  return (
    <Paper
      variant="outlined"
      sx={{
        borderRadius: 3,
        p: 2,
        mb: 2,
        borderLeft: 8,
        borderLeftColor: "divider",
      }}
    >
      <Stack flexDirection={"column"} sx={{ width: "100%" }}>
        <Stack
          flexDirection={"row"}
          sx={{ m: 0, width: "100%", alignItems: "center" }}
        >
          <Stack flexDirection={"row"} sx={{ alignItems: "center" }}>
            <Skeleton variant="circular">
              <Avatar sx={{ width: 70, height: 70 }} />
            </Skeleton>
            <Stack sx={{ ml: 3, alignItems: "left" }} gap={0.3}>
              <Typography variant="h5" sx={{ fontWeight: 650 }}>
                <Skeleton variant="text" width={250} />
              </Typography>

              <Stack flexDirection={"row"} gap={0.5}>
                <EmailIcon
                  sx={{
                    color: "primary.dark",
                    fontSize: 13,
                  }}
                />
                <Typography variant="body2" color="primary.dark">
                  <Skeleton variant="text" width={100} />
                </Typography>
              </Stack>
              <Stack flexDirection={"row"} gap={0.5}>
                <CallIcon
                  sx={{
                    color: "secondary.dark",
                    fontSize: 13,
                  }}
                />
                <Typography variant="body2" color="secondary.dark">
                  <Skeleton variant="text" width={100} />
                </Typography>
              </Stack>
              <Stack flexDirection={"row"} gap={0.5}>
                <LocationOnIcon
                  sx={{
                    color: "secondary.dark",
                    fontSize: 13,
                  }}
                />
                <Typography variant="body2" color="secondary.dark">
                  <Skeleton variant="text" width={100} />
                </Typography>
              </Stack>
            </Stack>
          </Stack>
          <Stack sx={{ ml: "auto" }}>
            <Stack
              flexDirection={"row"}
              gap={1.2}
              sx={{ ml: "auto", mb: 1.5 }}
              alignItems={"center"}
            >
              <Skeleton variant="circular" />
              <Skeleton variant="circular" />
              <Skeleton variant="circular" />
            </Stack>
            <Grid
              container
              flexDirection={"row"}
              sx={{ width: "auto", ml: "auto", mr: 1 }}
              gap={2}
            >
              <Skeleton
                variant="rectangular"
                sx={{ width: 140, height: 50, borderRadius: 3 }}
              />
              <Skeleton
                variant="rectangular"
                sx={{ width: 140, height: 50, borderRadius: 3 }}
              />
              <Skeleton
                variant="rectangular"
                sx={{ width: 140, height: 50, borderRadius: 3 }}
              />
              <Skeleton
                variant="rectangular"
                sx={{ width: 140, height: 50, borderRadius: 3 }}
              />
            </Grid>
          </Stack>
        </Stack>
      </Stack>
    </Paper>
  );
};

export default SkeletonCard;

// Copyright (c) 2024, WSO2 LLC. (https://www.wso2.com). All Rights Reserved.
//
// This software is the property of WSO2 LLC. and its suppliers, if any.
// Dissemination of any information or reproduction of any material contained
// herein in any form is strictly forbidden, unless permitted by WSO2 expressly.
// You may not alter or remove any copyright or other notice from copies of this content.

import { Avatar, Grid, Paper, Skeleton, Stack, Typography } from "@mui/material";
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
        <Stack flexDirection={"row"} sx={{ m: 0, width: "100%", alignItems: "center" }}>
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
            <Stack flexDirection={"row"} gap={1.2} sx={{ ml: "auto", mb: 1.5 }} alignItems={"center"}>
              <Skeleton variant="circular" />
              <Skeleton variant="circular" />
              <Skeleton variant="circular" />
            </Stack>
            <Grid container flexDirection={"row"} sx={{ width: "auto", ml: "auto", mr: 1 }} gap={2}>
              <Skeleton variant="rectangular" sx={{ width: 140, height: 50, borderRadius: 3 }} />
              <Skeleton variant="rectangular" sx={{ width: 140, height: 50, borderRadius: 3 }} />
              <Skeleton variant="rectangular" sx={{ width: 140, height: 50, borderRadius: 3 }} />
              <Skeleton variant="rectangular" sx={{ width: 140, height: 50, borderRadius: 3 }} />
            </Grid>
          </Stack>
        </Stack>
      </Stack>
    </Paper>
  );
};

export default SkeletonCard;

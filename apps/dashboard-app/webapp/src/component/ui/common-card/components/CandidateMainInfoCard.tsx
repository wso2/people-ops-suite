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

import React from "react";
import { Theme } from "@mui/material";
import { Grid, alpha, Typography, Stack } from "@mui/material";

interface CandidateMainInfoCardProps {
  title: string;
  subTitle: string;
  icon: React.ReactElement<any, string | React.JSXElementConstructor<any>>;
}

const CandidateMainInfoCard = ({
  title,
  subTitle,
  icon,
}: CandidateMainInfoCardProps) => {
  return (
    <Grid
      size={{ xs: 12 }}
      sx={{
        p: 1,
        bgcolor: (theme) =>
          alpha(
            theme.palette.primary.main,
            theme.palette.action.selectedOpacity
          ),
        borderColor: "primary.main",
        borderRadius: 2.5,
        display: "flex",
        flexDirection: "row",
        alignItems: "center",
      }}
      gap={1}
    >
      {React.cloneElement(icon, {
        sx: {
          bgcolor: (theme: Theme) => alpha(theme.palette.primary.main, 0.3),
          p: 0.4,
          fontSize: 25,
          borderRadius: 1,
          color: "primary.main",
        },
      })}

      <Stack gap={0.4}>
        <Typography sx={{ fontWeight: 600, fontSize: 10 }}>{title}</Typography>
        <Typography sx={{ fontWeight: 600, fontSize: 10 }} color="primary.dark">
          {subTitle}
        </Typography>
      </Stack>
    </Grid>
  );
};

export default CandidateMainInfoCard;

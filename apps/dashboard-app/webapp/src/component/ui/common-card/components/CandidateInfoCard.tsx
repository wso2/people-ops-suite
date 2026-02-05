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
import { Grid, Stack, Typography } from "@mui/material";

import React from "react";

interface CandidateInfoCardProps {
  title: string;
  items: CandidateInfoArray[];
}

interface CandidateInfoArray {
  title: string;
  subTitle?: string;
  icon: React.ReactElement<any, string | React.JSXElementConstructor<any>>;
}

const CandidateMainInfoCard = ({ title, items }: CandidateInfoCardProps) => {
  return (
    <Grid
      size={{ xs: 12 }}
      sx={{
        p: 2,
        border: 1,
        borderColor: "divider",
        borderRadius: 3,
        display: "flex",
        flexDirection: "column",
        gap: 2,
      }}
    >
      <Typography variant="h6" sx={{ fontWeight: 600 }} color="primary.dark">
        {title}
      </Typography>
      <Stack gap={1}>
        {items.map((item) => (
          <Stack key={item.title} flexDirection={"row"} gap={1}>
            {React.cloneElement(item.icon, {
              sx: {
                color: "secondary.dark",
                fontSize: 15,
              },
            })}
            <>
              <Typography
                variant="body2"
                color="secondary.main"
                sx={{
                  display: "flex",
                  flexDirection: "row",
                  gap: 1.5,
                  fontWeight: "bold",
                }}
              >
                {item.title} :
              </Typography>
              <Typography variant="body1" color="secondary.dark" sx={{ fontWeight: "bold" }}>
                {item.subTitle}
              </Typography>
            </>
          </Stack>
        ))}
      </Stack>
    </Grid>
  );
};

export default CandidateMainInfoCard;

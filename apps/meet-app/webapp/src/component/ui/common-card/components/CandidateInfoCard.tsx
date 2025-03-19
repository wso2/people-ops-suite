// Copyright (c) 2024, WSO2 LLC. (https://www.wso2.com). All Rights Reserved.
//
// This software is the property of WSO2 LLC. and its suppliers, if any.
// Dissemination of any information or reproduction of any material contained
// herein in any form is strictly forbidden, unless permitted by WSO2 expressly.
// You may not alter or remove any copyright or other notice from copies of this content.

import { Avatar, Card, CardContent, Grid, Paper, Stack, Theme, Typography, alpha } from "@mui/material";
import WorkIcon from "@mui/icons-material/Work";
import BadgeIcon from "@mui/icons-material/Badge";
import CalendarMonthIcon from "@mui/icons-material/CalendarMonth";
import React from "react";
import dayjs from "dayjs";

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
      item
      flex={1}
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
          <Stack flexDirection={"row"} gap={1}>
            {React.cloneElement(item.icon, {
              sx: {
                color: "secondary.dark",
                fontSize: 15,
              },
            })}

            <Typography
              variant="body2"
              color="secondary.main"
              sx={{ display: "flex", flexDirection: "row", gap: 1.5, fontWeight: "bold" }}
            >
              {item.title} :
              <Typography variant="body1" color="secondary.dark" sx={{ fontWeight: "bold" }}>
                {item.subTitle}
              </Typography>
            </Typography>
          </Stack>
        ))}
      </Stack>
    </Grid>
  );
};

export default CandidateMainInfoCard;

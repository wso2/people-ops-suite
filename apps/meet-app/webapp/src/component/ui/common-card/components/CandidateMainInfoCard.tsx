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

interface CandidateMainInfoCardProps {
  title: string;
  subTitle: string;
  icon: React.ReactElement<any, string | React.JSXElementConstructor<any>>;
}

const CandidateMainInfoCard = ({ title, subTitle, icon }: CandidateMainInfoCardProps) => {
  return (
    <Grid
      item
      sx={{
        p: 1,
        bgcolor: (theme) => alpha(theme.palette.primary.main, theme.palette.action.selectedOpacity),
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

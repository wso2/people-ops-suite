// Copyright (c) 2025, WSO2 LLC. (https://www.wso2.com). All Rights Reserved.
//
// This software is the property of WSO2 LLC. and its suppliers, if any.
// Dissemination of any information or reproduction of any material contained
// herein in any form is strictly forbidden, unless permitted by WSO2 expressly.
// You may not alter or remove any copyright or other notice from copies of this content.

import { Box, Typography } from "@mui/material";

export default function MaintenancePage() {
  return (
    <Box
      sx={{
        display: "flex",
        justifyContent: "center",
        alignItems: "center",
        flexDirection: "column",
        minHeight: "100vh",
      }}
    >
      <img alt="maintenance" src="/maintenance.gif" />
      <Typography variant="h4" style={{ color: "gray" }}>
        Exciting changes are on the way! Our website is currently undergoing a
        transformation to enhance your experience. Please check back soon to see
        the amazing updates.
      </Typography>
    </Box>
  );
}

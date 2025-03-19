// Copyright (c) 2024, WSO2 LLC. (https://www.wso2.com). All Rights Reserved.
//
// This software is the property of WSO2 LLC. and its suppliers, if any.
// Dissemination of any information or reproduction of any material contained
// herein in any form is strictly forbidden, unless permitted by WSO2 expressly.
// You may not alter or remove any copyright or other notice from copies of this content.

import { Backdrop, CircularProgress, useTheme } from "@mui/material";
import React from "react";

const BackdropProgress = ({ open }: any) => {
  const theme = useTheme();
  return (
    <Backdrop
      sx={{ zIndex: 500 + 1, color: theme.palette.secondary.contrastText }}
      open={open}
    >
      <CircularProgress />
    </Backdrop>
  );
};

export default BackdropProgress;

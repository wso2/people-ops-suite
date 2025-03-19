// Copyright (c) 2024, WSO2 LLC. (https://www.wso2.com). All Rights Reserved.
//
// This software is the property of WSO2 LLC. and its suppliers, if any.
// Dissemination of any information or reproduction of any material contained
// herein in any form is strictly forbidden, unless permitted by WSO2 expressly.
// You may not alter or remove any copyright or other notice from copies of this content.

import React from "react";
import { Grid, Typography } from "@mui/material";

function StateWithImage(props: {
  message: string;
  imageUrl: string;
  hideImage?: boolean;
}) {
  return (
    <Grid
      container
      direction="column"
      justifyContent="center"
      alignItems="center"
      sx={{ mt: 2 }}
      gap={2}
    >
      {!props.hideImage && (
        <Grid
          item
          xs={12}
          style={{
            display: "flex",
            justifyContent: "center",
          }}
        >
          <img alt="logo" width="120" height="auto" src={props.imageUrl}></img>
        </Grid>
      )}
      <Grid
        item
        xs={12}
        sx={{
          display: "flex",
          justifyContent: "center",
          mt: 2,
          color: (theme) => theme.palette.secondary.dark,
        }}
      >
        <Typography variant="h5">{props.message}</Typography>
      </Grid>
    </Grid>
  );
}

export default StateWithImage;

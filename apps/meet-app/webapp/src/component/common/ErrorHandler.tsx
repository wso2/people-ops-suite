// Copyright (c) 2024, WSO2 LLC. (https://www.wso2.com). All Rights Reserved.
//
// This software is the property of WSO2 LLC. and its suppliers, if any.
// Dissemination of any information or reproduction of any material contained
// herein in any form is strictly forbidden, unless permitted by WSO2 expressly.
// You may not alter or remove any copyright or other notice from copies of this content.

import Grid from "@mui/material/Grid";
import { Container, alpha, Paper, useTheme } from "@mui/material";
import { ErrorHandlerProps } from "../../types/types";
import StateWithImage from "@component/ui/StateWithImage";

const ErrorHandler = (props: ErrorHandlerProps) => {
  const theme = useTheme();
  return (
    <Paper
      variant="elevation"
      elevation={4}
      sx={{
        background: alpha(
          theme.palette.primary.main,
          theme.palette.action.hoverOpacity
        ),
        display: "flex",
        justifyContent: "center",
        borderRadius: 2,
        paddingY: 5,
        position: "relative",
        top: "15vh",
        m: "auto",
        maxWidth: "40vw",
      }}
    >
      <Container maxWidth="md">
        <Grid
          container
          direction="column"
          justifyContent="center"
          alignItems="center"
          gap={2}
        >
          <Grid item xs={12}>
            <img
              alt="logo"
              width="150"
              height="auto"
              src={require("../../assets/images/wso2-logo.svg").default}
            ></img>
          </Grid>
          <Grid item xs={12}>
            <StateWithImage
              message={
                props.message || "Something went wrong! Please try again later."
              }
              imageUrl={require("../../assets/images/not-found.svg").default}
            />
          </Grid>
        </Grid>
      </Container>
    </Paper>
  );
};

export default ErrorHandler;

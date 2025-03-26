// Copyright (c) 2025, WSO2 LLC. (https://www.wso2.com). All Rights Reserved.
//
// This software is the property of WSO2 LLC. and its suppliers, if any.
// Dissemination of any information or reproduction of any material contained
// herein in any form is strictly forbidden, unless permitted by WSO2 expressly.
// You may not alter or remove any copyright or other notice from copies of this content.

import Grid from "@mui/material/Grid";
import { Container, Box } from "@mui/material";
import StateWithImage from "@component/ui/StateWithImage";

interface ErrorHandlerProps {
  message: string | null;
}

const ErrorHandler = (props: ErrorHandlerProps) => {
  return (
    <Box
      sx={{
        paddingX: 2,
        paddingY: 5,
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
              src={require("@assets/images/wso2-logo.svg").default}
            />
          </Grid>
          <Grid item xs={12}>
            <StateWithImage
              message={
                props.message || "Something went wrong! Please try again later."
              }
              imageUrl={require("@assets/images/not-found.svg").default}
            />
          </Grid>
        </Grid>
      </Container>
    </Box>
  );
};

export default ErrorHandler;

// Copyright (c) 2024, WSO2 LLC. (https://www.wso2.com). All Rights Reserved.
//
// This software is the property of WSO2 LLC. and its suppliers, if any.
// Dissemination of any information or reproduction of any material contained
// herein in any form is strictly forbidden, unless permitted by WSO2 expressly.
// You may not alter or remove any copyright or other notice from copies of this content.

import Grid from "@mui/material/Grid";
import Typography from "@mui/material/Typography";
import { Box, Container, Button } from "@mui/material";

interface PreLoaderProps {
  message?: string | null;
  hideLogo?: boolean;
  action: () => void;
}

const StatusWithAction = (props: PreLoaderProps) => {
  return (
    <Box
      sx={{
        background: "#E7EBF0",
        display: "flex",
        pt: "20vh",
        flexDirection: "column",
        height: "100vh",
      }}
    >
      <Container maxWidth="md">
        <Box>
          <Grid
            container
            direction="column"
            justifyContent="center"
            alignItems="center"
            spacing={2}
          >
            <Grid item xs={12}>
              <img
                alt="logo"
                width="150"
                height="auto"
                src="https://wso2.cachefly.net/wso2/sites/images/brand/downloads/wso2-logo.png"
              ></img>
            </Grid>
            <Grid item xs={12}></Grid>

            <Grid item xs={12}>
              <Typography variant="h5">{props.message}</Typography>
            </Grid>
            <Grid item xs={12}></Grid>

            <Grid item xs={12}>
              <Button
                size="large"
                variant="contained"
                style={{ color: "#fff" }}
                color="success"
                onClick={() => props.action()}
              >
                SignIn
              </Button>
            </Grid>
          </Grid>
        </Box>
      </Container>
    </Box>
  );
};

export default StatusWithAction;

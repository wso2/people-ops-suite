// Copyright (c) 2024, WSO2 LLC. (https://www.wso2.com). All Rights Reserved.
//
// This software is the property of WSO2 LLC. and its suppliers, if any.
// Dissemination of any information or reproduction of any material contained
// herein in any form is strictly forbidden, unless permitted by WSO2 expressly.
// You may not alter or remove any copyright or other notice from copies of this content.

import { PreLoaderProps } from "../../types/types";
import Grid from "@mui/material/Grid";
import { Box, Container, Paper, alpha, useTheme } from "@mui/material";
import CircularProgress, {
  circularProgressClasses,
  CircularProgressProps,
} from "@mui/material/CircularProgress";
import { APP_NAME } from "@config/config";
import StateWithImage from "@component/ui/StateWithImage";

function CustomCircularProgress(props: CircularProgressProps) {
  return (
    <Box sx={{ position: "relative" }}>
      <CircularProgress
        variant="determinate"
        sx={{
          color: (theme) => theme.palette.grey[800],
        }}
        size={40}
        thickness={4}
        {...props}
        value={100}
      />
      <CircularProgress
        variant="indeterminate"
        disableShrink
        sx={{
          color: (theme) => theme.palette.primary.main,
          animationDuration: "550ms",
          position: "absolute",
          left: 0,
          [`& .${circularProgressClasses.circle}`]: {
            strokeLinecap: "round",
          },
        }}
        size={40}
        thickness={4}
        {...props}
      />
    </Box>
  );
}

const PreLoader = (props: PreLoaderProps) => {
  const theme = useTheme();

  return (
    <Paper
      variant="outlined"
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
        top: 60,
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
            {!props.hideLogo && (
              <img
                alt="logo"
                width="150"
                height="auto"
                src={require("../../assets/images/wso2-logo.svg").default}
              ></img>
            )}
          </Grid>
          <Grid item xs={12}>
            <StateWithImage
              message={"Loading " + APP_NAME + " Data..."}
              imageUrl={require("../../assets/images/loading.svg").default}
            />
          </Grid>
          <Grid item xs={12}>
            {props.isLoading && <CustomCircularProgress />}
          </Grid>
        </Grid>
      </Container>
    </Paper>
  );
};

export default PreLoader;

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

import Grid from "@mui/material/Grid";
import Typography from "@mui/material/Typography";
import {
  Box,
  Container,
  Card,
  CardContent,
  Divider,
  Stack,
} from "@mui/material";
import BackgroundImage from "@src/assets/images/app-login-background.png";
import ProductLogos from "@src/assets/images/app-login-logos.png";
import LoadingButton from "@mui/lab/LoadingButton";
import logo from "@src/assets/images/wso2-logo-black.png";
import { APP_NAME } from "@root/src/config/config";
import { APP_DESC } from "@root/src/config/constant";
import { useAppAuthContext } from "@root/src/context/AuthContext";

const LoginScreen = () => {
  const { appSignIn, appSignOut } = useAppAuthContext();

  return (
    <Box
      sx={{
        display: "flex",
        flexDirection: "column",
        width: "100vw",
        height: "100vh",
        justifyContent: "center",
        backgroundImage: `url(${BackgroundImage})`,
        backgroundRepeat: "no-repeat",
        backgroundPosition: "center",
      }}
    >
      <Container fixed maxWidth="xs">
        <Card
          elevation={24}
          sx={{
            borderRadius: 3,
            pt: 3,
            mx: 1,
            backgroundColor: "white",
          }}
        >
          <CardContent>
            <Box
              sx={{
                px: 1,
                backgroundColor: "white",
              }}
            >
              <Grid
                container
                direction="column"
                justifyContent="center"
                alignItems="center"
                spacing={2}
                p={1}
              >
                <Grid size={{ xs: 12 }}>
                  <img alt="logo" width="130" height="auto" src={logo}></img>
                </Grid>
                <Grid size={{ xs: 12 }}>
                  <Typography
                    align="center"
                    sx={{ fontWeight: "bold" }}
                    variant="h5"
                    color={"black"}
                  >
                    {APP_NAME}
                  </Typography>
                </Grid>
                <Grid size={{ xs: 12 }} sx={{ pb: 2 }}>
                  <Typography
                    align="center"
                    sx={{ fontSize: "1em" }}
                    color={"black"}
                    fontWeight={"400"}
                  >
                    {APP_DESC}
                  </Typography>
                </Grid>
                <Grid size={{ xs: 12 }}>
                  <LoadingButton
                    variant="contained"
                    color="primary"
                    sx={{ fontWeight: "bold" }}
                    onClick={() => {
                      appSignOut();

                      appSignIn();
                    }}
                  >
                    LOG IN
                  </LoadingButton>
                </Grid>
                <Grid size={{ xs: 12 }} mt={6}>
                  <Stack direction="column" spacing={2}>
                    <Typography align="center" color={"black"}>
                      Powered By
                    </Typography>
                    <Stack direction="row" spacing={2}>
                      <img height={22} alt="Product logos" src={ProductLogos} />
                    </Stack>
                  </Stack>
                </Grid>
                <Grid size={{ xs: 12 }} mt={3}>
                  <Typography
                    align="center"
                    color={"grey"}
                    sx={{ fontSize: "0.8em" }}
                  >
                    {/* {`© ${format(new Date(), "yyyy")} WSO2 LLC`} */}
                  </Typography>
                </Grid>
              </Grid>
            </Box>
          </CardContent>
          <Divider />
        </Card>
      </Container>
    </Box>
  );
};

export default LoginScreen;

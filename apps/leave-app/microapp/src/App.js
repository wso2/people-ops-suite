// Copyright (c) 2024 WSO2 LLC. (https://www.wso2.com).
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
import React, { useEffect, useState, useCallback } from "react";
import { useLocation } from "react-router-dom";
import { useDispatch, useSelector } from "react-redux";

import {
  Box,
  Button,
  Card,
  CardContent,
  CircularProgress,
  Container,
  Divider,
  Grid,
  ThemeProvider,
  Typography,
} from "@mui/material";

import { AuthProvider, Hooks, useAuthContext } from "@asgardeo/auth-react";

import Routes from "./routes";
import ScrollTop from "./components/ScrollTop";
import "./App.css";
import { APPLICATION_CONFIG, OAUTH_CONFIG } from "./config";
import {
  refreshToken,
  setIdToken,
  setRefreshTokenFunction,
  setSessionClearFunction,
} from "./components/webapp-bridge";
import {
  setAccessToken,
  setLogoutFunction,
  setUserName,
  setUserRoles,
  checkIfRolesExist,
} from "./utils/oauth";
import { createTheme } from "./themes";
import ConfirmationDialog from "./components/feedback/Dialog";
import { setIsAdmin } from "./store/reducers/menu";

const APP_NAME = "WSO2 Leave App";

const WebApp = () => {
  const {
    state,
    signIn,
    signOut,
    getBasicUserInfo,
    getIDToken,
    getDecodedIDToken,
    refreshAccessToken,
    getAccessToken,
    on,
  } = useAuthContext();
  const dispatch = useDispatch();

  const [, setHasAuthenticationErrors] = useState(false);
  const [, setHasLogoutFailureError] = useState();
  const [loadApp, setLoadApp] = useState(false);
  const [, setAuthenticateState] = useState(null);

  const getIsLoggedOut = () => {
    if (sessionStorage.getItem("isLoggedOut") === "true") {
      return true;
    } else {
      return false;
    }
  };

  const setIsLoggedOut = (value) => {
    sessionStorage.setItem("isLoggedOut", value);
  };

  const search = useLocation().search;
  const stateParam = new URLSearchParams(search).get("state");
  const errorDescParam = new URLSearchParams(search).get("error_description");

  const setIsInitLogin = (value) => {
    sessionStorage.setItem("isInitLogin", value);
  };

  const getIsInitLogin = () => {
    if (sessionStorage.getItem("isInitLogin") === "true") {
      return true;
    } else {
      return false;
    }
  };

  const setIsSessionTimeOut = (value) => {
    sessionStorage.setItem("isSessionTimeOut", value);
  };

  const sessionClearFn = () => {
    setLoadApp(false);
    setIsInitLogin("false");
    setIsSessionTimeOut("true");
    setIsLoggedOut("true");
  };

  const handleTokenRefresh = () => {
    return refreshAccessToken()
      .then(async (e) => {
        const idToken = await getIDToken();
        return idToken;
      })
      .catch((err) => {
        if (err) {
          signOut();
          throw err;
        }
      });
  };

  useEffect(() => {
    if (
      !getIsLoggedOut() &&
      !(state && (state.isLoading || state.isAuthenticated))
    ) {
      handleLogin();
    }
  }, [state.isLoading, state.isAuthenticated]);

  useEffect(() => {
    if (state && state.isAuthenticated) {
      setRefreshTokenFunction(handleTokenRefresh);
      setSessionClearFunction(sessionClearFn);

      const getUserData = async (callback) => {
        const basicUserInfo = await getBasicUserInfo();
        const idToken = await getIDToken();
        const accessToken = await getAccessToken();
        const decodedIDToken = await getDecodedIDToken();

        const authState = {
          authenticateResponse: basicUserInfo,
          idToken: idToken.split("."),
          decodedIdTokenHeader: JSON.parse(atob(idToken.split(".")[0])),
          decodedIDTokenPayload: decodedIDToken,
        };

        setIdToken(idToken);
        setAccessToken(accessToken);

        if (idToken) {
          refreshToken();
          if (callback) {
            callback();
          }
          if (basicUserInfo && basicUserInfo.email) {
            setUserName(basicUserInfo.email);
          }
          if (basicUserInfo && basicUserInfo.groups) {
            setUserRoles(basicUserInfo.groups);
            dispatch(
              setIsAdmin({
                isAdmin: checkIfRolesExist(
                  OAUTH_CONFIG.ADMIN_ROLES,
                  basicUserInfo.groups
                ),
              })
            );
          }
          setLoadApp(true);
        }

        setAuthenticateState(authState);
      };

      getUserData(() => {
        // initUserPrivileges(redirectToPathName()); TODO
      });
    }
  }, [state.isAuthenticated, state.isLoading]);

  useEffect(() => {
    if (stateParam && errorDescParam) {
      if (errorDescParam === "End User denied the logout request") {
        setHasLogoutFailureError(true);
      }
    }
  }, [stateParam, errorDescParam]);

  const handleLogin = useCallback(() => {
    setHasLogoutFailureError(false);
    signIn().catch(() => setHasAuthenticationErrors(true));
  }, [signIn]);

  const getIsSessionTimeOut = () => {
    if (sessionStorage.getItem("isSessionTimeOut") === "true") {
      return true;
    } else {
      return false;
    }
  };

  const handleLogout = () => {
    signOut();
  };

  /**
   * handles the error occurs when the logout consent page is enabled
   * and the user clicks 'NO' at the logout consent page
   */
  useEffect(() => {
    on(Hooks.SignOut, () => {
      setHasLogoutFailureError(false);
    });

    on(Hooks.SignOutFailed, () => {
      if (!errorDescParam) {
        handleLogin();
      }
    });
    setLogoutFunction(handleLogout);
  }, [on, handleLogin, handleLogout, errorDescParam]);

  return (
    <>
      {state.isAuthenticated && loadApp ? (
        <ScrollTop>
          <Routes />
        </ScrollTop>
      ) : getIsLoggedOut() ? (
        <Box
          sx={{
            backgroundColor: "background.default",
            display: "flex",
            flexDirection: "column",
            height: "100%",
            justifyContent: "center",
          }}
        >
          <Container maxWidth="md">
            <Card>
              <CardContent>
                <Box
                  sx={{
                    p: 2,
                  }}
                >
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
                    <Grid item xs={12} sx={{ pb: 2 }}>
                      <Typography variant="h3">{APP_NAME}</Typography>
                    </Grid>
                    {!(
                      getIsInitLogin() ||
                      state.isLoading ||
                      state.isAuthenticated
                    ) || getIsSessionTimeOut() ? (
                      <Grid item xs={12}>
                        <Button
                          id="login"
                          onClick={() => {
                            handleLogin();
                          }}
                          variant="contained"
                          color="secondary"
                          disabled={
                            (getIsInitLogin() ||
                              state.isLoading ||
                              state.isAuthenticated) &&
                            !getIsSessionTimeOut()
                          }
                        >
                          Log In
                        </Button>
                      </Grid>
                    ) : (
                      <Grid item xs={12}>
                        <Typography variant="caption">
                          <CircularProgress />
                        </Typography>
                      </Grid>
                    )}
                  </Grid>
                </Box>
              </CardContent>
              <Divider />
            </Card>
          </Container>
        </Box>
      ) : (
        <Box
          sx={{
            backgroundColor: "background.default",
            display: "flex",
            flexDirection: "column",
            height: "100%",
            justifyContent: "center",
          }}
        >
          <Container maxWidth="md">
            <Card>
              <CardContent>
                <Box
                  sx={{
                    p: 2,
                  }}
                >
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
                    <Grid item xs={12} sx={{ pb: 2 }}>
                      <Typography variant="h3">{APP_NAME}</Typography>
                    </Grid>

                    <Grid item xs={12}>
                      <Typography variant="caption">
                        <CircularProgress />
                      </Typography>
                    </Grid>
                  </Grid>
                </Box>
              </CardContent>
              <Divider />
            </Card>
          </Container>
        </Box>
      )}
    </>
  );
};

const MicroApp = () => {
  return (
    <>
      <ScrollTop>
        <Routes />
      </ScrollTop>
    </>
  );
};

const App = () => {
  const { isLoading, openBasicDialog, basicDialogInfo, basicDialogCallbackFn } =
    useSelector((state) => state.feedback);
  const theme = createTheme();

  useEffect(() => {}, [isLoading, openBasicDialog]);
  return (
    <ThemeProvider theme={theme}>
      {APPLICATION_CONFIG.isMicroApp ? (
        <MicroApp />
      ) : (
        <AuthProvider config={APPLICATION_CONFIG.authConfig}>
          <WebApp />
          <ConfirmationDialog
            isLoading={isLoading}
            open={openBasicDialog}
            message={basicDialogInfo.message}
            okCallback={basicDialogCallbackFn}
          />
        </AuthProvider>
      )}
    </ThemeProvider>
  );
};

export default App;

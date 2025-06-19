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

import { State } from "@utils/types";
import errorIcon from "@images/error.svg";
import Dialog from "@mui/material/Dialog";
import { Box, Button } from "@mui/material";
import { Messages } from "@config/constant";
import { APIService } from "@utils/apiService";
import PreLoader from "@component/common/PreLoader";
import DialogTitle from "@mui/material/DialogTitle";
import { setUserAuthData } from "@slices/authSlice";
import { getUserInfo } from "@slices/userSlice/user";
import DialogContent from "@mui/material/DialogContent";
import DialogActions from "@mui/material/DialogActions";
import StateWithImage from "@component/ui/StateWithImage";
import StatusWithAction from "@component/ui/StatusWithAction";
import React, { useContext, useEffect, useState } from "react";
import DialogContentText from "@mui/material/DialogContentText";
import { useAuthContext, SecureApp } from "@asgardeo/auth-react";
import { RootState, useAppDispatch, useAppSelector } from "@slices/store";

type AuthContextType = {
  appSignIn: () => void;
  appSignOut: () => void;
};
const AuthContext = React.createContext<AuthContextType>({} as AuthContextType);

const AppAuthProvider = (props: { children: React.ReactNode }) => {
  const [open, setOpen] = useState<boolean>(false);
  const [appState, setAppState] = useState<"logout" | "active" | "loading">("loading");

  const dispatch = useAppDispatch();
  const auth = useAppSelector((state: RootState) => state.auth);
  const userInfo = useAppSelector((state: RootState) => state.user);
  const userInfoState = useAppSelector((state: RootState) => state.user.state);

  const {
    state,
    signIn,
    signOut,
    getIDToken,
    isAuthenticated,
    getBasicUserInfo,
    getDecodedIDToken,
    refreshAccessToken,
  } = useAuthContext();

  useEffect(() => {
    var appStatus = localStorage.getItem("timesheet-app-state");

    if (!localStorage.getItem("timesheet-app-redirect-url")) {
      localStorage.setItem("timesheet-app-redirect-url", window.location.href.replace(window.location.origin, ""));
    }

    if (appStatus && appStatus === "logout") {
      setAppState("logout");
    } else {
      setAppState("active");
    }
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, []);

  useEffect(() => {
    const isSignInInitiated = localStorage.getItem("signInInitiated") === "true";
    if (state.isAuthenticated) {
      Promise.all([getBasicUserInfo(), getIDToken(), getDecodedIDToken()]).then(
        async ([userInfo, idToken, decodedIdToken]) => {
          dispatch(
            setUserAuthData({
              userInfo: userInfo,
              idToken: idToken,
              decodedIdToken: decodedIdToken,
            })
          );

          new APIService(idToken, refreshTokens);
          localStorage.setItem("signInInitiated", "false");
        }
      );
    } else if (!isSignInInitiated) {
      localStorage.setItem("signInInitiated", "true");
      signIn();
    }
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [state.isAuthenticated]);

  useEffect(() => {
    if (appState === "active") {
      if (state.isAuthenticated) {
        if (userInfo.state !== "loading") {
          const fetchData = async () => {
            await dispatch(getUserInfo());
          };
          fetchData();
        }
      } else {
        signIn();
      }
    } else if (appState === "loading") {
      <PreLoader isLoading={true} message={auth.statusMessage}></PreLoader>;
    }
  }, [auth.userInfo, appState]);

  const refreshTokens = () => {
    return new Promise<{ idToken: string }>(async (resolve) => {
      const userIsAuthenticated = await isAuthenticated();
      if (userIsAuthenticated) {
        resolve({ idToken: await getIDToken() });
      } else {
        refreshAccessToken()
          .then(async (_) => {
            const accessToken = await getIDToken();
            resolve({ idToken: accessToken });
          })
          .catch((_) => {
            appSignOut();
          });
      }
    });
  };

  const appSignOut = async () => {
    setAppState("loading");
    localStorage.setItem("timesheet-app-state", "logout");
    await signOut();
    setAppState("logout");
  };

  const appSignIn = async () => {
    setAppState("active");
    localStorage.setItem("timesheet-app-state", "active");
  };

  const authContext: AuthContextType = {
    appSignIn: appSignIn,
    appSignOut: appSignOut,
  };

  return (
    <>
      {appState === "loading" ? (
        <PreLoader isLoading={true} message="" />
      ) : (
        <>
          <Dialog
            open={open}
            onClose={() => setOpen(false)}
            aria-labelledby="alert-dialog-title"
            aria-describedby="alert-dialog-description"
          >
            <DialogTitle id="alert-dialog-title">{"Are you still there?"}</DialogTitle>
            <DialogContent>
              <DialogContentText id="alert-dialog-description">
                It looks like you've been inactive for a while. Would you like to continue?
              </DialogContentText>
            </DialogContent>
            <DialogActions>
              <Button onClick={() => setOpen(false)}>Continue</Button>
              <Button onClick={() => appSignOut()}>Logout</Button>
            </DialogActions>
          </Dialog>
          {appState === "active" ? (
            <AuthContext.Provider value={authContext}>
              {userInfoState === State.failed && (
                <Box height={"100vh"} width={"100%"} display={"flex"}>
                  <StateWithImage message={Messages.error.fetchEmployees} imageUrl={errorIcon} />
                </Box>
              )}
              {userInfoState === State.success && <SecureApp>{props.children}</SecureApp>}
              {userInfoState === State.loading && (
                <Box sx={{ width: "100%", height: "100%" }}>
                  <PreLoader isLoading={true} message={null} />
                </Box>
              )}
            </AuthContext.Provider>
          ) : (
            <StatusWithAction action={() => appSignIn()} />
          )}
        </>
      )}
    </>
  );
};

const useAppAuthContext = (): AuthContextType => useContext(AuthContext);

export { useAppAuthContext };

export default AppAuthProvider;

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
import Dialog from "@mui/material/Dialog";
import { Box, Button } from "@mui/material";
import { APIService } from "@utils/apiService";
import PreLoader from "@component/common/PreLoader";
import DialogTitle from "@mui/material/DialogTitle";
import { setUserAuthData } from "@slices/authSlice";
import { getUserInfo } from "@slices/userSlice/user";
import NoDataView from "@component/common/NoDataView";
import DialogContent from "@mui/material/DialogContent";
import DialogActions from "@mui/material/DialogActions";
import LoadingScreen from "@component/common/LoadingScreen";
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

  const { signIn, getIDToken, signOut, getDecodedIDToken, getBasicUserInfo, state } = useAuthContext();

  useEffect(() => {
    var appStatus = localStorage.getItem("hris-app-state");

    if (!localStorage.getItem("hris-app-redirect-url")) {
      localStorage.setItem("hris-app-redirect-url", window.location.href.replace(window.location.origin, ""));
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
    let isMounted = true;

    if (appState === "active") {
      if (state.isAuthenticated) {
        if (userInfo.state !== "loading") {
          Promise.all([dispatch(getUserInfo())]).catch((error) => {
            if (isMounted) {
              console.error("Error fetching data:", error);
            }
          });
        }
      } else {
        signIn();
      }
    } else if (appState === "loading") {
      <PreLoader isLoading={true} message={auth.statusMessage} />;
    }

    return () => {
      isMounted = false;
    };
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [auth.userInfo]);

  useEffect(() => {
    if (appState === "active") {
      if (state.isAuthenticated) {
        if (userInfoState === State.failed) {
          console.log(userInfo.state);
          console.log(userInfo.stateMessage);
        }
      }
    }
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [userInfo]);

  const refreshTokens = async () => {
    const idToken = await getIDToken();
    return { idToken: idToken };
  };

  const appSignOut = async () => {
    setAppState("loading");
    localStorage.setItem("hris-app-state", "logout");
    await signOut();
    setAppState("logout");
  };

  const appSignIn = async () => {
    setAppState("active");
    localStorage.setItem("hris-app-state", "active");
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
            <>
              {userInfoState === State.failed && (
                <Box sx={{ width: "100%", height: "90vh" }}>
                  <NoDataView message={userInfo.stateMessage || "No Data Found"} type="error" />
                </Box>
              )}
              {userInfoState === State.success && (
                <AuthContext.Provider value={authContext}>
                  <SecureApp>{props.children}</SecureApp>
                </AuthContext.Provider>
              )}
              {userInfoState === State.loading && (
                <Box sx={{ width: "100%", height: "100vh" }}>
                  <LoadingScreen message={userInfo.stateMessage || "Loading"} />
                </Box>
              )}
            </>
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

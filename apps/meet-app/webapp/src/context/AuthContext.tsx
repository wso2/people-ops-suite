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

import { Button } from "@mui/material";
import Dialog from "@mui/material/Dialog";
import { APIService } from "@utils/apiService";
import { useIdleTimer } from "react-idle-timer";
import DialogTitle from "@mui/material/DialogTitle";
import PreLoader from "@component/common/PreLoader";
import { getUserInfo } from "@slices/userSlice/user";
import DialogActions from "@mui/material/DialogActions";
import DialogContent from "@mui/material/DialogContent";
import StatusWithAction from "@component/ui/StatusWithAction";
import React, { useContext, useEffect, useState } from "react";
import DialogContentText from "@mui/material/DialogContentText";
import { useAuthContext, SecureApp } from "@asgardeo/auth-react";
import { loadPrivileges, setUserAuthData } from "@slices/authSlice/auth";
import { RootState, useAppDispatch, useAppSelector } from "@slices/store";

type AuthContextType = {
  appSignIn: () => void;
  appSignOut: () => void;
};
const AuthContext = React.createContext<AuthContextType>({} as AuthContextType);

const timeout = 1800_000;
const promptBeforeIdle = 4_000;

const AppAuthProvider = (props: { children: React.ReactNode }) => {
  const [open, setOpen] = useState<boolean>(false);
  const [appState, setAppState] = useState<"logout" | "active" | "loading">("loading");

  const dispatch = useAppDispatch();
  const auth = useAppSelector((state: RootState) => state.auth);
  const userInfo = useAppSelector((state: RootState) => state.user);

  const onPrompt = () => {
    appState === "active" && setOpen(true);
  };

  const { activate } = useIdleTimer({
    onPrompt,
    timeout,
    promptBeforeIdle,
    throttle: 500,
  });

  const handleContinue = () => {
    setOpen(false);
    activate();
  };

  const {
    signIn,
    signOut,
    getDecodedIDToken,
    getBasicUserInfo,
    refreshAccessToken,
    isAuthenticated,
    getIDToken,
    state,
  } = useAuthContext();

  useEffect(() => {
    var appStatus = localStorage.getItem("meet-app-state");

    if (!localStorage.getItem("meet-app-redirect-url")) {
      localStorage.setItem("meet-app-redirect-url", window.location.href.replace(window.location.origin, ""));
    }

    if (appStatus && appStatus === "logout") {
      setAppState("logout");
    } else {
      setAppState("active");
    }
  }, []);

  useEffect(() => {
    if (appState === "active") {
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
            new APIService(idToken, refreshToken);
          }
        );
      }
    }
  }, [appState, state.isAuthenticated]);

  useEffect(() => {
    if (appState === "active") {
      if (state.isAuthenticated) {
        if (userInfo.state !== "loading") {
          dispatch(getUserInfo()).then(() => {
            dispatch(loadPrivileges());
          });
        }
      } else {
        signIn();
      }
    } else if (appState === "loading") {
      <PreLoader isLoading={true} message={auth.statusMessage}></PreLoader>;
    }
  }, [auth.userInfo]);

  const refreshToken = () => {
    return new Promise<{ idToken: string }>(async (resolve) => {
      const userIsAuthenticated = await isAuthenticated();
      if (userIsAuthenticated) {
        resolve({ idToken: await getIDToken() });
      } else {
        refreshAccessToken()
          .then(async (res) => {
            const idToken = await getIDToken();
            resolve({ idToken: idToken });
          })
          .catch((error) => {
            appSignOut();
          });
      }
    });
  };

  const appSignOut = async () => {
    setAppState("loading");
    localStorage.setItem("meet-app-state", "logout");
    await signOut();
    setAppState("logout");
  };

  const appSignIn = async () => {
    setAppState("active");
    localStorage.setItem("meet-app-state", "active");
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
            onClose={handleContinue}
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
              <Button onClick={handleContinue}>Continue</Button>
              <Button onClick={() => appSignOut()}>Logout</Button>
            </DialogActions>
          </Dialog>
          {appState === "active" ? (
            <AuthContext.Provider value={authContext}>
              <SecureApp>{props.children}</SecureApp>
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

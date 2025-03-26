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

import { Suspense, useEffect, useState } from "react";
import { useSelector } from "react-redux";
import { Box, alpha } from "@mui/material";
import { useTheme } from "@mui/material/styles";
import CssBaseline from "@mui/material/CssBaseline";

import Header from "./header";
import Sidebar from "./sidebar";
import {
  Outlet,
  useLocation,
  useNavigate,
  matchRoutes,
} from "react-router-dom";
import { routes } from "../route";

import ConfirmationModalContextProvider from "@context/DialogContext";
import { selectUserInfo, selectRoles } from "@slices/authSlice";
import { useSnackbar } from "notistack";
import pJson from "../../package.json";
import { RootState, useAppSelector } from "@slices/store";
import { Typography } from "@mui/material";

export default function Layout() {
  //snackbar configuration
  const { enqueueSnackbar } = useSnackbar();
  const common = useAppSelector((state: RootState) => state.common);
  const navigate = useNavigate();
  useEffect(() => {
    if (common.timestamp != null) {
      enqueueSnackbar(common.message, {
        variant: common.type,
        preventDuplicate: true,
        anchorOrigin: { horizontal: "right", vertical: "bottom" },
      });
    }
  }, [common.timestamp]);

  useEffect(() => {
    if (localStorage.getItem("hris-app-redirect-url")) {
      navigate(localStorage.getItem("hris-app-redirect-url") as string);
      localStorage.removeItem("hris-app-redirect-url");
    }
  }, []);

  const location = useLocation();
  const matches = matchRoutes(routes, location.pathname);
  const theme = useTheme();

  const [open, setOpen] = useState(false);
  const roles = useSelector(selectRoles);

  return (
    <ConfirmationModalContextProvider>
      <Box sx={{ display: "flex" }}>
        <CssBaseline />

        <Sidebar
          roles={roles}
          currentPath={location.pathname}
          open={open}
          handleDrawer={() => setOpen(!open)}
          theme={theme}
        />
        <Header />

        <Box
          component="main"
          className="Hello"
          sx={{
            flexGrow: 1,
            height: "100vh",
            p: 3,
            pt: 9,
            pb: 6,
          }}
        >
          <Suspense fallback={<div>Loading...</div>}>
            <Outlet />
          </Suspense>
          <Box
            className="layout-note"
            sx={{
              background:
                theme.palette.mode === "light"
                  ? (theme) =>
                      alpha(
                        theme.palette.secondary.main,
                        theme.palette.action.activatedOpacity
                      )
                  : "#0d0d0d",
            }}
          >
            <Typography variant="h6" sx={{ color: "#919090" }}>
              v {pJson.version} | © {new Date().getFullYear()} WSO2 LLC
            </Typography>
          </Box>
        </Box>
      </Box>
    </ConfirmationModalContextProvider>
  );
}

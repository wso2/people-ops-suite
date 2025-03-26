// Copyright (c) 2025, WSO2 LLC. (https://www.wso2.com). All Rights Reserved.
//
// This software is the property of WSO2 LLC. and its suppliers, if any.
// Dissemination of any information or reproduction of any material contained
// herein in any form is strictly forbidden, unless permitted by WSO2 expressly.
// You may not alter or remove any copyright or other notice from copies of this content.

import { Suspense, useEffect, useState, useCallback } from "react";
import { useSelector } from "react-redux";
import { Box, alpha } from "@mui/material";
import { useTheme } from "@mui/material/styles";
import CssBaseline from "@mui/material/CssBaseline";
import Header from "./header";
import Sidebar from "./sidebar";
import { Outlet, useLocation, useNavigate } from "react-router-dom";
import { selectRoles } from "@slices/authSlice/auth";
import { useSnackbar } from "notistack";
import pJson from "../../package.json";
import { RootState, useAppSelector } from "@slices/store";
import { Typography } from "@mui/material";

export default function Layout() {
  const { enqueueSnackbar } = useSnackbar();
  const common = useAppSelector((state: RootState) => state.common);
  const navigate = useNavigate();
  const location = useLocation();
  const theme = useTheme();
  const [open, setOpen] = useState(false);
  const roles = useSelector(selectRoles);

  // Memoize enqueueSnackbar to prevent unnecessary re-renders
  const showSnackbar = useCallback(() => {
    if (common.timestamp != null) {
      enqueueSnackbar(common.message, {
        variant: common.type,
        preventDuplicate: true,
        anchorOrigin: { horizontal: "right", vertical: "bottom" },
      });
    }
  }, [common.message, common.type, common.timestamp, enqueueSnackbar]);

  // Show Snackbar Notifications
  useEffect(() => {
    showSnackbar();
  }, [showSnackbar]);

  // Handle Redirect After Login
  useEffect(() => {
    const redirectUrl = localStorage.getItem("sales-meet-app-redirect-url");
    if (redirectUrl) {
      navigate(redirectUrl);
      localStorage.removeItem("sales-meet-app-redirect-url");
    }
  }, [navigate]);

  return (
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
          pt: 7.5,
          pb: 4.5,
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
                : (theme) => alpha(theme.palette.common.black, 0.4),
          }}
        >
          <Typography variant="h6" sx={{ color: "#919090" }}>
            v {pJson.version} | © {new Date().getFullYear()} WSO2 LLC
          </Typography>
        </Box>
      </Box>
    </Box>
  );
}

// Copyright (c) 2026 WSO2 LLC. (https://www.wso2.com).
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
import {
  Avatar,
  Box,
  Menu,
  MenuItem,
  Stack,
  Tooltip,
  useMediaQuery,
  useTheme,
} from "@mui/material";
import Toolbar from "@mui/material/Toolbar";
import Typography from "@mui/material/Typography";

import React from "react";

import wso2LogoO from "@assets/images/wso2-logo-o.svg";
import Wso2Logo from "@assets/images/wso2-logo.svg";
import { APP_NAME } from "@config/config";
import { useAppAuthContext } from "@context/AuthContext";
import BasicBreadcrumbs from "@layout/BreadCrumbs/BreadCrumbs";
import { userApi } from "@services/user.api";
import { useAppSelector } from "@slices/store";

const Header = () => {
  const authContext = useAppAuthContext();
  const theme = useTheme();
  const [anchorElUser, setAnchorElUser] = React.useState<null | HTMLElement>(null);

  const user = useAppSelector((state) => userApi.endpoints.getUserInfo.select()(state)?.data);
  const isMobile = useMediaQuery(theme.breakpoints.down("sm"));

  const logo = isMobile ? wso2LogoO : Wso2Logo;

  const handleOpenUserMenu = (event: React.MouseEvent<HTMLElement>) => {
    setAnchorElUser(event.currentTarget);
  };

  const handleCloseUserMenu = () => {
    setAnchorElUser(null);
  };

  return (
    <Box
      sx={{
        zIndex: 10,
        backgroundColor: theme.palette.surface.secondary.active,
        boxShadow: theme.shadows[4],
      }}
    >
      <Toolbar
        variant="dense"
        sx={{
          paddingY: 0.3,
          display: "flex",
          gap: 0.5,
          "&.MuiToolbar-root": {
            px: 1.5,
          },
        }}
      >
        <img
          alt="wso2"
          style={{ marginRight: isMobile ? "4px" : "8px" }}
          onClick={() => (window.location.href = "/")}
          src={logo}
        ></img>

        <Box
          sx={{
            display: "flex",
            flexDirection: "row",
            gap: theme.spacing(0.5),
            width: "100%",
            alignItems: "center",
            height: "100%",
          }}
        >
          <Typography
            variant="h5"
            sx={{
              color: theme.palette.customText.primary.p1.active,
            }}
          >
            {APP_NAME}
          </Typography>
          {!isMobile && <BasicBreadcrumbs />}
        </Box>

        <Box sx={{ flexGrow: 0 }}>
          {user && (
            <>
              <Stack flexDirection={"row"} alignItems={"center"} gap={1}>
                <Tooltip title="Open settings">
                  <Avatar
                    onClick={handleOpenUserMenu}
                    sx={{
                      width: 48,
                      height: 48,
                      border: 1,
                      borderColor: theme.palette.customBorder.territory.active,
                    }}
                    src={user.employeeThumbnail || ""}
                    alt={user.firstName || "Avatar"}
                  >
                    {user.firstName?.charAt(0)}
                  </Avatar>
                </Tooltip>

                {!isMobile && (
                  <Box sx={{ width: "fit-content" }}>
                    <Typography
                      noWrap
                      variant="body1"
                      sx={{
                        color: theme.palette.customText.primary.p2.active,
                      }}
                    >
                      {[user.firstName, user.lastName].filter(Boolean).join(" ")}
                    </Typography>

                    <Typography
                      noWrap
                      variant="body2"
                      sx={{
                        color: theme.palette.customText.primary.p3.active,
                      }}
                    >
                      {user.jobRole}
                    </Typography>
                  </Box>
                )}
              </Stack>

              <Menu
                sx={{ mt: "45px" }}
                id="menu-appbar"
                anchorEl={anchorElUser}
                anchorOrigin={{
                  vertical: "top",
                  horizontal: "right",
                }}
                keepMounted
                transformOrigin={{
                  vertical: "top",
                  horizontal: "right",
                }}
                open={Boolean(anchorElUser)}
                onClose={handleCloseUserMenu}
              >
                <MenuItem
                  key={"logout"}
                  onClick={() => {
                    authContext.appSignOut();
                  }}
                >
                  <Typography textAlign="center">Logout</Typography>
                </MenuItem>
              </Menu>
            </>
          )}
        </Box>
      </Toolbar>
    </Box>
  );
};

export default Header;

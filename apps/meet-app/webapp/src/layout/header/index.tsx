// Copyright (c) 2024, WSO2 LLC. (https://www.wso2.com). All Rights Reserved.
//
// This software is the property of WSO2 LLC. and its suppliers, if any.
// Dissemination of any information or reproduction of any material contained
// herein in any form is strictly forbidden, unless permitted by WSO2 expressly.
// You may not alter or remove any copyright or other notice from copies of this content.

import React from "react";
import Typography from "@mui/material/Typography";
import Toolbar from "@mui/material/Toolbar";
import { AppBar, Avatar, Box, Menu, MenuItem, Stack, Tooltip } from "@mui/material";
import { useAppAuthContext } from "@context/AuthContext";
import { APP_NAME } from "@config/config";
import { RootState, useAppSelector } from "@slices/store";

const Header = () => {
  const authContext = useAppAuthContext();
  const [anchorElUser, setAnchorElUser] = React.useState<null | HTMLElement>(null);
  const user = useAppSelector((state: RootState) => state.user);

  const handleOpenUserMenu = (event: React.MouseEvent<HTMLElement>) => {
    setAnchorElUser(event.currentTarget);
  };

  const handleCloseUserMenu = () => {
    setAnchorElUser(null);
  };

  return (
    <AppBar
      position="fixed"
      sx={{
        zIndex: (theme) => theme.zIndex.drawer + 1,
        color: "black",

        background: (theme) => (theme.palette.mode === "light" ? theme.palette.common.white : "#0d0d0d"),
        boxShadow: 1,
      }}
    >
      <Toolbar
        variant="dense"
        sx={{
          paddingY: 0.3,
          "&.MuiToolbar-root": {
            pl: 0.3,
          },
        }}
      >
        <img
          alt="wso2"
          style={{
            height: "45px",
            maxWidth: "100px",
          }}
          onClick={() => (window.location.href = "/")}
          src={require("../../assets/images/wso2-logo.svg").default}
        ></img>
        <Typography
          variant="h5"
          sx={{
            ml: 1,
            flexGrow: 1,
            fontWeight: 600,
          }}
        >
          {APP_NAME}
        </Typography>

        <Box sx={{ flexGrow: 0 }}>
          {user.userInfo?.employeeThumbnail && (
            <>
              <Stack flexDirection={"row"} alignItems={"center"} gap={2}>
                <Box>
                  <Typography variant="body1" sx={{ fontWeight: 600 }}>
                    {user.userInfo?.firstName + " " + user.userInfo.lastName}
                  </Typography>
                  <Typography variant="body2">{user.userInfo?.jobRole}</Typography>
                </Box>
                <Tooltip title="Open settings">
                  <Avatar
                    onClick={handleOpenUserMenu}
                    sx={{ border: 1, borderColor: "primary.main" }}
                    src={user.userInfo?.employeeThumbnail || ""}
                    alt={user.userInfo?.firstName || "Avatar"}
                  >
                    {user.userInfo?.firstName?.charAt(0)}
                  </Avatar>
                </Tooltip>
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
    </AppBar>
  );
};

export default Header;

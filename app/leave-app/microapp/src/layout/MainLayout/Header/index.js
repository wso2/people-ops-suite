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
import React from "react";
import PropTypes from "prop-types";

import { isDesktop } from "react-device-detect";

import { useTheme } from "@mui/material/styles";
import { IconButton, Toolbar } from "@mui/material";
import MenuIcon from "@mui/icons-material/Menu";

import AppBarStyled from "./AppBarStyled";
import HeaderContent from "./HeaderContent";

const Header = ({ open, handleDrawerToggle }) => {
  const theme = useTheme();

  const iconBackColor = "grey.100";
  const iconBackColorOpen = "grey.200";

  const mainHeader = (
    <Toolbar>
      <IconButton
        disableRipple
        aria-label="open drawer"
        onClick={handleDrawerToggle}
        edge="start"
        color="secondary"
        sx={{
          color: "text.primary",
          bgcolor: open ? iconBackColorOpen : iconBackColor,
          ml: { xs: 0, lg: -2 },
        }}
      >
        {!open ? <MenuIcon /> : <MenuIcon />}
      </IconButton>
      <HeaderContent />
    </Toolbar>
  );

  const appBar = {
    position: "fixed",
    color: "inherit",
    elevation: 0,
    sx: {
      borderBottom: `1px solid ${theme.palette.divider}`,
    },
  };

  return (
    <>
      {isDesktop && (
        <AppBarStyled open={open} {...appBar}>
          {mainHeader}
        </AppBarStyled>
      )}
    </>
  );
};

Header.propTypes = {
  open: PropTypes.bool,
  handleDrawerToggle: PropTypes.func,
};

export default Header;

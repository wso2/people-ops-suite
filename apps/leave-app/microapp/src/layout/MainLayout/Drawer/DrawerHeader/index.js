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

import { useTheme } from "@mui/material/styles";
import { Stack, IconButton } from "@mui/material";
import MenuIcon from "@mui/icons-material/Menu";

import DrawerHeaderStyled from "./DrawerHeaderStyled";

const DrawerHeader = ({ open, handleDrawerClose, handleDrawerOpen }) => {
  const theme = useTheme();

  return (
    <DrawerHeaderStyled theme={theme} open={open}>
      {open ? (
        <IconButton onClick={handleDrawerClose}>
          <MenuIcon />
        </IconButton>
      ) : (
        <IconButton onClick={handleDrawerOpen}>
          <MenuIcon />
        </IconButton>
      )}
      <Stack direction="row" spacing={1} alignItems="center"></Stack>
    </DrawerHeaderStyled>
  );
};

DrawerHeader.propTypes = {
  open: PropTypes.bool,
};

export default DrawerHeader;

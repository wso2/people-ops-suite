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
import React, { useState } from "react";

import { Box, Typography } from "@mui/material";

import Profile from "./Profile";
import { APPLICATION_CONFIG } from "../../../../config";
import DrawerHeader from "../../Drawer/DrawerHeader";

const HeaderContent = ({ open, handleDrawerOpen, handleDrawerClose }) => {
  return (
    <>
      <DrawerHeader
        open={open}
        handleDrawerClose={handleDrawerClose}
        handleDrawerOpen={handleDrawerOpen}
      />
      <div
        style={{
          maxWidth: 80,
          paddingRight: 10,
          marginTop: 4,
        }}
      >
        <img
          src={"/wso2-logo.svg"}
          alt="Logo"
          style={{ maxWidth: "100px", height: "50px", display: "block" }}
        />
      </div>
      <Typography variant="h5" overflow={"visible"} noWrap>
        {APPLICATION_CONFIG.appName}
      </Typography>
      <Box sx={{ width: "100%", ml: 1 }} />
      <Profile />
    </>
  );
};

export default HeaderContent;

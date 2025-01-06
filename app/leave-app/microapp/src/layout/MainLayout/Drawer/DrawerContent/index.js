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

import { isDesktop } from "react-device-detect";

import { Box, Stack } from "@mui/material";

import NavCard from "./NavCard";
import Navigation from "./Navigation";

const DrawerContent = (props) => (
  <Box style={{ height: "100%" }}>
    <Stack
      sx={{ height: "100%" }}
      direction="column"
      justifyContent="space-between"
      alignItems="stretch"
      spacing={2}
    >
      <span>
        <Navigation open={props.open} />
      </span>
      <span>
        <div style={{ width: 100 }} />
      </span>
      <span>{isDesktop && <NavCard open={props.open} />}</span>
    </Stack>
  </Box>
);

export default DrawerContent;

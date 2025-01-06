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
import React, { useEffect } from "react";
import PropTypes from "prop-types";
import { useSelector } from "react-redux";

import { Box, List, Typography } from "@mui/material";

import NavItem from "./NavItem";

const NavGroup = ({ item, open }) => {
  const menu = useSelector((state) => state.menu);
  const { isAdmin, isLead, drawerOpen } = menu;

  useEffect(() => {}, [isAdmin, isLead]);

  return (
    <List
      subheader={
        item.title &&
        drawerOpen && (
          <Box sx={{ pl: 3, mb: 1.5 }}>
            <Typography variant="subtitle2" color="textSecondary">
              {item.title}
            </Typography>
          </Box>
        )
      }
      sx={{ mb: drawerOpen ? 1.5 : 0, py: 0, zIndex: 0 }}
    >
      {item.children &&
        item.children.map((menuItem) => {
          return (menuItem.isAdmin && !isAdmin) ||
            (menuItem.isLead && !isLead) ? null : (
            <NavItem key={menuItem.id} item={menuItem} level={1} open={open} />
          );
        })}
    </List>
  );
};

NavGroup.propTypes = {
  item: PropTypes.object,
};

export default NavGroup;

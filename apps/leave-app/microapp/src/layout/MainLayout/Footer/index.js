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
import React, { useEffect, useState } from "react";
import { useDispatch, useSelector } from "react-redux";

import BottomNavigation from "@mui/material/BottomNavigation";
import BottomNavigationAction from "@mui/material/BottomNavigationAction";
import { useTheme } from "@mui/material/styles";

import pages from "../../../menu-items/pages";
import { navigateToView } from "../../../store/reducers/menu";

export default function LabelBottomNavigation() {
  const theme = useTheme();
  const dispatch = useDispatch();
  const { isAdmin, isLead, navigatedView } = useSelector((state) => state.menu);
  const [value, setValue] = useState(navigatedView);

  const handleChange = (event, newValue) => {
    dispatch(navigateToView({ navigatedView: newValue }));
  };

  const bottomNavigationSx = {
    "& .Mui-selected": {
      color: theme.palette.secondary.main,
    },
  };

  useEffect(() => {
    setValue(navigatedView);
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [navigatedView, isAdmin, isLead]);

  return (
    <BottomNavigation
      sx={{ width: "100%" }}
      value={value}
      onChange={handleChange}
    >
      {pages.children.map((page) => {
        return (page.isAdmin && !isAdmin) || (page.isLead && !isLead) ? null : (
          <BottomNavigationAction
            sx={bottomNavigationSx}
            label={page.title}
            value={page.id}
            icon={page.icon({
              color: value === page.id ? "secondary" : "primary",
            })}
          />
        );
      })}
    </BottomNavigation>
  );
}

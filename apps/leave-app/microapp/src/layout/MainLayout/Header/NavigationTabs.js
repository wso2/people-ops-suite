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
import React, { useState, useEffect } from "react";
import { useDispatch, useSelector } from "react-redux";

import Tabs from "@mui/material/Tabs";
import Tab from "@mui/material/Tab";

import pages from "../../../menu-items/pages";
import { navigateToView } from "../../../store/reducers/menu";

function LinkTab(props) {
  return (
    <Tab
      component="a"
      onClick={(event) => {
        event.preventDefault();
      }}
      {...props}
    />
  );
}

export default function NavigationTabs() {
  const dispatch = useDispatch();
  const { isAdmin, isLead, navigatedView } = useSelector((state) => state.menu);
  const [value, setValue] = useState(navigatedView);

  const handleChange = (event, newValue) => {
    dispatch(navigateToView({ navigatedView: newValue }));
  };

  useEffect(() => {
    setValue(navigatedView);
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [navigatedView, isAdmin, isLead]);

  return (
    <Tabs
      value={navigatedView}
      onChange={handleChange}
      aria-label="navigation tabs"
      variant="fullWidth"
      centered
    >
      {pages.children.map((page) => {
        return (page.isAdmin && !isAdmin) || page.isLead || !isLead ? null : (
          <LinkTab
            icon={page.icon}
            value={page.id}
            key={page.id}
            label={page.title}
            iconPosition="start"
            aria-label={page.title}
            href={page.url}
          />
        );
      })}
    </Tabs>
  );
}

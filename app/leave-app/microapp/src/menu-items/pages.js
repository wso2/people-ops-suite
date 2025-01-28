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

import {
  Add as AddIcon,
  Assessment as AssessmentIcon,
  History as HistoryIcon,
  BarChart as BarChartIcon,
} from "@mui/icons-material";

const pages = {
  id: "views",
  title: "Views",
  type: "group",
  children: [
    {
      id: "form",
      title: "New Leave",
      type: "item",
      url: "/form",
      icon: (props) => <AddIcon {...props} />,
      target: true,
      isAdmin: false,
    },
    {
      id: "history",
      title: "History",
      type: "item",
      url: "/history",
      icon: (props) => <HistoryIcon {...props} />,
      target: true,
      isAdmin: false,
    },
    {
      id: "leads",
      title: "Lead Reports",
      type: "item",
      url: "/leads",
      icon: (props) => <AssessmentIcon {...props} />,
      target: true,
      isLead: true,
      isAdmin: false,
    },
    {
      id: "reports",
      title: "Reports",
      type: "item",
      url: "/reports",
      icon: (props) => <BarChartIcon {...props} />,
      target: true,
      isAdmin: true,
    },
  ],
};

export default pages;

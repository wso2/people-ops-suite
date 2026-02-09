// Copyright (c) 2025 WSO2 LLC. (https://www.wso2.com).
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
import { View } from "@view/index";
import { Role } from "@slices/authSlice/auth";
import DuoIcon from '@mui/icons-material/Duo';
import { isIncludedRole } from "@utils/utils";
import HelpOutlineIcon from '@mui/icons-material/HelpOutline';
import { RouteObject, NonIndexRouteObject } from "react-router-dom";
import { Dashboard } from "@mui/icons-material";

export interface RouteObjectWithRole extends NonIndexRouteObject {
  allowRoles: string[];
  icon:
  | React.ReactElement<any, string | React.JSXElementConstructor<any>>
  | undefined;
  text: string;
  children?: RouteObjectWithRole[];
  bottomNav?: boolean;
}

interface RouteDetail {
  path: string;
  allowRoles: string[];
  icon:
  | React.ReactElement<any, string | React.JSXElementConstructor<any>>
  | undefined;
  text: string;
  bottomNav?: boolean;
}

export const routes: RouteObjectWithRole[] = [
  {
    path: "/",
    text: "Meetings",
    icon: React.createElement(DuoIcon),
    element: React.createElement(View.meetings),
    allowRoles: [Role.ADMIN, Role.TEAM],
  },
  {
    path: "/dashboard",
    text: "Dashboard",
    icon: React.createElement(Dashboard),
    element: React.createElement(View.dashboard),
    allowRoles: [Role.ADMIN, Role.TEAM],
  },
  {
    path: "/help",
    text: "Help",
    icon: React.createElement(HelpOutlineIcon),
    element: React.createElement(View.help),
    allowRoles: [Role.ADMIN, Role.TEAM],
    bottomNav: true,
  },
];
export const getActiveRoutesV2 = (
  routes: RouteObjectWithRole[] | undefined,
  roles: string[]
): RouteObjectWithRole[] => {
  if (!routes) return [];
  var routesObj: RouteObjectWithRole[] = [];
  routes.forEach((routeObj) => {
    if (isIncludedRole(roles, routeObj.allowRoles)) {
      routesObj.push({
        ...routeObj,
        children: getActiveRoutesV2(routeObj.children, roles),
      });
    }
  });

  return routesObj;
};

export const getActiveRoutes = (roles: string[]): RouteObject[] => {
  var routesObj: RouteObject[] = [];
  routes.forEach((routeObj) => {
    if (isIncludedRole(roles, routeObj.allowRoles)) {
      routesObj.push({
        ...routeObj,
      });
    }
  });
  return routesObj;
};

export const getActiveRouteDetails = (roles: string[]): RouteDetail[] => {
  var routesObj: RouteDetail[] = [];
  routes.forEach((routeObj) => {
    if (isIncludedRole(roles, routeObj.allowRoles)) {
      routesObj.push({
        path: routeObj.path ? routeObj.path : "",
        ...routeObj,
      });
    }
  });
  return routesObj;
};

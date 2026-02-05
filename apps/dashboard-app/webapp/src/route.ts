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
import { HomeIcon } from "lucide-react";
import { CircleQuestionMark } from "lucide-react";

import React from "react";

import { Role } from "@slices/authSlice/auth";
import { isIncludedRole } from "@utils/utils";
import { View } from "@view/index";

import type { RouteDetail, RouteObjectWithRole } from "./types/types";

export const routes: RouteObjectWithRole[] = [
  {
    path: "/",
    text: "Home",
    icon: React.createElement(HomeIcon),
    element: React.createElement(View.firstView),
    allowRoles: [Role.ADMIN, Role.EMPLOYEE],
  },
  {
    path: "/help",
    text: "Help & Support",
    icon: React.createElement(CircleQuestionMark),
    element: React.createElement(View.help),
    allowRoles: [Role.ADMIN, Role.EMPLOYEE],
    bottomNav: true,
  },
  {
    path: "/page",
    text: "Page 1",
    icon: React.createElement(CircleQuestionMark),
    allowRoles: [Role.ADMIN, Role.EMPLOYEE],
    children: [
      {
        path: "nested-page",
        text: "Nested Page",
        icon: React.createElement(CircleQuestionMark),
        element: React.createElement(View.nestedPage),
        allowRoles: [Role.ADMIN, Role.EMPLOYEE],
      },
      {
        path: "nested-page-2",
        text: "Nested Page 2",
        icon: React.createElement(CircleQuestionMark),
        element: React.createElement(View.nestedPage),
        allowRoles: [Role.ADMIN, Role.EMPLOYEE],
      },
    ],
  },
  {
    path: "/page-two",
    text: "Page 2",
    icon: React.createElement(CircleQuestionMark),
    element: React.createElement(View.pageTwo),
    allowRoles: [Role.ADMIN, Role.EMPLOYEE],
    children: [
      {
        path: "nested-page",
        text: "Nested Page",
        icon: React.createElement(CircleQuestionMark),
        element: React.createElement(View.nestedPage),
        allowRoles: [Role.ADMIN, Role.EMPLOYEE],
      },
      {
        path: "nested-page-2",
        text: "Nested Page 2",
        icon: React.createElement(CircleQuestionMark),
        element: React.createElement(View.nestedPage),
        allowRoles: [Role.ADMIN, Role.EMPLOYEE],
      },
    ],
  },
];

export const getAllowedRoutes = (roles: string[]): RouteDetail[] => {
  const routesObj: RouteDetail[] = [];
  routes.forEach((routeObj) => {
    if (isIncludedRole(roles, routeObj.allowRoles)) {
      routesObj.push({
        ...routeObj,
        path: routeObj.path ?? "",
      });
    }
  });
  return routesObj;
};

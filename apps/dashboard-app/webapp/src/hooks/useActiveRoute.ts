// Copyright (c) 2026 WSO2 LLC. (https://www.wso2.com).
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
import { useLocation } from "react-router-dom";

import { useMemo } from "react";

import { RouteDetail } from "@/types/types";

export const useActiveRoute = () => {
  const location = useLocation();

  const checkIsActive = useMemo(() => {
    return (route: RouteDetail): boolean => {
      // Exact match
      if (location.pathname === route.path) {
        return true;
      }

      // If route has children, check if any child is active
      if (route.children && route.children.length > 0) {
        return location.pathname.startsWith(route.path + "/");
      }

      return false;
    };
  }, [location.pathname]);

  const getCurrentActiveRoute = (routes: RouteDetail[]) => {
    const path = location.pathname;

    for (const route of routes) {
      // Check exact match first
      if (route.path === path) {
        console.log("Found exact match:", route);
        return route;
      }

      // Check children if they exist
      if (route.children && route.children.length > 0) {
        for (const child of route.children) {
          const childPath = `${route.path}/${child.path}`;
          console.log(`Checking child path: ${childPath} vs ${path}`);

          if (childPath === path) {
            console.log("Found child match:", child);
            return child;
          }
        }
      }
    }

    return null; // No match found
  };

  return {
    checkIsActive,
    getCurrentActiveRoute,
  };
};

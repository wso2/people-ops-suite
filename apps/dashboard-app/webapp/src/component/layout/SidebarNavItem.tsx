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
import { Box, useTheme } from "@mui/material";
import Tooltip from "@mui/material/Tooltip";
import { Link, useNavigate } from "react-router-dom";

import { RouteDetail } from "@/types/types";

import LinkItem from "./LinkItem";
import SidebarSubMenu from "./SidebarSubMenu";

function SidebarNavItem({
  route,
  isActive,
  open,
}: {
  route: RouteDetail;
  isActive: boolean;
  open: boolean;
}) {
  const theme = useTheme();
  const navigate = useNavigate();

  const handleParentClick = () => {
    if (!route.element && route.children && route.children.length > 0) {
      const firstChild = route.children[0];
      navigate(`${route.path}/${firstChild.path}`);
    }
  };

  return (
    <Box
      sx={{
        position: "relative",
        transition: "box-shadow 0.2s",
        display: "flex",
        flexDirection: "column",
        gap: 1,
        width: "100%",
      }}
    >
      <Tooltip title={!open ? route.text : ""}>
        {route.element ? (
          <Link to={route.path} style={{ width: "100%", display: "block", textDecoration: "none" }}>
            <LinkItem
              label={route.text}
              icon={route.icon}
              open={open}
              isActive={isActive}
              hasChildren={!!(route.children && route.children.length > 0)}
              route={route}
            />
          </Link>
        ) : (
          <Box
            component="button"
            onClick={handleParentClick}
            sx={{
              width: "100%",
              cursor: "pointer",
              border: "none",
              background: "none",
              padding: 0,
            }}
          >
            <LinkItem
              label={route.text}
              icon={route.icon}
              open={open}
              isActive={isActive}
              hasChildren={!!(route.children && route.children.length > 0)}
              route={route}
            />
          </Box>
        )}
      </Tooltip>

      {/* Render expanded children, outside the Tooltip */}
      {route && route.children?.length && isActive && (
        <Box
          key="nested"
          sx={{
            display: "flex",
            flexDirection: "column",
            gap: theme.spacing(1.5),
            alignItems: "center",
            justifyContent: "center",
            marginLeft: open ? theme.spacing(2.5) : 0,
            borderLeft: open ? `1px solid ${theme.palette.neutral["1000"]}` : "none",
            paddingX: "8px",
          }}
        >
          <SidebarSubMenu parentRoute={route} open={open} />
        </Box>
      )}
    </Box>
  );
}

export default SidebarNavItem;

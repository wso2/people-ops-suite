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
import { Box, Divider, Stack, Tooltip, Typography, useMediaQuery, useTheme } from "@mui/material";
import { ChevronLeft, ChevronRight, Moon, Sun } from "lucide-react";

import { useMemo } from "react";

import SidebarNavItem from "@component/layout/SidebarNavItem";
import pJson from "@root/package.json";
import { useActiveRoute } from "@root/src/hooks/useActiveRoute";
import { getAllowedRoutes } from "@src/route";

interface SidebarProps {
  open: boolean;
  handleDrawer: () => void;
  roles: string[];
  currentPath: string;
  mode: string;
  onThemeToggle: () => void;
}

const Sidebar = (props: SidebarProps) => {
  const { mode, onThemeToggle } = props;

  const allRoutes = useMemo(() => getAllowedRoutes(props.roles), [props.roles]);

  const theme = useTheme();
  const isMobile = useMediaQuery(theme.breakpoints.down("sm"));
  const { checkIsActive } = useActiveRoute();

  const renderControlButton = (
    icon: React.ReactNode,
    onClick?: () => void,
    tooltipTitle?: string,
  ) => {
    const button = (
      <Box
        component="button"
        type="button"
        onClick={onClick}
        disabled={!onClick}
        aria-label={tooltipTitle}
        sx={{
          width: props.open ? "100%" : "fit-content",
          padding: theme.spacing(1),
          borderRadius: "8px",
          cursor: onClick ? "pointer" : "default",
          border: "none",
          background: "none",
          display: "flex",
          alignItems: "center",
          justifyContent: props.open ? "flex-start" : "center",
          gap: theme.spacing(1),
          color: theme.palette.customNavigation.text,
          transition: "all 0.2s ease-in-out",
          ...(onClick && {
            "&:hover": {
              backgroundColor: theme.palette.customNavigation.hoverBg,
              color: theme.palette.customNavigation.hover,
            },
            "&:active": {
              backgroundColor: theme.palette.customNavigation.clickedBg,
              color: theme.palette.customNavigation.clicked,
            },
          }),
        }}
      >
        {icon}
      </Box>
    );

    // Only show tooltip when sidebar is collapsed
    if (tooltipTitle && !props.open) {
      return <Tooltip title={tooltipTitle}>{button}</Tooltip>;
    }

    return button;
  };

  return (
    <Box
      sx={{
        height: "100%",
        paddingY: "16px",
        paddingX: "12px",
        backgroundColor: theme.palette.surface.navbar.active,
        zIndex: 10,
        display: "flex",
        flexDirection: "column",
        width: props.open ? "200px" : "fit-content",
        overflow: "visible",
      }}
  >
      {/* Navigation List */}
      <Stack
        direction="column"
        gap={1}
        sx={{
          overflow: "visible",
          width: props.open ? "100%" : "fit-content",
        }}
      >
        {allRoutes.map((route, idx) => {
          return (
            !route.bottomNav && (
              <Box
                key={idx}
                sx={{
                  width: props.open ? "100%" : "fit-content",
                  cursor: props.open ? "pointer" : "default",
                }}
              >
                <SidebarNavItem route={route} open={props.open} isActive={checkIsActive(route)} />
              </Box>
            )
          );
        })}
      </Stack>

      {/* Spacer */}
      <Box sx={{ flexGrow: 1 }} />

      {/* Footer Controls */}
      {!isMobile && (
        <Stack
          direction="column"
          gap={1}
          sx={{
            paddingBottom: "20px",
            alignItems: "center",
          }}
        >
          {allRoutes.map((route, idx) => {
            return (
              route.bottomNav && (
                <Box
                  key={idx}
                  sx={{
                    width: props.open ? "100%" : "fit-content",
                    cursor: props.open ? "pointer" : "default",
                  }}
                >
                  <SidebarNavItem route={route} open={props.open} isActive={checkIsActive(route)} />
                </Box>
              )
            );
          })}

          {/* Theme Toggle */}
          {renderControlButton(
            mode === "dark" ? <Sun size={16} /> : <Moon size={16} />,
            onThemeToggle,
            mode === "dark" ? "Switch to Light Mode" : "Switch to Dark Mode",
          )}

          {/* Sidebar Toggle */}
          {renderControlButton(
            !props.open ? <ChevronRight size={18} /> : <ChevronLeft size={18} />,
            props.handleDrawer,
            props.open ? "Collapse Sidebar" : "Expand Sidebar",
          )}

          <Divider
            sx={{
              width: "100%",
              backgroundColor: theme.palette.customBorder.primary.active,
            }}
          />

          {/* Version Info */}
          {renderControlButton(
            <Typography
              variant="body2"
              sx={{
                whiteSpace: "nowrap",
                color: "inherit",
                width: "100%",
              }}
            >
              {props.open
                ? `v${pJson.version} | © ${new Date().getFullYear()} WSO2 LLC`
                : `v${pJson.version.split(".")[0]}`}
            </Typography>,
            undefined,
            `Version ${pJson.version}`,
          )}
        </Stack>
      )}
    </Box>
  );
};

export default Sidebar;

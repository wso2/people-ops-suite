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
import CloseOutlinedIcon from "@mui/icons-material/CloseOutlined";
import MenuIcon from "@mui/icons-material/Menu";
import { AppBar, Box, IconButton, Typography, useTheme } from "@mui/material";
import { Moon, Sun } from "lucide-react";
import { useNavigate } from "react-router-dom";

import { useActiveRoute } from "@root/src/hooks/useActiveRoute";
import { getAllowedRoutes } from "@src/route";

interface MobileBottomBarProps {
  onMenuClick: () => void;
  onThemeToggle: () => void;
  mode: string;
  open: boolean;
  roles: string[];
}

export default function MobileBottomBar({
  onMenuClick,
  onThemeToggle,
  open,
  mode,
  roles,
}: MobileBottomBarProps) {
  const theme = useTheme();
  const navigate = useNavigate();

  const routes = getAllowedRoutes(roles);
  const { getCurrentActiveRoute } = useActiveRoute();
  const currentRoute = getCurrentActiveRoute(routes);

  return (
    <AppBar
      position="fixed"
      sx={{
        top: "auto",
        bottom: 10,
        backgroundColor: "transparent",
        backgroundImage: "none",
        alignItems: "center",
        boxShadow: "none",
        pointerEvents: "none",
      }}
    >
      <Box
        sx={{
          display: "flex",
          alignItems: "center",
          gap: "8px",
          padding: "3px 2px",
          backgroundColor:
            theme.palette.mode === "light"
              ? "rgba(255, 255, 255, 0.95)"
              : (theme.palette as any).surface?.secondary?.active || theme.palette.background.paper,
          border: `0.5px solid ${
            theme.palette.mode === "light"
              ? "rgba(230, 230, 230, 0.8)"
              : (theme.palette as any).border?.territory?.active || theme.palette.divider
          }`,
          borderRadius: "10px",
          boxShadow: "0px 3px 4px 0px rgba(0, 0, 0, 0.25)",
          pointerEvents: "auto",
        }}
      >
        {/* Home Button */}
        <Box
          onClick={() => navigate("/")}
          sx={{
            display: "flex",
            alignItems: "center",
            gap: "6px",
            padding: "5px 8px",
            borderRadius: "8px",
            backgroundColor: theme.palette.fill.primary_light.active,
            cursor: "pointer",
            transition: "background-color 0.2s ease",
            color: theme.palette.customText.brand.p1.active,
          }}
        >
          {currentRoute?.icon && (
            <Box
              sx={{
                display: "flex",
                alignItems: "center",
                "& svg": { width: "18px", height: "18px" },
              }}
            >
              {currentRoute.icon}
            </Box>
          )}

          <Typography
            sx={{
              fontSize: "14px",
              fontFamily: "'Geist', sans-serif",
              fontWeight: 400,
              lineHeight: 1.5,
              whiteSpace: "nowrap",
            }}
          >
            {currentRoute?.text}
          </Typography>
        </Box>

        {/* Theme Toggle Button */}
        <IconButton
          color="inherit"
          aria-label="toggle theme"
          onClick={onThemeToggle}
          sx={{
            padding: "8px",
            color: theme.palette.customText.primary.p2.active,
          }}
        >
          {mode === "dark" ? <Sun size={16} /> : <Moon size={16} />}
        </IconButton>

        {/* Menu Button */}
        <IconButton
          color="inherit"
          aria-label="open menu"
          onClick={onMenuClick}
          sx={{
            padding: "3px 5px 3px 0",
            color: theme.palette.customText.primary.p2.active,
          }}
        >
          {open ? (
            <CloseOutlinedIcon sx={{ fontSize: "20px" }} />
          ) : (
            <MenuIcon sx={{ fontSize: "20px" }} />
          )}
        </IconButton>
      </Box>
    </AppBar>
  );
}

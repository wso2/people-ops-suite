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

import { styled, Theme, CSSObject, alpha, useTheme } from "@mui/material/styles";
import { MUIStyledCommonProps } from "@mui/system";
import MuiDrawer from "@mui/material/Drawer";
import List from "@mui/material/List";
import ChevronLeftIcon from "@mui/icons-material/ChevronLeft";
import ChevronRightIcon from "@mui/icons-material/ChevronRight";
import IconButton from "@mui/material/IconButton";
import ListLinkItem from "@component/layout/LinkItem";
import LightModeOutlinedIcon from "@mui/icons-material/LightModeOutlined";
import DarkModeOutlinedIcon from "@mui/icons-material/DarkModeOutlined";
import { getActiveRouteDetails } from "./../../route";
import { SIDEBAR_WIDTH } from "@config/ui";
import { useLocation, matchPath, useMatches } from "react-router-dom";
import { ColorModeContext } from "../../App";
import { Stack, Typography } from "@mui/material";

interface SidebarProps {
  open: boolean;
  theme: Theme;
  handleDrawer: () => void;
  roles: string[];
  currentPath: string;
}

function useRouteMatch(patterns: readonly string[]) {
  const { pathname } = useLocation();

  let matches = useMatches();

  for (let i = 0; i < patterns.length; i += 1) {
    const pattern = patterns[i];
    const possibleMatch = matchPath(pattern, pathname);
    if (possibleMatch !== null) {
      return patterns.indexOf(possibleMatch.pattern.path);
    }
  }
  for (let i = 0; i < matches.length; i += 1) {
    if (patterns.indexOf(matches[i].pathname) !== -1) {
      return patterns.indexOf(matches[i].pathname);
    }
  }

  return null;
}

const Sidebar = (props: SidebarProps) => {
  const currentIndex = useRouteMatch([...getActiveRouteDetails(props.roles).map((r) => r.path)]);
  const theme = useTheme();

  return (
    <ColorModeContext.Consumer>
      {(colorMode) => (
        <Drawer
          variant="permanent"
          open={props.open}
          sx={{
            "& .MuiDrawer-paper": {
              background: alpha(theme.palette.primary.main, 0.85),
            },
          }}
        >
          <List
            sx={{
              display: "flex",
              flexDirection: "column",
              pt: 7.2,
            }}
          >
            {getActiveRouteDetails(props.roles).map((r, idx) => (
              <div key={idx}>
                {!r.bottomNav && (
                  <ListLinkItem
                    key={idx}
                    theme={props.theme}
                    to={r.path}
                    primary={r.text}
                    icon={r.icon}
                    open={props.open}
                    isActive={currentIndex === idx}
                  />
                )}
              </div>
            ))}
          </List>
          <DrawerSpace />
          <DrawerFooter>
            <Stack flexDirection={"column"} gap={3}>
              <IconButton
                onClick={colorMode.toggleColorMode}
                color="inherit"
                sx={{
                  color: "white",
                  "&:hover": {
                    background: alpha(props.theme.palette.common.white, 0.05),
                    ...(!props.open && {
                      "& .menu-tooltip": {
                        opacity: 1,
                        visibility: "visible",
                      },
                    }),
                  },
                }}
              >
                {props.theme.palette.mode === "dark" ? <LightModeOutlinedIcon /> : <DarkModeOutlinedIcon />}
                <span className="menu-tooltip">
                  <Typography variant="h6">
                    {"Switch to " + (props.theme.palette.mode === "dark" ? "light" : "dark") + " mode"}
                  </Typography>
                </span>
              </IconButton>
              <IconButton
                onClick={props.handleDrawer}
                sx={{
                  "&:hover": {
                    background: alpha(props.theme.palette.common.white, 0.05),
                  },
                }}
              >
                {!props.open ? (
                  <ChevronRightIcon sx={{ color: "white" }} />
                ) : (
                  <ChevronLeftIcon sx={{ color: "white" }} />
                )}
              </IconButton>
            </Stack>
          </DrawerFooter>
        </Drawer>
      )}
    </ColorModeContext.Consumer>
  );
};

export default Sidebar;

interface DrawerHeaderInterface extends MUIStyledCommonProps {
  open: boolean;
}

const DrawerSpace = styled("div")(({ theme }) => ({
  flex: 1,
  ...theme.mixins.toolbar,
}));

export const DrawerFooter = styled("div")(({ theme }) => ({
  position: "relative",
  bottom: 0,
  display: "flex",
  alignItems: "center",
  justifyContent: "flex-end",
  ...theme.mixins.toolbar,
}));

const Drawer = styled(MuiDrawer, {
  shouldForwardProp: (prop) => prop !== "open",
})(({ theme, open }) => ({
  width: SIDEBAR_WIDTH,
  flexShrink: 0,
  display: "flex",
  whiteSpace: "nowrap",
  ...(open && {
    ...openedMixin(theme),
    "& .MuiDrawer-paper": openedMixin(theme),
  }),
  ...(!open && {
    ...closedMixin(theme),
    "& .MuiDrawer-paper": closedMixin(theme),
  }),
}));

// When sideBar opens
const openedMixin = (theme: Theme): CSSObject => ({
  width: SIDEBAR_WIDTH,
  transition: theme.transitions.create("width", {
    easing: theme.transitions.easing.sharp,
    duration: theme.transitions.duration.enteringScreen,
  }),
  overflowX: "hidden",
  padding: theme.spacing(0.5),
});

// When sideBar closes
const closedMixin = (theme: Theme): CSSObject => ({
  transition: theme.transitions.create("width", {
    easing: theme.transitions.easing.sharp,
    duration: theme.transitions.duration.leavingScreen,
  }),
  overflowX: "hidden",
  width: theme.spacing(7),
  padding: theme.spacing(0.5),
});

export const DrawerHeader = styled("div")<DrawerHeaderInterface>(({ theme, open }) => ({
  display: "flex",
  alignItems: "center",
  justifyContent: "flex-end",
  padding: theme.spacing(0.5),
  transition: theme.transitions.create(["display"], {
    easing: theme.transitions.easing.sharp,
    duration: theme.transitions.duration.leavingScreen,
  }),
  ...theme.mixins.toolbar,
  ...(open && {
    justifyContent: "flex-start",
  }),
}));

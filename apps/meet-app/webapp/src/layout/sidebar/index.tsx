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

import List from "@mui/material/List";
import { SIDEBAR_WIDTH } from "@config/ui";
import { ColorModeContext } from "@src/App";
import MuiDrawer from "@mui/material/Drawer";
import { Stack, Typography } from "@mui/material";
import IconButton from "@mui/material/IconButton";
import { getActiveRouteDetails } from "@src/route";
import { MUIStyledCommonProps } from "@mui/system";
import ListLinkItem from "@component/layout/LinkItem";
import ChevronLeftIcon from "@mui/icons-material/ChevronLeft";
import ChevronRightIcon from "@mui/icons-material/ChevronRight";
import { useLocation, matchPath, useMatches, useNavigate } from "react-router-dom";
import DarkModeOutlinedIcon from "@mui/icons-material/DarkModeOutlined";
import LightModeOutlinedIcon from "@mui/icons-material/LightModeOutlined";
import { styled, Theme, CSSObject, alpha, useTheme } from "@mui/material/styles";

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
  const navigate = useNavigate();

  return (
    <ColorModeContext.Consumer>
      {(colorMode) => (
        <Drawer
          variant="permanent"
          open={props.open}
          sx={{
            "& .MuiDrawer-paper": {
              background: alpha(theme.palette.primary.dark, 1),
            },
          }}
        >
          <List
            sx={{
              display: "flex",
              flexDirection: "column",
              pt: 6.5,
            }}
          >
            {getActiveRouteDetails(props.roles).map((r, idx) => (
              <div key={idx}>
                {!r.bottomNav && !r.hidden && (
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
              {getActiveRouteDetails(props.roles).map(
                (r, idx) =>
                  r.bottomNav && (
                    <IconButton
                      key={"bottom-" + idx}
                      onClick={() => navigate(r.path)}
                      sx={{
                        color: (theme) => theme.palette.common.white,
                        ...(currentIndex === idx && {
                          color: (theme) => theme.palette.primary.main,
                        }),
                        "&:hover": {
                          background: (theme) =>
                            theme.palette.mode === "light"
                              ? alpha(theme.palette.common.white, 0.35)
                              : alpha(theme.palette.primary.main, 0.35),
                          ...(!props.open && {
                            "& .menu-tooltip": {
                              marginLeft: -3,
                              opacity: 1,
                              visibility: "visible",
                              boxShadow: theme.palette.mode === "dark" ? "0px 0px 10px rgba(120, 125, 129, 0.2)" : 10,
                            },
                          }),
                        },
                        ...(currentIndex === idx && {
                          background: (theme) =>
                            theme.palette.mode === "light"
                              ? alpha(theme.palette.common.white, 0.5)
                              : alpha(theme.palette.primary.main, 0.2),
                        }),
                      }}
                    >
                      {r.icon}
                      <span className="menu-tooltip">
                        <Typography sx={{ color: "white" }} variant="h6">
                          {"Help"}
                        </Typography>
                      </span>
                    </IconButton>
                  )
              )}
              <IconButton
                onClick={colorMode.toggleColorMode}
                color="inherit"
                sx={{
                  color: "white",
                  "&:hover": {
                    background: alpha(props.theme.palette.common.white, 0.05),
                    ...(!props.open && {
                      "& .menu-tooltip": {
                        marginLeft: -3,
                        opacity: 1,
                        visibility: "visible",
                        boxShadow: theme.palette.mode === "dark" ? "0px 0px 10px rgba(120, 125, 129, 0.2)" : 10,
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
                color="inherit"
                sx={{
                  color: "white",
                  "&:hover": {
                    background: alpha(props.theme.palette.common.white, 0.05),
                    ...(!props.open && {
                      "& .menu-tooltip": {
                        marginLeft: -3,
                        opacity: 1,
                        visibility: "visible",
                        boxShadow: theme.palette.mode === "dark" ? "0px 0px 10px rgba(120, 125, 129, 0.2)" : 10,
                      },
                    }),
                  },
                }}
              >
                {!props.open ? (
                  <ChevronRightIcon sx={{ color: "white" }} />
                ) : (
                  <ChevronLeftIcon sx={{ color: "white" }} />
                )}
                <span className="menu-tooltip">
                  <Typography variant="h6">{(props.open ? "Collapse" : "Expand") + " Sidebar"}</Typography>
                </span>
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
  position: "absolute",
  bottom: 0,
  left: 0,
  width: "100%",
  display: "flex",
  alignItems: "center",
  justifyContent: "space-between",
  padding: theme.spacing(1.5),
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

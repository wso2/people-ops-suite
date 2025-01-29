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
import PropTypes from "prop-types";
import React, { useEffect, useRef, useState } from "react";
import { useSelector } from "react-redux";

import { useTheme } from "@mui/material/styles";
import {
  Avatar,
  Box,
  ButtonBase,
  ClickAwayListener,
  IconButton,
  MenuItem,
  MenuList,
  Paper,
  Popper,
  Stack,
  Tooltip,
  Typography,
  useMediaQuery,
} from "@mui/material";

import { LogoutOutlined } from "@ant-design/icons";

import MainCard from "../../../../../components/MainCard";
import Transitions from "../../../../../components/@extended/Transitions";
import { getUserName, logout } from "../../../../../utils/oauth";
import { SERVER_TO_COUNTRY_CODE_MAP } from "../../../../../constants";

function TabPanel({ children, value, index, ...other }) {
  return (
    <div
      role="tabpanel"
      hidden={value !== index}
      id={`profile-tabpanel-${index}`}
      aria-labelledby={`profile-tab-${index}`}
      {...other}
    >
      {value === index && children}
    </div>
  );
}

TabPanel.propTypes = {
  children: PropTypes.node,
  index: PropTypes.any.isRequired,
  value: PropTypes.any.isRequired,
};

const Profile = () => {
  const theme = useTheme();
  const matchesDownSm = useMediaQuery(theme.breakpoints.down("sm"), {
    noSsr: true,
  });
  const { employeeMap } = useSelector((state) => state.menu);
  const [employee, setEmployee] = useState(employeeMap[getUserName()]);
  const [country, setCountry] = useState(null);
  const handleLogout = async () => {
    logout();
  };

  const anchorRef = useRef(null);
  const [open, setOpen] = useState(false);
  const handleToggle = () => {
    setOpen((prevOpen) => !prevOpen);
  };

  const handleClose = (event) => {
    if (anchorRef.current && anchorRef.current.contains(event.target)) {
      return;
    }
    setOpen(false);
  };

  const getUserCountry = () => {
    if (employee && employee.location) {
      return SERVER_TO_COUNTRY_CODE_MAP[employee.location];
    }
  };

  const iconBackColorOpen = "grey.300";

  useEffect(() => {
    setEmployee(employeeMap[getUserName()]);
  }, [employeeMap]);

  useEffect(() => {
    setCountry(getUserCountry());
  }, [employee]);

  return (
    <Box sx={{ flexShrink: 0, ml: 0.75 }}>
      <ButtonBase
        sx={{
          p: 0.25,
          bgcolor: open ? iconBackColorOpen : "transparent",
          "&:hover": { bgcolor: "secondary.lighter" },
          borderRadius: matchesDownSm && "50%",
        }}
        aria-label="open profile"
        ref={anchorRef}
        aria-controls={open ? "profile-grow" : undefined}
        aria-haspopup="true"
        onClick={handleToggle}
      >
        <Stack direction="row" spacing={2} alignItems="center" sx={{ p: 0.5 }}>
          <Avatar
            alt={getUserName()}
            src={employee && employee.employeeThumbnail}
            sx={{ width: 32, height: 32 }}
          />
          {!matchesDownSm && (
            <Typography variant="subtitle1">
              {employee && employee.firstName && employee.lastName
                ? `${employee.firstName} ${employee.lastName}`
                : getUserName()}
            </Typography>
          )}
        </Stack>
      </ButtonBase>
      <Popper
        placement="bottom-end"
        open={open}
        anchorEl={anchorRef.current}
        role={undefined}
        transition
        disablePortal
        popperOptions={{
          modifiers: [
            {
              name: "offset",
              options: {
                offset: [0, 9],
              },
            },
          ],
        }}
      >
        {({ TransitionProps }) => (
          <Transitions type="fade" in={open} {...TransitionProps}>
            {open && (
              <Paper
                sx={{
                  boxShadow: theme.customShadows.z1,
                  width: 290,
                  minWidth: 240,
                  maxWidth: 290,
                  [theme.breakpoints.down("md")]: {
                    maxWidth: 250,
                  },
                }}
              >
                <ClickAwayListener onClickAway={handleClose}>
                  <MainCard elevation={0} border={false} content={false}>
                    <MenuList>
                      <MenuItem>
                        <Stack
                          direction="row"
                          spacing={1.25}
                          alignItems="center"
                        >
                          <Avatar
                            alt={getUserName()}
                            src={
                              employee && employee.employeeThumbnail
                                ? employee.employeeThumbnail
                                : null
                            }
                            sx={{ width: 32, height: 32 }}
                          />
                          <Stack>
                            <Typography variant="h6">
                              {employee &&
                              employee.firstName &&
                              employee.lastName
                                ? `${employee.firstName} ${employee.lastName}`
                                : getUserName()}
                            </Typography>
                            <Typography variant="body">
                              {getUserName()}
                            </Typography>
                          </Stack>
                        </Stack>
                      </MenuItem>
                      <Tooltip
                        title="This is your work location"
                        placement="bottom"
                      >
                        <MenuItem>
                          <Stack
                            direction="row"
                            spacing={1.25}
                            alignItems="center"
                          >
                            {country && (
                              <Box
                                component="li"
                                sx={{ "& > img": { mr: 2, flexShrink: 0 } }}
                              >
                                <img
                                  loading="lazy"
                                  width="20"
                                  src={`https://flagcdn.com/w20/${country.code.toLowerCase()}.png`}
                                  srcSet={`https://flagcdn.com/w40/${country.code.toLowerCase()}.png 2x`}
                                  alt=""
                                />
                                {country.label} ({country.code})
                              </Box>
                            )}
                          </Stack>
                        </MenuItem>
                      </Tooltip>
                      <MenuItem>
                        <Typography variant="h6">Logout</Typography>
                        <IconButton
                          size="large"
                          color="secondary"
                          onClick={handleLogout}
                        >
                          <LogoutOutlined />
                        </IconButton>
                      </MenuItem>
                    </MenuList>
                  </MainCard>
                </ClickAwayListener>
              </Paper>
            )}
          </Transitions>
        )}
      </Popper>
    </Box>
  );
};

export default Profile;

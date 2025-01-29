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
import React, { useEffect, useState } from "react";
import { useDispatch, useSelector } from "react-redux";

import { useTheme } from "@mui/material/styles";
import {
  Avatar,
  Chip,
  ListItemButton,
  ListItemIcon,
  ListItemText,
  Typography,
} from "@mui/material";

import { navigateToView } from "../../../../../store/reducers/menu";

const NavItem = ({ item, level, open }) => {
  const theme = useTheme();
  const dispatch = useDispatch();
  const { openItem, navigatedView } = useSelector((state) => state.menu);
  const [value, setValue] = useState(navigatedView);

  const itemHandler = (newValue) => {
    dispatch(navigateToView({ navigatedView: newValue }));
  };

  const Icon = item.icon;
  const itemIcon = item.icon ? <Icon style={{ fontSize: "1.25rem" }} /> : false;

  const isSelected = openItem.findIndex((id) => id === item.id) > -1;

  useEffect(() => {
    const currentIndex = document.location.pathname
      .toString()
      .split("/")
      .findIndex((id) => id === item.id);
    if (currentIndex > -1) {
      // dispatch(activeItem({ openItem: [item.id] }));
    }
    // eslint-disable-next-line
  }, []);

  useEffect(() => {
    setValue(navigatedView);
  }, [navigatedView]);

  const textColor = "text.primary";
  const iconSelectedColor = "primary.main";

  return (
    <ListItemButton
      disabled={item.disabled}
      onClick={() => itemHandler(item.id)}
      selected={value === item.id}
      sx={{
        pl: `${level * 18}px`,
        py: level === 1 ? 1.25 : 1,
        ...(open && {
          "&:hover": {
            bgcolor: "primary.lighter",
          },
          "&.Mui-selected": {
            bgcolor: "primary.lighter",
            borderRight: `2px solid ${theme.palette.primary.main}`,
            color: iconSelectedColor,
            "&:hover": {
              color: iconSelectedColor,
              bgcolor: "primary.lighter",
            },
          },
        }),
        ...(!open && {
          "&:hover": {
            bgcolor: "primary.lighter",
          },
          "&.Mui-selected": {
            "&:hover": {
              bgcolor: "primary.lighter",
            },
            borderRight: `2px solid ${theme.palette.primary.main}`,
            bgcolor: "primary.lighter",
          },
        }),
      }}
    >
      {itemIcon && (
        <ListItemIcon
          sx={{
            minWidth: 28,
            color: isSelected ? iconSelectedColor : textColor,
            ...{
              borderRadius: 1.5,
              width: 36,
              height: 36,
              alignItems: "center",
              justifyContent: "center",
              "&:hover": {
                bgcolor: "secondary.lighter",
              },
            },
            ...(isSelected && {
              bgcolor: "primary.lighter",
              "&:hover": {
                bgcolor: "primary.lighter",
              },
            }),
          }}
        >
          {itemIcon}
        </ListItemIcon>
      )}
      {open && (
        <ListItemText
          primary={
            <Typography
              variant="h6"
              sx={{ color: isSelected ? iconSelectedColor : textColor }}
            >
              {item.title}
            </Typography>
          }
        />
      )}
      {open && item.chip && (
        <Chip
          color={item.chip.color}
          variant={item.chip.variant}
          size={item.chip.size}
          label={item.chip.label}
          avatar={item.chip.avatar && <Avatar>{item.chip.avatar}</Avatar>}
        />
      )}
    </ListItemButton>
  );
};

NavItem.propTypes = {
  item: PropTypes.object,
  level: PropTypes.number,
  open: PropTypes.bool,
};

export default NavItem;

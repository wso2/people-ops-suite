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
import { Box, Typography, useTheme } from "@mui/material";
import { ChevronDown as ChevronDownIcon } from "lucide-react";
import { ChevronUp as ChevronUpIcon } from "lucide-react";

import React from "react";

import { RouteDetail } from "@root/src/types/types";

interface ListItemLinkProps {
  icon?: React.ReactElement;
  label: string;
  open: boolean;
  isActive: boolean;
  hasChildren: boolean;
  route?: RouteDetail;
}

const LinkItem = (props: ListItemLinkProps) => {
  const { icon, label, open, isActive, hasChildren } = props;
  const theme = useTheme();

  return (
    <Box
      sx={{
        display: "flex",
        alignItems: "center",
        gap: 1,
        padding: 1,
        borderRadius: "8px",
        justifyContent: "space-between",
        transition: "all 0.2s",
        backgroundColor: isActive ? theme.palette.customNavigation.clickedBg : "transparent",
        "&:hover": {
          ...(!isActive && {
            backgroundColor: theme.palette.customNavigation.hoverBg,
          }),
        },
        color: isActive
          ? theme.palette.customNavigation.textClicked
          : theme.palette.customNavigation.text 
      }}
    >
      <Box
        sx={{
          display: "flex",
          alignItems: "center",
          gap: theme.spacing(1),
          justifyContent: "flex-start",
        }}
      >
        {icon && (
          <Box
            sx={{
              display: "flex",
              alignItems: "center",
              "& svg": { width: "20px", height: "20px" },
            }}
          >
            {icon}
          </Box>
        )}
        {open && (
          <Typography
            sx={{
              fontSize: "14px",
              fontWeight: 500,
              lineHeight: "150%",
              letterSpacing: "-0.03em",
            }}
          >
            {label}
          </Typography>
        )}
      </Box>
      {hasChildren && open && (isActive ? <ChevronUpIcon size={18} /> : <ChevronDownIcon size={18} />)}
    </Box>
  );
};
export default LinkItem;

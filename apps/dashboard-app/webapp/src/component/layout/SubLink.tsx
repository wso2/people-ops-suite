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
import Tooltip from "@mui/material/Tooltip";
import { Link, matchPath, useLocation } from "react-router-dom";

import React from "react";

interface SubLinkProps {
  icon?: React.ReactElement;
  primary: string;
  to: string;
  open: boolean;
  parentPath: string;
}

const SubLink = (props: SubLinkProps) => {
  const { icon, primary, to, open, parentPath } = props;
  const location = useLocation();
  const theme = useTheme();

  const fullPath = parentPath.replace(/\/$/, "") + "/" + to.replace(/^\//, "");

  const isActive = !!matchPath({ path: fullPath, end: true }, location.pathname);

  return (
    <>
      {open ? (
        <Box
          component={Link}
          to={fullPath}
          sx={{
            display: "flex",
            alignItems: "center",
            gap: 1,
            paddingX: "8px",
            paddingY: "8px",
            borderRadius: "8px",
            justifyContent: "flex-start",
            textDecoration: "none",
            color: isActive
              ? theme.palette.customNavigation.textClicked
              : theme.palette.customNavigation.text,
            "&:hover": {
              ...(!isActive && {
                backgroundColor: theme.palette.customNavigation.hoverBg,
                color: theme.palette.customNavigation.hover,
              }),
            },
          }}
        >
          {icon && (
            <Box
              sx={{
                display: "flex",
                alignItems: "center",
                "& svg": { width: "17px", height: "17px" },
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
              {primary}
            </Typography>
          )}
        </Box>
      ) : (
        <Box
          component={Link}
          to={fullPath}
          sx={{
            display: "flex",
            alignItems: "center",
            textDecoration: "none",
          }}
        >
          {icon && React.isValidElement(icon) ? (
            <Tooltip title={primary}>
              {React.cloneElement(icon as React.ReactElement<any>, {
                size: 24,
                style: {
                  width: "20px",
                  height: "20px",
                  color: isActive
                    ? theme.palette.customNavigation.textClicked
                    : theme.palette.customNavigation.text,
                },
              })}
            </Tooltip>
          ) : (
            icon
          )}
        </Box>
      )}
    </>
  );
};

export default SubLink;

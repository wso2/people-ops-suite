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

import React from "react";
import { useAppSelector } from "@slices/store";
import ContentCopyIcon from "@mui/icons-material/ContentCopy";
import { Box, Tooltip, Typography, IconButton, Avatar } from "@mui/material";

interface GridAvatarCardProps {
  email: string;
}

const GridAvatarCard: React.FC<GridAvatarCardProps> = ({ email }) => {
  const employeeMap = useAppSelector((state) => state.meteInfo.employeeMap);

  return (
    <Box display="flex" alignItems="center" position="relative">
      <Avatar
        src={employeeMap[email]?.employeeThumbnail}
        alt={employeeMap[email]?.employeeName || email}
        sx={{ marginRight: 2, height: "2.2rem", width: "2.2rem" }}
      />
      <Box
        sx={{
          position: "relative",
          transition: "transform 0.3s ease",
          "&:hover": {
            transform: "translateY(-10px)",
          },
          "&:hover > div": {
            opacity: 1,
          },
        }}
      >
        <Typography variant="body2">{employeeMap[email]?.employeeName || email}</Typography>
        <Box
          sx={{
            position: "absolute",
            top: "100%",
            left: 0,
            display: "flex",
            alignItems: "center",
            padding: "1px 0",
            borderRadius: "4px",
            opacity: 0,
            transition: "opacity 0.3s",
          }}
        >
          <Typography color={"GrayText"} variant="caption" mr={1}>
            {email}
          </Typography>
          <Tooltip title="Copy Email">
            <IconButton
              size="small"
              aria-label="Copy Email"
              onClick={() => {
                navigator.clipboard.writeText(email);
              }}
            >
              <ContentCopyIcon sx={{ fontSize: "15px" }} />
            </IconButton>
          </Tooltip>
        </Box>
      </Box>
    </Box>
  );
};
export default GridAvatarCard;

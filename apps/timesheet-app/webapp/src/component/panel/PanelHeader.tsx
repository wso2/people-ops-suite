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
import { Box, ButtonGroup, IconButton, Tooltip } from "@mui/material";
import { Cached } from "@mui/icons-material";

function PanelHeader(props: {
  refresh?: () => void;
  header?: React.ReactNode;
}) {
  return (
    <Box
      className="panel-con"
      sx={{
        height: "40px",
        width: "100%",
        marginBottom: "0px",
        display: "flex",
        flexDirection: "row",
        justifyContent: "space-between",
        alignItems: "center",
      }}
    >
      {props.header && <div>{props.header}</div>}

      <ButtonGroup>
        {props.refresh && (
          <Tooltip title={"Refresh Page"}>
            <IconButton
              size="small"
              onClick={() => {
                props.refresh && props.refresh();
              }}
            >
              <Cached />
            </IconButton>
          </Tooltip>
        )}
      </ButtonGroup>
    </Box>
  );
}

export default PanelHeader;

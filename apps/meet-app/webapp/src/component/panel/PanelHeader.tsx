// Copyright (c) 2024, WSO2 LLC. (https://www.wso2.com). All Rights Reserved.
//
// This software is the property of WSO2 LLC. and its suppliers, if any.
// Dissemination of any information or reproduction of any material contained
// herein in any form is strictly forbidden, unless permitted by WSO2 expressly.
// You may not alter or remove any copyright or other notice from copies of this content.

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

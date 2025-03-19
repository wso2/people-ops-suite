// Copyright (c) 2024, WSO2 LLC. (https://www.wso2.com). All Rights Reserved.
//
// This software is the property of WSO2 LLC. and its suppliers, if any.
// Dissemination of any information or reproduction of any material contained
// herein in any form is strictly forbidden, unless permitted by WSO2 expressly.
// You may not alter or remove any copyright or other notice from copies of this content.

import React from "react";

// MUI imports
import { Button, IconButton, Stack } from "@mui/material";
import SendIcon from "@mui/icons-material/Send";
import EditIcon from "@mui/icons-material/Edit";

// App imports
import { useConfirmationModalContext } from "@context/DialogContext";
import { ConfirmationType } from "../../../types/types";

const PanelOneToolbar = () => {
  const dialogContext = useConfirmationModalContext();

  return (
    <>
      <Stack flexDirection={"row"} gap={1.5}>
        <Button
          sx={{ borderRadius: 3 }}
          size="small"
          variant="outlined"
          onClick={() => {
            // User confirmation handler.
            dialogContext.showConfirmation(
              "Do you want to Action 1?",
              "Please note that once done, this cannot be undone.",
              ConfirmationType.accept,
              () => {
                // Trigger function.
              }
            );
          }}
        >
          Action 1
        </Button>
        <Button
          sx={{ borderRadius: 3, boxShadow: "none" }}
          variant="contained"
          size="small"
          color="success"
          startIcon={
            <SendIcon
              sx={{
                rotate: "-40deg",
                position: "relative",
                top: -2,
              }}
            />
          }
          onClick={() => {
            // User confirmation handler.
            dialogContext.showConfirmation(
              "Do you want to Action 2?",
              "Please note that once done, this cannot be undone.",
              ConfirmationType.send,
              () => {
                // Trigger function.
              }
            );
          }}
        >
          Action 2
        </Button>
        <IconButton
          size="small"
          sx={{ border: 1, borderColor: "info", borderRadius: 2 }}
          onClick={() => {
            // User confirmation handler.
            dialogContext.showConfirmation(
              "Do you want to Action 3?",
              "Please note that once done, this cannot be undone.",
              ConfirmationType.update,
              () => {
                // Trigger function.
              }
            );
          }}
        >
          <EditIcon fontSize="small" />
        </IconButton>
      </Stack>
    </>
  );
};
export default PanelOneToolbar;

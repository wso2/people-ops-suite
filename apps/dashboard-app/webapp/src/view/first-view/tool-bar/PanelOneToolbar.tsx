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

import EditIcon from "@mui/icons-material/Edit";
import SendIcon from "@mui/icons-material/Send";
import { Button, IconButton, Stack } from "@mui/material";

import { useConfirmationModalContext } from "@context/DialogContext";
import { ConfirmationType } from "@utils/types";

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
              },
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
              },
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
              },
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

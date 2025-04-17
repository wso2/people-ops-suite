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
import { Modal, Paper } from "@mui/material";

interface CustomModalProps {
  open: boolean;
  onClose: () => void;
  width?: string;
  maxHeight?: string;
  children: React.ReactNode;
}

export const CustomModal = ({
  open,
  onClose,
  children,
  width = "80vw",
  maxHeight = "95vh",
}: CustomModalProps) => {
  return (
    <Modal
      open={open}
      onClose={onClose}
      aria-labelledby="dashboard-modal-title"
      aria-describedby="dashboard-modal-description"
    >
      <Paper
        sx={{
          position: "absolute",
          width: width,
          maxHeight: maxHeight,
          bgcolor: "background.paper",
          boxShadow: 24,
          top: "50%",
          left: "50%",
          transform: "translate(-50%, -50%)",
          overflow: "auto",
          borderRadius: "0",
        }}
      >
        {children}
      </Paper>
    </Modal>
  );
};

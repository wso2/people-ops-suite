// Copyright (c) 2025, WSO2 LLC. (https://www.wso2.com). All Rights Reserved.
//
// This software is the property of WSO2 LLC. and its suppliers, if any.
// Dissemination of any information or reproduction of any material contained
// herein in any form is strictly forbidden, unless permitted by WSO2 expressly.
// You may not alter or remove any copyright or other notice from copies of this content.

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

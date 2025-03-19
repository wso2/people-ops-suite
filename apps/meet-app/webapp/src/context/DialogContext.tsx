// Copyright (c) 2024, WSO2 LLC. (https://www.wso2.com). All Rights Reserved.
//
// This software is the property of WSO2 LLC. and its suppliers, if any.
// Dissemination of any information or reproduction of any material contained
// herein in any form is strictly forbidden, unless permitted by WSO2 expressly.
// You may not alter or remove any copyright or other notice from copies of this content.

import React, { useContext, useEffect, useState } from "react";

// MUI Imports
import { IconButton, Stack, TextField, Typography } from "@mui/material";
import CloseIcon from "@mui/icons-material/Close";
import SendIcon from "@mui/icons-material/Send";
import SaveAltIcon from "@mui/icons-material/SaveAlt";
import DoneIcon from "@mui/icons-material/Done";
import Button from "@mui/material/Button";
import Dialog from "@mui/material/Dialog";
import DialogActions from "@mui/material/DialogActions";
import DialogContent from "@mui/material/DialogContent";
import DialogContentText from "@mui/material/DialogContentText";
import DialogTitle from "@mui/material/DialogTitle";
import { AdapterDayjs } from "@mui/x-date-pickers/AdapterDayjs";
import { LocalizationProvider } from "@mui/x-date-pickers/LocalizationProvider";
import LoadingButton from "@mui/lab/LoadingButton";

// APP imports
import { ConfirmationType } from "src/types/types";

type InputObj = {
  label: string;
  mandatory: boolean;
  type: "textarea" | "date";
};

type UseConfirmationDialogShowReturnType = {
  show: boolean;
  setShow: (value: boolean) => void;
  onHide: () => void;
};

const useDialogShow = (): UseConfirmationDialogShowReturnType => {
  const [show, setShow] = useState(false);

  const handleOnHide: () => void = () => {
    setShow(false);
  };

  return {
    show,
    setShow,
    onHide: handleOnHide,
  };
};

type ConfirmationDialogContextType = {
  showConfirmation: (
    title: string,
    message: string | JSX.Element,
    type: ConfirmationType,
    action: () => void,
    okText?: string,
    cancelText?: string,
    inputObj?: InputObj
  ) => void;
};

type ConfirmationModalContextProviderProps = {
  children: React.ReactNode;
};

const ConfirmationModalContext =
  React.createContext<ConfirmationDialogContextType>(
    {} as ConfirmationDialogContextType
  );

const ConfirmationDialogContextProvider: React.FC<
  ConfirmationModalContextProviderProps
> = (props) => {
  const { setShow, show, onHide } = useDialogShow();

  const [comment, setComment] = React.useState("");

  const [content, setContent] = useState<{
    title: string;
    message: string | JSX.Element;
    type: "update" | "send" | "upload" | "accept";
    action: (value?: string) => void;
    okText?: string;
    cancelText?: string;
    inputObj?: InputObj;
  }>({
    title: "",
    message: "",
    type: "send",
    action: () => {},
  });

  const handleShow = (
    title: string,
    message: string | JSX.Element,
    type: "update" | "send" | "upload" | "accept",
    action: (value?: string) => void,
    okText?: string,
    cancelText?: string,
    inputObj?: InputObj
  ) => {
    setContent({
      title,
      message,
      type,
      action,
      okText,
      cancelText,
      inputObj,
    });
    setShow(true);
  };

  const dialogContext: ConfirmationDialogContextType = {
    showConfirmation: handleShow,
  };

  const handleOk = (value?: string) => {
    content && content.action(value);
    onHide();
  };

  const handleCancel = () => {
    Reset();
    onHide();
  };

  const Reset = () => {
    setContent({
      title: "",
      message: "",
      type: "update",
      action: () => {},
      okText: undefined,
      cancelText: undefined,
    });

    setComment("");
  };

  const onChange = (
    event: React.ChangeEvent<HTMLInputElement | HTMLTextAreaElement>
  ) => {
    setComment(event.target.value);
  };

  return (
    <LocalizationProvider dateAdapter={AdapterDayjs}>
      <ConfirmationModalContext.Provider value={dialogContext}>
        {props.children}
        {content && (
          <Dialog
            open={show}
            sx={{
              ".MuiDialog-paper": {
                maxWidth: 350,
                borderRadius: 3,
              },
              backdropFilter: "blur(10px)",
            }}
          >
            <DialogTitle
              variant="h5"
              sx={{
                fontWeight: "bold",
                borderBottom: 1,
                borderColor: "divider",
                mb: 1,
                pd: 0,
              }}
            >
              {content?.title}
            </DialogTitle>
            <IconButton
              aria-label="close"
              onClick={handleCancel}
              sx={{
                position: "absolute",
                right: 8,
                top: 8,
                color: (theme) => theme.palette.grey[500],
              }}
            >
              <CloseIcon />
            </IconButton>
            <DialogContent sx={{ p: 0, m: 0, paddingX: 2 }}>
              <DialogContentText variant="body2">
                {content?.message}
              </DialogContentText>
            </DialogContent>
            {content.inputObj && (
              <TextField
                sx={{ marginX: 2, mt: 2, maxWidth: 350 }}
                value={comment}
                label={content.inputObj?.label}
                type="text"
                size="small"
                multiline
                rows={2}
                maxRows={6}
                onChange={onChange}
              />
            )}

            <DialogActions sx={{ pb: 2, pt: 0, mt: 0, paddingX: 2 }}>
              <Stack flexDirection={"row"} sx={{ mt: 1 }} gap={1}>
                {/* Cancel button */}
                <Button
                  sx={{
                    borderRadius: 2,
                  }}
                  onClick={handleCancel}
                  variant="outlined"
                  size="small"
                >
                  {content?.cancelText ? content.cancelText : "No"}
                </Button>

                {/* Ok button */}
                <LoadingButton
                  type="submit"
                  sx={{
                    borderRadius: 2,
                    boxShadow: "none",
                    border: 0.5,
                    borderColor: "divider",
                  }}
                  variant="contained"
                  size="small"
                  disabled={content?.inputObj?.mandatory && comment === ""}
                  onClick={() =>
                    content?.inputObj ? handleOk(comment) : handleOk()
                  }
                  loadingPosition="start"
                  startIcon={
                    content.type == "update" ? (
                      <SaveAltIcon />
                    ) : content.type == "send" ? (
                      <SendIcon />
                    ) : (
                      <DoneIcon />
                    )
                  }
                >
                  {content?.okText ? content.okText : "Yes"}
                </LoadingButton>
              </Stack>
            </DialogActions>
          </Dialog>
        )}
      </ConfirmationModalContext.Provider>
    </LocalizationProvider>
  );
};

const useConfirmationModalContext = (): ConfirmationDialogContextType =>
  useContext(ConfirmationModalContext);

export { useDialogShow, useConfirmationModalContext };

export default ConfirmationDialogContextProvider;

// Copyright (c) 2024 WSO2 LLC. (https://www.wso2.com).
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
import React, { useState, useEffect, forwardRef } from "react";
import { useDispatch } from "react-redux";

import Button from "@mui/material/Button";
import Dialog from "@mui/material/Dialog";
import DialogActions from "@mui/material/DialogActions";
import DialogContent from "@mui/material/DialogContent";
import DialogTitle from "@mui/material/DialogTitle";
import { Slide, Typography, useMediaQuery } from "@mui/material";
import { useTheme } from "@mui/system";
import { LoadingButton } from "@mui/lab";

import { openBasicDialog } from "../../store/reducers/feedback";

const Transition = forwardRef(function Transition(props, ref) {
  return <Slide direction="up" ref={ref} {...props} />;
});

export default function ConfirmationDialog(props) {
  const theme = useTheme();
  const { isLoading } = props;
  const dispatch = useDispatch();
  const [open, setOpen] = useState(props.open);
  const matchesMdDown = useMediaQuery(theme.breakpoints.down("md"));
  const { title, message, okCallback, closeCallback } = props;

  const handleClose = () => {
    closeCallback && closeCallback();
    setOpen(false);
    dispatch(
      openBasicDialog({
        openBasicDialog: false,
        basicDialogMessage: "",
        basicDialogCallbackFn: () => {},
      })
    );
  };

  useEffect(() => {
    setOpen(props.open);
  }, [props.open]);
  useEffect(() => {}, [title, message, okCallback, closeCallback, isLoading]);

  return (
    <Dialog
      open={open}
      TransitionComponent={Transition}
      onClose={handleClose}
      maxWidth={matchesMdDown ? "sm" : "md"}
      fullWidth
      aria-labelledby="alert-dialog-title"
      aria-describedby="alert-dialog-description"
    >
      <DialogTitle id="alert-dialog-title">
        <Typography variant="h5">{title ? title : "Confirmation"}</Typography>
      </DialogTitle>
      <DialogContent>
        <Typography variant="body1" id="alert-dialog-description">
          {message ? message : "Click okay to confirm action."}
        </Typography>
      </DialogContent>
      <DialogActions>
        <Button onClick={handleClose} variant="outlined" size="small">
          Close
        </Button>
        <LoadingButton
          loading={isLoading}
          onClick={okCallback}
          color="secondary"
          variant="contained"
          size="small"
        >
          Confirm
        </LoadingButton>
      </DialogActions>
    </Dialog>
  );
}

// Copyright (c) 2025, WSO2 LLC. (https://www.wso2.com). All Rights Reserved.
//
// This software is the property of WSO2 LLC. and its suppliers, if any.
// Dissemination of any information or reproduction of any material contained
// herein in any form is strictly forbidden, unless permitted by WSO2 expressly.
// You may not alter or remove any copyright or other notice from copies of this content.

import { createSlice, PayloadAction } from "@reduxjs/toolkit";
import { VariantType } from "notistack";

import { AppDispatch } from "@slices/store";

export interface CommonState {
  message: string;
  timestamp: number | null;
  type: VariantType;
}

const initialState: CommonState = {
  message: "",
  timestamp: null,
  type: "success",
};

export const CommonSlice = createSlice({
  name: "common",
  initialState,
  reducers: {
    enqueueSnackbarMessage: (
      state,
      action: PayloadAction<{
        message: string;
        type: "success" | "error" | "warning";
      }>
    ) => {
      state.message = action.payload.message;
      state.type = action.payload.type;
      state.timestamp = Date.now();
    },
  },
});

export function ShowSnackBarMessage(message: string, type: VariantType) {
  return (dispatch: AppDispatch) => {
    dispatch({
      type: "common/enqueueSnackbarMessage",
      payload: {
        message: message,
        type: "success",
      },
    });
  };
}

export const { enqueueSnackbarMessage } = CommonSlice.actions;

export default CommonSlice.reducer;

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

import { VariantType } from "notistack";
import { AppDispatch } from "@slices/store";
import { createSlice, PayloadAction } from "@reduxjs/toolkit";

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

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
import { createSlice } from "@reduxjs/toolkit";

const initialState = {
  isLoading: false,
  openBasicDialog: false,
  basicDialogInfo: {},
  basicDialogCallbackFn: () => {},
  showSnackbar: false,
  snackbarAlertStack: [],
};

const menu = createSlice({
  name: "feedback",
  initialState,
  reducers: {
    openBasicDialog(state, action) {
      state.openBasicDialog = action.payload.openBasicDialog;
      state.basicDialogInfo = { message: action.payload.basicDialogMessage };
      state.basicDialogCallbackFn = action.payload.basicDialogCallbackFn;
    },

    showSnackbar(state, action) {
      state.snackbarAlertStack = [
        ...state.snackbarAlertStack,
        { message: action.payload.snackbarMessage, key: new Date().getTime() },
      ];
    },

    handleIsLoading(state, action) {
      state.isLoading = action.payload.isLoading;
    },
  },
});

export default menu.reducer;

export const { openBasicDialog, showSnackbar, handleIsLoading } = menu.actions;

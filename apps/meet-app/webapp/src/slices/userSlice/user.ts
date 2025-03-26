// Copyright (c) 2025, WSO2 LLC. (https://www.wso2.com). All Rights Reserved.
//
// This software is the property of WSO2 LLC. and its suppliers, if any.
// Dissemination of any information or reproduction of any material contained
// herein in any form is strictly forbidden, unless permitted by WSO2 expressly.
// You may not alter or remove any copyright or other notice from copies of this content.

import { createSlice, createAsyncThunk, PayloadAction } from "@reduxjs/toolkit";
import { APIService } from "@utils/apiService";
import { AppConfig } from "@config/config";
import { State } from "@/types/types";

const initialState: UserState = {
  state: State.idle,
  stateMessage: null,
  errorMessage: null,
  userInfo: null,
};

interface UserState {
  state: State;
  stateMessage: string | null;
  errorMessage: string | null;
  userInfo: UserInfoInterface | null;
}

interface UserInfoInterface {
  employeeId: string;
  firstName: string;
  lastName: string;
  workEmail: string;
  employeeThumbnail: string;
  jobRole: string;
}

export const getUserInfo = createAsyncThunk("User/getUserInfo", async () => {
  return new Promise<{
    UserInfo: UserInfoInterface;
  }>((resolve, reject) => {
    APIService.getInstance()
      .get(AppConfig.serviceUrls.userInfo)
      .then((resp) => {
        resolve({
          UserInfo: resp.data,
        });
      })
      .catch((error: Error) => {
        reject(error);
      });
  });
});

export const UserSlice = createSlice({
  name: "getUserInfo",
  initialState,
  reducers: {
    updateStateMessage: (state, action: PayloadAction<string>) => {
      state.stateMessage = action.payload;
    },
  },
  extraReducers: (builder) => {
    builder
      .addCase(getUserInfo.pending, (state, action) => {
        state.state = State.loading;
        state.stateMessage = "Checking User Info";
      })
      .addCase(getUserInfo.fulfilled, (state, action) => {
        state.userInfo = action.payload.UserInfo;
        state.state = State.success;
      })
      .addCase(getUserInfo.rejected, (state) => {
        state.state = State.failed;
      });
  },
});

export const { updateStateMessage } = UserSlice.actions;

export default UserSlice.reducer;

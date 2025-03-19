// Copyright (c) 2024, WSO2 LLC. (https://www.wso2.com). All Rights Reserved.
//
// This software is the property of WSO2 LLC. and its suppliers, if any.
// Dissemination of any information or reproduction of any material contained
// herein in any form is strictly forbidden, unless permitted by WSO2 expressly.
// You may not alter or remove any copyright or other notice from copies of this content.

import { createSlice, PayloadAction } from "@reduxjs/toolkit";
import { RootState } from "../store";
import { AuthState, AuthData } from "../../utils/types";
import { State } from "../../types/types";
import { RECRUITMENT_ADMIN, RECRUITMENT_TEAM } from "@config/config";

const initialState: AuthState = {
  isAuthenticated: false,
  status: State.idle,
  mode: "active",
  statusMessage: null,
  userInfo: null,
  decodedIdToken: null,
  roles: [],
};

export const authSlice = createSlice({
  name: "auth",
  initialState,
  reducers: {
    setUserAuthData: (state, action: PayloadAction<AuthData>) => {
      state.userInfo = action.payload.userInfo;
      state.decodedIdToken = action.payload.decodedIdToken;
      var roles: string[] = [];
      var userPrivileges: string[] = action.payload.decodedIdToken.groups;
      if (userPrivileges.includes(RECRUITMENT_ADMIN)) {
        roles.push(RECRUITMENT_ADMIN);
      }
      if (userPrivileges.includes(RECRUITMENT_TEAM)) {
        roles.push(RECRUITMENT_TEAM);
      }
      state.roles = roles;
      state.status = State.success;
    },
  },
});
export const { setUserAuthData } = authSlice.actions;
export const selectUserInfo = (state: RootState) => state.auth.userInfo;
export const selectRoles = (state: RootState) => state.auth.roles;
export default authSlice.reducer;

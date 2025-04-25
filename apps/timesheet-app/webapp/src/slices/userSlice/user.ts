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

import { AxiosError } from "axios";
import { RootState } from "@slices/store";
import { AppConfig } from "@config/config";
import { APIService } from "@utils/apiService";
import { Roles, State, WorkPolicies } from "@utils/types";
import { createSlice, createAsyncThunk, PayloadAction } from "@reduxjs/toolkit";

const initialState: UserState = {
  state: State.idle,
  stateMessage: null,
  errorMessage: null,
  userInfo: null,
  roles: [],
  privileges: [],
  workPolicies: {} as WorkPolicies,
};

interface UserState {
  state: State;
  stateMessage: string | null;
  errorMessage: string | null;
  userInfo: UserInfoInterface | null;
  roles: Roles[];
  privileges: number[];
  workPolicies: WorkPolicies;
}

interface EmployeeInfo {
  employeeId: string;
  firstName: string;
  lastName: string;
  workEmail: string;
  employeeThumbnail: string | null;
  managerEmail: string;
  jobRole: string;
  company: string;
  lead: boolean;
}

interface UserInfoInterface {
  employeeInfo: EmployeeInfo;
  jobRole: string;
  privileges: number[];
  workPolicies: WorkPolicies;
}

export const getUserInfo = createAsyncThunk("User/getUserInfo", async (_, { rejectWithValue }) => {
  try {
    const resp = await APIService.getInstance().get(AppConfig.serviceUrls.getUserInfo);
    return {
      UserInfo: resp.data,
    };
  } catch (error: any) {
    const axiosError = error as AxiosError;
    const status = axiosError.response?.status;
    const message = "Request failed";

    return rejectWithValue({ status, message });
  }
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
        const userInfo = action.payload.UserInfo;
        state.userInfo = userInfo;
        var roles = [];
        if (userInfo.privileges.includes(987)) {
          roles.push(Roles.EMPLOYEE);
        }
        if (userInfo.privileges.includes(862)) {
          roles.push(Roles.LEAD);
        }
        if (userInfo.privileges.includes(762)) {
          roles.push(Roles.ADMIN);
        }
        state.roles = roles;
        state.state = State.success;
      })
      .addCase(getUserInfo.rejected, (state, action: any) => {
        state.state = State.failed;

        const status = action.payload?.status;

        switch (status) {
          case 401:
            state.stateMessage = "You are not authorized.";
            break;
          case 403:
            state.stateMessage = "Forbidden: You do not have access to the system.";
            break;
          case 404:
            state.stateMessage = "User not found.";
            break;
          case 500:
            state.stateMessage = "Server error. Please try again later.";
            break;
          default:
            state.stateMessage = "Failed to retrieve user info.";
        }
      });
  },
});

export const selectRoles = (state: RootState) => state.user.roles;
export const { updateStateMessage } = UserSlice.actions;

export default UserSlice.reducer;

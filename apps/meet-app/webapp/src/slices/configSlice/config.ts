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

import { State } from "@/types/types";
import { AppConfig } from "@config/config";
import axios, { HttpStatusCode } from "axios";
import { APIService } from "@utils/apiService";
import { SnackMessage } from "@config/constant";
import { createSlice, createAsyncThunk } from "@reduxjs/toolkit";
import { enqueueSnackbarMessage } from "@slices/commonSlice/common";

interface SupportTeamEmail {
  team: string;
  email: string;
}

interface AppConfigInfo {
  supportTeamEmails: SupportTeamEmail[];
}

interface AppConfigState {
  state: State;
  stateMessage: string | null;
  errorMessage: string | null;
  config: AppConfigInfo | null;
}

const initialState: AppConfigState = {
  state: State.idle,
  stateMessage: null,
  errorMessage: null,
  config: null,
};

export const fetchAppConfig = createAsyncThunk(
  "appConfig/fetchAppConfig",
  async (_, {dispatch, rejectWithValue }) => {
    APIService.getCancelToken().cancel();
    const newCancelTokenSource = APIService.updateCancelToken();
    return new Promise<AppConfigInfo>((resolve, reject) => {
      APIService.getInstance()
        .get(AppConfig.serviceUrls.appConfig, {
          cancelToken: newCancelTokenSource.token,
        })
        .then((response) => {
          resolve(response.data);
        })
        .catch((error) => {
          if (axios.isCancel(error)) {
            return rejectWithValue("Request canceled");
          }
          dispatch(
            enqueueSnackbarMessage({
              message:
                error.response?.status === HttpStatusCode.InternalServerError
                  ? SnackMessage.error.fetchAppConfigMessage
                  : "An unknown error occurred.",
              type: "error",
            })
          );
          reject(error.response.data.message);
        });
    });
  }
);

const AppConfigSlice = createSlice({
  name: "appConfig",
  initialState,
  reducers: {
    resetSubmitState(state) {
      state.state = State.idle;
    },
  },
  extraReducers: (builder) => {
    builder
      .addCase(fetchAppConfig.pending, (state) => {
        state.state = State.loading;
        state.stateMessage = "Fetching application configurations...";
      })
      .addCase(fetchAppConfig.fulfilled, (state, action) => {
        state.state = State.success;
        state.stateMessage = "Successfully fetched app configurations!";
        state.config = action.payload;
      })
      .addCase(fetchAppConfig.rejected, (state) => {
        state.state = State.failed;
        state.stateMessage = "Failed to fetch application configurations.";
      });
  },
});

export const { resetSubmitState } = AppConfigSlice.actions;
export default AppConfigSlice.reducer;

// Copyright (c) 2026 WSO2 LLC. (https://www.wso2.com).
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

interface Regions {
  regions: string[];
}

interface RegionsState {
  state: State;
  submitState: State;
  stateMessage: string | null;
  errorMessage: string | null;
  regions: Regions | null;
  backgroundProcess: boolean;
  backgroundProcessMessage: string | null;
}

const initialState: RegionsState = {
  state: State.idle,
  submitState: State.idle,
  stateMessage: "",
  errorMessage: "",
  regions: null,
  backgroundProcess: false,
  backgroundProcessMessage: null,
};

export const fetchRegions = createAsyncThunk(
  "region/fetchRegions",
  async (_, { dispatch, rejectWithValue }) => {
    APIService.getCancelToken().cancel();
    const newCancelTokenSource = APIService.updateCancelToken();
    return new Promise<Regions>((resolve, reject) => {
      APIService.getInstance()
        .get(AppConfig.serviceUrls.regions, {
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
                  ? SnackMessage.error.fetchRegions
                  : "An unknown error occurred.",
              type: "error",
            }),
          );
          reject(error.response.data.message);
        });
    });
  },
);

const RegionsSlice = createSlice({
  name: "region",
  initialState,
  reducers: {
    resetSubmitState(state) {
      state.submitState = State.idle;
    },
  },
  extraReducers: (builder) => {
    builder
      .addCase(fetchRegions.pending, (state) => {
        state.state = State.loading;
        state.stateMessage = "Fetching region...";
      })
      .addCase(fetchRegions.fulfilled, (state, action) => {
        state.state = State.success;
        state.stateMessage = "Successfully fetched!";
        state.regions = action.payload;
      })
      .addCase(fetchRegions.rejected, (state) => {
        state.state = State.failed;
        state.stateMessage = "Failed to fetch regions!";
      });
  },
});

export const { resetSubmitState } = RegionsSlice.actions;
export default RegionsSlice.reducer;

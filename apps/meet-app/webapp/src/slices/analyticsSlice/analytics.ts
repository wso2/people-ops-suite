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

import { State } from "../../types/types";
import { AppConfig } from "../../config/config";
import { APIService } from "../../utils/apiService";
import { createSlice, createAsyncThunk, PayloadAction } from "@reduxjs/toolkit";
import axios, { HttpStatusCode } from "axios";
import { SnackMessage } from "@root/src/config/constant";
import { enqueueSnackbarMessage } from "../commonSlice/common";

export interface MonthlyStat {
  year: number;
  month: number;
  recordingCount: number;
  scheduledCount: number;
}

export interface TypeStat {
  meeting_type: string;
  count: number;
}

export interface RegionStat {
  name: string;
  value: number;
}

export interface Stat {
  name: string;
  value: number;
  email: string;
}

export interface AnalyticsState {
  state: State;
  stateMessage: string | null;
  errorMessage: string | null;
  recordingStats: MonthlyStat[];
  typeStats: TypeStat[];
  regionalStats: RegionStat[];
  amStats: Stat[];
  toStats: Stat[];
}

const initialState: AnalyticsState = {
  state: State.idle,
  stateMessage: null,
  errorMessage: null,
  recordingStats: [],
  typeStats: [],
  regionalStats: [],
  amStats: [],
  toStats: [],
};

interface Analytics {
  monthlyStats: MonthlyStat[];
  typeStats: TypeStat[];
  regionalStats: RegionStat[];
  amStats: Stat[];
  toStats: Stat[];
}

export const getRecordingStats = createAsyncThunk(
  "analytics/getRecordingStats",
  async (
    { startDate, endDate }: { startDate: string; endDate: string },
    { dispatch, rejectWithValue },
  ) => {
    APIService.getCancelToken().cancel();
    const newCancelTokenSource = APIService.updateCancelToken();
    return new Promise<Analytics>((resolve, reject) => {
      APIService.getInstance()
        .get(AppConfig.serviceUrls.analyticsRecordings, {
          params: { startDate, endDate },
          cancelToken: newCancelTokenSource.token,
        })
        .then((resp) => {
          resolve(resp.data);
        })
        .catch((error) => {
          if (axios.isCancel(error)) {
            return rejectWithValue("Request canceled");
          }
          const errorMessage =
            error.response?.data?.message ||
            (error.response?.status === HttpStatusCode.InternalServerError
              ? SnackMessage.error.fetchRecordingStatsMessage
              : "An unknown error occurred.");
          dispatch(
            enqueueSnackbarMessage({
              message: errorMessage,
              type: "error",
            }),
          );
          reject(error);
        });
    });
  },
);

export const AnalyticsSlice = createSlice({
  name: "analytics",
  initialState,
  reducers: {
    updateStateMessage: (state, action: PayloadAction<string>) => {
      state.stateMessage = action.payload;
    },
  },
  extraReducers: (builder) => {
    builder
      .addCase(getRecordingStats.pending, (state) => {
        state.state = State.loading;
        state.stateMessage = "Fetching analytics data...";
      })
      .addCase(getRecordingStats.fulfilled, (state, action) => {
        state.recordingStats = action.payload.monthlyStats;
        state.typeStats = action.payload.typeStats;
        state.regionalStats = action.payload.regionalStats;
        state.amStats = action.payload.amStats;
        state.toStats = action.payload.toStats;
        state.state = State.success;
      })
      .addCase(getRecordingStats.rejected, (state, action) => {
        state.state = State.failed;
        state.errorMessage = "Failed to load analytics data.";
      });
  },
});

export const { updateStateMessage } = AnalyticsSlice.actions;
export default AnalyticsSlice.reducer;

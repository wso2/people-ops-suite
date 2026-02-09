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

export interface AmStat {
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
  amStats: AmStat[];
}

const initialState: AnalyticsState = {
  state: State.idle,
  stateMessage: null,
  errorMessage: null,
  recordingStats: [],
  typeStats: [],
  regionalStats: [],
  amStats: [],
};

export const getRecordingStats = createAsyncThunk(
  "analytics/getRecordingStats",
  async (params: { startDate: string; endDate: string }) => {
    return new Promise<{ monthlyStats: MonthlyStat[]; typeStats: TypeStat[]; regionalStats: RegionStat[]; amStats: AmStat[] }>((resolve, reject) => {
      APIService.getInstance()
        .get(`${AppConfig.serviceUrls.analyticsRecordings}?startDate=${params.startDate}&endDate=${params.endDate}`)
        .then((resp) => {
          resolve(resp.data);
        })
        .catch((error: Error) => {
          reject(error);
        });
    });
  }
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

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

import { AppConfig } from "@config/config";
import { Messages } from "@config/constant";
import axios, { HttpStatusCode } from "axios";
import { APIService } from "@utils/apiService";
import { createSlice } from "@reduxjs/toolkit";
import { createAsyncThunk } from "@reduxjs/toolkit";
import { enqueueSnackbarMessage } from "../commonSlice/common";
import {
  CreateTimeLogsPayload,
  State,
  TimeLogReview,
  TimesheetData,
  TimesheetStatus,
  TimesheetUpdate,
} from "@utils/types";

interface TimesheetRecordState {
  retrievingState: State;
  submitState: State;
  stateMessage: string | null;
  errorMessage: string | null;
  timesheetData: TimesheetData | null;
  backgroundProcess: boolean;
  backgroundProcessMessage: string | null;
}

const initialState: TimesheetRecordState = {
  retrievingState: State.idle,
  submitState: State.idle,
  stateMessage: "",
  errorMessage: "",
  timesheetData: null,
  backgroundProcess: false,
  backgroundProcessMessage: null,
};

export const addTimesheetRecords = createAsyncThunk(
  "timesheet/addTimesheetRecords",
  async ({ payload }: { payload: CreateTimeLogsPayload }, { dispatch }) => {
    return new Promise((resolve, reject) => {
      APIService.getInstance()
        .post(`${AppConfig.serviceUrls.timesheetRecords}`, payload)
        .then((response) => {
          dispatch(
            enqueueSnackbarMessage({
              message: Messages.success.saveRecords,
              type: "success",
            })
          );
          resolve(response.data);
        })
        .catch((error) => {
          const errorMessage =
            error.response?.status === HttpStatusCode.InternalServerError
              ? Messages.error.sendRecords
              : error.response?.data?.message || "An unexpected error occurred";
          dispatch(
            enqueueSnackbarMessage({
              message: errorMessage,
              type: "error",
            })
          );
          reject(error);
        });
    });
  }
);

export const fetchTimesheetRecords = createAsyncThunk(
  "timesheet/fetchTimesheetRecords",
  async (
    params: {
      employeeEmail?: string;
      status?: TimesheetStatus;
      limit?: number;
      offset?: number;
      rangeStart?: string;
      rangeEnd?: string;
      leadEmail?: string;
    },
    { dispatch, rejectWithValue }
  ) => {
    APIService.getCancelToken().cancel();
    const newCancelTokenSource = APIService.updateCancelToken();

    const queryParams = new URLSearchParams();
    if (params.employeeEmail) queryParams.append("employeeEmail", params.employeeEmail);
    if (params.status) queryParams.append("status", params.status);
    if (params.limit) queryParams.append("limit", params.limit.toString());
    if (params.offset) queryParams.append("offset", params.offset.toString());
    if (params.rangeStart) queryParams.append("rangeStart", params.rangeStart);
    if (params.rangeEnd) queryParams.append("rangeEnd", params.rangeEnd);
    if (params.leadEmail) queryParams.append("leadEmail", params.leadEmail);

    return new Promise<TimesheetData>((resolve, reject) => {
      APIService.getInstance()
        .get(`${AppConfig.serviceUrls.timesheetRecords}?${queryParams.toString()}`, {
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
                  ? Messages.error.fetchRecords
                  : String(error.response?.data?.message || error.message),
              type: "error",
            })
          );
          reject(error.response?.data?.message || error.message);
        });
    });
  }
);

export const updateTimesheetRecord = createAsyncThunk(
  "timesheet/updateTimesheetRecord",
  async (
    params: {
      employeeEmail: string;
      recordId: number;
      timesheetRecord: TimesheetUpdate;
    },
    { dispatch, rejectWithValue }
  ) => {
    try {
      APIService.getCancelToken().cancel();
      const newCancelTokenSource = APIService.updateCancelToken();

      await APIService.getInstance().patch(
        `${AppConfig.serviceUrls.employees}/${params.employeeEmail}/time-log/${params.recordId}`,
        params.timesheetRecord,
        {
          cancelToken: newCancelTokenSource.token,
          headers: {
            "Content-Type": "application/json",
          },
        }
      );

      dispatch(
        enqueueSnackbarMessage({
          message: Messages.success.updateRecord,
          type: "success",
        })
      );

      return { success: true };
    } catch (error) {
      if (axios.isAxiosError(error)) {
        if (error.code === "ERR_CANCELED") {
          return rejectWithValue("Request canceled");
        }

        const errorMessage =
          error.response?.status === HttpStatusCode.InternalServerError
            ? Messages.error.updateRecords
            : String(error.response?.data?.message || error.message);

        dispatch(
          enqueueSnackbarMessage({
            message: errorMessage,
            type: "error",
          })
        );

        return rejectWithValue(errorMessage);
      }

      const errorMessage = error instanceof Error ? error.message : "Unknown error";
      dispatch(
        enqueueSnackbarMessage({
          message: errorMessage,
          type: "error",
        })
      );
      return rejectWithValue(errorMessage);
    }
  }
);

export const updateTimesheetRecords = createAsyncThunk(
  "timesheet/updateTimesheetRecords",
  async (
    params: {
      payload: TimeLogReview;
    },
    { dispatch, rejectWithValue }
  ) => {
    try {
      APIService.getCancelToken().cancel();
      const newCancelTokenSource = APIService.updateCancelToken();

      await APIService.getInstance().patch(`${AppConfig.serviceUrls.timesheetRecords}`, params.payload, {
        cancelToken: newCancelTokenSource.token,
        headers: {
          "Content-Type": "application/json",
        },
      });

      dispatch(
        enqueueSnackbarMessage({
          message: Messages.success.updateRecord,
          type: "success",
        })
      );

      return { success: true };
    } catch (error) {
      if (axios.isAxiosError(error)) {
        if (error.code === "ERR_CANCELED") {
          return rejectWithValue("Request canceled");
        }

        const errorMessage =
          error.response?.status === HttpStatusCode.InternalServerError
            ? Messages.error.updateRecords
            : String(error.response?.data?.message || error.message);

        dispatch(
          enqueueSnackbarMessage({
            message: errorMessage,
            type: "error",
          })
        );

        return rejectWithValue(errorMessage);
      }

      const errorMessage = error instanceof Error ? error.message : "Unknown error";
      dispatch(
        enqueueSnackbarMessage({
          message: errorMessage,
          type: "error",
        })
      );
      return rejectWithValue(errorMessage);
    }
  }
);

const TimesheetRecordSlice = createSlice({
  name: "timesheetRecord",
  initialState,
  reducers: {
    resetSubmitSate(state) {
      state.submitState = State.idle;
    },
    resetTimesheetRecords(state) {
      state.timesheetData = null;
      state.retrievingState = State.idle;
    },
  },
  extraReducers: (builder) => {
    builder
      .addCase(fetchTimesheetRecords.pending, (state) => {
        state.retrievingState = State.loading;
        state.stateMessage = "Fetching records...";
      })
      .addCase(fetchTimesheetRecords.fulfilled, (state, action) => {
        state.retrievingState = State.success;
        state.stateMessage = "Successfully fetched!";
        state.timesheetData = action.payload;
      })
      .addCase(fetchTimesheetRecords.rejected, (state) => {
        state.retrievingState = State.failed;
        state.stateMessage = "Failed to fetch!";
      })
      .addCase(addTimesheetRecords.pending, (state) => {
        state.submitState = State.loading;
        state.stateMessage = "Creating records...";
      })
      .addCase(addTimesheetRecords.fulfilled, (state) => {
        state.submitState = State.success;
        state.stateMessage = "Successfully created!";
      })
      .addCase(addTimesheetRecords.rejected, (state) => {
        state.submitState = State.failed;
        state.stateMessage = "Failed to create!";
      })
      .addCase(updateTimesheetRecords.pending, (state) => {
        state.submitState = State.loading;
        state.stateMessage = "Updating records...";
      })
      .addCase(updateTimesheetRecords.fulfilled, (state) => {
        state.submitState = State.success;
        state.stateMessage = "Successfully updated!";
      })
      .addCase(updateTimesheetRecords.rejected, (state) => {
        state.submitState = State.failed;
        state.stateMessage = "Failed to update!";
      })
      .addCase(updateTimesheetRecord.pending, (state) => {
        state.submitState = State.loading;
        state.stateMessage = "Updating record...";
      })
      .addCase(updateTimesheetRecord.fulfilled, (state) => {
        state.submitState = State.success;
        state.stateMessage = "Successfully updated!";
      })
      .addCase(updateTimesheetRecord.rejected, (state) => {
        state.submitState = State.failed;
        state.stateMessage = "Failed to update!";
      });
  },
});

export const { resetSubmitSate, resetTimesheetRecords } = TimesheetRecordSlice.actions;
export default TimesheetRecordSlice.reducer;

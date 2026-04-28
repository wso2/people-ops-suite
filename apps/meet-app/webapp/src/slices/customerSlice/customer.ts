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

interface Customer {
  id: string;
  name: string;
}
interface customerMeetingsSummary {
  customerName: string;
  meetingCount: number;
}
interface MeetingsSummary {
  meetingsSummary: customerMeetingsSummary[];
  count: number;
}
interface CustomerState {
  state: State;
  submitState: State;
  meetingsSummaryState: State;
  stateMessage: string | null;
  errorMessage: string | null;
  customers: Customer[] | null;
  meetingsSummary: MeetingsSummary | null;
  backgroundProcess: boolean;
  backgroundProcessMessage: string | null;
}
const initialState: CustomerState = {
  state: State.idle,
  submitState: State.idle,
  meetingsSummaryState: State.idle,
  stateMessage: "",
  errorMessage: "",
  customers: null,
  meetingsSummary: null,
  backgroundProcess: false,
  backgroundProcessMessage: null,
};

export const fetchCustomers = createAsyncThunk(
  "customer/fetchCustomers",
  async (_, { dispatch, rejectWithValue }) => {
    APIService.getCancelToken().cancel();
    const newCancelTokenSource = APIService.updateCancelToken();
    return new Promise<Customer[]>((resolve, reject) => {
      APIService.getInstance()
        .get(AppConfig.serviceUrls.customers, {
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
                  ? SnackMessage.error.fetchCustomers
                  : "An unknown error occurred.",
              type: "error",
            }),
          );
          reject(error.response.data.message);
        });
    });
  },
);

export const fetchCustomersMeetingsSummary = createAsyncThunk(
  "customers/fetchMeetingsSummary",
  async (
    {
      customerName,
      limit,
      offset,
    }: {
      customerName: string | null;
      limit: number;
      offset: number;
    },
    { dispatch, rejectWithValue },
  ) => {
    APIService.getCancelToken().cancel();
    const newCancelTokenSource = APIService.updateCancelToken();
    return new Promise<MeetingsSummary>((resolve, reject) => {
      APIService.getInstance()
        .get(AppConfig.serviceUrls.customersMeetingsSummary, {
          params: { customerName, limit, offset },
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
                  ? SnackMessage.error.fetchCustomersMeetingsSummary
                  : "An unknown error occurred when retrieving the customers meetings summary",
              type: "error",
            }),
          );
          reject(error?.response?.data?.message ?? error?.message ?? "Request failed");
        });
    });
  },
);

function mergeCustomerSummary(
  current: MeetingsSummary | null,
  newData: MeetingsSummary,
  offset: number,
): MeetingsSummary {
  if (offset === 0 || !current) {
    return newData;
  }
  return {
    count: newData.count,
    meetingsSummary: [...current.meetingsSummary, ...newData.meetingsSummary],
  };
}

const CustomerSlice = createSlice({
  name: "customer",
  initialState,
  reducers: {
    resetSubmitState(state) {
      state.submitState = State.idle;
    },
  },
  extraReducers: (builder) => {
    builder
      .addCase(fetchCustomers.pending, (state) => {
        state.state = State.loading;
        state.stateMessage = "Fetching customers...";
      })
      .addCase(fetchCustomers.fulfilled, (state, action) => {
        state.state = State.success;
        state.stateMessage = "Successfully fetched!";
        state.customers = action.payload;
      })
      .addCase(fetchCustomers.rejected, (state) => {
        state.state = State.failed;
        state.stateMessage = "Failed to fetch customers!";
      })
      .addCase(fetchCustomersMeetingsSummary.pending, (state) => {
        state.meetingsSummaryState = State.loading;
        state.stateMessage = "Fetching customers meetings summary...";
      })
      .addCase(fetchCustomersMeetingsSummary.fulfilled, (state, action) => {
        state.meetingsSummaryState = State.success;
        state.stateMessage = "Successfully fetched!";
        const offset = action.meta.arg.offset;
        state.meetingsSummary = mergeCustomerSummary(
          state.meetingsSummary,
          action.payload,
          offset,
        );
      })
      .addCase(fetchCustomersMeetingsSummary.rejected, (state) => {
        state.meetingsSummaryState = State.failed;
        state.stateMessage = "Failed to fetch meetings summary!";
      });
  },
});

export const { resetSubmitState } = CustomerSlice.actions;
export default CustomerSlice.reducer;

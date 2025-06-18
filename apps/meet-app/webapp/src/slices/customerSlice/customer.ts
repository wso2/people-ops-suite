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

interface CustomerState {
  state: State;
  submitState: State;
  stateMessage: string | null;
  errorMessage: string | null;
  customers: Customer[] | null;
  backgroundProcess: boolean;
  backgroundProcessMessage: string | null;
}

const initialState: CustomerState = {
  state: State.idle,
  submitState: State.idle,
  stateMessage: "",
  errorMessage: "",
  customers: null,
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
            })
          );
          reject(error.response.data.message);
        });
    });
  }
);

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
  },
});

export const { resetSubmitState } = CustomerSlice.actions;
export default CustomerSlice.reducer;

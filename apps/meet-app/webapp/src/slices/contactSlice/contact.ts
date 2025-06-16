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


interface Contact {
  name: string;
  email: string;
}

interface ContactState {
  state: State;
  submitState: State;
  stateMessage: string | null;
  errorMessage: string | null;
  contacts: Contact[] | null;
  backgroundProcess: boolean;
  backgroundProcessMessage: string | null;
}

const initialState: ContactState = {
  state: State.idle,
  submitState: State.idle,
  stateMessage: "",
  errorMessage: "",
  contacts: null,
  backgroundProcess: false,
  backgroundProcessMessage: null,
};

export const fetchContacts = createAsyncThunk(
  "contact/fetchContacts",
  async ({customerId}: {customerId:string | null}, { dispatch, rejectWithValue }) => {
    APIService.getCancelToken().cancel();
    const newCancelTokenSource = APIService.updateCancelToken();
    return new Promise<Contact[]>((resolve, reject) => {
      APIService.getInstance()
        .get(AppConfig.serviceUrls.contacts, {
          params: {customerId},
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
                  ? SnackMessage.error.fetchContacts
                  : "An unknown error occurred.",
              type: "error",
            })
          );
          reject(error.response.data.message);
        });
    });
  }
);

const ContactSlice = createSlice({
  name: "contact",
  initialState,
  reducers: {
    resetSubmitState(state) {
      state.submitState = State.idle;
    },
  },
  extraReducers: (builder) => {
    builder
      .addCase(fetchContacts.pending, (state) => {
        state.state = State.loading;
        state.stateMessage = "Fetching contacts...";
      })
      .addCase(fetchContacts.fulfilled, (state, action) => {
        state.state = State.success;
        state.stateMessage = "Successfully fetched!";
        state.contacts = action.payload;
      })
      .addCase(fetchContacts.rejected, (state) => {
        state.state = State.failed;
        state.stateMessage = "Failed to fetch contacts!";
      })
  },
});

export const { resetSubmitState } = ContactSlice.actions;
export default ContactSlice.reducer;

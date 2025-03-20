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

import { createSlice, isDraft, PayloadAction } from "@reduxjs/toolkit";
import { State } from "../../types/types";
import { createAsyncThunk } from "@reduxjs/toolkit";
import { APIService } from "../../utils/apiService";
import { AppConfig } from "../../config/config";
import { enqueueSnackbarMessage } from "../commonSlice/common";
import { SnackMessage } from "../../config/constant";
import axios, { HttpStatusCode } from "axios";

interface CollectionState {
  state: State;
  submitState: State;
  stateMessage: string | null;
  errorMessage: string | null;
  collections: Collections | null;
  backgroundProcess: boolean;
  backgroundProcessMessage: string | null;
  [key: string]: any; // Index signature
}

const initialState: CollectionState = {
  state: State.idle,
  submitState: State.idle,
  stateMessage: "",
  errorMessage: "",
  collections: null,
  backgroundProcess: false,
  backgroundProcessMessage: null,
};

interface Collections {
  count: number;
  collections: Collection[];
}

export interface Collection {
  id: number;
  name: String;
  createdOn: String;
  createdBy: String;
  updatedOn: String;
  updatedBy: String;
}

export const fetchCollections = createAsyncThunk(
  "collection/fetchCollections",
  async (_, { dispatch, rejectWithValue }) => {
    APIService.getCancelToken().cancel();
    const newCancelTokenSource = APIService.updateCancelToken();
    return new Promise<Collections>((resolve, reject) => {
      APIService.getInstance()
        .get(AppConfig.serviceUrls.collections, {
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
                  ? SnackMessage.error.fetchCollectionsMessage
                  : String(error.response.data.message),
              type: "error",
            })
          );
          reject(error.response.data.message);
        });
    });
  }
);

// Payload of the add new collection
export interface AddCollectionPayload {
  name: string;
}

export const addCollections = createAsyncThunk(
  "collection/addCollections",
  async (payload: AddCollectionPayload, { dispatch }) => {
    return new Promise<AddCollectionPayload>((resolve, reject) => {
      APIService.getInstance()
        .post(AppConfig.serviceUrls.collections, payload)
        .then((response) => {
          dispatch(
            enqueueSnackbarMessage({
              message: SnackMessage.success.addCollections,
              type: "success",
            })
          );
          resolve(response.data);
        })
        .catch((error) => {
          dispatch(
            enqueueSnackbarMessage({
              message:
                error.response?.status === HttpStatusCode.InternalServerError
                  ? SnackMessage.error.addCollections
                  : String(error.response.data.message),
              type: "error",
            })
          );
          reject(error);
        });
    });
  }
);

const CollectionSlice = createSlice({
  name: "collection",
  initialState,
  reducers: {
    resetSubmitSate(state) {
      state.submitState = State.idle;
    },
  },
  extraReducers: (builder) => {
    builder
      .addCase(fetchCollections.pending, (state) => {
        state.state = State.loading;
        state.stateMessage = "Fetching collections...";
      })
      .addCase(fetchCollections.fulfilled, (state, action) => {
        state.state = State.success;
        state.stateMessage = "Successfully fetched!";
        state.collections = action.payload;
      })
      .addCase(fetchCollections.rejected, (state) => {
        state.state = State.failed;
        state.stateMessage = "Failed to fetch!";
      })
      .addCase(addCollections.pending, (state) => {
        state.submitState = State.loading;
        state.stateMessage = "Creating collections...";
      })
      .addCase(addCollections.fulfilled, (state) => {
        state.submitState = State.success;
        state.stateMessage = "Successfully created!";
      })
      .addCase(addCollections.rejected, (state) => {
        state.state = State.failed;
        state.stateMessage = "Failed to create!";
      });
  },
});

export const { resetSubmitSate } = CollectionSlice.actions;
export default CollectionSlice.reducer;

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

import { State } from "@utils/types";
import { AppConfig } from "@config/config";
import { Messages } from "@config/constant";
import axios, { HttpStatusCode } from "axios";
import { APIService } from "@utils/apiService";
import { enqueueSnackbarMessage } from "../commonSlice/common";
import { createAsyncThunk, createSlice } from "@reduxjs/toolkit";

const initialState: MetaInfoState = {
  employeeMap: {},
  employeeArray: [],
  metaDataStatus: State.idle,
};

export interface BasicEmployee {
  workEmail: string;
  firstName: string;
  lastName: string;
  company: string;
  managerEmail: string;
  employeeThumbnail: string;
}

interface MetaInfoState {
  employeeMap: {
    [key: string]: { employeeName: string; employeeThumbnail: string };
  };
  employeeArray: BasicEmployee[];
  metaDataStatus: State;
}

export const fetchEmployeeMetaData = createAsyncThunk(
  "metaSlice/fetchEmployeeMetaData",
  async (_, { dispatch, rejectWithValue }) => {
    try {
      const response = await APIService.getInstance().get(AppConfig.serviceUrls.employees);
      return response.data;
    } catch (error) {
      if (axios.isCancel(error)) {
        return rejectWithValue("Request canceled");
      }

      if (axios.isAxiosError(error)) {
        dispatch(
          enqueueSnackbarMessage({
            message:
              error.response?.status === HttpStatusCode.InternalServerError
                ? Messages.error.fetchRecords
                : String(error.response?.data?.message || error.message),
            type: "error",
          })
        );

        return rejectWithValue(error.response?.data?.message || error.message);
      }

      dispatch(
        enqueueSnackbarMessage({
          message: String(error),
          type: "error",
        })
      );

      return rejectWithValue(String(error));
    }
  }
);

const metaSlice = createSlice({
  name: "meta",
  initialState,
  reducers: {},
  extraReducers: (builder) => {
    builder
      .addCase(fetchEmployeeMetaData.pending, (state) => {
        state.metaDataStatus = State.loading;
      })
      .addCase(fetchEmployeeMetaData.fulfilled, (state, action) => {
        const employees = action.payload as BasicEmployee[];
        state.employeeArray = employees.sort((a, b) => {
          const emailA = a.workEmail.toLowerCase();
          const emailB = b.workEmail.toLowerCase();
          if (emailA < emailB) return -1;
          if (emailA > emailB) return 1;
          return 0;
        });
        state.employeeMap = employees.reduce(
          (acc, employee) => {
            acc[employee.workEmail] = {
              employeeName: [employee.firstName, employee.lastName].join(" "),
              employeeThumbnail: employee.employeeThumbnail,
            };
            return acc;
          },
          {} as {
            [key: string]: {
              employeeName: string;
              employeeThumbnail: string;
            };
          }
        );
        state.metaDataStatus = State.success;
      })
      .addCase(fetchEmployeeMetaData.rejected, (state) => {
        state.metaDataStatus = State.failed;
      });
  },
});

export default metaSlice.reducer;

// Copyright (c) 2024, WSO2 LLC. (https://www.wso2.com). All Rights Reserved.
//
// This software is the property of WSO2 LLC. and its suppliers, if any.
// Dissemination of any information or reproduction of any material contained
// herein in any form is strictly forbidden, unless permitted by WSO2 expressly.
// You may not alter or remove any copyright or other notice from copies of this content.

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
      const response = await APIService.getInstance().get(AppConfig.serviceUrls.metaData);
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

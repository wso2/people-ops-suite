// Copyright (c) 2024 WSO2 LLC. (https://www.wso2.com).
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
import React, { useEffect, useReducer } from "react";

import { Grid, LinearProgress, Stack } from "@mui/material";
import { DatePicker, LocalizationProvider } from "@mui/x-date-pickers";
import LoadingButton from "@mui/lab/LoadingButton";
import { AdapterDayjs } from "@mui/x-date-pickers/AdapterDayjs";

import "dayjs/locale/en-gb";
import dayjs from "dayjs";

import useHttp from "../utils/http";
import { services } from "../config";
import { getDateFromDateString } from "../utils/formatting";
import OverallLeaveReport from "../components/OverallLeaveReport";
import { getEndDateOfThisYear, getStartDateOfThisYear } from "../utils/utils";

const ACTIONS = {
  SET_LEAVES: "SET_LEAVES",
  SET_SUMMARY: "SET_SUMMARY",
  SET_EMPLOYEE: "SET_EMPLOYEE",
  SET_IS_LOADING: "SET_IS_LOADING",
  SET_REPORT_FILTERS: "SET_REPORT_FILTERS",
  SET_EMPLOYEE_STATUS: "SET_EMPLOYEE_STATUS",
  SET_BUSINESS_UNIT: "SET_BUSINESS_UNIT",
  SET_DEPARTMENT: "SET_DEPARTMENT",
  SET_TEAM: "SET_TEAM",
  SET_LOCATION: "SET_LOCATION",
  SET_DATE_RANGE: "SET_DATE_RANGE",
  HANDLE_RESET: "HANDLE_RESET",
};

const leaveReducer = (curLeaveState, action) => {
  switch (action.type) {
    case ACTIONS.SET_LEAVES:
      return {
        ...curLeaveState,
        leaves: action.leaves,
        leaveMap: action.leaveMap,
      };
    case ACTIONS.SET_SUMMARY:
      return { ...curLeaveState, summary: action.summary };
    case ACTIONS.SET_EMPLOYEE:
      return { ...curLeaveState, employee: action.employee };
    case ACTIONS.SET_IS_LOADING:
      return { ...curLeaveState, isLoading: action.isLoading };
    case ACTIONS.SET_REPORT_FILTERS:
      return {
        ...curLeaveState,
        locations: action.locations,
        businessUnits: action.businessUnits,
        departments: action.departments,
        teams: action.teams,
        orgMap: action.orgMap,
      };

    case ACTIONS.SET_DATE_RANGE:
      return {
        ...curLeaveState,
        ...(action.startDate ? { startDate: action.startDate } : {}),
        ...(action.endDate ? { endDate: action.endDate } : {}),
      };
    case ACTIONS.HANDLE_RESET:
      return { ...curLeaveState, employee: null, leaves: [], leaveMap: {} };
    default:
      throw new Error("Should not get here");
  }
};

const LeadReport = (props) => {
  const [{ isLoading, startDate, endDate, summary }, dispatchLeave] =
    useReducer(leaveReducer, {
      isLoading: false,
      startDate: dayjs(getStartDateOfThisYear()).toDate(),
      endDate: dayjs(getEndDateOfThisYear()).toDate(),
      summary: {},
    });
  const { handleRequest, handleRequestWithNewToken } = useHttp();

  const handleDateChange = (type) => (date) => {
    dispatchLeave({ type: ACTIONS.SET_DATE_RANGE, [type]: date });
  };

  const loadSummary = () => {
    dispatchLeave({ type: ACTIONS.SET_IS_LOADING, isLoading: true });
    handleRequestWithNewToken(() => {
      handleRequest(
        `${services.GENERATE_LEAVE_REPORT}`,
        "POST",
        {
          startDate: getDateFromDateString(startDate),
          endDate: getDateFromDateString(endDate),
        },
        (data) => {
          if (data) {
            let tempData = data;
            Object.keys(data).forEach((key) => {
              if (tempData[key].sick) {
                // TODO REMOVE AFTER MIGRATION
                if (tempData[key].casual) {
                  tempData[key].casual =
                    tempData[key].casual + tempData[key].sick;
                } else {
                  tempData[key]["casual"] = tempData[key].sick;
                }
              }
            });
            dispatchLeave({ type: ACTIONS.SET_SUMMARY, summary: tempData });
          }
        },
        () => {},
        (isLoading) => {
          dispatchLeave({ type: ACTIONS.SET_IS_LOADING, isLoading });
        }
      );
    });
  };

  useEffect(() => {
    loadSummary();
  }, []);

  return (
    <Grid
      container
      direction="row"
      justifyContent="space-around"
      alignItems="flex-start"
      spacing={2}
    >
      <Grid item xs={12}>
        {isLoading && <LinearProgress color="secondary" />}
      </Grid>
      <Grid item xs={12}>
        <Stack
          direction="column"
          justifyContent="center"
          alignItems="stretch"
          spacing={1}
        >
          <span>
            <LocalizationProvider
              dateAdapter={AdapterDayjs}
              adapterLocale={"en-gb"}
            >
              <Stack
                direction="row"
                justifyContent="flex-end"
                alignItems="center"
                spacing={1}
              >
                <span>
                  <DatePicker
                    value={dayjs(startDate)}
                    onChange={handleDateChange("startDate")}
                    label="Start date"
                  />
                </span>
                <span>
                  <DatePicker
                    value={dayjs(endDate)}
                    onChange={handleDateChange("endDate")}
                    label="End date"
                  />
                </span>
                <span>
                  <LoadingButton
                    color="secondary"
                    size="small"
                    onClick={loadSummary}
                    loading={isLoading}
                    loadingIndicator="Fetching…"
                    variant="contained"
                  >
                    <span>Fetch Report</span>
                  </LoadingButton>
                </span>
              </Stack>
            </LocalizationProvider>
          </span>
          <span>
            <OverallLeaveReport summary={summary} isLoading={isLoading} />
          </span>
        </Stack>
      </Grid>
    </Grid>
  );
};

export default LeadReport;

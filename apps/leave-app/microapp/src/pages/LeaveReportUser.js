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

import { Box, Card, CardContent, Grid, Stack } from "@mui/material";
import { DatePicker, LocalizationProvider } from "@mui/x-date-pickers";
import { AdapterDayjs } from "@mui/x-date-pickers/AdapterDayjs";

import dayjs from "dayjs";
import "dayjs/locale/en-gb";

import UserLeaveReport from "../components/UserLeaveReport";
import AccountProfile from "../components/AccountProfile"
import { services } from "../config";
import Loader from "../components/Loader";
import useHttp from "../utils/http";
import { getDateFromDateString } from "../utils/formatting";
import {
  getEndDateOfThisYear,
  getStartDateOfThisYear,
  getYearsBetweenDateRange,
  sickLeaveExceptionHandler,
} from "../utils/utils";

const ACTIONS = {
  SET_LEAVES: "SET_LEAVES",
  SET_EMPLOYEE: "SET_EMPLOYEE",
  SET_LEAVE_ENTITLEMENT: "SET_LEAVE_ENTITLEMENT",
  SET_IS_LOADING: "SET_IS_LOADING",
  SET_IS_LEAVE_ENTITLEMENT_LOADING: "SET_IS_LEAVE_ENTITLEMENT_LOADING",
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
    case ACTIONS.SET_EMPLOYEE:
      return {
        ...curLeaveState,
        employee: action.employee,
        leaves: [],
        leaveMap: {},
        leaveEntitlement: [],
      };
    case ACTIONS.SET_LEAVE_ENTITLEMENT:
      return { ...curLeaveState, leaveEntitlement: action.leaveEntitlement };
    case ACTIONS.SET_IS_LOADING:
      return { ...curLeaveState, isLoading: action.isLoading };
    case ACTIONS.SET_IS_LEAVE_ENTITLEMENT_LOADING:
      return {
        ...curLeaveState,
        isLeaveEntitlementLoading: action.isLeaveEntitlementLoading,
      };
    case ACTIONS.SET_DATE_RANGE:
      return {
        ...curLeaveState,
        ...(action.startDate ? { startDate: action.startDate } : {}),
        ...(action.endDate ? { endDate: action.endDate } : {}),
      };
    case ACTIONS.HANDLE_RESET:
      return {
        ...curLeaveState,
        employee: null,
        leaves: [],
        leaveMap: {},
        leaveEntitlement: [],
      };
    default:
      throw new Error("Should not get here");
  }
};

const LeaveReportUser = (props) => {
  const [
    {
      employee,
      leaves,
      leaveMap,
      leaveEntitlement,
      isLoading,
      isLeaveEntitlementLoading,
      startDate,
      endDate,
    },
    dispatchLeave,
  ] = useReducer(leaveReducer, {
    employee: null,
    leaves: [],
    leaveMap: {},
    leaveEntitlement: [],
    isLoading: false,
    isLeaveEntitlementLoading: false,
    startDate: dayjs(getStartDateOfThisYear()).toDate(),
    endDate: dayjs(getEndDateOfThisYear()).toDate(),
  });
  const { handleRequest, handleRequestWithNewToken } = useHttp();

  const handleEmployeeChange = (email) => {
    dispatchLeave({ type: ACTIONS.SET_EMPLOYEE, employee: email });
  };

  const handleDateChange = (type) => (date) => {
    dispatchLeave({ type: ACTIONS.SET_DATE_RANGE, [type]: date });
  };

  const loadSummary = () => {
    dispatchLeave({ type: ACTIONS.SET_IS_LOADING, isLoading: true });
    handleRequestWithNewToken(() => {
      handleRequest(
        `${services.LIST_LEAVE}?email=${
          employee.workEmail
        }&startDate=${getDateFromDateString(
          startDate
        )}&endDate=${getDateFromDateString(endDate)}&isActive=true`,
        "GET",
        null,
        (data) => {
          if (data) {
            var leaveMap = {};
            var leaves = [];
            if (data.stats && leaveMap) {
              var summaryArray = data.stats.slice();
              leaveMap = JSON.parse(JSON.stringify(leaveMap));
              summaryArray.forEach((stat) => {
                let statElement = sickLeaveExceptionHandler(stat); // Remove after migration
                if (leaveMap[statElement.type]) {
                  leaveMap[statElement.type]["count"] =
                    leaveMap[statElement.type]["count"] + statElement.count;
                } else {
                  leaveMap[statElement.type] = {};
                  leaveMap[statElement.type]["count"] = statElement.count;
                }
                if (statElement.type !== "total") {
                  if (leaveMap["all"]) {
                    leaveMap["all"]["count"] =
                      statElement.count + leaveMap["all"].count;
                  } else {
                    leaveMap["all"] = {};
                    leaveMap["all"]["count"] = statElement.count;
                  }
                }
              });
            }

            if (data.leaves) {
              leaves = data.leaves.slice();
              leaves.forEach((leave) => {
                let leaveElement = sickLeaveExceptionHandler(leave); // Remove after migration
                if (leaveMap[leaveElement.leaveType]) {
                  if (!leaveMap[leaveElement.leaveType]["list"]) {
                    leaveMap[leaveElement.leaveType]["list"] = [];
                  }
                  leaveMap[leaveElement.leaveType]["list"] =
                    leaveMap[leaveElement.leaveType]["list"].concat(
                      leaveElement
                    );
                } else {
                  leaveMap[leaveElement.leaveType] = {};
                  leaveMap[leaveElement.leaveType]["list"] = [leaveElement];
                }
                if (leaveMap["all"]) {
                  if (!leaveMap["all"]["list"]) {
                    leaveMap["all"]["list"] = [];
                  }
                  leaveMap["all"]["list"] =
                    leaveMap["all"]["list"].concat(leaveElement);
                } else {
                  leaveMap["all"] = {};
                  leaveMap["all"]["list"] = [leaveElement];
                }
              });
            }
            dispatchLeave({
              type: ACTIONS.SET_LEAVES,
              leaves,
              leaveMap,
            });
          }
        },
        () => {},
        (isLoading) => {
          dispatchLeave({ type: ACTIONS.SET_IS_LOADING, isLoading });
        }
      );
    });
  };

  const getPolicyAdjustedLeave = () => {
    if (employee) {
      dispatchLeave({
        type: ACTIONS.SET_IS_LEAVE_ENTITLEMENT_LOADING,
        isLoading: true,
      });
      handleRequestWithNewToken(() => {
        handleRequest(
          `${services.FETCH_EMPLOYEES}/${employee.workEmail}${
            services.FETCH_LEAVE_ENTITLEMENT_PATH
          }?years=${getYearsBetweenDateRange(startDate, endDate).join(",")}`,
          "GET",
          null,
          (data) => {
            if (data) {
              dispatchLeave({
                type: ACTIONS.SET_LEAVE_ENTITLEMENT,
                leaveEntitlement: data,
              });
            }
          },
          () => {},
          (isLoading) => {
            dispatchLeave({
              type: ACTIONS.SET_IS_LEAVE_ENTITLEMENT_LOADING,
              isLoading,
            });
          }
        );
      });
    }
  };

  useEffect(() => {
    if (employee) {
      loadSummary();
      getPolicyAdjustedLeave();
    }
  }, [employee, startDate, endDate]);

  return (
    <Grid
      container
      direction="row"
      justifyContent="space-around"
      alignItems=""
      spacing={2}
    >
      <Grid item xs={12}>
        {isLoading && <Loader />}
      </Grid>
      <Grid item xs={9}>
        <UserLeaveReport
          employee={employee}
          leaves={leaves}
          isLoading={isLoading}
          isLeaveEntitlementLoading={isLeaveEntitlementLoading}
          leaveMap={leaveMap}
          leaveEntitlement={leaveEntitlement}
        />
      </Grid>
      <Grid item xs={3}>
        <AccountProfile
          employee={employee}
          handleEmployeeChange={handleEmployeeChange}
        />
        <Card>
          <CardContent>
            <Box
              sx={{
                alignItems: "center",
                display: "flex",
                flexDirection: "column",
              }}
            >
              <LocalizationProvider
                dateAdapter={AdapterDayjs}
                adapterLocale={"en-gb"}
              >
                <Stack
                  direction="column"
                  justifyContent="center"
                  alignItems="center"
                  spacing={3}
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
                </Stack>
              </LocalizationProvider>
            </Box>
          </CardContent>
        </Card>
      </Grid>
    </Grid>
  );
};

export default LeaveReportUser;

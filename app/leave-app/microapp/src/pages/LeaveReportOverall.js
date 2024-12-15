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

import {
  Box,
  Card,
  CardContent,
  Chip,
  FormControl,
  Grid,
  InputLabel,
  LinearProgress,
  MenuItem,
  OutlinedInput,
  Select,
  Stack,
} from "@mui/material";
import { DatePicker, LocalizationProvider } from "@mui/x-date-pickers";
import LoadingButton from "@mui/lab/LoadingButton";
import { AdapterDayjs } from "@mui/x-date-pickers/AdapterDayjs";

import dayjs from "dayjs";
import "dayjs/locale/en-gb";

import { services } from "../config";
import CountryPicker from "../components/subcomponents/CountryPicker";
import { LEAVE_APP } from "../constants";
import OverallLeaveReport from "../components/OverallLeaveReport";
import useHttp from "../utils/http";
import { getDateFromDateString } from "../utils/formatting";
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

const ITEM_HEIGHT = 48;
const ITEM_PADDING_TOP = 8;
const MenuProps = {
  PaperProps: {
    style: {
      maxHeight: ITEM_HEIGHT * 4.5 + ITEM_PADDING_TOP,
      width: 250,
    },
  },
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
    case ACTIONS.SET_EMPLOYEE_STATUS:
      return { ...curLeaveState, employeeStatuses: action.employeeStatuses };
    case ACTIONS.SET_BUSINESS_UNIT:
      return { ...curLeaveState, businessUnit: action.value };
    case ACTIONS.SET_DEPARTMENT:
      return { ...curLeaveState, department: action.value };
    case ACTIONS.SET_TEAM:
      return { ...curLeaveState, team: action.value };
    case ACTIONS.SET_LOCATION:
      return { ...curLeaveState, location: action.location };
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

const LeaveReportOverall = (props) => {
  const [
    {
      isLoading,
      startDate,
      endDate,
      locations,
      location,
      businessUnits,
      businessUnit,
      departments,
      department,
      teams,
      team,
      employeeStatuses,
      summary,
    },
    dispatchLeave,
  ] = useReducer(leaveReducer, {
    employee: "",
    leaves: [],
    leaveMap: {},
    isLoading: false,
    startDate: dayjs(getStartDateOfThisYear()).toDate(),
    endDate: dayjs(getEndDateOfThisYear()).toDate(),
    locations: [],
    location: "",
    businessUnits: [],
    businessUnit: "",
    departments: [],
    department: "",
    teams: [],
    team: "",
    employeeStatuses: [],
    orgMap: {},
    summary: {},
  });
  const { handleRequest, handleRequestWithNewToken } = useHttp();

  const handleLocationChange = (location) => {
    dispatchLeave({ type: ACTIONS.SET_LOCATION, location });
  };

  const handleDateChange = (type) => (date) => {
    dispatchLeave({ type: ACTIONS.SET_DATE_RANGE, [type]: date });
  };

  const loadSummary = () => {
    dispatchLeave({ type: ACTIONS.SET_IS_LOADING, isLoading: true });
    handleRequestWithNewToken(() => {
      handleRequest(
        `${services.GENERATE_REPORT}`,
        "POST",
        {
          startDate: getDateFromDateString(startDate),
          endDate: getDateFromDateString(endDate),
          businessUnit,
          department,
          team,
          location: location
            ? location.serverName
              ? location.serverName
              : location.label
            : null,
          employeeStatuses,
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

  const loadReportFilters = () => {
    handleRequestWithNewToken(() => {
      handleRequest(
        `${services.FETCH_REPORT_FILTERS}`,
        "GET",
        null,
        (data) => {
          let businessUnits = [];
          let teamsMap = {};
          let unitsMap = {};
          let orgMapTemp = {};
          if (data) {
            if (data.orgStructure) {
              data.orgStructure.businessUnits.forEach((bu) => {
                let teamMap = {};
                let teamsForBu = [];
                bu.teams.forEach((team) => {
                  let unitMap = {};
                  let unitsForTeam = [];
                  team.units.forEach((unit) => {
                    unitsForTeam.push(unit);
                    unitsMap[unit.name] = unit;
                  });
                  teamsMap[team.name] = team;
                  teamsForBu.push({ ...team, teams: unitsForTeam });
                  teamMap[team.name] = { unitsForTeam, unitMap };
                });
                businessUnits.push({ ...bu, departments: teamsForBu });
                orgMapTemp[bu.name] = { teamsForBu, teamMap };
              });
              businessUnits.sort((a, b) => a.name.localeCompare(b.name));
            }
          }
          dispatchLeave({
            type: ACTIONS.SET_REPORT_FILTERS,
            locations: data.countries,
            businessUnits,
            departments: Object.values(teamsMap),
            teams: Object.values(unitsMap),
            orgMap: orgMapTemp,
          });
        },
        () => {},
        (isLoading) => {
          dispatchLeave({ type: ACTIONS.SET_IS_LOADING, isLoading });
        }
      );
    });
  };

  const handleReportFilters = (type) => (event) => {
    const {
      target: { value },
    } = event;
    dispatchLeave({ type: type, value });
  };

  const handleEmployeeStatus = (event) => {
    const {
      target: { value },
    } = event;
    dispatchLeave({
      type: ACTIONS.SET_EMPLOYEE_STATUS,
      employeeStatuses: value,
    });
  };

  useEffect(() => {
    loadReportFilters();
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
      <Grid item md={8} lg={9}>
        <OverallLeaveReport summary={summary} isLoading={isLoading} />
      </Grid>
      <Grid item md={4} lg={3}>
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
                    <CountryPicker
                      visibleCountries={locations}
                      onChange={handleLocationChange}
                    />
                  </span>
                  <span>
                    <FormControl sx={{ m: 1, minWidth: 220 }}>
                      <InputLabel id="bu-select-small-label">
                        Business Unit
                      </InputLabel>
                      <Select
                        labelId="bu-select-small-label"
                        id="bu-select-small"
                        value={businessUnit}
                        label="Business Unit"
                        onChange={handleReportFilters(
                          ACTIONS.SET_BUSINESS_UNIT
                        )}
                        // displayEmpty
                        inputProps={{ "aria-label": "Without label" }}
                        disabled={isLoading}
                      >
                        <MenuItem value={null}>
                          <em>None</em>
                        </MenuItem>
                        {businessUnits.map((bu, index) => {
                          return (
                            <MenuItem value={bu.name} key={index}>
                              {bu.name}
                            </MenuItem>
                          );
                        })}
                      </Select>
                    </FormControl>
                  </span>
                  <span>
                    <FormControl sx={{ m: 1, minWidth: 220 }}>
                      <InputLabel id="department-select-small-label">
                        Department
                      </InputLabel>
                      <Select
                        labelId="department-select-small-label"
                        id="department-select-small"
                        value={department}
                        label="Department"
                        onChange={handleReportFilters(ACTIONS.SET_DEPARTMENT)}
                        disabled={isLoading}
                      >
                        <MenuItem value={null}>
                          <em>None</em>
                        </MenuItem>
                        {departments
                          .slice()
                          .sort((a, b) => a.name.localeCompare(b.name))
                          .map((dept, index) => {
                            return (
                              <MenuItem value={dept.name} key={index}>
                                {dept.name}
                              </MenuItem>
                            );
                          })}
                      </Select>
                    </FormControl>
                  </span>
                  <span>
                    <FormControl sx={{ m: 1, minWidth: 220 }}>
                      <InputLabel id="team-select-small-label">Team</InputLabel>
                      <Select
                        labelId="team-select-small-label"
                        id="team-select-small"
                        value={team}
                        label="Team"
                        onChange={handleReportFilters(ACTIONS.SET_TEAM)}
                        disabled={isLoading}
                        inputProps={{ "aria-label": "Without label" }}
                      >
                        <MenuItem value={null}>
                          <em>None</em>
                        </MenuItem>
                        {teams
                          .slice()
                          .sort((a, b) => a.name.localeCompare(b.name))
                          .map((team, index) => {
                            return (
                              <MenuItem value={team.name} key={index}>
                                {team.name}
                              </MenuItem>
                            );
                          })}
                      </Select>
                    </FormControl>
                  </span>
                  <span>
                    <FormControl sx={{ m: 1, width: 220 }}>
                      <InputLabel id="demo-multiple-chip-label">
                        Employee Status
                      </InputLabel>
                      <Select
                        labelId="demo-multiple-chip-label"
                        id="demo-multiple-chip"
                        multiple
                        value={employeeStatuses}
                        onChange={handleEmployeeStatus}
                        input={
                          <OutlinedInput
                            id="select-multiple-chip"
                            label="Employee Status"
                          />
                        }
                        renderValue={(selected) => (
                          <Box
                            sx={{ display: "flex", flexWrap: "wrap", gap: 0.5 }}
                          >
                            {selected.map((status) => (
                              <Chip
                                key={status}
                                label={status}
                                style={{
                                  backgroundColor:
                                    LEAVE_APP.EMPLOYEE_STATUS[status].color,
                                }}
                              />
                            ))}
                          </Box>
                        )}
                        MenuProps={MenuProps}
                      >
                        {Object.values(LEAVE_APP.EMPLOYEE_STATUS).map(
                          (status) => (
                            <MenuItem
                              key={status.value}
                              value={status.value}
                              style={{
                                color: status.color,
                              }}
                            >
                              {status.value}
                            </MenuItem>
                          )
                        )}
                      </Select>
                    </FormControl>
                  </span>
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
            </Box>
          </CardContent>
        </Card>
      </Grid>
    </Grid>
  );
};

export default LeaveReportOverall;

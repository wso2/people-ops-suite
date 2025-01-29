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
import { LEAVE_APP } from "../constants";
import { getCountry } from "./oauth";

export const getLeaveTypes = (isLocationBased) => {
  const country = getCountry();
  if (isLocationBased && country === LEAVE_APP.COUNTRIES.LK.label) {
    return Object.values(LEAVE_APP.LEAVE_TYPES).filter(
      (e) =>
        !(
          e.countryRestriction &&
          e.countryRestriction[country] &&
          !e.countryRestriction[country].enabled
        )
    );
  }

  return Object.values(LEAVE_APP.LEAVE_TYPES);
};

export const getLeaveTypeTitle = (leaveType) => {
  var leaveTypeTitle = LEAVE_APP.LEAVE_TYPES[leaveType]
    ? LEAVE_APP.LEAVE_TYPES[leaveType].title
    : "";
  const country = getCountry();
  if (country === LEAVE_APP.COUNTRIES.LK.label) {
    var countryRestrictionTitle = LEAVE_APP.LEAVE_TYPES[leaveType]
      ? LEAVE_APP.LEAVE_TYPES[leaveType].countryRestriction &&
        LEAVE_APP.LEAVE_TYPES[leaveType].countryRestriction[country]
        ? LEAVE_APP.LEAVE_TYPES[leaveType].countryRestriction[country].title
        : leaveTypeTitle
      : leaveTypeTitle;
    return countryRestrictionTitle;
  }

  return leaveTypeTitle;
};

// Function to handle the very specific change to merge sick and casual leaves to one. This will be removed after migration.
export const sickLeaveExceptionHandler = (leave) => {
  if (
    leave.type === "sick" ||
    leave.leaveType === `sick` ||
    leave.key === "sick"
  ) {
    return {
      ...leave,
      type: "casual",
      leaveType: "casual",
      key: "casual",
      value: isNaN(leave.value)
        ? LEAVE_APP.LEAVE_TYPES.casual.title
        : leave.value,
      label: LEAVE_APP.LEAVE_TYPES.casual.title,
      name: LEAVE_APP.LEAVE_TYPES.casual.title,
    };
  }

  return leave;
};

// Function to handle the very specific change to merge annual and casual leaves to one. This is effective for only LK employees.
export const annualLeaveLkEmployeeHandler = (leave) => {
  const country = getCountry();
  if (
    country === LEAVE_APP.COUNTRIES.LK.label &&
    (leave.type === "annual" ||
      leave.leaveType === `annual` ||
      leave.key === "annual")
  ) {
    return {
      ...leave,
      type: "casual",
      leaveType: "casual",
      key: "casual",
      value: isNaN(leave.value)
        ? LEAVE_APP.LEAVE_TYPES.casual.title
        : leave.value,
      label: LEAVE_APP.LEAVE_TYPES.casual.title,
      name: LEAVE_APP.LEAVE_TYPES.casual.title,
    };
  }

  return leave;
};

// Function to get start date of this year
export const getStartDateOfThisYear = () => {
  var date = new Date();
  return new Date(date.getFullYear(), 0, 1);
};

// Function to get end date of this year
export const getEndDateOfThisYear = () => {
  var date = new Date();
  return new Date(date.getFullYear(), 11, 31);
};

// Function to get all years between two dates
export const getYearsBetweenDateRange = (startDate, endDate) => {
  var years = [];
  var startYear = new Date(startDate).getFullYear();
  var endYear = new Date(endDate).getFullYear();
  for (var i = startYear; i <= endYear; i++) {
    years.push(i);
  }
  return years;
};

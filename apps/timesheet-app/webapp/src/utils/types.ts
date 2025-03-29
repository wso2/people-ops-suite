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

import { BasicUserInfo, DecodedIDTokenPayload } from "@asgardeo/auth-spa";

export interface AuthState {
  status: State;
  mode: "active" | "maintenance";
  statusMessage: string | null;
  isAuthenticated: boolean;
  userInfo: BasicUserInfo | null;
  decodedIdToken: DecodedIDTokenPayload | null;
}

export interface AuthData {
  userInfo: BasicUserInfo;
  idToken: string;
  decodedIdToken: DecodedIDTokenPayload;
}

export interface Employee {
  workEmail: string;
  firstName: string;
  lastName: string;
  jobBand: number;
  employeeThumbnail: string;
}

export interface Header {
  title: string;
  size: number;
  align: "left" | "right" | "center";
}

export enum ThemeMode {
  Light = "light",
  Dark = "dark",
}

export interface PreLoaderProps {
  message: string | null;
  hideLogo?: boolean;
  isLoading?: boolean;
}

export interface ErrorHandlerProps {
  message: string | null;
}

export enum State {
  failed = "failed",
  success = "success",
  loading = "loading",
  idle = "idle",
}

export enum ConfirmationType {
  update = "update",
  send = "send",
  upload = "upload",
  accept = "accept",
}

export enum Roles {
  ADMIN = "ADMIN",
  EMPLOYEE = "EMPLOYEE",
  LEAD = "LEAD",
}

export enum TimesheetStatus {
  PENDING = "PENDING",
  APPROVED = "APPROVED",
  REJECTED = "REJECTED",
}

export interface TimesheetRecord {
  recordId: number;
  employeeEmail: string;
  recordDate: number;
  companyName: string;
  clockInTime: number;
  clockOutTime: number;
  isLunchIncluded: boolean;
  overtimeDuration: number;
  overtimeReason: string | null;
  leadEmail: string;
  overtimeRejectReason: string | null;
  overtimeStatus: TimesheetStatus;
}

export interface CreateUITimesheetRecord {
  recordId: number;
  recordDate: Date | null;
  clockInTime: Date | null;
  clockOutTime: Date | null;
  isLunchIncluded: boolean;
  overtimeDuration: number;
  overtimeReason: string | null;
  overtimeStatus: TimesheetStatus;
}

export interface TimesheetData {
  totalRecordCount: number;
  timesheetRecords: TimesheetRecord[];
  timesheetInfo: TimesheetInfo;
}

export interface WorkPolicies {
  otHoursPerYear: number;
  workingHoursPerDay: number;
  lunchHoursPerDay: number;
}

export interface TimesheetInfo {
  approvedRecords?: number;
  overTimeLeft: number;
  pendingRecords?: number;
  rejectedRecords?: number;
  totalOverTimeTaken?: number;
  totalRecords?: number;
}

export interface TimesheetUpdate {
  recordId: number;
  recordDate?: string;
  clockInTime?: number;
  clockOutTime?: number;
  isLunchIncluded?: boolean;
  overtimeDuration?: string;
  overtimeReason?: string;
  overtimeRejectReason?: string;
  overtimeStatus?: TimesheetStatus;
}

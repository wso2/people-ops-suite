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
import { State } from "src/types/types";
export type stateType = "failed" | "success" | "loading" | "idle";

export interface AuthState {
  status: State;
  mode: "active" | "maintenance";
  statusMessage: string | null;
  isAuthenticated: boolean;
  userInfo: BasicUserInfo | null;
  decodedIdToken: DecodedIDTokenPayload | null;
  roles: string[];
}

export interface AuthData {
  userInfo: BasicUserInfo;
  idToken: string;
  decodedIdToken: DecodedIDTokenPayload;
}

export interface UserState {
  state: State;
  stateMessage: string | null;
  errorMessage: string | null;
  userInfo: UserInfoInterface | null;
}

export interface UserInfoInterface {
  employeeId: string;
  firstName: string;
  lastName: string;
  workEmail: string;
  employeeThumbnail: string | null;
  jobRole: string;
  privileges: number[];
}

export enum Role {
  ADMIN = "ADMIN",
  TEAM = "TEAM",
}

export interface MeetingTypes {
  domain: string;
  types: string[];
}

export interface Meeting {
  meetingId: number;
  title: string;
  googleEventId: string;
  host: string;
  startTime: string;
  endTime: string;
  internalParticipants: string;
  meetingStatus: string;
}

export interface Meetings {
  count: number;
  meetings: Meeting[];
}

export interface MeetingState {
  state: State;
  submitState: State;
  stateMessage: string | null;
  errorMessage: string | null;
  meetings: Meetings | null;
  meetingTypes: string[] | null;
  backgroundProcess: boolean;
  backgroundProcessMessage: string | null;
}

export interface AddMeetingPayload {
  title: string;
  description: string;
  startTime: string;
  endTime: string;
  timeZone: string;
  internalParticipants: string[];
  externalParticipants: string[];
}

export interface DeleteMeeting {
  message: string;
}

export interface Attachments {
  attachments: Attachment[];
}

export interface Attachment {
  fileUrl: string;
  title: string;
  mimeType: string;
  iconLink: string;
  fileId: string;
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

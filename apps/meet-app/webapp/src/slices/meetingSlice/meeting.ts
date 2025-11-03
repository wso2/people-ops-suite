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

interface Meetings {
  count: number;
  meetings: Meeting[];
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
  isRecurring: boolean; 
}

interface MeetingState {
  state: State;
  submitState: State;
  stateMessage: string | null;
  errorMessage: string | null;
  meetings: Meetings | null;
  meetingTypes: string[] | null;
  backgroundProcess: boolean;
  backgroundProcessMessage: string | null;
}

interface AddMeetingPayload {
  title: string;
  description: string;
  startTime: string;
  endTime: string;
  timeZone: string;
  internalParticipants: string[];
  externalParticipants: string[];
  recurrence?: { frequency: "DAILY" | "WEEKLY" | "MONTHLY"; count: number };
  recurrenceRule?: string | null;
  isRecurring?: boolean;
}

interface DeleteMeeting {
  message: string;
}

interface Attachments {
  attachments: Attachment[];
}

interface Attachment {
  fileUrl: string;
  title: string;
  mimeType: string;
  iconLink: string;
  fileId: string;
}

interface MeetingTypes {
  domain: string;
  types: string[];
}

const initialState: MeetingState = {
  state: State.idle,
  submitState: State.idle,
  stateMessage: "",
  errorMessage: "",
  meetings: null,
  meetingTypes: null,
  backgroundProcess: false,
  backgroundProcessMessage: null,
};

export const fetchMeetingTypes = createAsyncThunk(
  "meeting/fetchMeetingTypes",
  async (_, { dispatch, rejectWithValue }) => {
    APIService.getCancelToken().cancel();
    const newCancelTokenSource = APIService.updateCancelToken();
    return new Promise<MeetingTypes>((resolve, reject) => {
      APIService.getInstance()
        .get(AppConfig.serviceUrls.meetingTypes, {
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
                  ? SnackMessage.error.fetchMeetingTypes
                  : "An unknown error occurred.",
              type: "error",
            })
          );
          reject(error.response.data.message);
        });
    });
  }
);

export const addMeetings = createAsyncThunk("meeting/addMeetings", async (payload: AddMeetingPayload, { dispatch }) => {
  APIService.getCancelToken().cancel();
  const newCancelTokenSource = APIService.updateCancelToken();
  return new Promise<AddMeetingPayload>((resolve, reject) => {
    APIService.getInstance()
      .post(AppConfig.serviceUrls.meetings, payload, {
        cancelToken: newCancelTokenSource.token,
      })
      .then((response) => {
        dispatch(
          enqueueSnackbarMessage({
            message: SnackMessage.success.addMeetings,
            type: "success",
          })
        );
        resolve(response.data);
      })
      .catch((error) => {
        const errorMessage =
          error.response?.data?.message ||
          (error.response?.status === HttpStatusCode.InternalServerError
            ? SnackMessage.error.addMeetings
            : "An unknown error occurred.");
        dispatch(
          enqueueSnackbarMessage({
            message: errorMessage,
            type: "error",
          })
        );
        reject(error);
      });
  });
});

export const fetchMeetings = createAsyncThunk(
  "meeting/fetchMeetings",
  async (
    { title, limit, offset }: { title: string | null; limit: number; offset: number },
    { dispatch }
  ) => {
    APIService.getCancelToken().cancel();
    const newCancelTokenSource = APIService.updateCancelToken();
    return new Promise<Meetings>((resolve, reject) => {
      APIService.getInstance()
        .get(AppConfig.serviceUrls.meetings, {
          params: { title, limit, offset },
          cancelToken: newCancelTokenSource.token,
        })
        .then((response) => {
          resolve(response.data);
        })
        .catch((error) => {
          const errorMessage =
            error.response?.data?.message ||
            (error.response?.status === HttpStatusCode.InternalServerError
              ? SnackMessage.error.fetchMeetings
              : "An unknown error occurred.");
          dispatch(
            enqueueSnackbarMessage({
              message: errorMessage,
              type: "error",
            })
          );
          reject(error);
        });
    });
  }
);

export const deleteMeeting = createAsyncThunk("meeting/deleteMeeting", async (meetingId: number, { dispatch }) => {
  APIService.getCancelToken().cancel();
  const newCancelTokenSource = APIService.updateCancelToken();
  return new Promise<DeleteMeeting>((resolve, reject) => {
    APIService.getInstance()
      .delete(`${AppConfig.serviceUrls.meetings}/${meetingId}`, {
        cancelToken: newCancelTokenSource.token,
      })
      .then((response) => {
        dispatch(
          enqueueSnackbarMessage({
            message: SnackMessage.success.deleteMeeting,
            type: "success",
          })
        );
        resolve(response.data);
      })
      .catch((error) => {
        const errorMessage =
          error.response?.data?.message ||
          (error.response?.status === HttpStatusCode.InternalServerError
            ? SnackMessage.error.deleteMeeting
            : "An unknown error occurred.");
        dispatch(
          enqueueSnackbarMessage({
            message: errorMessage,
            type: "error",
          })
        );
        reject(error);
      });
  });
});

export const fetchAttachments = createAsyncThunk(
  "meeting/fetchAttachments",
  async (meetingId: number, { dispatch, rejectWithValue }) => {
    APIService.getCancelToken().cancel();
    const newCancelTokenSource = APIService.updateCancelToken();
    return new Promise<Attachments>((resolve, reject) => {
      APIService.getInstance()
        .get(`${AppConfig.serviceUrls.meetings}/${meetingId}/attachments`, {
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
                  ? SnackMessage.error.fetchAttachments
                  : error.response?.status === HttpStatusCode.Forbidden
                  ? SnackMessage.error.insufficientPrivileges
                  : "An unknown error occurred.",
              type: "error",
            })
          );
          reject(error.response.data.message);
        });
    });
  }
);

const MeetingSlice = createSlice({
  name: "meeting",
  initialState,
  reducers: {
    resetSubmitState(state) {
      state.submitState = State.idle;
    },
  },
  extraReducers: (builder) => {
    builder
      .addCase(fetchMeetingTypes.pending, (state) => {
        state.state = State.loading;
        state.stateMessage = "Fetching meeting types...";
      })
      .addCase(fetchMeetingTypes.fulfilled, (state, action) => {
        state.state = State.success;
        state.stateMessage = "Successfully fetched!";
        state.meetingTypes = action.payload.types;
      })
      .addCase(fetchMeetingTypes.rejected, (state) => {
        state.state = State.failed;
        state.stateMessage = "Failed to fetch!";
      })
      .addCase(addMeetings.pending, (state) => {
        state.submitState = State.loading;
        state.stateMessage = "Creating meetings...";
      })
      .addCase(addMeetings.fulfilled, (state) => {
        state.submitState = State.success;
        state.stateMessage = "Successfully created!";
      })
      .addCase(addMeetings.rejected, (state, action) => {
        state.submitState = State.failed;
        state.stateMessage = "Failed to create!";
      })
      .addCase(fetchMeetings.pending, (state) => {
        state.state = State.loading;
        state.stateMessage = "Fetching meetings...";
      })
      .addCase(fetchMeetings.fulfilled, (state, action) => {
        state.state = State.success;
        state.stateMessage = "Successfully fetched!";
        state.meetings = action.payload;
      })
      .addCase(fetchMeetings.rejected, (state) => {
        state.state = State.failed;
        state.stateMessage = "Failed to fetch!";
      })
      .addCase(deleteMeeting.pending, (state) => {
        state.submitState = State.loading;
        state.stateMessage = "Deleting meeting...";
      })
      .addCase(deleteMeeting.fulfilled, (state) => {
        state.submitState = State.success;
        state.stateMessage = "Successfully deleted!";
      })
      .addCase(deleteMeeting.rejected, (state) => {
        state.submitState = State.failed;
        state.stateMessage = "Failed to delete!";
      })
      .addCase(fetchAttachments.pending, (state) => {
        state.submitState = State.loading;
        state.stateMessage = "Fetching attachments...";
      })
      .addCase(fetchAttachments.fulfilled, (state) => {
        state.submitState = State.success;
        state.stateMessage = "Successfully fetched!";
      })
      .addCase(fetchAttachments.rejected, (state) => {
        state.submitState = State.failed;
        state.stateMessage = "Failed to fetch!";
      });
  },
});

export const { resetSubmitState } = MeetingSlice.actions;
export default MeetingSlice.reducer;

// Copyright (c) 2026 WSO2 LLC. (https://www.wso2.com).
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

import  { useEffect } from "react";
import {
  Box,
  Container,
  Grid,
  Typography,
  Button,
  Chip,
  Paper,
  CircularProgress,
  IconButton,
  Stack,
  useTheme,
} from "@mui/material";

import AddIcon from "@mui/icons-material/Add";
import HistoryIcon from "@mui/icons-material/History";
import { useAppDispatch, useAppSelector } from "@root/src/slices/store";
import { useParams, useNavigate } from "react-router-dom";
import {
  fetchMeetingsByCustomer,
  fetchAttachments,
  fetchMeetingsByDatesForCustomer,
} from "@root/src/slices/meetingSlice/meeting";
import { State } from "@root/src/types/types";
import ErrorHandler from "@component/common/ErrorHandler";
import MeetingsAccordion from "@root/src/component/ui/MeetingsAccordion";
import { useState } from "react";
import { Attachment } from "../../types/types";
import { formatDateTime } from "@root/src/utils/useFormatDate";
import PersonRoundedIcon from "@mui/icons-material/PersonRounded";
import ArrowBackIcon from "@mui/icons-material/ArrowBack";
import UpcomingMeetingCard from "@root/src/component/ui/UpcomingMeetingCard";

export default function CustomerMeetings() {
  const theme = useTheme();
  const navigate = useNavigate();

  const [attachmentMap, setAttachmentMap] = useState<
    Record<number, Attachment[]>
  >({});
  const [loadingAttachments, setLoadingAttachments] = useState<
    Record<number, boolean>
  >({});
  const { customerName } = useParams();
  console.log(customerName);
  const dispatch = useAppDispatch();
  const meeting = useAppSelector((state) => state.meeting);
  const upComingMeetings = useAppSelector(
    (state) => state.meeting.customerDateRangeMeetings,
  );
  const upComingMeetingsState = useAppSelector(
    (state) => state.meeting.customerDateRangeMeetingsState,
  );
  useEffect(() => {
    const today = new Date();
    const params: any = {
      customerName: customerName,
      limit: 10,
      endTime: today.toISOString(),
    };
    const promise = dispatch(fetchMeetingsByCustomer(params));
    promise.unwrap().then(() => {
      fetchUpcomingMeetings();
    });
  }, [customerName]);
  const meetingList = meeting?.customerMeetings?.meetings ?? [];
  const upComingMeetingsList = upComingMeetings?.meetings ?? [];
  console.log(upComingMeetingsList);

  const fetchUpcomingMeetings = () => {
    const today = new Date();
    const params: any = {
      startTime: today.toISOString(),
      limit: 10,
      customerName: customerName,
    };
    dispatch(fetchMeetingsByDatesForCustomer(params));
  };
  const handleAccordionChange = (meetingId: number, isExpanded: boolean) => {
    if (isExpanded && !attachmentMap[meetingId]) {
      setLoadingAttachments((prev) => ({ ...prev, [meetingId]: true }));
      dispatch(fetchAttachments(meetingId)).then((data: any) => {
        if (data.payload && data.payload.attachments) {
          setAttachmentMap((prev) => ({
            ...prev,
            [meetingId]: data.payload.attachments,
          }));
        }
        setLoadingAttachments((prev) => ({ ...prev, [meetingId]: false }));
      });
    }
  };
  const handleDeleteMeeting = (meetingId: number, meetingTitle: string) => {
    console.log(meetingId, meetingTitle);
  };
  return (
    <Box
      sx={{
        bgcolor: "background.default",
        minHeight: "100vh",
        py: 4,
        color: "text.primary",
      }}
    >
      <Container maxWidth="xl">
        <Box
          sx={{
            display: "flex",
            justifyContent: "space-between",
            alignItems: "center",
            mb: 4,
            flexWrap: "wrap",
            gap: 2,
          }}
        >
          {/* Grouping Back button and Title so they stay on the left together */}
          <Box sx={{ display: "flex", alignItems: "center", gap: 2 }}>
            <IconButton
              onClick={() => navigate(-1)} // Added routing action
              sx={{ bgcolor: "action.hover" }}
              aria-label="go back"
            >
              <ArrowBackIcon />
            </IconButton>

            {/* Title Box with Icon */}
            <Box sx={{ display: "flex", alignItems: "center", gap: 1.5 }}>
              <Box
                sx={{
                  bgcolor: theme.palette.brand.main,
                  borderRadius: 1.5,
                  p: 1,
                  display: "flex",
                  color: "white",
                }}
              >
                <PersonRoundedIcon />
              </Box>
              <Box>
                <Typography variant="h5" fontWeight="700" color="text.primary">
                  Customer: {customerName}
                </Typography>
                <Typography variant="body2" color="text.secondary">
                  Review past sessions and upcoming schedules for this customer.
                </Typography>
              </Box>
            </Box>
          </Box>

          <Stack direction="row" spacing={2}>
            <Button
              variant="contained"
              startIcon={<AddIcon />}
              sx={{ textTransform: "none" }}
            >
              Schedule New
            </Button>
          </Stack>
        </Box>

        <Grid container spacing={3}>
          <Grid item xs={12} lg={8}>
            <Box
              sx={{
                display: "flex",
                alignItems: "center",
                justifyContent: "space-between",
                mb: 2,
              }}
            >
              <Stack direction="row" spacing={1} alignItems="center">
                <HistoryIcon color="action" />
                <Typography variant="h6" sx={{ fontWeight: 700 }}>
                  Past Sessions & Recordings
                </Typography>
              </Stack>
              <Chip
                label={`Total Sessions ${meeting.customerMeetings?.count || 0}`}
                size="medium"
                sx={{ bgcolor: "action.hover" }}
              />
            </Box>
            {meeting.customerMeetingsState == State.loading ? (
              <Box sx={{ display: "flex", justifyContent: "center", p: 4 }}>
                <CircularProgress sx={{ color: theme.palette.brand.main }} />
              </Box>
            ) : meeting.customerMeetingsState === State.failed ? (
              <ErrorHandler message="Failed to fetch meetings." />
            ) : meetingList.length === 0 ? (
              <Paper
                sx={{
                  p: 6,
                  textAlign: "center",
                  borderRadius: 3,
                  boxShadow: (theme: any) => theme.customShadows.modern,
                  bgcolor: "background.paper",
                }}
              >
                <Typography variant="h6" color="text.secondary">
                  No meetings found.
                </Typography>
              </Paper>
            ) : (
              <Box sx={{ display: "flex", flexDirection: "column", gap: 2 }}>
                {meetingList.map((row) => (
                  <MeetingsAccordion
                    meeting={row}
                    handleAccordionChange={handleAccordionChange}
                    formatDateTime={formatDateTime}
                    key={row.meetingId}
                    handleDeleteMeeting={handleDeleteMeeting}
                    loadingAttachments={loadingAttachments}
                    attachmentMap={attachmentMap}
                  />
                ))}
              </Box>
            )}
          </Grid>

          <Grid item xs={12} lg={4}>
            <UpcomingMeetingCard
              variant="customer"
              upcomingMeetings={upComingMeetingsList}
              loadingMeetings={upComingMeetingsState === State.loading}
              onViewAllClick={() => console.log("Navigate to all meetings")}
            />
          </Grid>
        </Grid>
      </Container>
    </Box>
  );
}

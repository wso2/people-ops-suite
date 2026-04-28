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

import { useEffect, useState, useRef, useCallback } from "react";
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
  resetCustomerMeetings,
} from "@root/src/slices/meetingSlice/meeting";
import { State } from "@root/src/types/types";
import ErrorHandler from "@component/common/ErrorHandler";
import MeetingsAccordion from "@root/src/component/ui/MeetingsAccordion";
import { Attachment } from "../../types/types";
import { formatDateTime } from "@root/src/utils/useFormatDate";
import PersonRoundedIcon from "@mui/icons-material/PersonRounded";
import ArrowBackIcon from "@mui/icons-material/ArrowBack";
import UpcomingMeetingCard from "@root/src/component/ui/UpcomingMeetingCard";
import { setCustomerName } from "@root/src/slices/viewSlice/view";

export default function CustomerMeetings() {
  const theme = useTheme();
  const navigate = useNavigate();
  const dispatch = useAppDispatch();
  const { customerName } = useParams();
  const [page, setPage] = useState(0);
  const pageSize = 10;
  const customerMeetings = useAppSelector(
    (state) => state.meeting.customerMeetings,
  );
  const customerMeetingsState = useAppSelector(
    (state) => state.meeting.customerMeetingsState,
  );
  const upComingMeetings = useAppSelector(
    (state) => state.meeting.customerDateRangeMeetings,
  );
  const upComingMeetingsState = useAppSelector(
    (state) => state.meeting.customerDateRangeMeetingsState,
  );

  const [attachmentMap, setAttachmentMap] = useState<
    Record<number, Attachment[]>
  >({});
  const [loadingAttachments, setLoadingAttachments] = useState<
    Record<number, boolean>
  >({});
  const prevCustomerRef = useRef<string | undefined>(undefined);

  const scrollData = useRef({
    state: customerMeetingsState,
    data: customerMeetings,
  });
  useEffect(() => {
    scrollData.current = {
      state: customerMeetingsState,
      data: customerMeetings,
    };
  }, [customerMeetingsState, customerMeetings]);

  const observer = useRef<IntersectionObserver | null>(null);
  const observerTarget = useCallback((node: HTMLDivElement | null) => {
    if (observer.current) observer.current.disconnect();
    if (!node) return;

    observer.current = new IntersectionObserver(
      (entries) => {
        if (entries[0].isIntersecting) {
          const { state, data } = scrollData.current;
          if (state === State.loading) return;

          const currentCount = data?.meetings?.length || 0;
          const totalCount = data?.count || 0;

          if (currentCount < totalCount) {
            setPage((prev) => prev + 1);
          }
        }
      },
      { threshold: 0.1 },
    );

    observer.current.observe(node);
  }, []);

  useEffect(() => {
    if (!customerName) return;

    const isNewCustomer = prevCustomerRef.current !== customerName;

    const loadData = async () => {
      if (isNewCustomer) {
        dispatch(resetCustomerMeetings());
        prevCustomerRef.current = customerName;

        if (page !== 0) {
          setPage(0);
          return;
        }
      }
      try {
        const today = new Date();
        const historyParams = {
          customerName: customerName,
          limit: pageSize,
          offset: page * pageSize,
          endTime: today.toISOString(),
          searchString: null,
        };
        await dispatch(fetchMeetingsByCustomer(historyParams)).unwrap();
        if (page === 0) {
          dispatch(
            fetchMeetingsByDatesForCustomer({
              startTime: today.toISOString(),
              limit: 10,
              customerName: customerName,
            }),
          );
        }
      } catch (error) {
        if (error instanceof Error && error.name !== "ConditionError") {
          console.error("Fetch failed:", error);
        }
      }
    };

    loadData();
  }, [customerName, page, dispatch]);

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

  const handleNewSchedule = () => {
    navigate("/?tab=create-meeting");
    dispatch(setCustomerName(customerName ?? ""));
  };

  const meetingList = customerMeetings?.meetings ?? [];
  const upComingMeetingsList = upComingMeetings?.meetings ?? [];

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
          <Box sx={{ display: "flex", alignItems: "center", gap: 2 }}>
            <IconButton
              onClick={() => navigate(-1)}
              sx={{ bgcolor: "action.hover" }}
            >
              <ArrowBackIcon />
            </IconButton>
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
                <Typography variant="h5" fontWeight="700">
                  Customer: {customerName}
                </Typography>
                <Typography variant="body2" color="text.secondary">
                  Review past sessions and upcoming schedules.
                </Typography>
              </Box>
            </Box>
          </Box>
          <Button
            variant="contained"
            startIcon={<AddIcon />}
            sx={{ textTransform: "none" }}
            onClick={handleNewSchedule}
          >
            Schedule New
          </Button>
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
                  Past Sessions
                </Typography>
              </Stack>
              <Chip
                label={`Total Sessions ${customerMeetings?.count || 0}`}
                sx={{ bgcolor: "action.hover" }}
              />
            </Box>

            {/* List Content */}
            {customerMeetingsState === State.loading && page === 0 ? (
              <Box sx={{ display: "flex", justifyContent: "center", p: 4 }}>
                <CircularProgress sx={{ color: theme.palette.brand.main }} />
              </Box>
            ) : customerMeetingsState === State.failed ? (
              <ErrorHandler message="Failed to fetch meetings." />
            ) : meetingList.length === 0 ? (
              <Paper
                sx={{
                  p: 6,
                  textAlign: "center",
                  borderRadius: 3,
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
                    key={row.meetingId}
                    meeting={row}
                    handleAccordionChange={handleAccordionChange}
                    formatDateTime={formatDateTime}
                    handleDeleteMeeting={() => {}}
                    loadingAttachments={loadingAttachments}
                    attachmentMap={attachmentMap}
                  />
                ))}

                <div
                  ref={observerTarget}
                  style={{
                    minHeight: "50px",
                    display: "flex",
                    justifyContent: "center",
                    padding: 2,
                  }}
                >
                  {customerMeetingsState === State.loading && page > 0 && (
                    <CircularProgress
                      size={24}
                      sx={{ color: theme.palette.brand.main }}
                    />
                  )}
                </div>
              </Box>
            )}
          </Grid>

          <Grid item xs={12} lg={4}>
            <UpcomingMeetingCard
              variant="customer"
              upcomingMeetings={upComingMeetingsList}
              loadingMeetings={upComingMeetingsState === State.loading}
            />
          </Grid>
        </Grid>
      </Container>
    </Box>
  );
}

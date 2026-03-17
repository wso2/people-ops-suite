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

import {
  Box,
  Grid,
  Typography,
  TextField,
  CircularProgress,
  Card,
  CardContent,
  List,
  ListItem,
  Paper,
  InputAdornment,
  SelectChangeEvent,
} from "@mui/material";
import useDebounce from "@utils/useDebounce";
import { DropdownOption, State } from "@/types/types";
import { ChangeEvent, useEffect, useMemo, useRef, useState } from "react";
import { ConfirmationType } from "@/types/types";
import ErrorHandler from "@component/common/ErrorHandler";
import { useAppDispatch, useAppSelector } from "@slices/store";
import { useConfirmationModalContext } from "@context/DialogContext";
import ViewListIcon from "@mui/icons-material/ViewList";
import ViewModuleIcon from "@mui/icons-material/ViewModule";
import ToggleButton from "@mui/material/ToggleButton";
import ToggleButtonGroup from "@mui/material/ToggleButtonGroup";
import { Search, Schedule, EventNote } from "@mui/icons-material";
import {
  fetchMeetings,
  deleteMeeting,
  fetchAttachments,
  fetchMeetingsByDates,
} from "@slices/meetingSlice/meeting";
import { useTheme } from "@mui/material/styles";
import {
  fetchCustomers,
  fetchCustomersMeetingsSummary,
} from "@root/src/slices/customerSlice/customer";
import CustomerCard from "@component/ui/CustomerCard";
import { useNavigate } from "react-router-dom";
import { Attachment } from "../../../types/types";
import { MeetingsAccordion } from "../../../component/ui/MeetingsAccordion";
import { fetchRegions } from "@root/src/slices/regionsSlice/regions";
import Dropdown from "@root/src/component/ui/Dropdown";
import RadioGroup from "@mui/material/RadioGroup";
import StyledRadio from "@root/src/component/ui/StyledRadio";
import {formatDateTime,formatDateForInput,formatForAPI} from "@root/src/utils/useFormatDate"


function MeetingHistory() {
  const theme = useTheme();
  const dispatch = useAppDispatch();
  const navigate = useNavigate();
  const meeting = useAppSelector((state) => state.meeting);
  const upcomingMeetings = useAppSelector(
    (state) => state.meeting.dateRangeMeetings,
  );
  const upcomingMeetingsLoading = useAppSelector(
    (state) => state.meeting.dateRangeState,
  );
  const meetingsSummary = useAppSelector(
    (state) => state.customer.meetingsSummary,
  );
  const meetingsSummaryState = useAppSelector(
    (state) => state.customer.meetingsSummaryState,
  );
  const customers = useAppSelector((state) => state.customer.customers) || [];
  const customersState = useAppSelector((state) => state.customer.state);

  const regions = useAppSelector((state) => state.region);
  const [page, setPage] = useState(0);
  const pageSize = 10;
  const observerTarget = useRef(null);
  const dialogContext = useConfirmationModalContext();
  const [loadingDelete, setLoadingDelete] = useState(false);
  const [searchQuery, setSearchQuery] = useState<string>("");
  const [view, setView] = useState("list");
  const debouncedSearchTerm = useDebounce(searchQuery, 500);
  const [attachmentMap, setAttachmentMap] = useState<
    Record<number, Attachment[]>
  >({});
  const [loadingAttachments, setLoadingAttachments] = useState<
    Record<number, boolean>
  >({});

  const [regionOption, setRegionRangeOption] = useState<string>("All");
  const [meetingType, setMeetingType] = useState("Past");
  const [endDate, setEndDate] = useState(() => formatDateForInput(new Date()));
  const [isInitialLoadDone, setIsInitialLoadDone] = useState(false);

  useEffect(() => {
    const params: any = {
      searchString: debouncedSearchTerm,
      limit: pageSize,
      offset: page * pageSize,
    };

    if (regionOption !== "All") {
      params.region = regionOption;
    }

    if (meetingType === "Past") {
      params.endTime = formatForAPI(endDate);
    }

    const promise = dispatch(fetchMeetings(params));

    promise.unwrap().then(() => {
      if (!isInitialLoadDone && upcomingMeetingsLoading === State.idle) {
        refreshUpcomingMeetings();
        setIsInitialLoadDone(true);
      }
    });

    return () => {
      promise.abort();
    };
  }, [
    dispatch,
    debouncedSearchTerm,
    page,
    pageSize,
    regionOption,
    meetingType,
    endDate,
  ]);

  useEffect(() => {
    dispatch(fetchCustomersMeetingsSummary());
  }, [dispatch, debouncedSearchTerm]);

  useEffect(() => {
    if (
      !customers.length &&
      (customersState === State.idle || customersState === State.failed)
    ) {
      dispatch(fetchCustomers());
    }
  }, [dispatch, customers.length]);

  useEffect(() => {
    const observer = new IntersectionObserver(
      (entries) => {
        if (entries[0].isIntersecting && meeting.state !== State.loading) {
          const currentCount = meeting.meetings?.meetings?.length || 0;
          const totalCount = meeting.meetings?.count || 0;
          if (currentCount < totalCount) {
            setPage((prev) => prev + 1);
          }
        }
      },
      { threshold: 1.0 },
    );

    if (observerTarget.current) observer.observe(observerTarget.current);
    return () => {
      if (observerTarget.current) observer.unobserve(observerTarget.current);
    };
  }, [meeting.state, meeting.meetings]);

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

  const refreshUpcomingMeetings = () => {
    const today = new Date();
    const twoDaysLater = new Date();
    twoDaysLater.setDate(today.getDate() + 2);
    return dispatch(
      fetchMeetingsByDates({
        startTime: today.toISOString(),
        endTime: twoDaysLater.toISOString(),
        limit: 10,
      }),
    );
  };

  const handleRadioButtonChange = (event: ChangeEvent<HTMLInputElement>) => {
    const selectedValue = event.target.value;
    setMeetingType(selectedValue);
    if (selectedValue === "Past") {
      setEndDate(formatDateForInput(new Date()));
    }
  };

  useEffect(() => {
    if (regions.state === State.idle) {
      dispatch(fetchRegions());
    }
  }, [dispatch, regions.state]);

  const regionsOption: DropdownOption[] = useMemo(() => {
    const fetchedRegions = regions.regions?.regions ?? [];

    const dynamicOptions = fetchedRegions.map((region) => ({
      value: region,
      label: region,
    }));

    return [{ value: "All", label: "All" }, ...dynamicOptions];
  }, [regions.regions?.regions]);

  const handleRegionChange = (event: SelectChangeEvent) => {
    setRegionRangeOption(event.target.value);
  };

  const handleDeleteMeeting = (meetingId: number, meetingTitle: string) => {
    dialogContext.showConfirmation(
      "Confirm Deletion",
      <Typography variant="body1">
        Are you sure you want to delete <strong>{meetingTitle}</strong>?
      </Typography>,
      ConfirmationType.accept,
      async () => {
        setLoadingDelete(true);
        await dispatch(deleteMeeting(meetingId))
          .then(() => {
            setPage(0);
            dispatch(
              fetchMeetings({
                searchString: debouncedSearchTerm,
                limit: pageSize,
                offset: 0,
              }),
            )
              .unwrap()
              .then(() => {
                if (
                  upcomingMeetings?.some((up) => up.meetingId === meetingId)
                ) {
                  refreshUpcomingMeetings();
                }
              });
          })
          .finally(() => {
            setLoadingDelete(false);
          });
      },
      "Yes",
      "No",
    );
  };

  // Section related to upcoming sidebar
  const sortedUpcomingMeetings = useMemo(() => {
    if (!upcomingMeetings) return [];
    return upcomingMeetings
      .filter((meeting) => meeting.meetingStatus === "ACTIVE")
      .sort(
        (a, b) =>
          new Date(a.startTime).getTime() - new Date(b.startTime).getTime(),
      )
      .slice(0, 5);
  }, [upcomingMeetings]);

  const createDateTime = (date: Date) => {
    const now = new Date();
    const tomorrow = new Date(now);
    tomorrow.setDate(now.getDate() + 1);
    const isToday =
      date.getFullYear() === now.getFullYear() &&
      date.getMonth() === now.getMonth() &&
      date.getDate() === now.getDate();

    const isTomorrow =
      date.getFullYear() === tomorrow.getFullYear() &&
      date.getMonth() === tomorrow.getMonth() &&
      date.getDate() === tomorrow.getDate();

    const timeStr = date.toLocaleTimeString("en-GB", {
      hour: "2-digit",
      minute: "2-digit",
    });

    if (isToday) {
      return `Today, ${timeStr}`;
    } else if (isTomorrow) {
      return `Tomorrow, ${timeStr}`;
    } else {
      const dateStr = date.toLocaleString("en-GB", {
        month: "short",
        day: "2-digit",
      });
      return `${dateStr}, ${timeStr}`;
    }
  };

  const handleToggleButtonChange = (
    event: React.MouseEvent<HTMLElement>,
    nextView: string | null,
  ) => {
    if (nextView != null) {
      setView(nextView);
    }
  };

  const handlePress = (customerName: string) => {

    navigate(`/meetings/${customerName}`);
  };
  const meetingList = meeting.meetings?.meetings ?? [];

  return (
    <Box
      sx={{
        p: { xs: 2, md: 4 },
        margin: "0 auto",
        bgcolor: "background.default",
        minHeight: "100vh",
      }}
    >
      <Box
        sx={{
          display: "flex",
          justifyContent: "space-between",
          alignItems: "center",
          mb: 4,
        }}
      >
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
            <EventNote />
          </Box>
          <Box>
            <Typography variant="h5" fontWeight="700" color="text.primary">
              Meeting History
            </Typography>
            <Typography variant="body2" color="text.secondary">
              Review past discussions and upcoming schedules.
            </Typography>
          </Box>
        </Box>
        <Box sx={{ display: "flex", alignItems: "center", gap: 2 }}>
          <RadioGroup
            row
            name="use-radio-group"
            defaultValue="Past"
            onChange={handleRadioButtonChange}
          >
            <StyledRadio value="Past" label="Past Meetings" />
            <StyledRadio value="All" label="All Meetings" />
          </RadioGroup>
          <Dropdown
            label="Region"
            value={regionOption}
            options={regionsOption}
            onChange={handleRegionChange}
            isLoading={regions.state === State.loading}
            size="small"
          />
          <TextField
            placeholder="Search meetings..."
            size="small"
            value={searchQuery}
            onChange={(e) => setSearchQuery(e.target.value)}
            sx={{
              width: 350,
              bgcolor: "background.paper",
              boxShadow: (theme) => theme.customShadows.modern,
              borderRadius: 2,
              "& .MuiOutlinedInput-root": {
                borderRadius: 2,
                "& fieldset": { border: "1.5px solid #d1d3d4" },
                "&:hover fieldset": { border: "1.5px solid #d1d3d4" },
                "&.Mui-focused fieldset": {
                  border: `1.5px solid ${theme.palette.brand.main}`,
                },
              },
              "& input": { color: "text.primary" },
            }}
            InputProps={{
              startAdornment: (
                <InputAdornment position="start">
                  <Search sx={{ color: "text.secondary" }} />
                </InputAdornment>
              ),
            }}
          />
          <ToggleButtonGroup
            value={view}
            exclusive
            onChange={handleToggleButtonChange}
          >
            <ToggleButton value="list" aria-label="list">
              <ViewListIcon />
            </ToggleButton>
            <ToggleButton value="module" aria-label="module">
              <ViewModuleIcon />
            </ToggleButton>
          </ToggleButtonGroup>
        </Box>
      </Box>

      <Grid container spacing={4}>
        <Grid item xs={12} md={view === "list" ? 8 : 12}>
          <Box sx={{ minHeight: 500 }}>
            {view === "list" ? (
              meeting.state === State.loading && page === 0 ? (
                <Box sx={{ display: "flex", justifyContent: "center", p: 4 }}>
                  <CircularProgress sx={{ color: theme.palette.brand.main }} />
                </Box>
              ) : meeting.state === State.failed ? (
                <ErrorHandler message="Failed to fetch meetings." />
              ) : meetingList.length === 0 ? (
                <Paper
                  sx={{
                    p: 6,
                    textAlign: "center",
                    borderRadius: 3,
                    boxShadow: (theme) => theme.customShadows.modern,
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
                      key={row.meetingId} // Add a unique key here
                      formatDateTime={formatDateTime}
                      meeting={row}
                      handleAccordionChange={handleAccordionChange}
                      handleDeleteMeeting={handleDeleteMeeting}
                      loadingAttachments={loadingAttachments}
                      attachmentMap={attachmentMap}
                    />
                  ))}

                  <div
                    ref={observerTarget}
                    style={{ height: "20px", marginTop: "10px" }}
                  >
                    {meeting.state === State.loading && page > 0 && (
                      <Box sx={{ display: "flex", justifyContent: "center" }}>
                        <CircularProgress
                          size={24}
                          sx={{ color: theme.palette.brand.main }}
                        />
                      </Box>
                    )}
                  </div>
                </Box>
              )
            ) : (
              <Grid container spacing={3}>
                {meetingsSummaryState === State.loading ? (
                  <Grid
                    item
                    xs={12}
                    sx={{ display: "flex", justifyContent: "center", p: 4 }}
                  >
                    <CircularProgress />
                  </Grid>
                ) : meetingsSummary?.meetingsSummary &&
                  meetingsSummary.meetingsSummary.length > 0 ? (
                  meetingsSummary.meetingsSummary.map((summary, index) => (
                    <Grid item xs={12} sm={6} md={4} lg={3} key={index}>
                      <CustomerCard
                        id={index}
                        customerName={summary.customerName}
                        meetingCount={summary.meetingCount}
                        onCardClick={()=>handlePress(summary.customerName)}
                      />
                    </Grid>
                  ))
                ) : (
                  <Grid item xs={12}>
                    <Typography
                      variant="body1"
                      color="text.secondary"
                      align="center"
                      sx={{ mt: 4 }}
                    >
                      No customer summaries available.
                    </Typography>
                  </Grid>
                )}
              </Grid>
            )}
          </Box>
        </Grid>

        {view === "list" && (
          <Grid item xs={12} md={4}>
            <Card
              sx={{
                boxShadow: (theme) => theme.customShadows.modern,
                borderRadius: 3,
                position: "sticky",
                top: 24,
                p: 2,
                bgcolor: "background.paper",
                border: "1.5px solid #d1d3d4",
                transition: "border-color 0.3s ease-in-out",
                "&:hover": {
                  borderColor: theme.palette.brand.main,
                },
              }}
            >
              <CardContent sx={{ "&:last-child": { pb: 0 } }}>
                <Typography
                  variant="h6"
                  fontWeight="700"
                  color="text.primary"
                  sx={{ mb: 2, display: "flex", alignItems: "center", gap: 1 }}
                >
                  <Schedule sx={{ color: theme.palette.brand.main }} /> Upcoming
                  Meetings
                </Typography>
                <List disablePadding>
                  {upcomingMeetingsLoading === State.loading ? (
                    <ListItem disableGutters>
                      <CircularProgress size={20} />
                    </ListItem>
                  ) : sortedUpcomingMeetings.length > 0 ? (
                    sortedUpcomingMeetings.map((item, index) => (
                      <ListItem
                        key={index}
                        disableGutters
                        sx={{
                          borderBottom:
                            index < sortedUpcomingMeetings.length - 1
                              ? `1px solid ${theme.palette.divider}`
                              : "none",
                          py: 2,
                          display: "flex",
                          alignItems: "center",
                          gap: 2,
                        }}
                      >
                        <Typography
                          variant="caption"
                          color="text.secondary"
                          sx={{
                            minWidth: 90,
                            textAlign: "left",
                            display: "inline-flex",
                            alignItems: "center",
                            mr: 2,
                          }}
                        >
                          {createDateTime(new Date(item.startTime))}
                        </Typography>
                        <Box sx={{ flex: 1 }}>
                          <Typography
                            variant="subtitle2"
                            fontWeight="700"
                            color="text.primary"
                            component="span"
                          >
                            {item.title}
                          </Typography>
                        </Box>
                      </ListItem>
                    ))
                  ) : (
                    <ListItem disableGutters>
                      <Typography variant="body2" color="text.secondary">
                        No upcoming meetings.
                      </Typography>
                    </ListItem>
                  )}
                </List>
                {/* <Button fullWidth variant="contained" disableElevation>
                  View more upcoming meetings
                </Button> */}
              </CardContent>
            </Card>
          </Grid>
        )}
      </Grid>
    </Box>
  );
}

export default MeetingHistory;

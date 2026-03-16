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

import React, { useEffect } from "react";
import {
  Box,
  Container,
  Grid,
  Typography,
  Button,
  Avatar,
  Chip,
  Paper,
  Divider,
  List,
  ListItem,
  ListItemText,
  Accordion,
  AccordionSummary,
  CircularProgress,
  AccordionDetails,
  IconButton,
  Card,
  CardContent,
  Stack,
  Link,
  useTheme,
} from "@mui/material";

// Icons
import AddIcon from "@mui/icons-material/Add";
import ExpandMoreIcon from "@mui/icons-material/ExpandMore";
import HistoryIcon from "@mui/icons-material/History";
import PlayCircleOutlineIcon from "@mui/icons-material/PlayCircleOutline";
import PictureAsPdfIcon from "@mui/icons-material/PictureAsPdf";
import DescriptionIcon from "@mui/icons-material/Description";
import SlideshowIcon from "@mui/icons-material/Slideshow";
import DownloadIcon from "@mui/icons-material/Download";
import VideoCameraBackIcon from "@mui/icons-material/VideoCameraBack";
import LockIcon from "@mui/icons-material/Lock";
import { useAppDispatch, useAppSelector } from "@root/src/slices/store";
import { useParams } from "react-router-dom";
import { fetchMeetingsByCustomer } from "@root/src/slices/meetingSlice/meeting";
import { State } from "@root/src/types/types";
import ErrorHandler from "@component/common/ErrorHandler";
import MeetingsAccordion from "@root/src/component/ui/MeetingsAccordion";
import { useState } from "react";
import {
  fetchMeetings,
  deleteMeeting,
  fetchAttachments,
  fetchMeetingsByDates,
} from "@slices/meetingSlice/meeting";
import { Attachment } from "../../types/types";

export default function CustomerMeetings() {
  const formatDateTime = (dateTimeStr: string) => {
    const utcDate = new Date(dateTimeStr + " UTC");
    return utcDate.toLocaleString("en-GB", {
      day: "2-digit",
      month: "short",
      year: "numeric",
      hour: "2-digit",
      minute: "2-digit",
    });
  };
  const theme = useTheme();
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
  useEffect(() => {
    const params: any = {
      customerName: customerName,
      limit: 10,
    };
    dispatch(fetchMeetingsByCustomer(params));
  }, [customerName]);
  const meetingList = meeting?.customerMeetings?.meetings ?? [];
  console.log(meetingList);

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
            alignItems: "flex-start",
            mb: 4,
            flexWrap: "wrap",
            gap: 2,
          }}
        >
          <Box>
            <Typography
              variant="h5"
              sx={{ fontWeight: 800, mb: 1, color: "text.primary" }}
            >
              Customer : {customerName}
            </Typography>
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
                label={`total sessions ${meeting.customerMeetings?.count}`}
                size="small"
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
             { meetingList.map((row) => (
      
               
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

            <Box
              sx={{
                display: "flex",
                justifyContent: "flex-end",
                alignItems: "center",
                mt: 2,
                color: "text.secondary",
                fontSize: "0.875rem",
              }}
            >
              Rows per page: 10 <ExpandMoreIcon fontSize="small" /> &nbsp; 1-3
              of 12 &nbsp; &lt; &nbsp; &gt;
            </Box>
          </Grid>

          <Grid item xs={12} lg={4}>
            <Card sx={{ mb: 3, borderRadius: 2, bgcolor: "background.paper" }}>
              <CardContent>
                <Box
                  sx={{
                    display: "flex",
                    justifyContent: "space-between",
                    mb: 2,
                  }}
                >
                  <Typography variant="h6" sx={{ fontWeight: 700 }}>
                    Upcoming Schedule
                  </Typography>
                  <Link
                    href="#"
                    underline="hover"
                    sx={{
                      fontWeight: 600,
                      fontSize: "0.875rem",
                      color: "primary.main",
                    }}
                  >
                    View All
                  </Link>
                </Box>

                <List disablePadding>
                  <ListItem
                    disableGutters
                    alignItems="flex-start"
                    sx={{ mb: 2 }}
                  >
                    <Box sx={{ minWidth: 40, mr: 2, textAlign: "center" }}>
                      <Typography
                        variant="caption"
                        sx={{ fontWeight: "bold", color: "primary.main" }}
                      >
                        JAN
                      </Typography>
                      <Typography
                        variant="h6"
                        sx={{ lineHeight: 1, fontWeight: "bold" }}
                      >
                        30
                      </Typography>
                    </Box>
                    <ListItemText
                      primary={
                        <Typography
                          variant="subtitle2"
                          sx={{ fontWeight: 700 }}
                        >
                          Architecture Review
                        </Typography>
                      }
                      secondary={
                        <Box component="span">
                          <Typography
                            variant="caption"
                            display="block"
                            color="text.secondary"
                          >
                            10:00 AM - 12:00 PM
                          </Typography>
                          <Box
                            component="span"
                            sx={{
                              display: "flex",
                              alignItems: "center",
                              mt: 0.5,
                              color: "primary.main",
                              fontWeight: 600,
                              fontSize: "0.75rem",
                              cursor: "pointer",
                            }}
                          >
                            <VideoCameraBackIcon
                              sx={{ fontSize: 14, mr: 0.5 }}
                            />{" "}
                            Join Meeting
                          </Box>
                        </Box>
                      }
                    />
                  </ListItem>
                  <Divider
                    sx={{
                      my: 1,
                      borderStyle: "dashed",
                      borderColor: "divider",
                    }}
                  />

                  <ListItem
                    disableGutters
                    alignItems="flex-start"
                    sx={{ mb: 2, mt: 1 }}
                  >
                    <Box sx={{ minWidth: 40, mr: 2, textAlign: "center" }}>
                      <Typography
                        variant="caption"
                        sx={{ fontWeight: "bold", color: "primary.main" }}
                      >
                        FEB
                      </Typography>
                      <Typography
                        variant="h6"
                        sx={{ lineHeight: 1, fontWeight: "bold" }}
                      >
                        06
                      </Typography>
                    </Box>
                    <ListItemText
                      primary={
                        <Typography
                          variant="subtitle2"
                          sx={{ fontWeight: 700 }}
                        >
                          Weekly Sync
                        </Typography>
                      }
                      secondary={
                        <Box component="span">
                          <Typography
                            variant="caption"
                            display="block"
                            color="text.secondary"
                          >
                            09:00 AM - 10:00 AM
                          </Typography>
                          <Box
                            component="span"
                            sx={{
                              display: "flex",
                              alignItems: "center",
                              mt: 0.5,
                              color: "text.disabled",
                              fontSize: "0.75rem",
                            }}
                          >
                            <LockIcon sx={{ fontSize: 14, mr: 0.5 }} /> Not
                            Started
                          </Box>
                        </Box>
                      }
                    />
                  </ListItem>
                </List>
              </CardContent>
            </Card>

            <Card sx={{ borderRadius: 2, bgcolor: "background.paper" }}>
              <CardContent>
                <Box
                  sx={{
                    display: "flex",
                    justifyContent: "space-between",
                    mb: 2,
                    alignItems: "center",
                  }}
                >
                  <Typography variant="h6" sx={{ fontWeight: 700 }}>
                    All Attachments
                  </Typography>
                  <Chip label="5 Files" size="small" />
                </Box>

                <List>
                  <ListItem
                    disableGutters
                    secondaryAction={
                      <IconButton edge="end">
                        <DownloadIcon color="action" />
                      </IconButton>
                    }
                  >
                    <PictureAsPdfIcon
                      sx={{ color: "#f44336", mr: 2, fontSize: 32 }}
                    />
                    <ListItemText
                      primary="WSO2_Architecture_v2.pdf"
                      primaryTypographyProps={{
                        variant: "subtitle2",
                        fontWeight: 600,
                        color: "text.primary",
                      }}
                      secondary="Added Jan 23 • 4.2 MB"
                      secondaryTypographyProps={{ variant: "caption" }}
                    />
                  </ListItem>
                  <Divider />

                  <ListItem
                    disableGutters
                    secondaryAction={
                      <IconButton edge="end">
                        <DownloadIcon color="action" />
                      </IconButton>
                    }
                  >
                    <SlideshowIcon
                      sx={{ color: "#ff9800", mr: 2, fontSize: 32 }}
                    />
                    <ListItemText
                      primary="Kickoff_Deck.pptx"
                      primaryTypographyProps={{
                        variant: "subtitle2",
                        fontWeight: 600,
                        color: "text.primary",
                      }}
                      secondary="Added Jan 09 • 12.5 MB"
                      secondaryTypographyProps={{ variant: "caption" }}
                    />
                  </ListItem>
                </List>

                <Button
                  variant="outlined"
                  fullWidth
                  sx={{
                    mt: 1,
                    textTransform: "none",
                    color: "text.secondary",
                    borderColor: "divider",
                  }}
                >
                  Show All Files
                </Button>
              </CardContent>
            </Card>
          </Grid>
        </Grid>
      </Container>
    </Box>
  );
}

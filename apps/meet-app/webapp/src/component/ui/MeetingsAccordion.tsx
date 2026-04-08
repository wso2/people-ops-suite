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

import "../../theme";
import {
  Box,
  Button,
  Grid,
  Typography,
  CircularProgress,
  Accordion,
  AccordionSummary,
  AccordionDetails,
  Chip,
  Divider,
  Tooltip,
} from "@mui/material";
import {
  ExpandMore,
  DeleteForever,
  InsertDriveFile,
  Schedule,
  Loop,
  Person,
  Group,
} from "@mui/icons-material";
import CheckCircleIcon from "@mui/icons-material/CheckCircle";
import DeleteIcon from "@mui/icons-material/Delete";
import { useTheme, alpha } from "@mui/material/styles";
import { Meeting } from "../../slices/meetingSlice/meeting";
import { Attachment } from "../../types/types";

interface MeetingsAccordionProps {
  meeting: Meeting;
  handleAccordionChange: (id: number, expanded: boolean) => void;
  formatDateTime: (dateTimeStr: string) => string;
  loadingAttachments: Record<number, boolean>;
  attachmentMap: Record<number, Attachment[]>;
  handleDeleteMeeting: (id: number, title: string) => void;
  isAdmin?: boolean;
  userEmail?: string;
}

export const MeetingsAccordion = ({
  meeting,
  handleAccordionChange,
  formatDateTime,
  handleDeleteMeeting,
  loadingAttachments,
  attachmentMap,
  isAdmin,
  userEmail,
}: MeetingsAccordionProps) => {
  const theme = useTheme();
  return (
    <Accordion
      key={meeting.meetingId}
      disableGutters
      elevation={0}
      onChange={(_, expanded) =>
        handleAccordionChange(meeting.meetingId, expanded)
      }
      sx={{
        boxShadow: (theme) => theme.customShadows.modern,
        borderRadius: "12px !important",
        bgcolor: "background.paper",
        border: `1.5px solid #d1d3d4`,
        "&:before": { display: "none" },
        transition: "all 0.3s ease-in-out",
        "&:hover": {
          boxShadow: (theme) => theme.customShadows.hover,
          transform: "translateY(-2px)",
          borderColor: theme.palette.brand.main,
        },
      }}
    >
      <AccordionSummary
        expandIcon={<ExpandMore sx={{ color: theme.palette.brand.main }} />}
        sx={{ px: 3, py: 1 }}
      >
        <Box
          sx={{
            display: "flex",
            justifyContent: "space-between",
            alignItems: "center",
            width: "100%",
            pr: 2,
          }}
        >
          <Box
            sx={{
              display: "flex",
              alignItems: "center",
              gap: 1.5,
            }}
          >
            {meeting.meetingStatus === "ACTIVE" ? (
              <Tooltip title="ACTIVE">
                <CheckCircleIcon color="success" />
              </Tooltip>
            ) : meeting.meetingStatus === "CANCELLED" ? (
              <Tooltip title="CANCELLED">
                <DeleteIcon color="disabled" />
              </Tooltip>
            ) : null}
            <Typography
              fontWeight="700"
              variant="subtitle1"
              sx={{ color: "text.primary" }}
            >
              {meeting.title}
            </Typography>
            {(meeting.timeStatus === "UPCOMING") == true && (
              <Chip
                label="Upcoming"
                size="small"
                color="primary"
                sx={{ height: 20, fontSize: "0.65rem" }}
              />
            )}
          </Box>
          <Box
            sx={{
              display: "flex",
              alignItems: "center",
              gap: 0.5,
            }}
          >
            <Schedule fontSize="small" sx={{ color: "text.secondary" }} />
            <Typography variant="body2" color="text.secondary" fontWeight="500">
              {formatDateTime(meeting.startTime)}
            </Typography>
          </Box>
        </Box>
      </AccordionSummary>

      <AccordionDetails sx={{ px: 3, pb: 3, pt: 1 }}>
        <Divider sx={{ mb: 3 }} />
        <Grid container spacing={3}>
          <Grid item xs={12} sm={6}>
            <Typography
              variant="caption"
              sx={{
                color: "text.disabled",
                letterSpacing: 0.5,
                fontWeight: "bold",
              }}
            >
              HOST
            </Typography>
            <Typography
              variant="body2"
              sx={{
                display: "flex",
                alignItems: "center",
                gap: 1,
                mt: 0.5,
                color: "text.primary",
              }}
            >
              <Person
                fontSize="small"
                sx={{ color: theme.palette.brand.main }}
              />{" "}
              {meeting.host}
            </Typography>
          </Grid>

          <Grid item xs={12} sm={6}>
            <Typography
              variant="caption"
              sx={{
                color: "text.disabled",
                letterSpacing: 0.5,
                fontWeight: "bold",
              }}
            >
              RECURRING
            </Typography>
            <Typography
              variant="body2"
              sx={{
                display: "flex",
                alignItems: "center",
                gap: 1,
                mt: 0.5,
                color: "text.primary",
              }}
            >
              <Loop fontSize="small" sx={{ color: theme.palette.brand.main }} />{" "}
              {meeting.isRecurring ? "Yes, Recurring Series" : "No"}
            </Typography>
          </Grid>
          <Grid item xs={12}>
            <Typography
              variant="caption"
              sx={{
                color: "text.disabled",
                letterSpacing: 0.5,
                fontWeight: "bold",
              }}
            >
              PARTICIPANTS
            </Typography>
            <Box
              sx={{
                display: "flex",
                flexWrap: "wrap",
                gap: 1,
                mt: 1,
              }}
            >
              {meeting.internalParticipants
                .toString()
                .split(",")
                .map((email: string, i: number) => (
                  <Chip
                    key={i}
                    label={email.trim()}
                    icon={<Group sx={{ pl: 0.5 }} />}
                    size="small"
                    sx={{
                      bgcolor: theme.palette.action.selected,
                      color: "text.primary",
                      fontWeight: 500,
                    }}
                  />
                ))}
            </Box>
          </Grid>
          <Grid item xs={12}>
            <Typography
              variant="caption"
              sx={{
                color: "text.disabled",
                letterSpacing: 0.5,
                fontWeight: "bold",
              }}
            >
              ATTACHMENTS
            </Typography>
            <Box sx={{ mt: 1 }}>
              {loadingAttachments[meeting.meetingId] ? (
                <Box
                  sx={{
                    display: "flex",
                    alignItems: "center",
                    gap: 1,
                  }}
                >
                  <CircularProgress
                    size={16}
                    sx={{ color: theme.palette.brand.main }}
                  />
                  <Typography variant="caption" color="text.secondary">
                    Loading...
                  </Typography>
                </Box>
              ) : attachmentMap[meeting.meetingId]?.length > 0 ? (
                <Box
                  sx={{
                    display: "flex",
                    flexWrap: "wrap",
                    gap: 1,
                  }}
                >
                  {attachmentMap[meeting.meetingId].map((att, idx) => (
                    <Button
                      key={idx}
                      variant="outlined"
                      startIcon={<InsertDriveFile />}
                      onClick={() => window.open(att.fileUrl, "_blank")}
                      size="small"
                      sx={{
                        borderColor: theme.palette.divider,
                        color: "text.secondary",
                        textTransform: "none",
                        borderRadius: 2,
                        "&:hover": {
                          borderColor: theme.palette.brand.main,
                          color: theme.palette.brand.main,
                          bgcolor: alpha(theme.palette.brand.main, 0.04),
                        },
                      }}
                    >
                      {att.title || "Attachment"}
                    </Button>
                  ))}
                </Box>
              ) : (
                <Typography
                  variant="body2"
                  color="text.secondary"
                  fontStyle="italic"
                >
                  No attachments available.
                </Typography>
              )}
            </Box>
          </Grid>

          {/* Actions */}
          <Grid
            item
            xs={12}
            sx={{
              display: "flex",
              justifyContent: "flex-end",
              mt: -2,
            }}
          >
            <Button
              color="error"
              startIcon={<DeleteForever />}
              disabled={
                meeting.meetingStatus === "CANCELLED" ||
                meeting.timeStatus === "PAST" ||
                !isAdmin ||
                userEmail === meeting.host
              }
              onClick={() =>
                handleDeleteMeeting(meeting.meetingId, meeting.title)
              }
              sx={{ textTransform: "none", fontWeight: 600 }}
            >
              Delete Meeting
            </Button>
          </Grid>
        </Grid>
      </AccordionDetails>
    </Accordion>
  );
};

export default MeetingsAccordion;

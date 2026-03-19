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

import {
  Box,
  Typography,
  CircularProgress,
  List,
  ListItem,
  Card,
  CardContent,
} from "@mui/material";
import { Schedule } from "@mui/icons-material";
import { useTheme } from "@mui/material/styles";
import { Meeting } from "../../slices/meetingSlice/meeting";

interface UpcomingMeetingCardProps {
  upcomingMeetings: Meeting[];
  loadingMeetings: boolean;
  formatDateTime?: (dateTimeStr: Date) => string;
  variant?: "history" | "customer";
  onViewAllClick?: () => void;
}

const UpcomingMeetingCard = ({
  upcomingMeetings,
  loadingMeetings,
  formatDateTime,
  variant = "history", 
  onViewAllClick,
}: UpcomingMeetingCardProps) => {
  const theme = useTheme() as any;
  const getMonth = (dateString: string) => {
    return new Date(dateString)
      .toLocaleString("en-US", { month: "short" })
      .toUpperCase();
  };
  const getDay = (dateString: string) => {
    return new Date(dateString).toLocaleString("en-US", { day: "2-digit" });
  };

  return (
    <Card
      sx={{
        boxShadow: (theme: any) => theme.customShadows?.modern || 3,
        borderRadius: 3,
        bgcolor: "background.paper",
        border: "1.5px solid #d1d3d4",
        transition: "border-color 0.3s ease-in-out",
        "&:hover": {
          borderColor: theme.palette.brand?.main || theme.palette.primary.main,
        },
        p: 2,
      }}
    >
      <CardContent sx={{ "&:last-child" : "padd"}}>
        <Typography
          variant="h6"
          fontWeight="700"
          color="text.primary"
          sx={{ mb: 2, display: "flex", alignItems: "center", gap: 1 }}
        >
          <Schedule
            sx={{ color: theme.palette.brand?.main || "primary.main" }}
          />{" "}
          Upcoming Meetings
        </Typography>

        <List disablePadding>
          {loadingMeetings ? (
            <ListItem disableGutters sx={{ justifyContent: "center", py: 2 }}>
              <CircularProgress
                size={20}
                sx={{ color: theme.palette.brand?.main || "primary.main" }}
              />
            </ListItem>
          ) : upcomingMeetings.length > 0 ? (
            upcomingMeetings.map((item, index) => {
              return (
                <ListItem
                  key={item.meetingId || index}
                  disableGutters
                  sx={{
                    borderBottom:
                      index < upcomingMeetings.length - 1
                        ? `1px solid ${theme.palette.divider}`
                        : "none",
                    py: 2,
                    display: "flex",
                    alignItems: "center",
                    gap: 2,
                  }}
                >
                  {variant === "customer" ? (
                    <Box sx={{ minWidth: 40, mr: 2, textAlign: "center" }}>
                      <Typography
                        variant="caption"
                        sx={{ fontWeight: "bold", color: "primary.main" }}
                      >
                        {getMonth(item.startTime)}
                      </Typography>
                      <Typography
                        variant="h6"
                        sx={{ lineHeight: 1, fontWeight: "bold" }}
                      >
                        {getDay(item.startTime)}
                      </Typography>
                    </Box>
                  ) : (
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
                      {formatDateTime
                        ? formatDateTime(new Date(item.startTime))
                        : item.startTime}
                    </Typography>
                  )}
                  <Box sx={{ flex: 1 }}>
                    <Typography
                      variant="subtitle2"
                      fontWeight="700"
                      color="text.primary"
                    >
                      {item.title}
                    </Typography>
                  </Box>
                </ListItem>
              );
            })
          ) : (
            <ListItem disableGutters sx={{ py: 2 }}>
              <Typography variant="body2" color="text.secondary">
                No upcoming meetings.
              </Typography>
            </ListItem>
          )}
        </List>
      </CardContent>
    </Card>
  );
};

export default UpcomingMeetingCard;

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
  Card,
  CardContent,
  Chip,
  CardActionArea,
  alpha,
} from "@mui/material";
import EventNoteIcon from "@mui/icons-material/EventNote";
interface CustomerCardProps {
  id: number;
  customerName: string;
  meetingCount: number;
  onCardClick?: (id: number) => void;
}
const CustomerCard = ({
  id,
  customerName,
  meetingCount,
  onCardClick,
}: CustomerCardProps) => {
  return (
    <Card
      variant="outlined"
      sx={{
        height: "100%",
        borderRadius: 2,
        boxShadow: "0 2px 4px rgba(0,0,0,0.05)",
        transition: "transform 0.2s, box-shadow 0.2s, border-color 0.2s",
        "&:hover": {
          transform: "translateY(-2px)",
          boxShadow: "0 4px 12px rgba(0,0,0,0.1)",
          borderColor: "primary.main",
        },
      }}
    >
      <CardActionArea
        onClick={() => onCardClick?.(id)}
        sx={{
          height: "100%",
          display: "flex",
          flexDirection: "column",
          alignItems: "stretch",
          justifyContent: "flex-start",
        }}
      >
        <CardContent
          sx={{
            display: "flex",
            flexDirection: "column",
            gap: 2,
            height: "100%",
          }}
        >
          <Box>
            <Typography
              variant="overline"
              color="text.secondary"
              fontWeight="bold"
            >
              Customer
            </Typography>
            <Typography
              variant="h6"
              component="div"
              fontWeight="bold"
              sx={{
                lineHeight: 1.3,
                display: "-webkit-box",
                overflow: "hidden",
                WebkitBoxOrient: "vertical",
                WebkitLineClamp: 2,
              }}
            >
              {customerName}
            </Typography>
          </Box>

          <Box sx={{ flexGrow: 1 }} />
          <Box
            display="flex"
            alignItems="center"
            justifyContent="space-between"
            sx={{
              bgcolor: (theme) =>
                theme.palette.mode === "dark"
                  ? alpha(theme.palette.common.white, 0.05)
                  : theme.palette.grey[50], 
              p: 2,
              borderRadius: 2,
              border: "1px solid",
              borderColor: "divider",
            }}
          >
            <Box
              display="flex"
              alignItems="center"
              gap={1}
              color="text.secondary"
            >
              <EventNoteIcon fontSize="small" />
              <Typography variant="body2" fontWeight="medium">
                Meetings
              </Typography>
            </Box>

            <Chip
              label={meetingCount}
              color="primary"
              size="small"
              sx={{ fontWeight: "bold", minWidth: "40px" }}
            />
          </Box>
        </CardContent>
      </CardActionArea>
    </Card>
  );
};

export default CustomerCard;

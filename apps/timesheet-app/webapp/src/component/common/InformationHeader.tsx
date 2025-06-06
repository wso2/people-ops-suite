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
// under the License.import React from "react";
import {
  Box,
  Card,
  Chip,
  Grid,
  Stack,
  Tooltip,
  Divider,
  useTheme,
  Typography,
  CardContent,
  LinearProgress,
} from "@mui/material";
import {
  Work,
  Cancel,
  AccessTime,
  CheckCircle,
  HourglassTop,
  FreeBreakfast,
  PendingActions,
  HourglassBottom,
  RunningWithErrors,
} from "@mui/icons-material";
import { TimesheetInfo, WorkPolicies } from "@utils/types";

interface InformationHeaderProps {
  timesheetInfo: TimesheetInfo;
  workPolicies: WorkPolicies;
  isLeadView?: boolean;
  isAdminView?: boolean;
}

const InformationHeader: React.FC<InformationHeaderProps> = ({
  timesheetInfo,
  workPolicies,
  isLeadView,
  isAdminView,
}) => {
  const theme = useTheme();

  const {
    approvedRecords = 0,
    pendingRecords = 0,
    rejectedRecords = 0,
    totalOverTimeTaken = 0,
    totalRecords = 0,
  } = timesheetInfo;

  const otHoursPerYear = workPolicies?.otHoursPerYear ?? 0;
  const workingHoursPerDay = workPolicies?.workingHoursPerDay ?? 0;
  const pendingRate = totalRecords > 0 ? (pendingRecords / totalRecords) * 100 : 0;
  const overTimeLeft = otHoursPerYear > 0 ? otHoursPerYear - totalOverTimeTaken : 0;
  const approvalRate = totalRecords > 0 ? (approvedRecords / totalRecords) * 100 : 0;
  const rejectionRate = totalRecords > 0 ? (rejectedRecords / totalRecords) * 100 : 0;
  const otUtilizationPercentage = otHoursPerYear > 0 ? Math.min(100, (totalOverTimeTaken / otHoursPerYear) * 100) : 0;

  const statusChips = [
    {
      label: `Approved: ${approvedRecords}`,
      icon: <CheckCircle fontSize="small" />,
      color: "success" as const,
    },
    {
      label: `Pending: ${pendingRecords}`,
      icon: <PendingActions fontSize="small" />,
      color: "warning" as const,
    },
    {
      label: `Rejected: ${rejectedRecords}`,
      icon: <Cancel fontSize="small" />,
      color: "error" as const,
    },
    {
      label: `Total Records: ${totalRecords}`,
      icon: <AccessTime fontSize="small" />,
      color: "info" as const,
    },
  ];

  const stats = [
    {
      title: "OT Utilization",
      value: `${totalOverTimeTaken.toFixed(1)}h`,
      subtitle: `${otUtilizationPercentage.toFixed(0)}% of allowance`,
      icon: <HourglassTop />,
      color: otUtilizationPercentage > 80 ? "error" : "primary",
      progress: otUtilizationPercentage,
    },
    {
      title: "OT Remaining",
      value: `${overTimeLeft.toFixed(1)}h`,
      subtitle: `${(otHoursPerYear > 0 ? (overTimeLeft / otHoursPerYear) * 100 : 0).toFixed(0)}% left`,
      icon: <HourglassBottom />,
      color: "success",
      progress: otHoursPerYear > 0 ? (overTimeLeft / otHoursPerYear) * 100 : 0,
    },
    {
      title: "Approval Rate",
      value: `${approvalRate.toFixed(0)}%`,
      subtitle: `${approvedRecords} approved records`,
      icon: <CheckCircle />,
      color: approvalRate > 80 ? "success" : approvalRate > 50 ? "warning" : "error",
      progress: approvalRate,
    },
    {
      title: "Rejection Rate",
      value: `${rejectionRate.toFixed(0)}%`,
      subtitle: `${rejectedRecords} rejected records`,
      icon: <Cancel />,
      color: rejectionRate > 30 ? "error" : rejectionRate > 15 ? "warning" : "success",
      progress: rejectionRate,
    },
    {
      title: "Pending Rate",
      value: `${pendingRate.toFixed(0)}%`,
      subtitle: `${pendingRecords} pending records`,
      icon: <PendingActions />,
      color: pendingRate > 30 ? "warning" : "info",
      progress: pendingRate,
    },
  ];

  return (
    <Card
      sx={{
        borderRadius: 2,
        boxShadow: theme.shadows[3],
        mb: 1,
      }}
    >
      <CardContent>
        <Stack
          direction="row"
          spacing={1}
          sx={{
            flexWrap: "wrap",
            gap: 1,
            justifyContent: "center",
          }}
        >
          {statusChips.map((chip, index) => (
            <Chip
              key={index}
              icon={chip.icon}
              label={chip.label}
              color={chip.color}
              variant="outlined"
              size="medium"
              sx={{
                borderWidth: 2,
                px: 1,
              }}
            />
          ))}
          {!isLeadView && !isAdminView && (
            <>
              <Chip
                icon={<FreeBreakfast />}
                label={`Lunch Time: ${workPolicies.lunchHoursPerDay}h`}
                variant="outlined"
                sx={{
                  borderWidth: 2,
                  px: 1,
                }}
              />
              <Chip
                icon={<RunningWithErrors />}
                label={`OT Annual Allowance: ${workPolicies.otHoursPerYear}h`}
                color="primary"
                variant="outlined"
                sx={{
                  borderWidth: 2,
                  px: 1,
                }}
              />
              <Chip
                icon={<Work />}
                label={`Work TIme ${workingHoursPerDay}h`}
                color="secondary"
                variant="outlined"
                sx={{
                  borderWidth: 2,
                  px: 1,
                }}
              />
            </>
          )}
        </Stack>

        {!isLeadView && (
          <>
            <Divider sx={{ my: 1 }} />
            <Grid container spacing={3}>
              {stats.map((stat, index) => (
                <Grid item xs={12} sm={2.4} md={2.4} lg={2.4} key={index}>
                  <Box sx={{ display: "flex", alignItems: "center", mb: 1 }}>
                    <Box>
                      <Typography variant="body2" color="text.secondary">
                        {stat.title}
                      </Typography>
                      <Typography variant="h6">{stat.value}</Typography>
                    </Box>
                  </Box>
                  <Typography variant="caption" color="text.secondary">
                    {stat.subtitle}
                  </Typography>
                  <Tooltip title={`${stat.progress.toFixed(0)}%`}>
                    <LinearProgress
                      variant="determinate"
                      value={stat.progress}
                      color={stat.color as any}
                      sx={{
                        height: 6,
                        borderRadius: 3,
                        mt: 1,
                        backgroundColor: theme.palette.grey[200],
                      }}
                    />
                  </Tooltip>
                </Grid>
              ))}
            </Grid>
          </>
        )}
      </CardContent>
    </Card>
  );
};

export default InformationHeader;

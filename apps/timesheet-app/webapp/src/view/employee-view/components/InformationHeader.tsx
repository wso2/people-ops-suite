import React from "react";
import {
  Card,
  CardContent,
  LinearProgress,
  Tooltip,
  Typography,
  Grid,
  Box,
  Divider,
  Chip,
  Avatar,
  useTheme
} from "@mui/material";
import {
  AccessTime,
  Person,
  Work,
  FreeBreakfast,
  EmojiEvents,
  HourglassTop,
  HourglassBottom,
  TrendingUp,
  TrendingDown
} from "@mui/icons-material";




interface InformationHeaderProps {
    metaData: {
      overtimeCount: number;
      totalRecords: number;
      recordsWithOvertime: number;
      employeeEmail: string;
      leadEmail: string;
    };
    workPolicies: {
      otHoursPerYear: number;
      workingHoursPerDay: number;
      lunchHoursPerDay: number;
    };
  }



// interface InformationHeaderProps {
//   metaData: {
//     overtimeCount: number;
//     totalRecords: number;
//     recordsWithOvertime: number;
//     employeeEmail: string;
//     leadEmail: string;
//     averageDailyHours?: number;
//     approvedRecords?: number;
//     pendingRecords?: number;
//   };
//   workPolicies: {
//     otHoursPerYear: number;
//     workingHoursPerDay: number;
//     lunchHoursPerDay: number;
//   };
// }

const InformationHeader: React.FC<InformationHeaderProps> = ({ metaData, workPolicies }) => {

    console.log(metaData.leadEmail)
  const theme = useTheme();
  const otHoursUsed = metaData.overtimeCount;
  const otHoursRemaining = Math.max(0, workPolicies.otHoursPerYear - otHoursUsed);
  const otUtilizationPercentage = Math.min(100, (otHoursUsed / workPolicies.otHoursPerYear) * 100);
  const otTrend = otHoursUsed > (workPolicies.otHoursPerYear / 2) ? "high" : "low";

  const dailyWorkingHours = workPolicies.workingHoursPerDay;
  const dailyWorkingHoursWithoutLunch = dailyWorkingHours - workPolicies.lunchHoursPerDay;

  const overtimeRatio = metaData.totalRecords > 0
    ? (metaData.recordsWithOvertime / metaData.totalRecords) * 100
    : 0;

//   const approvalRate = metaData.approvedRecords && metaData.totalRecords > 0
//     ? (metaData.approvedRecords / metaData.totalRecords) * 100
//     : 0;

//   const avgDailyHours = metaData.averageDailyHours || 0;
//   const efficiency = avgDailyHours > 0
//     ? (avgDailyHours / dailyWorkingHoursWithoutLunch) * 100
//     : 0;

  const getTrendIcon = (value: number, threshold: number) => {
    return value > threshold ? <TrendingUp color="error" /> : <TrendingDown color="success" />;
  };

  const stats = [
    {
      title: "OT Utilization",
      value: `${otHoursUsed.toFixed(1)}h`,
      subtitle: `${otUtilizationPercentage.toFixed(0)}% of allowance`,
      icon: <HourglassTop />,
      color: otUtilizationPercentage > 80 ? "error" : "primary",
      progress: otUtilizationPercentage,
      trend: getTrendIcon(otHoursUsed, workPolicies.otHoursPerYear * 0.5)
    },
    {
      title: "OT Remaining",
      value: `${otHoursRemaining.toFixed(1)}h`,
      subtitle: `${((otHoursRemaining / workPolicies.otHoursPerYear) * 100).toFixed(0)}% remaining`,
      icon: <HourglassBottom />,
      color: "success",
      progress: (otHoursRemaining / workPolicies.otHoursPerYear) * 100
    },
    {
      title: "Overtime Frequency",
      value: `${metaData.recordsWithOvertime}`,
      subtitle: `${overtimeRatio.toFixed(0)}% of records`,
      icon: <TrendingUp />,
      color: overtimeRatio > 30 ? "warning" : "info",
      progress: overtimeRatio
    },
    // {
    //   title: "Approval Rate",
    //   value: metaData.approvedRecords ? `${metaData.approvedRecords}` : "N/A",
    //   subtitle: metaData.approvedRecords ? `${approvalRate.toFixed(0)}% approved` : "No data",
    //   icon: <EmojiEvents />,
    //   color: approvalRate > 80 ? "success" : "warning",
    //   progress: approvalRate
    // },
    // {
    //   title: "Avg Daily Hours",
    //   value: `${avgDailyHours.toFixed(1)}h`,
    //   subtitle: `${efficiency.toFixed(0)}% efficiency`,
    //   icon: <AccessTime />,
    //   color: efficiency > 100 ? "error" : "primary",
    //   progress: efficiency > 100 ? 100 : efficiency
    // },
    {
      title: "Work Policy",
      value: `${dailyWorkingHours}h day`,
      subtitle: `${dailyWorkingHoursWithoutLunch}h net`,
      icon: <Work />,
      color: "secondary",
      progress: 100
    }
  ];

  return (
    <Card sx={{
      borderRadius: 2,
      boxShadow: theme.shadows[3],
      mb: 1
    }}>
      <CardContent>

        <Divider sx={{ my: 2 }} />

        <Grid container spacing={3}>
          {stats.map((stat, index) => (
            <Grid item xs={12} sm={6} md={4} lg={2} key={index}>
              <Box sx={{ display: 'flex', alignItems: 'center', mb: 1 }}>
                <Avatar sx={{
                //   bgcolor: theme.palette[stat.color].light,
                //   color: theme.palette[stat.color].dark,
                  mr: 2,
                  width: 40,
                  height: 40
                }}>
                  {stat.icon}
                </Avatar>
                <Box>
                  <Typography variant="body2" color="text.secondary">
                    {stat.title}
                  </Typography>
                  <Typography variant="h6">
                    {stat.value} {stat.trend}
                  </Typography>
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
                    backgroundColor: theme.palette.grey[200]
                  }}
                />
              </Tooltip>
            </Grid>
          ))}
        </Grid>

        <Box sx={{ mt: 3, display: 'flex', justifyContent: 'space-between' }}>
          <Chip
            label={`Total Records: ${metaData.totalRecords}`}
            variant="outlined"
            size="small"
          />
          {/* <Chip
            label={`Pending: ${metaData.pendingRecords || 0}`}
            color="warning"
            size="small"
          /> */}
          <Chip
            label={`OT Threshold: ${workPolicies.otHoursPerYear}h/year`}
            color="info"
            size="small"
          />
                      <Chip
              icon={<FreeBreakfast />}
              label={`${workPolicies.lunchHoursPerDay}h lunch`}
              variant="outlined"
            />
        </Box>
      </CardContent>
    </Card>
  );
};

export default InformationHeader;

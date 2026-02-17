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
  Grid,
  Paper,
  Typography,
  LinearProgress,
  TextField,
  MenuItem,
  Select,
  FormControl,
  InputLabel,
  SelectChangeEvent,
  IconButton,
  useTheme,
} from "@mui/material";
import {
  LineChart,
  Line,
  XAxis,
  YAxis,
  CartesianGrid,
  Tooltip,
  ResponsiveContainer,
  BarChart,
  Bar,
  PieChart,
  Pie,
  Cell,
  Legend,
} from "recharts";
import ChevronRightIcon from "@mui/icons-material/ChevronRight";
import ChevronLeftIcon from "@mui/icons-material/ChevronLeft";
import {
  RootState,
  useAppDispatch,
  useAppSelector,
} from "@root/src/slices/store";
import { getRecordingStats } from "@root/src/slices/analyticsSlice/analytics";
import { State } from "@root/src/types/types";
import { useEffect, useMemo, useState } from "react";

const formatDateForInput = (date: Date) => {
  const tzOffsetMs = date.getTimezoneOffset() * 60000;
  return new Date(date.getTime() - tzOffsetMs).toISOString().split("T")[0];
};

const formatForAPI = (dateStr: string) => {
  const [year, month, day] = dateStr.split("-").map(Number);
  return new Date(year, month - 1, day).toISOString();
};

const ITEMS_PER_PAGE = 5;

function Analytics() {
  const theme = useTheme();
  const colors = theme.palette.analytics;
  const dispatch = useAppDispatch();

  const { recordingStats, typeStats, regionalStats, amStats, toStats, state } =
    useAppSelector((state: RootState) => state.analytics);

  const [dateRangeOption, setDateRangeOption] = useState<string>("6M");
  const [endDate, setEndDate] = useState<string>(() =>
    formatDateForInput(new Date()),
  );
  const [startDate, setStartDate] = useState<string>(() => {
    const date = new Date();
    date.setMonth(date.getMonth() - 6);
    return formatDateForInput(date);
  });

  const [meetingTypePage, setMeetingTypePage] = useState(0);
  const [listPage, setListPage] = useState(0);

  const [groupBy, setGroupBy] = useState<"AM" | "TO">("AM");

  const handleRangeChange = (event: SelectChangeEvent) => {
    const option = event.target.value;
    setDateRangeOption(option);

    const end = new Date();
    const start = new Date();

    switch (option) {
      case "1M":
        start.setMonth(end.getMonth() - 1);
        break;
      case "3M":
        start.setMonth(end.getMonth() - 3);
        break;
      case "6M":
        start.setMonth(end.getMonth() - 6);
        break;
      case "1Y":
        start.setFullYear(end.getFullYear() - 1);
        break;
      case "custom":
        return;
      default:
        start.setMonth(end.getMonth() - 6);
    }

    setEndDate(formatDateForInput(end));
    setStartDate(formatDateForInput(start));
  };

  const handleManualDateChange = (type: "start" | "end", value: string) => {
    setDateRangeOption("custom");
    if (type === "start") setStartDate(value);
    else setEndDate(value);
  };

  useEffect(() => {
    if (startDate && endDate) {
      if (new Date(startDate) > new Date(endDate)) return;
      dispatch(
        getRecordingStats({
          startDate: formatForAPI(startDate),
          endDate: formatForAPI(endDate),
        }),
      );
      setMeetingTypePage(0);
      setListPage(0);
    }
  }, [dispatch, startDate, endDate]);

  useEffect(() => {
    setListPage(0);
  }, [groupBy]);

  const lineChartData = useMemo(() => {
    const getMonthName = (monthNum: number) => {
      const date = new Date();
      date.setMonth(monthNum - 1);
      return date.toLocaleString("default", { month: "short" });
    };
    const sortedStats = [...recordingStats].reverse();
    return sortedStats.map((item) => ({
      name: getMonthName(item.month),
      scheduled: item.scheduledCount,
      recorded: item.recordingCount,
    }));
  }, [recordingStats]);

  const barChartData = useMemo(() => {
    return typeStats.map((item) => ({
      name: item.meeting_type,
      value: item.count,
    }));
  }, [typeStats]);

  const totalScheduled = useMemo(() => {
    return recordingStats.reduce((acc, curr) => acc + curr.scheduledCount, 0);
  }, [recordingStats]);

  const paginatedBarData = useMemo(() => {
    const start = meetingTypePage * ITEMS_PER_PAGE;
    return barChartData.slice(start, start + ITEMS_PER_PAGE);
  }, [barChartData, meetingTypePage]);

  const currentListData = useMemo(() => {
    return groupBy === "AM" ? amStats : toStats;
  }, [groupBy, amStats, toStats]);

  const paginatedListData = useMemo(() => {
    const start = listPage * ITEMS_PER_PAGE;
    return currentListData.slice(start, start + ITEMS_PER_PAGE);
  }, [currentListData, listPage]);

  return (
    <Box
      sx={{ p: 2, backgroundColor: "background.default", minHeight: "100vh" }}
    >
      {/* Header & Filters */}
      <Box
        sx={{
          display: "flex",
          justifyContent: "space-between",
          alignItems: "center",
          mb: 1,
          flexWrap: "wrap",
          gap: 0.5,
        }}
      >
        <Typography
          variant="h4"
          sx={{ fontWeight: "bold", color: "text.primary" }}
        >
          Analytics Dashboard
        </Typography>

        <Box sx={{ display: "flex", gap: 0.5, alignItems: "center" }}>
          <FormControl size="small" sx={{ minWidth: 150 }}>
            <InputLabel sx={{ fontWeight: "bold", color: "text.primary" }}>
              Date Range
            </InputLabel>
            <Select
              value={dateRangeOption}
              label="Date Range"
              onChange={handleRangeChange}
              sx={{ fontWeight: "bold", color: "text.primary" }}
            >
              <MenuItem value="1M">Last Month</MenuItem>
              <MenuItem value="3M">Last 3 Months</MenuItem>
              <MenuItem value="6M">Last 6 Months</MenuItem>
              <MenuItem value="1Y">Last Year</MenuItem>
              <MenuItem value="custom">Custom</MenuItem>
            </Select>
          </FormControl>
          <TextField
            label="Start Date"
            type="date"
            size="small"
            value={startDate}
            onChange={(e) => handleManualDateChange("start", e.target.value)}
            InputLabelProps={{
              shrink: true,
              sx: { fontWeight: "bold", color: "text.primary" },
            }}
            InputProps={{ sx: { fontWeight: "bold", color: "text.primary" } }}
          />
          <TextField
            label="End Date"
            type="date"
            size="small"
            value={endDate}
            onChange={(e) => handleManualDateChange("end", e.target.value)}
            InputLabelProps={{
              shrink: true,
              sx: { fontWeight: "bold", color: "text.primary" },
            }}
            InputProps={{ sx: { fontWeight: "bold", color: "text.primary" } }}
          />
        </Box>
      </Box>

      {state === State.loading && <LinearProgress sx={{ mb: 1 }} />}

      <Grid container spacing={2}>
        {/* Line Chart */}
        <Grid item xs={12} md={8}>
          <Paper
            sx={{
              p: 2,
              backgroundColor: colors.cardBg,
              borderRadius: 4,
              height: "100%",
              boxShadow: "0px 4px 20px rgba(0,0,0,0.02)",
            }}
          >
            <Typography variant="h6" sx={{ mb: 1, color: "text.primary" }}>
              Meetings Organised
            </Typography>
            <ResponsiveContainer width="100%" height={220}>
              <LineChart data={lineChartData}>
                <CartesianGrid
                  strokeDasharray="3 3"
                  vertical={false}
                  stroke={colors.gridLines}
                />
                <XAxis
                  dataKey="name"
                  axisLine={false}
                  tickLine={false}
                  tick={{ fill: theme.palette.text.secondary, fontSize: 12 }}
                  dy={10}
                />
                <YAxis
                  axisLine={false}
                  tickLine={false}
                  tick={{ fill: theme.palette.text.secondary, fontSize: 12 }}
                />
                <Tooltip
                  contentStyle={{
                    borderRadius: 8,
                    border: "none",
                    boxShadow: "0 4px 12px rgba(0,0,0,0.1)",
                    backgroundColor: theme.palette.background.paper,
                    color: theme.palette.text.primary,
                  }}
                />
                <Legend
                  iconType="square"
                  align="right"
                  verticalAlign="middle"
                  layout="vertical"
                  wrapperStyle={{ paddingLeft: 20 }}
                />
                <Line
                  type="monotone"
                  dataKey="scheduled"
                  name="Meetings Scheduled"
                  stroke={colors.chartLine1}
                  strokeWidth={3}
                  dot={{ r: 0 }}
                  activeDot={{ r: 6 }}
                />
                <Line
                  type="monotone"
                  dataKey="recorded"
                  name="Meetings Recorded"
                  stroke={colors.chartLine2}
                  strokeWidth={3}
                  dot={{ r: 0 }}
                  activeDot={{ r: 6 }}
                />
              </LineChart>
            </ResponsiveContainer>
          </Paper>
        </Grid>

        {/* Total Meetings Card */}
        <Grid item xs={12} md={4}>
          <Paper
            sx={{
              p: 2,
              borderRadius: 4,
              backgroundColor: colors.cardBg,
              height: "100%",
              display: "flex",
              flexDirection: "column",
              justifyContent: "center",
              alignItems: "center",
              boxShadow: "0px 4px 20px rgba(0,0,0,0.02)",
            }}
          >
            <Typography variant="h6" sx={{ mb: 1, color: "text.primary" }}>
              Total Meetings Scheduled
            </Typography>
            <Typography
              variant="h1"
              sx={{ fontWeight: "bold", color: "#ff7300" }}
            >
              {totalScheduled}
            </Typography>
            <Typography variant="body2" color="text.secondary" sx={{ mb: 1 }}>
              {dateRangeOption !== "custom"
                ? `Last ${dateRangeOption}`
                : "Custom Range"}
            </Typography>
          </Paper>
        </Grid>

        {/* Meeting Types Bar Chart */}
        <Grid item xs={12} md={4}>
          <Paper
            sx={{
              p: 2,
              pb: 0.5,
              borderRadius: 4,
              backgroundColor: colors.cardBg,
              height: "340px",
              display: "flex",
              flexDirection: "column",
              boxShadow: "0px 4px 20px rgba(0,0,0,0.02)",
            }}
          >
            <Typography variant="h6" sx={{ mb: 1, color: "text.primary" }}>
              Meeting Types
            </Typography>
            <Box sx={{ flexGrow: 1, width: "100%", minHeight: 0 }}>
              <ResponsiveContainer width="100%" height="100%">
                <BarChart
                  layout="vertical"
                  data={paginatedBarData}
                  margin={{ top: 5, right: 30, left: 20, bottom: 5 }}
                >
                  <XAxis type="number" hide />
                  <YAxis
                    dataKey="name"
                    type="category"
                    width={100}
                    axisLine={false}
                    tickLine={false}
                    tick={{ fontSize: 11, fill: theme.palette.text.secondary }}
                  />
                  <Tooltip
                    cursor={{ fill: "transparent" }}
                    contentStyle={{
                      backgroundColor: theme.palette.background.paper,
                      color: theme.palette.text.primary,
                      border: "none",
                      borderRadius: 8,
                    }}
                  />
                  <Bar
                    dataKey="value"
                    fill="#ff7300"
                    barSize={15}
                    radius={[0, 10, 10, 0]}
                  />
                </BarChart>
              </ResponsiveContainer>
            </Box>

            {/* Pagination Controls */}
            <Box sx={{ display: "flex", justifyContent: "flex-start", mt: 1 }}>
              <IconButton
                size="small"
                disabled={meetingTypePage === 0}
                onClick={() => setMeetingTypePage((p) => p - 1)}
                aria-label="Previous Page"
              >
                <ChevronLeftIcon />
              </IconButton>
              <IconButton
                size="small"
                disabled={
                  (meetingTypePage + 1) * ITEMS_PER_PAGE >= barChartData.length
                }
                onClick={() => setMeetingTypePage((p) => p + 1)}
                aria-label="Next Page"
              >
                <ChevronRightIcon />
              </IconButton>
            </Box>
          </Paper>
        </Grid>

        {/* Regional Breakdown */}
        <Grid item xs={12} md={4}>
          <Paper
            sx={{
              p: 2,
              borderRadius: 4,
              backgroundColor: colors.cardBg,
              height: "340px",
              display: "flex",
              flexDirection: "column",
              alignItems: "center",
              boxShadow: "0px 4px 20px rgba(0,0,0,0.02)",
            }}
          >
            <Box
              sx={{ position: "relative", width: "100%", height: 200, mb: 1 }}
            >
              <ResponsiveContainer>
                <PieChart>
                  <Pie
                    data={regionalStats as any}
                    innerRadius={40}
                    outerRadius={65}
                    paddingAngle={0}
                    dataKey="value"
                  >
                    {regionalStats.map((entry, index) => (
                      <Cell
                        key={`cell-${index}`}
                        fill={colors.pieColors[index % colors.pieColors.length]}
                      />
                    ))}
                  </Pie>
                  <Tooltip
                    contentStyle={{
                      backgroundColor: theme.palette.background.paper,
                      color: theme.palette.text.primary,
                      border: "none",
                      borderRadius: 8,
                    }}
                  />
                </PieChart>
              </ResponsiveContainer>
            </Box>
            <Typography
              variant="h6"
              sx={{ fontWeight: "bold", mb: 1, color: "text.primary" }}
            >
              Regional Breakdown
            </Typography>

            <Box
              sx={{
                width: "100%",
                px: 1,
                display: "flex",
                flexDirection: "column",
                gap: 0.5,
                overflowY: "auto",
                flexGrow: 1,
              }}
            >
              {regionalStats.map((item, index) => (
                <Box
                  key={item.name}
                  sx={{
                    display: "flex",
                    justifyContent: "space-between",
                    borderBottom: `1px solid ${colors.gridLines}`,
                    pb: 1,
                  }}
                >
                  <Box sx={{ display: "flex", alignItems: "center", gap: 0.5 }}>
                    <Box
                      sx={{
                        width: 6,
                        height: 6,
                        bgcolor:
                          colors.pieColors[index % colors.pieColors.length],
                        borderRadius: "2px",
                      }}
                    />
                    <Typography
                      variant="caption"
                      sx={{ fontWeight: "bold", color: "text.primary" }}
                    >
                      {item.name}
                    </Typography>
                  </Box>
                  <Typography variant="caption" color="text.secondary">
                    {item.value}
                  </Typography>
                </Box>
              ))}
            </Box>
          </Paper>
        </Grid>

        {/* Meetings by AM/TO - UPDATED */}
        <Grid item xs={12} md={4}>
          <Paper
            sx={{
              p: 2,
              pb: 0.5,
              borderRadius: 4,
              backgroundColor: colors.cardBg,
              height: "340px",
              display: "flex",
              flexDirection: "column",
              boxShadow: "0px 4px 20px rgba(0,0,0,0.02)",
            }}
          >
            {/* Header with Dropdown */}
            <Box sx={{ display: "flex", alignItems: "center", mb: 1, gap: 1 }}>
              <Typography variant="h6" sx={{ color: "text.primary" }}>
                Meetings by
              </Typography>
              <Select
                value={groupBy}
                onChange={(e) => setGroupBy(e.target.value as "AM" | "TO")}
                variant="standard"
                disableUnderline
                sx={{
                  color: "#ff7300",
                  fontSize: "1.25rem",
                  fontWeight: "bold",
                  "& .MuiSelect-icon": { color: "#ff7300" },
                  "& .MuiSelect-select": { paddingBottom: 0, paddingTop: 0 },
                }}
              >
                <MenuItem value="AM">AM</MenuItem>
                <MenuItem value="TO">TO</MenuItem>
              </Select>
            </Box>

            <Box
              sx={{
                display: "flex",
                flexDirection: "column",
                gap: 1,
                flexGrow: 1,
                overflowY: "auto",
                overflowX: "hidden",
              }}
            >
              {paginatedListData.map((person, index) => {
                const percentage =
                  totalScheduled > 0
                    ? (person.value / totalScheduled) * 100
                    : 0;
                const displayName = person.name;

                return (
                  <Box key={person.email || index} sx={{ width: "100%" }}>
                    <Box
                      sx={{
                        display: "flex",
                        justifyContent: "space-between",
                        alignItems: "center",
                        mb: 0.5,
                      }}
                    >
                      <Typography
                        variant="body2"
                        sx={{
                          fontWeight: 500,
                          fontSize: "0.85rem",
                          color: "text.primary",
                        }}
                      >
                        {displayName}
                      </Typography>
                      <Typography variant="caption" color="text.secondary">
                        {person.value} ({Math.round(percentage)}%)
                      </Typography>
                    </Box>

                    <LinearProgress
                      variant="determinate"
                      value={percentage}
                      sx={{
                        height: 6,
                        borderRadius: 6,
                        mb: 0.5,
                        backgroundColor: colors.progressBarBg,
                        "& .MuiLinearProgress-bar": {
                          backgroundColor: "#ff7300",
                          borderRadius: 6,
                        },
                      }}
                    />
                  </Box>
                );
              })}
              {paginatedListData.length === 0 && (
                <Typography
                  variant="caption"
                  color="text.secondary"
                  sx={{ mt: 2, textAlign: "center" }}
                >
                  No data available for {groupBy}.
                </Typography>
              )}
            </Box>

            {/* Pagination Controls */}
            <Box
              sx={{
                display: "flex",
                justifyContent: "flex-start",
                mt: "auto",
                pt: 1,
              }}
            >
              <IconButton
                size="small"
                disabled={listPage === 0}
                onClick={() => setListPage((p) => p - 1)}
                aria-label="Previous Page"
              >
                <ChevronLeftIcon />
              </IconButton>
              <IconButton
                size="small"
                disabled={
                  (listPage + 1) * ITEMS_PER_PAGE >= currentListData.length
                }
                onClick={() => setListPage((p) => p + 1)}
                aria-label="Next Page"
              >
                <ChevronRightIcon />
              </IconButton>
            </Box>
          </Paper>
        </Grid>
      </Grid>
    </Box>
  );
}

export default Analytics;

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
  Box, Grid, Paper, Typography, LinearProgress, TextField, MenuItem, Select, 
  FormControl, InputLabel, SelectChangeEvent, IconButton } from "@mui/material";
import {
  LineChart, Line, XAxis, YAxis, CartesianGrid, Tooltip, ResponsiveContainer,
  BarChart, Bar, PieChart, Pie, Cell, Legend } from 'recharts';
import ChevronRightIcon from '@mui/icons-material/ChevronRight';
import ChevronLeftIcon from '@mui/icons-material/ChevronLeft';
import { useAppDispatch, useAppSelector } from "@root/src/slices/store";
import { getRecordingStats } from "@root/src/slices/analyticsSlice/analytics";
import { State } from "@root/src/types/types";
import { useEffect, useMemo, useState } from "react";

// Format Date object to YYYY-MM-DD
const formatDateForInput = (date: Date) => {
  return date.toISOString().split('T')[0];
};

const COLORS = ['#ff7300', '#de6300', '#9e4500', '#632800', '#2e0f00'];
const formatForAPI = (dateStr: string) => {
  return new Date(dateStr).toISOString();
};

const ITEMS_PER_PAGE = 5;

function Analytics() {
  const dispatch = useAppDispatch();
  const { recordingStats, typeStats, regionalStats, amStats, state } = useAppSelector((state) => state.analytics);
  const [dateRangeOption, setDateRangeOption] = useState<string>("6M");
  const [endDate, setEndDate] = useState<string>(() => formatDateForInput(new Date()));
  const [startDate, setStartDate] = useState<string>(() => {
    const d = new Date();
    d.setMonth(d.getMonth() - 6);
    return formatDateForInput(d);
  });
  const [meetingTypePage, setMeetingTypePage] = useState(0);
  const [amPage, setAmPage] = useState(0);
  const handleRangeChange = (event: SelectChangeEvent) => {
    const option = event.target.value;
    setDateRangeOption(option);

    const end = new Date();
    const start = new Date();

    switch (option) {
      case "1M": start.setMonth(end.getMonth() - 1); break;
      case "3M": start.setMonth(end.getMonth() - 3); break;
      case "6M": start.setMonth(end.getMonth() - 6); break;
      case "1Y": start.setFullYear(end.getFullYear() - 1); break;
      case "custom": return;
      default: start.setMonth(end.getMonth() - 6);
    }

    setEndDate(formatDateForInput(end));
    setStartDate(formatDateForInput(start));
  };

  const handleManualDateChange = (type: 'start' | 'end', value: string) => {
    setDateRangeOption("custom");
    if (type === 'start') setStartDate(value);
    else setEndDate(value);
  };

  useEffect(() => {
    if (startDate && endDate) {
      if (new Date(startDate) > new Date(endDate)) return;
      dispatch(getRecordingStats({
        startDate: formatForAPI(startDate),
        endDate: formatForAPI(endDate)
      }));
      setMeetingTypePage(0);
      setAmPage(0);
    }
  }, [dispatch, startDate, endDate]);

  const lineChartData = useMemo(() => {
    const getMonthName = (monthNum: number) => {
      const date = new Date();
      date.setMonth(monthNum - 1);
      return date.toLocaleString('default', { month: 'short' });
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
      value: item.count
    }));
  }, [typeStats]);

  const totalScheduled = useMemo(() => {
    return recordingStats.reduce((acc, curr) => acc + curr.scheduledCount, 0);
  }, [recordingStats]);

  const paginatedBarData = useMemo(() => {
    const start = meetingTypePage * ITEMS_PER_PAGE;
    return barChartData.slice(start, start + ITEMS_PER_PAGE);
  }, [barChartData, meetingTypePage]);

  const paginatedAmData = useMemo(() => {
    const start = amPage * ITEMS_PER_PAGE;
    return amStats.slice(start, start + ITEMS_PER_PAGE);
  }, [amStats, amPage]);

  return (
    <Box sx={{ p: 2, backgroundColor: '#ffffff', minHeight: '100vh' }}>

      {/* Header & Filters */}
      <Box sx={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', mb: 1, flexWrap: 'wrap', gap: 0.5 }}>
        <Typography variant="h4" sx={{ fontWeight: 'bold', color: '#0d1b3e' }}>
          Analytics Dashboard
        </Typography>

        <Box sx={{ display: 'flex', gap: 0.5, alignItems: 'center' }}>
          <FormControl size="small" sx={{ minWidth: 150 }}>
            <InputLabel>Date Range</InputLabel>
            <Select value={dateRangeOption} label="Date Range" onChange={handleRangeChange}>
              <MenuItem value="1M">Last Month</MenuItem>
              <MenuItem value="3M">Last 3 Months</MenuItem>
              <MenuItem value="6M">Last 6 Months</MenuItem>
              <MenuItem value="1Y">Last Year</MenuItem>
              <MenuItem value="custom">Custom</MenuItem>
            </Select>
          </FormControl>
          <TextField label="Start Date" type="date" size="small" value={startDate} onChange={(e) => handleManualDateChange('start', e.target.value)} InputLabelProps={{ shrink: true }} />
          <TextField label="End Date" type="date" size="small" value={endDate} onChange={(e) => handleManualDateChange('end', e.target.value)} InputLabelProps={{ shrink: true }} />
        </Box>
      </Box>

      {state === State.loading && <LinearProgress sx={{ mb: 1 }} />}

      <Grid container spacing={2}>

        {/* Line Chart */}
        <Grid item xs={12} md={8}>
          <Paper sx={{ p: 2, backgroundColor: '#f5f5f5', borderRadius: 4, height: '100%', boxShadow: '0px 4px 20px rgba(0,0,0,0.02)' }}>
            <Typography variant="h6" sx={{ mb: 1, color: '#333' }}>Meetings Organised</Typography>
            <ResponsiveContainer width="100%" height={220}>
              <LineChart data={lineChartData}>
                <CartesianGrid strokeDasharray="3 3" vertical={false} stroke="#eee" />
                <XAxis dataKey="name" axisLine={false} tickLine={false} tick={{ fill: '#888', fontSize: 12 }} dy={10} />
                <YAxis axisLine={false} tickLine={false} tick={{ fill: '#888', fontSize: 12 }} />
                <Tooltip contentStyle={{ borderRadius: 8, border: 'none', boxShadow: '0 4px 12px rgba(0,0,0,0.1)' }} />
                <Legend iconType="square" align="right" verticalAlign="middle" layout="vertical" wrapperStyle={{ paddingLeft: 20 }} />
                <Line type="monotone" dataKey="scheduled" name="Meetings Scheduled" stroke="#ff7300" strokeWidth={3} dot={{ r: 0 }} activeDot={{ r: 6 }} />
                <Line type="monotone" dataKey="recorded" name="Meetings Recorded" stroke="#473f38" strokeWidth={3} dot={{ r: 0 }} activeDot={{ r: 6 }} />
              </LineChart>
            </ResponsiveContainer>
          </Paper>
        </Grid>

        {/* Total Meetings Card */}
        <Grid item xs={12} md={4}>
          <Paper sx={{ p: 2, borderRadius: 4, backgroundColor: '#f5f5f5', height: '100%', display: 'flex', flexDirection: 'column', justifyContent: 'center', alignItems: 'center', boxShadow: '0px 4px 20px rgba(0,0,0,0.02)' }}>
            <Typography variant="h6" sx={{ mb: 1 }}>Total Meetings Scheduled</Typography>
            <Typography variant="h1" sx={{ fontWeight: 'bold', color: '#ff7300' }}>
              {totalScheduled}
            </Typography>
            <Typography variant="body2" color="text.secondary" sx={{ mb: 1 }}>
              {dateRangeOption !== "custom" ? `Last ${dateRangeOption}` : "Custom Range"}
            </Typography>
            <Box sx={{ width: '80%' }}>
              <LinearProgress variant="determinate" value={70} sx={{ height: 15, borderRadius: 5, backgroundColor: '#bec0c2', '& .MuiLinearProgress-bar': { backgroundColor: '#473f38', borderRadius: 5 } }} />
            </Box>
          </Paper>
        </Grid>

        {/* Meeting Types Bar Chart */}
        <Grid item xs={12} md={4}>
          <Paper sx={{ p: 2, pb: 0.5, borderRadius: 4, backgroundColor: '#f5f5f5', height: '340px', display: 'flex', flexDirection: 'column', boxShadow: '0px 4px 20px rgba(0,0,0,0.02)' }}>
            <Typography variant="h6" sx={{ mb: 1 }}>Meeting Types</Typography>
            <Box sx={{ flexGrow: 1, width: '100%', minHeight: 0 }}>
              <ResponsiveContainer width="100%" height="100%">
                <BarChart layout="vertical" data={paginatedBarData} margin={{ top: 5, right: 30, left: 20, bottom: 5 }}>
                  <XAxis type="number" hide />
                  <YAxis dataKey="name" type="category" width={100} axisLine={false} tickLine={false} tick={{ fontSize: 11 }} />
                  <Tooltip cursor={{ fill: 'transparent' }} />
                  <Bar dataKey="value" fill="#ff7300" barSize={15} radius={[0, 10, 10, 0]} />
                </BarChart>
              </ResponsiveContainer>
            </Box>

            {/* Pagination Controls */}
            <Box sx={{ display: 'flex', justifyContent: 'flex-start', mt: 1 }}>
              <IconButton
                size="small"
                disabled={meetingTypePage === 0}
                onClick={() => setMeetingTypePage(p => p - 1)}
              >
                <ChevronLeftIcon />
              </IconButton>
              <IconButton
                size="small"
                disabled={(meetingTypePage + 1) * ITEMS_PER_PAGE >= barChartData.length}
                onClick={() => setMeetingTypePage(p => p + 1)}
              >
                <ChevronRightIcon />
              </IconButton>
            </Box>
          </Paper>
        </Grid>

        {/* Regional Breakdown */}
        <Grid item xs={12} md={4}>
          <Paper sx={{ p: 2, borderRadius: 4, backgroundColor: '#f5f5f5', height: '340px', display: 'flex', flexDirection: 'column', alignItems: 'center', boxShadow: '0px 4px 20px rgba(0,0,0,0.02)' }}>
            <Box sx={{ position: 'relative', width: '100%', height: 200, mb: 1 }}>
              <ResponsiveContainer>
                <PieChart>
                  <Pie data={regionalStats as any} innerRadius={40} outerRadius={65} paddingAngle={0} dataKey="value">
                    {regionalStats.map((entry, index) => (
                      <Cell key={`cell-${index}`} fill={COLORS[index % COLORS.length]} />
                    ))}
                  </Pie>
                  <Tooltip />
                </PieChart>
              </ResponsiveContainer>
            </Box>
            <Typography variant="h6" sx={{ fontWeight: 'bold', mb: 1 }}>Regional Breakdown</Typography>

            <Box sx={{ width: '100%', px: 1, display: 'flex', flexDirection: 'column', gap: 0.5, overflowY: 'auto', flexGrow: 1 }}>
              {regionalStats.map((item, index) => (
                <Box key={item.name} sx={{ display: 'flex', justifyContent: 'space-between', borderBottom: '1px solid #eee', pb: 1 }}>
                  <Box sx={{ display: 'flex', alignItems: 'center', gap: 0.5 }}>
                    <Box sx={{ width: 6, height: 6, bgcolor: COLORS[index % COLORS.length], borderRadius: '2px' }} />
                    <Typography variant="caption" sx={{ fontWeight: 'bold' }}>{item.name}</Typography>
                  </Box>
                  <Typography variant="caption">{item.value}</Typography>
                </Box>
              ))}
            </Box>
          </Paper>
        </Grid>

        {/* Meetings by AM */}
        <Grid item xs={12} md={4}>
          <Paper sx={{ p: 2, pb: 0.5, borderRadius: 4, backgroundColor: '#f5f5f5', height: '340px', display: 'flex', flexDirection: 'column', boxShadow: '0px 4px 20px rgba(0,0,0,0.02)' }}>
            <Typography variant="h6" sx={{ mb: 1 }}>Meetings by AM</Typography>

            <Box sx={{ display: 'flex', flexDirection: 'column', gap: 0.5, flexGrow: 1, overflow: 'hidden' }}>
              {paginatedAmData.map((am) => {
                const percentage = totalScheduled > 0 ? (am.value / totalScheduled) * 100 : 0;
                return (
                  <Box key={am.email}>
                    <Box sx={{ display: 'flex', justifyContent: 'space-between', mb: 1 }}>
                      <Typography variant="body2" sx={{ fontWeight: 500, fontSize: '0.85rem' }}>{am.name}</Typography>
                      <Typography variant="caption" color="text.secondary">
                        {am.value} ({Math.round(percentage)}%)
                      </Typography>
                    </Box>
                    <LinearProgress
                      variant="determinate"
                      value={percentage}
                      sx={{ height: 6, borderRadius: 6, backgroundColor: '#bec0c2', '& .MuiLinearProgress-bar': { backgroundColor: '#ff7300', borderRadius: 6 } }}
                    />
                  </Box>
                );
              })}
              {paginatedAmData.length === 0 && <Typography variant="caption" color="text.secondary">No data available.</Typography>}
            </Box>

            {/* Pagination Controls */}
            <Box sx={{ display: 'flex', justifyContent: 'flex-start', mt: 1 }}>
              <IconButton
                size="small"
                disabled={amPage === 0}
                onClick={() => setAmPage(p => p - 1)}
              >
                <ChevronLeftIcon />
              </IconButton>
              <IconButton
                size="small"
                disabled={(amPage + 1) * ITEMS_PER_PAGE >= amStats.length}
                onClick={() => setAmPage(p => p + 1)}
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
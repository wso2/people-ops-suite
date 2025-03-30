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
import { useState } from "react";
import PersonIcon from "@mui/icons-material/Person";
import { LocalizationProvider } from "@mui/x-date-pickers";
import AccessTimeIcon from "@mui/icons-material/AccessTime";
import FilterComponent from "@component/common/FilterModal";
import LunchDiningIcon from "@mui/icons-material/LunchDining";
import { useAppDispatch, useAppSelector } from "@slices/store";
import CalendarMonthIcon from "@mui/icons-material/CalendarMonth";
import { fetchTimesheetRecords } from "@slices/recordSlice/record";
import { AdapterDateFns } from "@mui/x-date-pickers/AdapterDateFns";
import { useConfirmationModalContext } from "@context/DialogContext";
import { Box, Chip, Stack, Paper, Button, Tooltip, useTheme, Typography } from "@mui/material";
import { Filter, State, statusChipStyles, TimesheetRecord, TimesheetStatus } from "@utils/types";
import { DataGrid, GridToolbar, GridFilterModel, GridLogicOperator, GridRenderCellParams } from "@mui/x-data-grid";

const ReportView = () => {
  const theme = useTheme();
  const dispatch = useAppDispatch();
  const dialogContext = useConfirmationModalContext();
  const recordLoadingState = useAppSelector((state) => state.timesheetRecord.retrievingState);
  const records = useAppSelector((state) => state.timesheetRecord.timesheetData?.timesheetRecords || []);
  const totalRecordCount = useAppSelector((state) => state.timesheetRecord.timesheetData?.totalRecordCount || 0);
  const [filters, setFilters] = useState<Filter[]>([]);
  const availableFields = [
    { field: "employeeEmail", label: "Employee Email", type: "text" },
    { field: "rangeStart", label: "Start Date", type: "date" },
    { field: "rangeEnd", label: "End Date", type: "date" },
  ];
  const [filterModel, setFilterModel] = useState<GridFilterModel>({
    items: [],
    logicOperator: GridLogicOperator.And,
    quickFilterValues: [],
  });

  const columns = [
    {
      field: "employeeEmail",
      headerName: "Employee",
      flex: 1,
      renderCell: (params: GridRenderCellParams<TimesheetRecord>) => (
        <Stack direction="row" alignItems="center" gap={1}>
          <PersonIcon fontSize="small" color="action" />
          <Typography variant="body2">{params.row.employeeEmail}</Typography>
        </Stack>
      ),
    },
    {
      field: "recordDate",
      headerName: "Date",
      flex: 1,
      renderCell: (params: GridRenderCellParams<TimesheetRecord>) => (
        <Stack direction="row" alignItems="center" gap={1}>
          <CalendarMonthIcon fontSize="small" color="action" />
          <Typography variant="body2">{params.row.recordDate}</Typography>
        </Stack>
      ),
    },
    {
      field: "clockInTime",
      headerName: "Clock In",
      flex: 1,
      renderCell: (params: GridRenderCellParams<TimesheetRecord>) => (
        <Stack direction="row" alignItems="center" gap={1}>
          <AccessTimeIcon fontSize="small" color="action" />
          <Typography variant="body2">{params.row.clockInTime}</Typography>
        </Stack>
      ),
    },
    {
      field: "clockOutTime",
      headerName: "Clock Out",
      flex: 1,
      renderCell: (params: GridRenderCellParams<TimesheetRecord>) => (
        <Stack direction="row" alignItems="center" gap={1}>
          <AccessTimeIcon fontSize="small" color="action" />
          <Typography variant="body2">{params.row.clockOutTime}</Typography>
        </Stack>
      ),
    },
    {
      field: "isLunchIncluded",
      headerName: "Lunch",
      flex: 0.5,
      renderCell: (params: GridRenderCellParams<TimesheetRecord>) => (
        <Stack direction="row" alignItems="center" gap={1}>
          <LunchDiningIcon fontSize="small" color={params.row.isLunchIncluded ? "success" : "error"} />
          <Typography variant="body2">{params.row.isLunchIncluded ? "Yes" : "No"}</Typography>
        </Stack>
      ),
    },
    {
      field: "overtimeDuration",
      headerName: "Overtime",
      flex: 2,
      renderCell: (params: GridRenderCellParams<TimesheetRecord>) => (
        <Box>
          {params.row.overtimeDuration > 0 && (
            <Chip
              label={`${params.row.overtimeDuration}h`}
              color="primary"
              size="small"
              sx={{ mr: 2, width: "50px" }}
              variant="outlined"
            />
          )}
          {params.row.overtimeDuration > 0 && (
            <Tooltip title={params.row.overtimeReason}>
              <Typography variant="caption" color="text.secondary" noWrap>
                {params.row.overtimeReason}
              </Typography>
            </Tooltip>
          )}
        </Box>
      ),
    },
    {
      field: "recordStatus",
      headerName: "Status",
      flex: 1,
      renderCell: (params: GridRenderCellParams<TimesheetRecord>) => (
        <Chip
          icon={statusChipStyles[params.row.overtimeStatus as TimesheetStatus].icon}
          label={params.row.overtimeStatus}
          color={
            statusChipStyles[params.row.overtimeStatus as TimesheetStatus].color as "success" | "error" | "warning"
          }
          variant="outlined"
          size="small"
          sx={{ width: "110px" }}
        />
      ),
    },
  ];

  const fetchData = async () => {
    const filterParams = filters.reduce((acc, filter) => {
      return { ...acc, [filter.field]: filter.value };
    }, {});

    dispatch(
      fetchTimesheetRecords({
        ...filterParams,
      })
    );
  };

  const handleResetFilters = () => {
    setFilters([]);
  };

  return (
    <LocalizationProvider dateAdapter={AdapterDateFns}>
      <Box sx={{ width: "100%", height: "99%", overflow: "auto", p: 1 }}>
        <Stack direction="row" justifyContent="space-end" alignItems="right" mb={1} spacing={1}>
          <FilterComponent
            availableFields={availableFields}
            filters={filters}
            setFilters={setFilters}
            onApply={fetchData}
            onReset={handleResetFilters}
          />
        </Stack>

        <Paper
          elevation={0}
          sx={{
            height: "95%",
            width: "100%",
            borderRadius: 2,
            border: "1px solid",
            borderColor: "divider",
            overflow: "auto",
          }}
        >
          {records && (
            <DataGrid
              pagination
              rows={records}
              columns={columns}
              disableDensitySelector
              paginationMode="server"
              rowCount={totalRecordCount}
              disableRowSelectionOnClick
              loading={recordLoadingState === State.loading}
              getRowId={(row) => row.recordId}
              filterModel={filterModel}
              onFilterModelChange={setFilterModel}
              slots={{ toolbar: GridToolbar }}
              slotProps={{
                toolbar: {
                  showQuickFilter: true,
                  quickFilterProps: { debounceMs: 500 },
                },
              }}
              sx={{
                border: "none",
                "& .MuiDataGrid-columnHeaders": {
                  backgroundColor: theme.palette.background.paper,
                  borderBottom: `1px solid ${theme.palette.divider}`,
                },
                "& .MuiDataGrid-cell": {
                  borderBottom: `1px solid ${theme.palette.divider}`,
                },
                "& .MuiDataGrid-virtualScroller": {
                  backgroundColor: theme.palette.background.default,
                },
                "& .MuiDataGrid-footerContainer": {
                  borderTop: `1px solid ${theme.palette.divider}`,
                  backgroundColor: theme.palette.background.paper,
                },
                "& .MuiDataGrid-row": {
                  "&:hover": {
                    backgroundColor: theme.palette.action.hover,
                  },
                  "&.Mui-selected": {
                    backgroundColor: theme.palette.action.selected,
                    "&:hover": {
                      backgroundColor: theme.palette.action.selected,
                    },
                  },
                },
                overflow: "auto",
                height: "100%",
                width: "100%",
              }}
            />
          )}
        </Paper>
      </Box>
    </LocalizationProvider>
  );
};
export default ReportView;

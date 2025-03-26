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

import { format, parseISO } from "date-fns";
import { SetStateAction, useEffect, useState } from "react";
import AddIcon from "@mui/icons-material/Add";
import EditIcon from "@mui/icons-material/Edit";
import CancelIcon from "@mui/icons-material/Cancel";
import DeleteIcon from "@mui/icons-material/Delete";
import PendingIcon from "@mui/icons-material/Pending";
import { LocalizationProvider } from "@mui/x-date-pickers";
import AccessTimeIcon from "@mui/icons-material/AccessTime";
import LunchDiningIcon from "@mui/icons-material/LunchDining";
import CheckCircleIcon from "@mui/icons-material/CheckCircle";
import { useAppDispatch, useAppSelector } from "@slices/store";
import SubmitRecordModal from "../components/SubmitRecordModal";
import { fetchTimesheetRecords } from "@slices/recordSlice/record";
import { AdapterDateFns } from "@mui/x-date-pickers/AdapterDateFns";
import { CustomModal } from "@component/common/CustomComponentModal";
import { State, TimesheetRecord, TimeSheetStatus } from "@utils/types";
import { DataGrid, GridPaginationModel, GridRenderCellParams } from "@mui/x-data-grid";
import { Box, Typography, Paper, Chip, IconButton, Button, Stack, useTheme, Tooltip } from "@mui/material";

const statusChipStyles = {
  [TimeSheetStatus.APPROVED]: {
    icon: <CheckCircleIcon fontSize="small" />,
    color: "success",
  },
  [TimeSheetStatus.PENDING]: {
    icon: <PendingIcon fontSize="small" />,
    color: "warning",
  },
  [TimeSheetStatus.REJECTED]: {
    icon: <CancelIcon fontSize="small" />,
    color: "error",
  },
};

const TimesheetDataGrid = () => {
  const theme = useTheme();
  const [openDialog, setOpenDialog] = useState(false);
  const handleOpenDialog = () => setOpenDialog(true);
  const handleCloseDialog = () => setOpenDialog(false);
  const dispatch = useAppDispatch();

  const formatTime = (timeString: string) => {
    try {
      if (!timeString) return "N/A";
      if (timeString.includes("T")) {
        return format(parseISO(timeString), "hh:mm a");
      }
      return timeString;
    } catch {
      return timeString;
    }
  };

  const columns = [
    {
      field: "recordDate",
      headerName: "Date",
      flex: 1,
      valueGetter: (params: { row: TimesheetRecord }) => format(parseISO(params.row.recordDate), "MMM dd, yyyy"),
    },
    {
      field: "clockInTime",
      headerName: "Clock In",
      flex: 1,
      renderCell: (params: GridRenderCellParams<TimesheetRecord>) => (
        <Stack direction="row" alignItems="center" gap={1}>
          <AccessTimeIcon fontSize="small" color="action" />
          <Typography variant="body2">{formatTime(params.row.clockInTime)}</Typography>
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
          <Typography variant="body2">{formatTime(params.row.clockOutTime)}</Typography>
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
            <Chip label={`${params.row.overtimeDuration}h`} color="primary" size="small" sx={{ mr: 2 }} />
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
          icon={statusChipStyles[params.row.overtimeStatus as TimeSheetStatus].icon}
          label={params.row.overtimeStatus}
          color={
            statusChipStyles[params.row.overtimeStatus as TimeSheetStatus].color as "success" | "error" | "warning"
          }
          variant="outlined"
          size="small"
        />
      ),
    },
    {
      field: "actions",
      headerName: "Actions",
      width: 120,
      renderCell: (params: GridRenderCellParams<TimesheetRecord>) => (
        <Stack direction="row">
          <Tooltip title="Edit">
            <IconButton size="small" disabled={params.row.overtimeStatus === TimeSheetStatus.APPROVED}>
              <EditIcon fontSize="small" />
            </IconButton>
          </Tooltip>
          <Tooltip title="Delete">
            <IconButton size="small" disabled={params.row.overtimeStatus === TimeSheetStatus.APPROVED}>
              <DeleteIcon fontSize="small" />
            </IconButton>
          </Tooltip>
        </Stack>
      ),
    },
  ];

  const userEmail = useAppSelector((state) => state.auth.userInfo?.email);
  const leadEmail = useAppSelector((state) => state.auth.userInfo?.leadEmail);
  const recordLoadingState = useAppSelector((state) => state.timesheetRecord.retrievingState);
  const records = useAppSelector((state) => state.timesheetRecord.timesheetData?.timesheetRecords || []);
  const totalRecordCount = useAppSelector(
    (state) => state.timesheetRecord.timesheetData?.overtimeInfo?.totalRecords || 0
  );

  const [paginationModel, setPaginationModel] = useState<GridPaginationModel>({
    page: 0,
    pageSize: 5,
  });

  const fetchData = async () => {
    if (!userEmail) return;

    dispatch(
      fetchTimesheetRecords({
        employeeEmail: userEmail,
        // status: TimeSheetStatus.APPROVED,
        limit: paginationModel.pageSize,
        offset: paginationModel.page * paginationModel.pageSize,
        rangeStart: "2025-01-01",
        rangeEnd: "2025-03-25",
        leadEmail: leadEmail,
      })
    );
  };

  useEffect(() => {
    if (!userEmail) return;
    fetchData();
  }, [paginationModel]);

  return (
    <LocalizationProvider dateAdapter={AdapterDateFns}>
      <Paper sx={{ width: "100%", height: "100%", p: 3, overflow: "auto" }}>
        <Stack direction="row" justifyContent="space-between" alignItems="center" mb={3}>
          <Typography variant="h5" fontWeight="bold" color="text.primary">
            Timesheet Entries
          </Typography>
          <Button
            variant="contained"
            startIcon={<AddIcon />}
            onClick={handleOpenDialog}
            sx={{
              boxShadow: "none",
              "&:hover": {
                boxShadow: "none",
              },
            }}
          >
            New Entry
          </Button>
        </Stack>
        <Paper
          elevation={0}
          sx={{
            height: "calc(70vh - 72px)",
            width: "100%",
            borderRadius: 2,
            border: "1px solid",
            borderColor: "divider",
            overflow: "hidden",
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
              paginationModel={paginationModel}
              onPaginationModelChange={setPaginationModel}
              loading={recordLoadingState === State.loading}
              getRowId={(row) => row.recordId}
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

        <CustomModal open={openDialog} onClose={handleCloseDialog}>
          <SubmitRecordModal onClose={handleCloseDialog} />
        </CustomModal>
      </Paper>
    </LocalizationProvider>
  );
};

export default TimesheetDataGrid;

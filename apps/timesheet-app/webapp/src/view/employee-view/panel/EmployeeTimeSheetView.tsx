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
import {
  Box,
  Chip,
  Grid,
  Stack,
  Paper,
  Dialog,
  Button,
  Tooltip,
  useTheme,
  TextField,
  Typography,
  IconButton,
  DialogTitle,
  DialogActions,
  DialogContent,
  InputAdornment,
  FormControlLabel,
  Switch,
} from "@mui/material";
import {
  DataGrid,
  GridToolbar,
  GridFilterModel,
  GridLogicOperator,
  GridPaginationModel,
  GridRenderCellParams,
} from "@mui/x-data-grid";
import { useEffect, useState } from "react";
import AddIcon from "@mui/icons-material/Add";
import EditIcon from "@mui/icons-material/Edit";
import CancelIcon from "@mui/icons-material/Cancel";
import PendingIcon from "@mui/icons-material/Pending";
import AccessTimeIcon from "@mui/icons-material/AccessTime";
import FilterComponent from "@component/common/FilterModal";
import LunchDiningIcon from "@mui/icons-material/LunchDining";
import CheckCircleIcon from "@mui/icons-material/CheckCircle";
import { useAppDispatch, useAppSelector } from "@slices/store";
import SubmitRecordModal from "../components/SubmitRecordModal";
import CalendarMonthIcon from "@mui/icons-material/CalendarMonth";
import { fetchTimesheetRecords } from "@slices/recordSlice/record";
import InformationHeader from "@component/common/InformationHeader";
import { AdapterDateFns } from "@mui/x-date-pickers/AdapterDateFns";
import { CustomModal } from "@component/common/CustomComponentModal";
import { State, TimesheetRecord, TimesheetStatus } from "@utils/types";
import { differenceInMinutes, format, isWeekend, parseISO } from "date-fns";
import { DatePicker, LocalizationProvider, TimePicker } from "@mui/x-date-pickers";

const statusChipStyles = {
  [TimesheetStatus.APPROVED]: {
    icon: <CheckCircleIcon fontSize="small" />,
    color: "success",
  },
  [TimesheetStatus.PENDING]: {
    icon: <PendingIcon fontSize="small" />,
    color: "warning",
  },
  [TimesheetStatus.REJECTED]: {
    icon: <CancelIcon fontSize="small" />,
    color: "error",
  },
};

interface Filter {
  id: string;
  field: string;
  operator: string;
  value: any;
}

const TimesheetDataGrid = () => {
  const theme = useTheme();
  const dispatch = useAppDispatch();
  const handleOpenDialog = () => setOpenDialog(true);
  const [openDialog, setOpenDialog] = useState(false);
  const handleCloseDialog = () => setOpenDialog(false);
  const userEmail = useAppSelector((state) => state.auth.userInfo?.email);
  const leadEmail = useAppSelector((state) => state.auth.userInfo?.leadEmail);
  const [errors, setErrors] = useState<Partial<Record<keyof TimesheetRecord, string>>>({});
  const recordLoadingState = useAppSelector((state) => state.timesheetRecord.retrievingState);
  const records = useAppSelector((state) => state.timesheetRecord.timesheetData?.timesheetRecords || []);
  const totalRecordCount = useAppSelector((state) => state.timesheetRecord.timesheetData?.totalRecordCount || 0);
  const timesheetInfo = useAppSelector((state) => state.timesheetRecord.timesheetData?.timesheetInfo);
  const workPolicies = useAppSelector((state) => state.user.userInfo?.workPolicies);
  const [paginationModel, setPaginationModel] = useState<GridPaginationModel>({
    page: 0,
    pageSize: 5,
  });
  const [editDialogOpen, setEditDialogOpen] = useState(false);
  const [editingEntry, setEditingEntry] = useState<any | null>(null);
  const [filters, setFilters] = useState<Filter[]>([]);

  const columns = [
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
          icon={statusChipStyles[params.row.overtimeStatus as TimesheetStatus].icon}
          label={params.row.overtimeStatus}
          color={
            statusChipStyles[params.row.overtimeStatus as TimesheetStatus].color as "success" | "error" | "warning"
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
            <span>
              <IconButton
                size="small"
                color="primary"
                onClick={() => openEditDialog(params.row)}
                sx={{ mr: 1 }}
                disabled={params.row.overtimeStatus === TimesheetStatus.APPROVED}
              >
                <EditIcon fontSize="small" />
              </IconButton>
            </span>
          </Tooltip>
        </Stack>
      ),
    },
  ];

  const availableFields = [
    { field: "status", label: "Status", type: "select", options: Object.values(TimesheetStatus) },
    { field: "rangeStart", label: "Start Date", type: "date" },
    { field: "rangeEnd", label: "End Date", type: "date" },
  ];

  useEffect(() => {
    if (!userEmail) return;
    fetchData();
  }, [paginationModel]);

  const [filterModel, setFilterModel] = useState<GridFilterModel>({
    items: [],
    logicOperator: GridLogicOperator.And,
    quickFilterValues: [],
  });

  const fetchData = async () => {
    if (!userEmail) return;

    const filterParams = filters.reduce((acc, filter) => {
      return { ...acc, [filter.field]: filter.value };
    }, {});

    dispatch(
      fetchTimesheetRecords({
        employeeEmail: userEmail,
        limit: paginationModel.pageSize,
        offset: paginationModel.page * paginationModel.pageSize,
        ...filterParams,
      })
    );
  };

  const fetchDefaultData = async () => {
    if (!userEmail) return;
    dispatch(
      fetchTimesheetRecords({
        employeeEmail: userEmail,
        limit: paginationModel.pageSize,
        offset: paginationModel.page * paginationModel.pageSize,
        leadEmail: leadEmail,
      })
    );
  };

  const handleResetFilters = () => {
    fetchDefaultData();
    setFilters([]);
  };

  const handleEditFieldChange = (field: keyof TimesheetRecord, value: any) => {
    if (editingEntry) {
      const updatedEntry = {
        ...editingEntry,
        [field]: value,
      };

      if (["recordDate", "clockInTime", "clockOutTime", "isLunchIncluded"].includes(field)) {
        setEditingEntry(calculateOvertime(updatedEntry));
      } else {
        setEditingEntry(updatedEntry);
      }
    }
  };

  const calculateOvertime = (entry: TimesheetRecord): TimesheetRecord => {
    if (entry.clockInTime && entry.clockOutTime && entry.recordDate) {
      const totalMinutes = differenceInMinutes(entry.clockOutTime, entry.clockInTime);
      const lunchBreakMinutes = entry.isLunchIncluded ? 60 : 0;
      const workMinutes = Math.max(0, totalMinutes - lunchBreakMinutes);

      let overtimeMinutes = 0;
      if (isWeekend(entry.recordDate)) {
        overtimeMinutes = workMinutes;
      } else {
        // overtimeMinutes = Math.max(0, workMinutes - regularWorkMinutes);
      }

      const overtimeDuration = parseFloat((overtimeMinutes / 60).toFixed(2));

      const overtimeReason =
        overtimeDuration > 0 ? entry.overtimeReason || (isWeekend(entry.recordDate) ? "Weekend work" : "") : "";

      return {
        ...entry,
        overtimeDuration,
        overtimeReason,
      };
    }
    return entry;
  };

  const openEditDialog = (entry: TimesheetRecord) => {
    setEditingEntry({
      ...entry,
      recordDate: parseISO(entry.recordDate.toString()),
      clockInTime: parseISO(`1970-01-01T${entry.clockInTime}`),
      clockOutTime: parseISO(`1970-01-01T${entry.clockOutTime}`),
    });
    setEditDialogOpen(true);
  };

  const handleSaveEditedEntry = async () => {
    if (!editingEntry) return;

    const newErrors: Partial<Record<keyof TimesheetRecord, string>> = {};

    if (!editingEntry.recordDate) {
      newErrors.recordDate = "Date is required";
    }

    if (!editingEntry.clockInTime) {
      newErrors.clockInTime = "Clock in time is required";
    }

    if (!editingEntry.clockOutTime) {
      newErrors.clockOutTime = "Clock out time is required";
    }

    if (editingEntry.clockInTime && editingEntry.clockOutTime && editingEntry.clockOutTime < editingEntry.clockInTime) {
      newErrors.clockOutTime = "Clock out time must be after clock in time";
    }

    if (editingEntry.overtimeDuration > 0 && !editingEntry.overtimeReason) {
      newErrors.overtimeReason = "Overtime reason is required when there is overtime";
    }

    setErrors(newErrors);

    if (Object.keys(newErrors).length > 0) {
      return;
    }

    try {
      const formattedEntry = {
        ...editingEntry,
        recordDate: format(editingEntry.recordDate, "yyyy-MM-dd"),
        clockInTime: format(editingEntry.clockInTime, "HH:mm:ss"),
        clockOutTime: format(editingEntry.clockOutTime, "HH:mm:ss"),
      };

      console.log("formatted entry", formattedEntry)

      //   await dispatch(updateTimesheetRecord(formattedEntry)).unwrap();
      setEditDialogOpen(false);
      setEditingEntry(null);
      setErrors({});
      fetchData(); // Refresh the data after update
    } catch (error) {
      console.error("Failed to update record:", error);
    }
  };

  return (
    <LocalizationProvider dateAdapter={AdapterDateFns}>
      <Box sx={{ width: "100%", height: "99%", overflow: "auto", p: 1, pr: 1 }}>
        {timesheetInfo && workPolicies && (
          <Box sx={{ width: "100%", height: "auto" }}>
            <InformationHeader timesheetInfo={timesheetInfo} workPolicies={workPolicies} />
          </Box>
        )}

        <Stack direction="row" justifyContent="space-end" alignItems="right" mb={1} spacing={1}>
          <FilterComponent
            availableFields={availableFields}
            filters={filters}
            setFilters={setFilters}
            onApply={fetchData}
            onReset={handleResetFilters}
          />

          <Button
            variant="contained"
            startIcon={<AddIcon />}
            onClick={handleOpenDialog}
            sx={{
              boxShadow: "none",
              "&:hover": { boxShadow: "none" },
            }}
          >
            ADD NEW ENTRIES
          </Button>
        </Stack>
        <Paper
          elevation={0}
          sx={{
            height: "60%",
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
              paginationModel={paginationModel}
              pageSizeOptions={[5]}
              onPaginationModelChange={setPaginationModel}
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

        <CustomModal open={openDialog} onClose={handleCloseDialog}>
          <SubmitRecordModal onClose={handleCloseDialog} regularWorkHoursPerDay={workPolicies?.workingHoursPerDay} />
        </CustomModal>

        <Dialog open={editDialogOpen} onClose={() => setEditDialogOpen(false)} maxWidth="md" fullWidth>
          <DialogTitle>Edit Time Entry</DialogTitle>
          <DialogContent>
            {editingEntry && (
              <Grid container spacing={2} sx={{ mt: 1 }}>
                <Grid item xs={12} md={6}>
                  <DatePicker
                    label="Date"
                    value={editingEntry.recordDate}
                    onChange={(newDate) => handleEditFieldChange("recordDate", newDate)}
                    slotProps={{
                      textField: {
                        fullWidth: true,
                        variant: "outlined",
                        error: !!errors.recordDate,
                        helperText: errors.recordDate,
                      },
                    }}
                  />
                </Grid>
                <Grid item xs={12} md={6}>
                  <FormControlLabel
                    control={
                      <Switch
                        checked={editingEntry.isLunchIncluded}
                        onChange={(e) => handleEditFieldChange("isLunchIncluded", e.target.checked)}
                        name="isLunchIncluded"
                        color="primary"
                      />
                    }
                    label="Lunch Break Taken"
                  />
                </Grid>
                <Grid item xs={12} md={6}>
                  <TimePicker
                    label="Clock In"
                    value={editingEntry.clockInTime}
                    onChange={(newTime) => handleEditFieldChange("clockInTime", newTime)}
                    slotProps={{
                      textField: {
                        fullWidth: true,
                        variant: "outlined",
                        error: !!errors.clockInTime,
                        helperText: errors.clockInTime,
                      },
                    }}
                  />
                </Grid>
                <Grid item xs={12} md={6}>
                  <TimePicker
                    label="Clock Out"
                    value={editingEntry.clockOutTime}
                    onChange={(newTime) => handleEditFieldChange("clockOutTime", newTime)}
                    slotProps={{
                      textField: {
                        fullWidth: true,
                        variant: "outlined",
                        error: !!errors.clockOutTime,
                        helperText: errors.clockOutTime,
                      },
                    }}
                  />
                </Grid>
                {editingEntry.overtimeDuration > 0 && (
                  <Grid item xs={12}>
                    <TextField
                      label="Overtime Reason"
                      value={editingEntry.overtimeReason}
                      onChange={(e) => handleEditFieldChange("overtimeReason", e.target.value)}
                      error={!!errors.overtimeReason}
                      helperText={errors.overtimeReason}
                      variant="outlined"
                      fullWidth
                      multiline
                      rows={3}
                      required={editingEntry.overtimeDuration > 0}
                      InputProps={{
                        startAdornment: editingEntry.overtimeDuration > 0 && (
                          <InputAdornment position="start">
                            <Chip
                              label={`OT: ${editingEntry.overtimeDuration.toFixed(2)} hrs`}
                              color="primary"
                              size="small"
                            />
                          </InputAdornment>
                        ),
                      }}
                    />
                  </Grid>
                )}
              </Grid>
            )}
          </DialogContent>
          <DialogActions>
            <Button onClick={() => setEditDialogOpen(false)} color="secondary">
              Cancel
            </Button>
            <Button onClick={handleSaveEditedEntry} color="primary">
              Save Changes
            </Button>
          </DialogActions>
        </Dialog>
      </Box>
    </LocalizationProvider>
  );
};
export default TimesheetDataGrid;

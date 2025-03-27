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
  Stack,
  Paper,
  Button,
  Tooltip,
  useTheme,
  MenuItem,
  TextField,
  Typography,
  IconButton,
} from "@mui/material";
import {
  DataGrid,
  GridToolbar,
  GridFilterModel,
  GridLogicOperator,
  GridPaginationModel,
  GridRenderCellParams,
} from "@mui/x-data-grid";
import { format, parseISO } from "date-fns";
import { useEffect, useState } from "react";
import AddIcon from "@mui/icons-material/Add";
import EditIcon from "@mui/icons-material/Edit";
import TuneIcon from "@mui/icons-material/Tune";
import CloseIcon from "@mui/icons-material/Close";
import CancelIcon from "@mui/icons-material/Cancel";
import DeleteIcon from "@mui/icons-material/Delete";
import PendingIcon from "@mui/icons-material/Pending";
import AccessTimeIcon from "@mui/icons-material/AccessTime";
import LunchDiningIcon from "@mui/icons-material/LunchDining";
import CheckCircleIcon from "@mui/icons-material/CheckCircle";
import { useAppDispatch, useAppSelector } from "@slices/store";
import SubmitRecordModal from "../components/SubmitRecordModal";
import { fetchTimesheetRecords } from "@slices/recordSlice/record";
import { AdapterDateFns } from "@mui/x-date-pickers/AdapterDateFns";
import { CustomModal } from "@component/common/CustomComponentModal";
import { State, TimesheetRecord, TimesheetStatus } from "@utils/types";
import { DatePicker, LocalizationProvider } from "@mui/x-date-pickers";

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
  const [openDialog, setOpenDialog] = useState(false);
  const handleOpenDialog = () => setOpenDialog(true);
  const handleCloseDialog = () => setOpenDialog(false);
  const userEmail = useAppSelector((state) => state.auth.userInfo?.email);
  const leadEmail = useAppSelector((state) => state.auth.userInfo?.leadEmail);
  const recordLoadingState = useAppSelector((state) => state.timesheetRecord.retrievingState);
  const records = useAppSelector((state) => state.timesheetRecord.timesheetData?.timesheetRecords || []);
  const totalRecordCount = useAppSelector(
    (state) => state.timesheetRecord.timesheetData?.metaData?.totalRecords || 0
  );
  const [paginationModel, setPaginationModel] = useState<GridPaginationModel>({
    page: 0,
    pageSize: 5,
  });

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
            <IconButton size="small" disabled={params.row.overtimeStatus === TimesheetStatus.APPROVED}>
              <EditIcon fontSize="small" />
            </IconButton>
          </Tooltip>
          <Tooltip title="Delete">
            <IconButton size="small" disabled={params.row.overtimeStatus === TimesheetStatus.APPROVED}>
              <DeleteIcon fontSize="small" />
            </IconButton>
          </Tooltip>
        </Stack>
      ),
    },
  ];

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

  useEffect(() => {
    if (!userEmail) return;
    fetchData();
  }, [paginationModel]);

  //   const fetchData = async () => {
  //     if (!userEmail) return;

  //     dispatch(
  //       fetchTimesheetRecords({
  //         employeeEmail: userEmail,
  //         status: TimesheetStatus.APPROVED,
  //         limit: paginationModel.pageSize,
  //         offset: paginationModel.page * paginationModel.pageSize,
  //         rangeStart: "2025-01-01",
  //         rangeEnd: "2025-03-25",
  //         leadEmail: leadEmail,
  //       })
  //     );
  //   };

  const [filters, setFilters] = useState<Filter[]>([]);
  const [availableFields, setAvailableFields] = useState([
    { field: "status", label: "Status", type: "select", options: Object.values(TimesheetStatus) },
    { field: "leadEmail", label: "Lead Email", type: "text" },
    { field: "rangeStart", label: "Start Date", type: "date" },
    { field: "rangeEnd", label: "End Date", type: "date" },
  ]);
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
        leadEmail: leadEmail,
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

  const handleAddFilter = () => {
    if (filters.some((f) => f.field === "status")) {
      const defaultField = availableFields.find((f) => f.field !== "status")?.field || availableFields[0].field;
      setFilters([
        ...filters,
        {
          id: Date.now().toString(),
          field: defaultField,
          operator: "equals",
          value: defaultField.includes("Date") ? new Date() : "",
        },
      ]);
    } else {
      const defaultField = availableFields[0].field;
      setFilters([
        ...filters,
        {
          id: Date.now().toString(),
          field: defaultField,
          operator: "equals",
          value: defaultField.includes("Date") ? new Date() : "",
        },
      ]);
    }
  };

  const handleFilterChange = (id: string, field: string, value: any) => {
    if (field === "field" && value === "status" && filters.some((f) => f.field === "status" && f.id !== id)) {
      return;
    }

    setFilters(filters.map((filter) => (filter.id === id ? { ...filter, [field]: value } : filter)));
  };

  const handleRemoveFilter = (id: string) => {
    setFilters(filters.filter((filter) => filter.id !== id));
  };

  const applyFilters = () => {
    fetchData();
  };

  const resetFilters = () => {
    setFilters([]);
    fetchDefaultData();
  };

  const getFilterComponent = (filter: Filter) => {
    const fieldConfig = availableFields.find((f) => f.field === filter.field);
    console.log(fieldConfig);
    if (!fieldConfig) return null;

    switch (fieldConfig.type) {
      case "select":
        return (
          <TextField
            select
            size="small"
            value={filter.value}
            onChange={(e) => handleFilterChange(filter.id, "value", e.target.value)}
            sx={{ minWidth: 150 }}
          >
            {fieldConfig.options?.map((option) => (
              <MenuItem key={option} value={option}>
                {option}
              </MenuItem>
            ))}
          </TextField>
        );
      case "date":
        return (
          <DatePicker
            value={filter.value}
            onChange={(newValue) => handleFilterChange(filter.id, "value", newValue)}
            slotProps={{ textField: { size: "small" } }}
          />
        );
      default:
        return (
          <TextField
            size="small"
            value={filter.value}
            onChange={(e) => handleFilterChange(filter.id, "value", e.target.value)}
          />
        );
    }
  };

  return (
    <LocalizationProvider dateAdapter={AdapterDateFns}>
      <Paper sx={{ width: "100%", height: "100%", p: 2, overflow: "auto" }}>
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
              "&:hover": { boxShadow: "none" },
            }}
          >
            New Entry
          </Button>
        </Stack>

        <Paper elevation={0} sx={{ p: 2, mb: 2, border: "1px solid", borderColor: "divider" }}>
          <Stack direction="row" alignItems="center" spacing={1}>
            <TuneIcon color="action" />
            <Typography variant="subtitle1">Filters</Typography>
            <Button
              size="small"
              variant="outlined"
              startIcon={<AddIcon />}
              onClick={handleAddFilter}
              sx={{ mr: "auto" }}
            >
              Add Filter
            </Button>
          </Stack>

          {filters.length > 0 && (
            <>
              <Stack spacing={2} m={1}>
                {filters.map((filter) => {
                  const fieldConfig = availableFields.find((f) => f.field === filter.field);
                  return (
                    <Stack key={filter.id} direction="row" spacing={2} alignItems="center">
                      <TextField
                        select
                        size="small"
                        value={filter.field}
                        onChange={(e) => handleFilterChange(filter.id, "field", e.target.value)}
                        sx={{ minWidth: 150 }}
                      >
                        {availableFields.map((field) => (
                          <MenuItem key={field.field} value={field.field}>
                            {field.label}
                          </MenuItem>
                        ))}
                      </TextField>
                      {getFilterComponent(filter)}
                      <IconButton onClick={() => handleRemoveFilter(filter.id)}>
                        <CloseIcon />
                      </IconButton>
                    </Stack>
                  );
                })}
              </Stack>
              <Stack direction="row" spacing={2}>
                <Button variant="contained" onClick={applyFilters}>
                  Apply Filters
                </Button>
                <Button variant="outlined" onClick={resetFilters}>
                  Reset
                </Button>
              </Stack>
            </>
          )}
        </Paper>

        <Paper
          elevation={0}
          sx={{
            height: "80%",
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
          <SubmitRecordModal onClose={handleCloseDialog} />
        </CustomModal>
      </Paper>
    </LocalizationProvider>
  );
};
export default TimesheetDataGrid;

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
  State,
  Filter,
  TimeLogReview,
  TimesheetRecord,
  TimesheetStatus,
  statusChipStyles,
  ConfirmationType,
} from "@utils/types";
import {
  DataGrid,
  GridFilterModel,
  GridLogicOperator,
  GridPaginationModel,
  GridRenderCellParams,
  GridRowSelectionModel,
} from "@mui/x-data-grid";
import { useEffect, useState } from "react";
import { Messages } from "@config/constant";
import { DEFAULT_PAGE_SIZE } from "@config/config";
import NoDataView from "@component/common/NoDataView";
import ThumbUpIcon from "@mui/icons-material/ThumbUp";
import ThumbDownIcon from "@mui/icons-material/ThumbDown";
import { LocalizationProvider } from "@mui/x-date-pickers";
import AccessTimeIcon from "@mui/icons-material/AccessTime";
import FilterComponent from "@component/common/FilterModal";
import ContentCopyIcon from "@mui/icons-material/ContentCopy";
import LunchDiningIcon from "@mui/icons-material/LunchDining";
import { useAppDispatch, useAppSelector } from "@slices/store";
import CalendarMonthIcon from "@mui/icons-material/CalendarMonth";
import { AdapterDateFns } from "@mui/x-date-pickers/AdapterDateFns";
import InformationHeader from "@component/common/InformationHeader";
import { useConfirmationModalContext } from "@context/DialogContext";
import { fetchTimesheetRecords, resetTimesheetRecords, updateTimesheetRecords } from "@slices/recordSlice/record";
import { Box, Chip, Stack, Paper, Button, Tooltip, useTheme, Typography, IconButton, Avatar } from "@mui/material";

const TimesheetAuditView = () => {
  const theme = useTheme();
  const dispatch = useAppDispatch();
  const dialogContext = useConfirmationModalContext();
  const leadEmail = useAppSelector((state) => state.auth.userInfo?.email);
  const employeeMap = useAppSelector((state) => state.meteInfo.employeeMap);
  const [selectionModel, setSelectionModel] = useState<GridRowSelectionModel>([]);
  const workPolicies = useAppSelector((state) => state.user.userInfo?.workPolicies);
  const recordLoadingState = useAppSelector((state) => state.timesheetRecord.retrievingState);
  const timesheetLoadingInfo = useAppSelector((state) => state.timesheetRecord.retrievingState);
  const records = useAppSelector((state) => state.timesheetRecord.timesheetData?.timeLogs || []);
  const timesheetInfo = useAppSelector((state) => state.timesheetRecord.timesheetData?.timesheetInfo);
  const totalRecordCount = useAppSelector((state) => state.timesheetRecord.timesheetData?.totalRecordCount || 0);
  const [paginationModel, setPaginationModel] = useState<GridPaginationModel>({
    page: 0,
    pageSize: DEFAULT_PAGE_SIZE,
  });
  const [filters, setFilters] = useState<Filter[]>([]);
  const availableFields = [
    { field: "status", label: "Status", type: "select", options: Object.values(TimesheetStatus) },
    { field: "onApply", label: "Employee Email", type: "text" },
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
      flex: 2,
      renderCell: (params: GridRenderCellParams<TimesheetRecord>) => (
        <Box display="flex" alignItems="center" position="relative">
          <Avatar
            src={employeeMap[params.row?.employeeEmail]?.employeeThumbnail}
            alt={employeeMap[params.row?.employeeEmail]?.employeeName || params.row?.employeeEmail}
            sx={{ marginRight: 2, height: "2.2rem", width: "2.2rem" }}
          />
          <Box
            sx={{
              position: "relative",
              transition: "transform 0.3s ease",
              "&:hover": {
                transform: "translateY(-10px)",
              },
              "&:hover > div": {
                opacity: 1,
              },
            }}
          >
            <Typography variant="body2">
              {employeeMap[params.row?.employeeEmail]?.employeeName || params.row?.employeeEmail}
            </Typography>
            <Box
              sx={{
                position: "absolute",
                top: "100%",
                left: 0,
                display: "flex",
                alignItems: "center",
                padding: "1px 0",
                borderRadius: "4px",
                opacity: 0,
                transition: "opacity 0.3s",
              }}
            >
              <Typography color={"GrayText"} variant="caption" mr={1}>
                {params.row?.employeeEmail}
              </Typography>
              <Tooltip title="Copy Email">
                <IconButton
                  size="small"
                  aria-label="Copy Email"
                  onClick={() => {
                    navigator.clipboard.writeText(params.row?.employeeEmail);
                  }}
                >
                  <ContentCopyIcon sx={{ fontSize: "15px" }} />
                </IconButton>
              </Tooltip>
            </Box>
          </Box>
        </Box>
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
    {
      field: "overtimeRejectReason",
      headerName: "",
      flex: 2,
      renderCell: (params: GridRenderCellParams<TimesheetRecord>) => (
        <>
          {params.row.overtimeStatus === TimesheetStatus.REJECTED && (
            <Tooltip title={params.row.overtimeRejectReason}>
              <Typography color="text.secondary" noWrap variant="body2">
                {params.row.overtimeRejectReason}
              </Typography>
            </Tooltip>
          )}
        </>
      ),
    },
    {
      field: "actions",
      headerName: "Actions",
      width: 120,
      renderCell: (params: GridRenderCellParams<TimesheetRecord>) => (
        <Stack direction="row">
          <Tooltip title="Approve OT">
            <span>
              <IconButton
                size="small"
                color="info"
                onClick={() => handleApproveRecords(params.row.recordId)}
                disabled={params.row.overtimeStatus !== TimesheetStatus.PENDING || selectionModel.length > 1}
                sx={{ mr: 1 }}
              >
                <ThumbUpIcon fontSize="small" />
              </IconButton>
            </span>
          </Tooltip>
          <Tooltip title="Decline OT">
            <span>
              <IconButton
                size="small"
                color="error"
                disabled={params.row.overtimeStatus !== TimesheetStatus.PENDING || selectionModel.length > 1}
                onClick={() => handleDeclineRecords(params.row.recordId)}
              >
                <ThumbDownIcon fontSize="small" />
              </IconButton>
            </span>
          </Tooltip>
        </Stack>
      ),
    },
  ];

  useEffect(() => {
    if (!leadEmail) return;
    fetchData();
    //eslint-disable-next-line react-hooks/exhaustive-deps
  }, [paginationModel]);

  const fetchDefaultData = async () => {
    if (!leadEmail) return;
    dispatch(
      fetchTimesheetRecords({
        status: TimesheetStatus.PENDING,
        limit: paginationModel.pageSize,
        offset: paginationModel.page * paginationModel.pageSize,
        leadEmail: leadEmail,
      })
    );
  };

  const handleSelectionChange = (newSelectionModel: GridRowSelectionModel) => {
    newSelectionModel[newSelectionModel.length - 1] as number;
    setSelectionModel(newSelectionModel);
  };

  const handleApproveRecords = (recordId?: number) => {
    dialogContext.showConfirmation(
      "Do you want to approve the selected?",
      "Please note that once done, this cannot be undone.",
      ConfirmationType.send,
      () => {
        handleUpdateRecords(TimesheetStatus.APPROVED, recordId);
      },
      "Approve",
      "Cancel"
    );
  };

  const handleDeclineRecords = (recordId?: number) => {
    dialogContext.showConfirmation(
      "Do you want to decline the selected?",
      "Please note that once done, this cannot be undone.",
      ConfirmationType.send,
      (comment) => {
        handleUpdateRecords(TimesheetStatus.REJECTED, recordId, comment);
      },
      "Decline",
      "Cancel",
      {
        label: "Reason for decline",
        mandatory: true,
        type: "textarea",
      }
    );
  };

  const handleUpdateRecords = async (status: TimesheetStatus, recordId?: number, comment?: string) => {
    const recordIds = selectionModel.length > 1 ? selectionModel.map((id) => id as number) : [recordId as number];

    const payload: TimeLogReview = {
      recordIds,
      overtimeRejectReason: comment,
      overtimeStatus: status,
    };

    await dispatch(updateTimesheetRecords({ payload }));
    fetchData();
  };

  const fetchData = async () => {
    if (!leadEmail) return;

    const filterParams = Object.fromEntries(filters.map(({ field, value }) => [field, value]));

    dispatch(
      fetchTimesheetRecords({
        leadEmail,
        status: TimesheetStatus.PENDING,
        limit: paginationModel.pageSize,
        offset: paginationModel.page * paginationModel.pageSize,
        ...filterParams,
      })
    );
  };

  const handleResetFilters = () => {
    fetchDefaultData();
    setFilters([]);
  };

  useEffect(() => {
    return () => {
      dispatch(resetTimesheetRecords());
    };
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, []);

  return (
    <Box sx={{ width: "100%", height: "100%" }}>
      {timesheetLoadingInfo === State.failed ? (
        <NoDataView message={Messages.error.fetchRecords} type="error" />
      ) : (
        <LocalizationProvider dateAdapter={AdapterDateFns}>
          <Box sx={{ width: "100%", height: "99%", overflow: "auto", p: 1 }}>
            {timesheetInfo && workPolicies && (
              <Box sx={{ width: "100%", height: "auto" }}>
                <InformationHeader timesheetInfo={timesheetInfo} workPolicies={workPolicies} isLeadView={true} />
              </Box>
            )}

            <Stack direction="row" justifyContent="space-between" alignItems="right" mb={1} spacing={1}>
              <FilterComponent
                availableFields={availableFields}
                filters={filters}
                setFilters={setFilters}
                onApply={fetchData}
                onReset={handleResetFilters}
                isLead={true}
              />
              <Box>
                <Button
                  variant="contained"
                  onClick={() => handleApproveRecords()}
                  sx={{ width: "160px", mx: 1 }}
                  startIcon={<ThumbUpIcon />}
                  disabled={selectionModel.length <= 1}
                >
                  Batch Approve
                </Button>

                <Button
                  variant="contained"
                  onClick={() => handleDeclineRecords()}
                  color="error"
                  sx={{ width: "160px", mx: 1 }}
                  startIcon={<ThumbDownIcon />}
                  disabled={selectionModel.length <= 1}
                >
                  Batch Reject
                </Button>
              </Box>
            </Stack>

            <Paper
              elevation={0}
              sx={{
                height: "85%",
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
                  disableRowSelectionOnClick
                  loading={recordLoadingState === State.loading}
                  getRowId={(row) => row.recordId}
                  filterModel={filterModel}
                  onFilterModelChange={setFilterModel}
                  onRowSelectionModelChange={handleSelectionChange}
                  checkboxSelection
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
      )}
    </Box>
  );
};
export default TimesheetAuditView;

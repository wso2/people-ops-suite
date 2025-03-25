import { useEffect, useState } from "react";
import { Box, Typography, Paper, Chip, IconButton, Button, Stack, useTheme, Tooltip } from "@mui/material";
import { DataGrid, GridRenderCellParams } from "@mui/x-data-grid";
import { AdapterDateFns } from "@mui/x-date-pickers/AdapterDateFns";
import { LocalizationProvider } from "@mui/x-date-pickers";
import AddIcon from "@mui/icons-material/Add";
import AccessTimeIcon from "@mui/icons-material/AccessTime";
import EditIcon from "@mui/icons-material/Edit";
import DeleteIcon from "@mui/icons-material/Delete";
import LunchDiningIcon from "@mui/icons-material/LunchDining";
import { TimesheetEntry, TimeSheetStatus } from "@utils/types";
import { CustomModal } from "@component/common/CustomComponentModal";
import SubmitRecordModal from "../components/SubmitRecordModal";
import { format, parseISO } from "date-fns";
import CheckCircleIcon from "@mui/icons-material/CheckCircle";
import PendingIcon from "@mui/icons-material/Pending";
import CancelIcon from "@mui/icons-material/Cancel";

const sampleData: TimesheetEntry[] = [
  {
    id: 1,
    recordDate: "2025-03-24",
    clockIn: "08:00:00",
    clockOut: "2025-03-24T17:00:00",
    lunchIncluded: true,
    overtimeHours: 1,
    overtimeReason: "Stayed late to finish the timesheet app",
    overtimeRejectionReason: "",
    recordStatus: TimeSheetStatus.APPROVED,
  },
  {
    id: 2,
    recordDate: "2025-03-23",
    clockIn: "2025-03-23T08:30:00",
    clockOut: "2025-03-23T16:30:00",
    lunchIncluded: true,
    overtimeHours: 0,
    overtimeReason: "",
    overtimeRejectionReason: "",
    recordStatus: TimeSheetStatus.PENDING,
  },
  {
    id: 3,
    recordDate: "2025-03-22",
    clockIn: "2025-03-22T09:00:00",
    clockOut: "2025-03-22T18:00:00",
    lunchIncluded: false,
    overtimeHours: 2,
    overtimeReason: "Client emergency meeting",
    overtimeRejectionReason: "",
    recordStatus: TimeSheetStatus.REJECTED,
  },
  {
    id: 4,
    recordDate: "2025-03-21",
    clockIn: "2025-03-21T08:00:00",
    clockOut: "2025-03-21T16:00:00",
    lunchIncluded: true,
    overtimeHours: 0,
    overtimeReason: "",
    overtimeRejectionReason: "",
    recordStatus: TimeSheetStatus.PENDING,
  },
  {
    id: 5,
    recordDate: "2025-03-20",
    clockIn: "2025-03-20T08:15:00",
    clockOut: "2025-03-20T17:45:00",
    lunchIncluded: true,
    overtimeHours: 1.5,
    overtimeReason: "Sprint deadline preparation",
    overtimeRejectionReason: "",
    recordStatus: TimeSheetStatus.APPROVED,
  },
  {
    id: 6,
    recordDate: "2025-03-24",
    clockIn: "08:00:00",
    clockOut: "2025-03-24T17:00:00",
    lunchIncluded: true,
    overtimeHours: 1,
    overtimeReason: "Stayed late to finish the timesheet app",
    overtimeRejectionReason: "",
    recordStatus: TimeSheetStatus.APPROVED,
  },
  {
    id: 7,
    recordDate: "2025-03-23",
    clockIn: "2025-03-23T08:30:00",
    clockOut: "2025-03-23T16:30:00",
    lunchIncluded: true,
    overtimeHours: 0,
    overtimeReason: "",
    overtimeRejectionReason: "",
    recordStatus: TimeSheetStatus.PENDING,
  },
  {
    id: 8,
    recordDate: "2025-03-22",
    clockIn: "2025-03-22T09:00:00",
    clockOut: "2025-03-22T18:00:00",
    lunchIncluded: false,
    overtimeHours: 2,
    overtimeReason: "Client emergency meeting",
    overtimeRejectionReason: "",
    recordStatus: TimeSheetStatus.REJECTED,
  },
  {
    id: 9,
    recordDate: "2025-03-21",
    clockIn: "2025-03-21T08:00:00",
    clockOut: "2025-03-21T16:00:00",
    lunchIncluded: true,
    overtimeHours: 0,
    overtimeReason: "",
    overtimeRejectionReason: "",
    recordStatus: TimeSheetStatus.PENDING,
  },
  {
    id: 10,
    recordDate: "2025-03-20",
    clockIn: "2025-03-20T08:15:00",
    clockOut: "2025-03-20T17:45:00",
    lunchIncluded: true,
    overtimeHours: 1.5,
    overtimeReason: "Sprint deadline preparation",
    overtimeRejectionReason: "",
    recordStatus: TimeSheetStatus.APPROVED,
  },
  {
    id: 11,
    recordDate: "2025-03-24",
    clockIn: "08:00:00",
    clockOut: "2025-03-24T17:00:00",
    lunchIncluded: true,
    overtimeHours: 1,
    overtimeReason: "Stayed late to finish the timesheet app",
    overtimeRejectionReason: "",
    recordStatus: TimeSheetStatus.APPROVED,
  },
  {
    id: 12,
    recordDate: "2025-03-23",
    clockIn: "2025-03-23T08:30:00",
    clockOut: "2025-03-23T16:30:00",
    lunchIncluded: true,
    overtimeHours: 0,
    overtimeReason: "",
    overtimeRejectionReason: "",
    recordStatus: TimeSheetStatus.PENDING,
  },
  {
    id: 13,
    recordDate: "2025-03-22",
    clockIn: "2025-03-22T09:00:00",
    clockOut: "2025-03-22T18:00:00",
    lunchIncluded: false,
    overtimeHours: 2,
    overtimeReason: "Client emergency meeting",
    overtimeRejectionReason: "",
    recordStatus: TimeSheetStatus.REJECTED,
  },
  {
    id: 14,
    recordDate: "2025-03-21",
    clockIn: "2025-03-21T08:00:00",
    clockOut: "2025-03-21T16:00:00",
    lunchIncluded: true,
    overtimeHours: 0,
    overtimeReason: "",
    overtimeRejectionReason: "",
    recordStatus: TimeSheetStatus.PENDING,
  },
  {
    id: 15,
    recordDate: "2025-03-20",
    clockIn: "2025-03-20T08:15:00",
    clockOut: "2025-03-20T17:45:00",
    lunchIncluded: true,
    overtimeHours: 1.5,
    overtimeReason: "Sprint deadline preparation",
    overtimeRejectionReason: "",
    recordStatus: TimeSheetStatus.APPROVED,
  },
];

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

  const rowCount = 15;

  const [rowCountState, setRowCountState] = useState(rowCount);

  useEffect(() => {
    setRowCountState((prevRowCountState) => (rowCount !== undefined ? rowCount : prevRowCountState));
  }, [rowCount, setRowCountState]);

  const handleOpenDialog = () => setOpenDialog(true);
  const handleCloseDialog = () => setOpenDialog(false);

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
      valueGetter: (params: { row: TimesheetEntry }) => format(parseISO(params.row.recordDate), "MMM dd, yyyy"),
    },
    {
      field: "clockIn",
      headerName: "Clock In",
      flex: 1,
      renderCell: (params: GridRenderCellParams<TimesheetEntry>) => (
        <Stack direction="row" alignItems="center" gap={1}>
          <AccessTimeIcon fontSize="small" color="action" />
          <Typography variant="body2">{formatTime(params.row.clockIn)}</Typography>
        </Stack>
      ),
    },
    {
      field: "clockOut",
      headerName: "Clock Out",
      flex: 1,
      renderCell: (params: GridRenderCellParams<TimesheetEntry>) => (
        <Stack direction="row" alignItems="center" gap={1}>
          <AccessTimeIcon fontSize="small" color="action" />
          <Typography variant="body2">{formatTime(params.row.clockOut)}</Typography>
        </Stack>
      ),
    },
    {
      field: "lunchIncluded",
      headerName: "Lunch",
      flex: 0.8,
      renderCell: (params: GridRenderCellParams<TimesheetEntry>) => (
        <Stack direction="row" alignItems="center" gap={1}>
          <LunchDiningIcon fontSize="small" color={params.row.lunchIncluded ? "success" : "error"} />
          <Typography variant="body2">{params.row.lunchIncluded ? "Yes" : "No"}</Typography>
        </Stack>
      ),
    },
    {
      field: "overtimeHours",
      headerName: "Overtime",
      flex: 1,
      renderCell: (params: GridRenderCellParams<TimesheetEntry>) => (
        <Box>
          <Typography variant="body2" fontWeight={params.row.overtimeHours > 0 ? 600 : 400}>
            {params.row.overtimeHours > 0 ? `${params.row.overtimeHours}h` : "None"}
          </Typography>
          {params.row.overtimeHours > 0 && (
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
      renderCell: (params: GridRenderCellParams<TimesheetEntry>) => (
        <Chip
          icon={statusChipStyles[params.row.recordStatus as TimeSheetStatus].icon}
          label={params.row.recordStatus}
          color={statusChipStyles[params.row.recordStatus as TimeSheetStatus].color as "success" | "error" | "warning"}
          variant="outlined"
          size="small"
        />
      ),
    },
    {
      field: "actions",
      headerName: "Actions",
      width: 120,
      renderCell: (params: GridRenderCellParams<TimesheetEntry>) => (
        <Stack direction="row">
          <Tooltip title="Edit">
            <IconButton size="small" disabled={params.row.recordStatus === TimeSheetStatus.APPROVED}>
              <EditIcon fontSize="small" />
            </IconButton>
          </Tooltip>
          <Tooltip title="Delete">
            <IconButton size="small" disabled={params.row.recordStatus === TimeSheetStatus.APPROVED}>
              <DeleteIcon fontSize="small" />
            </IconButton>
          </Tooltip>
        </Stack>
      ),
    },
  ];

  return (
    <LocalizationProvider dateAdapter={AdapterDateFns}>
      <Paper sx={{ width: "100%", height: "100%", p: 3 }}>
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
          <DataGrid
            rows={sampleData}
            columns={columns}
            disableDensitySelector
            disableSelectionOnClick
            pagination
            paginationMode="server"
            rowCount={15}
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
            rowsPerPageOptions={[5]}
          />
        </Paper>

        <CustomModal open={openDialog} onClose={handleCloseDialog}>
          <SubmitRecordModal />
        </CustomModal>
      </Paper>
    </LocalizationProvider>
  );
};

export default TimesheetDataGrid;

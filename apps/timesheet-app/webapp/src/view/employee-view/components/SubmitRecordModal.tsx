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
  Card,
  Chip,
  Grid,
  Paper,
  Table,
  Switch,
  Dialog,
  Button,
  Tooltip,
  Divider,
  TableRow,
  TableBody,
  TableCell,
  TableHead,
  TextField,
  IconButton,
  CardHeader,
  FormControl,
  CardContent,
  DialogTitle,
  DialogActions,
  DialogContent,
  TableContainer,
  InputAdornment,
  FormControlLabel,
} from "@mui/material";
import { Messages } from "@config/constant";
import AddIcon from "@mui/icons-material/Add";
import { TimesheetStatus } from "@utils/types";
import EditIcon from "@mui/icons-material/Edit";
import CloseIcon from "@mui/icons-material/Close";
import DeleteIcon from "@mui/icons-material/Delete";
import PublishIcon from "@mui/icons-material/Publish";
import { HourglassBottom } from "@mui/icons-material";
import { CreateUITimesheetRecord } from "@utils/types";
import React, { useState, useEffect, useRef } from "react";
import { DatePicker } from "@mui/x-date-pickers/DatePicker";
import { TimePicker } from "@mui/x-date-pickers/TimePicker";
import RestartAltIcon from "@mui/icons-material/RestartAlt";
import { useAppDispatch, useAppSelector } from "@slices/store";
import ReceiptLongIcon from "@mui/icons-material/ReceiptLong";
import { addTimesheetRecords } from "@slices/recordSlice/record";
import { AdapterDateFns } from "@mui/x-date-pickers/AdapterDateFns";
import { enqueueSnackbarMessage } from "@slices/commonSlice/common";
import { format, differenceInMinutes, isWeekend, startOfDay } from "date-fns";
import { LocalizationProvider } from "@mui/x-date-pickers/LocalizationProvider";

interface TimeTrackingFormProps {
  onClose?: () => void;
}

const SubmitRecordModal: React.FC<TimeTrackingFormProps> = ({ onClose }) => {
  const dispatch = useAppDispatch();
  const regularLunchHoursPerDay = useAppSelector((state) => state.user.userInfo?.workPolicies.lunchHoursPerDay);
  const regularWorkHoursPerDay = useAppSelector((state) => state.user.userInfo?.workPolicies.workingHoursPerDay);
  const newRecordId = useRef<number>(0);
  const regularWorkMinutes = (regularWorkHoursPerDay ?? 8) * 60;
  const [editDialogOpen, setEditDialogOpen] = useState(false);
  const [errors, setErrors] = useState<Record<string, string>>({});
  const [entries, setEntries] = useState<CreateUITimesheetRecord[]>([]);
  const totalDays = entries.length;
  const userEmail = useAppSelector((state) => state.user.userInfo!.employeeInfo.workEmail);
  const [editingEntry, setEditingEntry] = useState<CreateUITimesheetRecord | null>(null);
  const totalOvertimeHours = entries.reduce((sum, entry) => sum + entry.overtimeDuration, 0);
  const [currentEntry, setCurrentEntry] = useState<CreateUITimesheetRecord>(createNewEntry());
  const timesheetInfo = useAppSelector((state) => state.timesheetRecord.timesheetData?.timesheetInfo);

  function createNewEntry(): CreateUITimesheetRecord {
    return {
      recordId: (newRecordId.current += 1),
      recordDate: new Date(),
      clockInTime: null,
      clockOutTime: null,
      isLunchIncluded: true,
      overtimeDuration: 0,
      overtimeReason: "",
      overtimeStatus: TimesheetStatus.APPROVED,
    };
  }

  useEffect(() => {
    setCurrentEntry(calculateOvertime(currentEntry));
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [
    currentEntry.clockInTime,
    currentEntry.clockOutTime,
    currentEntry.isLunchIncluded,
    currentEntry.recordDate,
    regularWorkMinutes,
  ]);

  const handleDateChange = (newDate: Date | null) => {
    setCurrentEntry({ ...currentEntry, recordDate: newDate });
  };

  const handleClockInChange = (newTime: Date | null) => {
    setCurrentEntry({ ...currentEntry, clockInTime: newTime });
  };

  const handleClockOutChange = (newTime: Date | null) => {
    setCurrentEntry({ ...currentEntry, clockOutTime: newTime });
  };

  const handleSwitchChange = (event: React.ChangeEvent<HTMLInputElement>) => {
    setCurrentEntry({ ...currentEntry, isLunchIncluded: event.target.checked });
  };

  const handleOvertimeReasonChange = (event: React.ChangeEvent<HTMLInputElement>) => {
    setCurrentEntry({ ...currentEntry, overtimeReason: event.target.value });
  };

  const handleAddEntry = () => {
    const entryErrors = validateEntry(currentEntry);

    if (Object.keys(entryErrors).length === 0) {
      setEntries([...entries, currentEntry]);
      setCurrentEntry(createNewEntry());
      setErrors({});
    } else {
      setErrors(entryErrors);
    }
  };

  const handleDeleteEntry = (recordId: number) => {
    setEntries(entries.filter((entry) => entry.recordId !== recordId));
  };

  const handleBatchSubmit = () => {
    if (entries.length === 0) {
      const entryErrors = validateEntry(currentEntry);

      if (Object.keys(entryErrors).length === 0) {
        setEntries([...entries, currentEntry]);
        setCurrentEntry(createNewEntry());
      } else {
        setErrors(entryErrors);
      }
    } else {
      handleDataSubmit();
    }
  };

  const cleanTimeEntries = (entries: CreateUITimesheetRecord[]) => {
    return entries.map((entry) => {
      const formattedRecordDate = entry.recordDate ? entry.recordDate.toISOString().split("T")[0] : "";

      const formatTime = (dateTime: Date) => {
        const date = new Date(dateTime);
        return date.toISOString().split("T")[1].split(".")[0];
      };

      return {
        ...entry,
        isLunchIncluded: entry.isLunchIncluded ? 1 : 0,
        recordDate: formattedRecordDate,
        clockInTime: formatTime(entry.clockInTime!),
        clockOutTime: formatTime(entry.clockOutTime!),
        overtimeStatus: entry.overtimeDuration > 0 ? TimesheetStatus.PENDING : TimesheetStatus.APPROVED,
      };
    });
  };

  const handleDataSubmit = async () => {
    if (timesheetInfo && totalOvertimeHours > timesheetInfo?.overTimeLeft) {
      dispatch(
        enqueueSnackbarMessage({
          message: Messages.error.otExceeds,
          type: "error",
        })
      );
      return;
    } else {
      const cleanedEntries = cleanTimeEntries(entries);
      const resultAction = await dispatch(addTimesheetRecords({ employeeEmail: userEmail, payload: cleanedEntries }));
      if (addTimesheetRecords.fulfilled.match(resultAction)) {
        onClose?.();
      }
    }
  };

  const handleReset = () => {
    setCurrentEntry(createNewEntry());
    setErrors({});
  };

  const openEditDialog = (entry: CreateUITimesheetRecord) => {
    setEditingEntry(entry);
    setEditDialogOpen(true);
  };

  const calculateOvertime = (entry: CreateUITimesheetRecord): CreateUITimesheetRecord => {
    if (!(entry.clockInTime && entry.clockOutTime && entry.recordDate)) return entry;

    const totalMinutes = differenceInMinutes(entry.clockOutTime, entry.clockInTime);
    const lunchBreakMinutes = entry.isLunchIncluded ? (regularLunchHoursPerDay ?? 0) * 60 : 0;
    const workMinutes = Math.max(0, totalMinutes - lunchBreakMinutes);
    const overtimeMinutes = isWeekend(entry.recordDate) ? totalMinutes : Math.max(0, workMinutes - regularWorkMinutes);

    return {
      ...entry,
      overtimeDuration: parseFloat((overtimeMinutes / 60).toFixed(2)),
      overtimeReason:
        overtimeMinutes > 0 ? entry.overtimeReason ?? (isWeekend(entry.recordDate) ? "Weekend work" : "") : "",
    };
  };

  const handleSaveEditedEntry = () => {
    if (editingEntry) {
      const updatedEntry = calculateOvertime(editingEntry);
      const entryErrors = validateEntry(updatedEntry);

      if (updatedEntry.overtimeDuration <= 0 && entryErrors.overtimeReason) {
        delete entryErrors.overtimeReason;
      }

      if (Object.keys(entryErrors).length === 0) {
        setEntries(entries.map((entry) => (entry.recordId === updatedEntry.recordId ? updatedEntry : entry)));
        setEditDialogOpen(false);
        setEditingEntry(null);
        setErrors({});
      } else {
        setErrors(entryErrors);
      }
    }
  };

  const handleEditFieldChange = (field: keyof CreateUITimesheetRecord, value: any) => {
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

  const validateEntry = (entry: CreateUITimesheetRecord): Record<string, string> => {
    const entryErrors: Record<string, string> = {};

    if (!entry.recordDate) {
      entryErrors.recordDate = "Date is required";
    }

    if (!entry.clockInTime) {
      entryErrors.clockInTime = "Clock in time is required";
    }

    if (!entry.clockOutTime) {
      entryErrors.clockOutTime = "Clock out time is required";
    }

    if (entry.clockInTime && entry.clockOutTime && entry.clockInTime.getTime() >= entry.clockOutTime.getTime()) {
      entryErrors.clockOutTime = "Clock out time must be after clock in time";
    }

    if (entry.overtimeDuration > 0 && !entry.overtimeReason?.trim()) {
      entryErrors.overtimeReason = "Reason is required for overtime hours";
    }

    if (entry.recordDate) {
      const entryDate = startOfDay(entry.recordDate).getTime();
      const conflictingEntry = entries.find(
        (e) => e.recordId !== entry.recordId && e.recordDate && startOfDay(e.recordDate).getTime() === entryDate
      );

      if (conflictingEntry) {
        entryErrors.recordDate = "You already have an entry for this recordDate";
      }
    }

    return entryErrors;
  };

  return (
    <Box sx={{ height: "100%", overflow: "auto" }}>
      <LocalizationProvider dateAdapter={AdapterDateFns}>
        <Card elevation={3} sx={{ height: "100%" }}>
          <CardHeader
            subheader="Record your work hours"
            titleTypographyProps={{ variant: "h5" }}
            sx={{ bgcolor: "primary.main", color: "primary.contrastText" }}
            action={
              <>
                <Button
                  variant="contained"
                  color="secondary"
                  onClick={handleBatchSubmit}
                  sx={{ width: "160px", mx: 1 }}
                  startIcon={<PublishIcon />}
                  disabled={entries.length === 0}
                >
                  Submit Entries
                </Button>

                <IconButton color="secondary" onClick={onClose} sx={{ mx: 1 }}>
                  <CloseIcon />
                </IconButton>
              </>
            }
          />
          <CardContent>
            <Box sx={{ mb: 4 }}>
              <Grid container spacing={2} alignItems="center" justifyContent="center" textAlign="center">
                <Grid item xs={12} md={3} lg={1.5}>
                  <DatePicker
                    label="Date"
                    value={currentEntry.recordDate}
                    onChange={handleDateChange}
                    maxDate={new Date()}
                    slotProps={{
                      textField: {
                        fullWidth: true,
                        variant: "outlined",
                        error: !!errors.recordDate,
                        helperText:
                          errors.recordDate ||
                          (currentEntry.recordDate && isWeekend(currentEntry.recordDate) ? "Weekend" : ""),
                        sx: { textAlign: "center" },
                      },
                    }}
                  />
                </Grid>
                <Grid item xs={12} md={3} lg={1.5}>
                  <TimePicker
                    label="Clock In"
                    value={currentEntry.clockInTime}
                    onChange={handleClockInChange}
                    slotProps={{
                      textField: {
                        fullWidth: true,
                        variant: "outlined",
                        error: !!errors.clockInTime,
                        helperText: errors.clockInTime,
                        sx: { textAlign: "center" },
                      },
                    }}
                  />
                </Grid>
                <Grid item xs={12} md={3} lg={1.5}>
                  <TimePicker
                    label="Clock Out"
                    value={currentEntry.clockOutTime}
                    onChange={handleClockOutChange}
                    slotProps={{
                      textField: {
                        fullWidth: true,
                        variant: "outlined",
                        error: !!errors.clockOutTime,
                        helperText: errors.clockOutTime,
                        sx: { textAlign: "center" },
                      },
                    }}
                  />
                </Grid>
                <Grid item xs={12} md={3} lg={1.5} sx={{ display: "flex", justifyContent: "center" }}>
                  <FormControlLabel
                    control={
                      <Switch
                        checked={currentEntry.isLunchIncluded}
                        onChange={handleSwitchChange}
                        name="isLunchIncluded"
                        color="primary"
                      />
                    }
                    label="Lunch Break"
                  />
                </Grid>
                <Grid item xs={12} md={6} lg={3}>
                  {currentEntry.overtimeDuration > 0 && (
                    <FormControl fullWidth error={!!errors.overtimeReason} variant="outlined">
                      <TextField
                        label="Reason for Overtime"
                        value={currentEntry.overtimeReason}
                        onChange={handleOvertimeReasonChange}
                        error={!!errors.overtimeReason}
                        helperText={errors.overtimeReason}
                        variant="outlined"
                        multiline
                        required
                        sx={{ textAlign: "center" }}
                        InputProps={{
                          startAdornment: currentEntry.overtimeDuration > 0 && (
                            <InputAdornment position="end">
                              <Tooltip title={currentEntry.overtimeReason}>
                                <Chip
                                  label={`${currentEntry.overtimeDuration} hr${
                                    currentEntry.overtimeDuration !== 1 ? "s" : ""
                                  }`}
                                  color="primary"
                                  size="small"
                                  sx={{ mr: 1 }}
                                />
                              </Tooltip>
                            </InputAdornment>
                          ),
                        }}
                      />
                    </FormControl>
                  )}
                </Grid>
                <Grid item xs={12} md={12} lg={3}>
                  <Box sx={{ display: "flex", justifyContent: "center", gap: 2 }}>
                    <Button
                      variant="outlined"
                      color="error"
                      onClick={handleReset}
                      sx={{ width: "120px" }}
                      startIcon={<RestartAltIcon />}
                    >
                      Reset
                    </Button>
                    <Button
                      variant="outlined"
                      color="primary"
                      onClick={handleAddEntry}
                      disabled={entries.length >= 14}
                      startIcon={<AddIcon />}
                      sx={{ width: "120px" }}
                    >
                      Add Entry
                    </Button>
                  </Box>
                </Grid>
              </Grid>
            </Box>

            {entries.length > 0 && (
              <Box sx={{ mt: 4 }}>
                <Divider sx={{ mb: 2 }}>
                  <Chip label="Entries to Submit" />
                </Divider>
                <TableContainer component={Paper} elevation={2}>
                  <Table size="small">
                    <TableHead>
                      <TableRow>
                        <TableCell>Date</TableCell>
                        <TableCell>Clock In</TableCell>
                        <TableCell>Clock Out</TableCell>
                        <TableCell>Lunch</TableCell>
                        <TableCell>OT Hours</TableCell>
                        <TableCell>Actions</TableCell>
                      </TableRow>
                    </TableHead>
                    <TableBody>
                      {entries.map((entry) => (
                        <TableRow key={entry.recordDate?.toString()}>
                          <TableCell>
                            {entry.recordDate ? format(entry.recordDate, "MMM dd, yyyy") : ""}
                            {entry.recordDate && isWeekend(entry.recordDate) && (
                              <Chip size="small" label="Weekend" color="secondary" sx={{ ml: 1 }} />
                            )}
                          </TableCell>
                          <TableCell>{entry.clockInTime ? format(entry.clockInTime, "hh:mm a") : ""}</TableCell>
                          <TableCell>{entry.clockOutTime ? format(entry.clockOutTime, "hh:mm a") : ""}</TableCell>
                          <TableCell>{entry.isLunchIncluded ? "Yes" : "No"}</TableCell>
                          <TableCell>
                            {entry.overtimeDuration > 0 ? (
                              <Tooltip title={entry.overtimeReason}>
                                <Chip
                                  label={`${entry.overtimeDuration.toFixed(2)} hr${
                                    entry.overtimeDuration !== 1 ? "s" : ""
                                  }`}
                                  color="primary"
                                  size="small"
                                />
                              </Tooltip>
                            ) : (
                              "0"
                            )}
                          </TableCell>
                          <TableCell>
                            <Box sx={{ display: "flex" }}>
                              <IconButton
                                size="small"
                                color="primary"
                                onClick={() => openEditDialog(entry)}
                                sx={{ mr: 1 }}
                              >
                                <EditIcon fontSize="small" />
                              </IconButton>
                              <IconButton size="small" color="error" onClick={() => handleDeleteEntry(entry.recordId)}>
                                <DeleteIcon fontSize="small" />
                              </IconButton>
                            </Box>
                          </TableCell>
                        </TableRow>
                      ))}
                    </TableBody>
                  </Table>
                </TableContainer>
                <Box sx={{ mt: 2, display: "flex", justifyContent: "space-between", alignItems: "center" }}>
                  <Chip
                    title="OT Remaining"
                    label={
                      <>
                        Total: {totalDays} day{totalDays !== 1 ? "s" : ""}
                        {totalOvertimeHours > 0 &&
                          ` with ${totalOvertimeHours.toFixed(2)} overtime hour${totalOvertimeHours !== 1 ? "s" : ""}`}
                      </>
                    }
                    color="success"
                    icon={<ReceiptLongIcon />}
                    variant="outlined"
                    size="medium"
                    sx={{
                      borderWidth: 2,
                      px: 1,
                    }}
                  />
                  <Chip
                    title="OT Remaining"
                    label={`OT Remaining ${timesheetInfo?.overTimeLeft.toFixed(1)}h`}
                    color="success"
                    icon={<HourglassBottom />}
                    variant="outlined"
                    size="medium"
                    sx={{
                      borderWidth: 2,
                      px: 1,
                    }}
                  />
                </Box>
              </Box>
            )}
          </CardContent>
        </Card>

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
      </LocalizationProvider>
    </Box>
  );
};

export default SubmitRecordModal;

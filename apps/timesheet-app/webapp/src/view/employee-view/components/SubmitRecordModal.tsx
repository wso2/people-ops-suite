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
  Accordion,
  TableHead,
  TextField,
  IconButton,
  CardHeader,
  Typography,
  CardContent,
  DialogTitle,
  CardActions,
  DialogActions,
  DialogContent,
  TableContainer,
  InputAdornment,
  FormControlLabel,
  AccordionSummary,
  AccordionDetails,
} from "@mui/material";
import {
  format,
  isAfter,
  subDays,
  isWeekend,
  isSameDay,
  startOfDay,
  eachDayOfInterval,
  differenceInMinutes,
} from "date-fns";
import { Messages } from "@config/constant";
import AddIcon from "@mui/icons-material/Add";
import EditIcon from "@mui/icons-material/Edit";
import CloseIcon from "@mui/icons-material/Close";
import DeleteIcon from "@mui/icons-material/Delete";
import PublishIcon from "@mui/icons-material/Publish";
import { HourglassBottom } from "@mui/icons-material";
import { DEFAULT_TIME_ENTRY_SIZE } from "@config/config";
import React, { useState, useRef, useEffect } from "react";
import ExpandMoreIcon from "@mui/icons-material/ExpandMore";
import { DatePicker } from "@mui/x-date-pickers/DatePicker";
import { TimePicker } from "@mui/x-date-pickers/TimePicker";
import ReceiptLongIcon from "@mui/icons-material/ReceiptLong";
import { useAppDispatch, useAppSelector } from "@slices/store";
import { addTimesheetRecords } from "@slices/recordSlice/record";
import { AdapterDateFns } from "@mui/x-date-pickers/AdapterDateFns";
import { enqueueSnackbarMessage } from "@slices/commonSlice/common";
import { useConfirmationModalContext } from "@context/DialogContext";
import { ConfirmationType, CreateUITimesheetRecord } from "@utils/types";
import { LocalizationProvider } from "@mui/x-date-pickers/LocalizationProvider";

interface TimeTrackingFormProps {
  onClose?: () => void;
}

const SubmitRecordModal: React.FC<TimeTrackingFormProps> = ({ onClose }) => {
  const dispatch = useAppDispatch();
  const newRecordId = useRef<number>(0);
  const dialogContext = useConfirmationModalContext();
  const [isAddingNew, setIsAddingNew] = useState(false);
  const [editDialogOpen, setEditDialogOpen] = useState(false);
  const [errors, setErrors] = useState<Record<string, string>>({});
  const [bulkLunchIncluded, setBulkLunchIncluded] = useState(true);
  const [bulkOvertimeReason, setBulkOvertimeReason] = useState("");
  const [bulkEndDate, setBulkEndDate] = useState<Date | null>(null);
  const [entriesCount, setEntriesCount] = useState(0);
  const [entries, setEntries] = useState<CreateUITimesheetRecord[]>([]);
  const [bulkStartDate, setBulkStartDate] = useState<Date | null>(null);
  const [bulkClockInTime, setBulkClockInTime] = useState<Date | null>(null);
  const [bulkClockOutTime, setBulkClockOutTime] = useState<Date | null>(null);
  const [editingEntry, setEditingEntry] = useState<CreateUITimesheetRecord | null>(null);
  const userEmail = useAppSelector((state) => state.user.userInfo!.employeeInfo.workEmail);
  const totalOvertimeHours = entries.reduce((sum, entry) => sum + entry.overtimeDuration, 0);
  const timesheetInfo = useAppSelector((state) => state.timesheetRecord.timesheetData?.timesheetInfo);
  const regularLunchHoursPerDay = useAppSelector((state) => state.user.userInfo?.workPolicies.lunchHoursPerDay);
  const regularWorkHoursPerDay = useAppSelector((state) => state.user.userInfo?.workPolicies.workingHoursPerDay);
  const regularWorkMinutes = (regularWorkHoursPerDay ?? 8) * 60;

  function createNewEntry(): CreateUITimesheetRecord {
    return {
      recordId: (newRecordId.current += 1),
      recordDate: new Date(),
      clockInTime: null,
      clockOutTime: null,
      isLunchIncluded: true,
      overtimeDuration: 0,
      overtimeReason: "",
    };
  }

  const handleAddNewEntry = () => {
    setIsAddingNew(true);
    setEditingEntry(createNewEntry());
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

  const handleDeleteEntry = (recordId: number) => {
    setEntries(entries.filter((entry) => entry.recordId !== recordId));
  };

  const handleBatchSubmit = () => {
    handleDataSubmit();
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
      };
    });
  };

  const handleDataSubmit = async () => {
    if (entriesCount === 0) {
      dispatch(
        enqueueSnackbarMessage({
          message: "Please add at least one entry to submit",
          type: "error",
        })
      );
      return;
    }

    if (timesheetInfo?.overTimeLeft !== undefined && totalOvertimeHours > timesheetInfo.overTimeLeft) {
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

  const openEditDialog = (entry: CreateUITimesheetRecord) => {
    setIsAddingNew(false);
    setEditingEntry(entry);
    setEditDialogOpen(true);
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
        entryErrors.recordDate = "You already have an entry for this date";
      }
    }

    return entryErrors;
  };

  const validateBulkEntry = () => {
    const errors: Record<string, string> = {};

    if (!bulkStartDate) {
      errors.startDate = "Start date is required";
    }

    if (!bulkEndDate) {
      errors.endDate = "End date is required";
    }

    if (bulkStartDate && bulkEndDate && isAfter(bulkStartDate, bulkEndDate)) {
      errors.endDate = "End date must be after start date";
    }

    if (bulkStartDate && bulkEndDate) {
      const daysBetween = eachDayOfInterval({ start: bulkStartDate, end: bulkEndDate }).length;
      if (daysBetween > DEFAULT_TIME_ENTRY_SIZE) {
        errors.endDate = `Date range cannot exceed allowed entry count of ${DEFAULT_TIME_ENTRY_SIZE}, currently selected is ${daysBetween}`;
      }
    }

    if (!bulkClockInTime) {
      errors.clockInTime = "Clock in time is required";
    }

    if (!bulkClockOutTime) {
      errors.clockOutTime = "Clock out time is required";
    }

    if (bulkClockInTime && bulkClockOutTime) {
      if (bulkClockInTime.getTime() >= bulkClockOutTime.getTime()) {
        errors.clockOutTime = "Clock out time must be after clock in time";
      }
      if (differenceInMinutes(bulkClockOutTime, bulkClockInTime) > regularWorkMinutes) {
        if (!bulkOvertimeReason?.trim()) {
          errors.bulkOvertimeReason = "Overtime reason is required for overtime hours";
        }
      }
    }

    return errors;
  };

  const handleSaveEditedEntry = () => {
    if (editingEntry) {
      const updatedEntry = calculateOvertime(editingEntry);
      const entryErrors = validateEntry(updatedEntry);

      if (updatedEntry.overtimeDuration <= 0 && entryErrors.overtimeReason) {
        delete entryErrors.overtimeReason;
      }

      if (Object.keys(entryErrors).length === 0) {
        if (isAddingNew) {
          setEntries([...entries, updatedEntry]);
        } else {
          setEntries(entries.map((entry) => (entry.recordId === updatedEntry.recordId ? updatedEntry : entry)));
        }
        setEditDialogOpen(false);
        setEditingEntry(null);
        setErrors({});
        setIsAddingNew(false);
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

  const handleDuplicateLastEntry = () => {
    if (entriesCount === 0) {
      dispatch(
        enqueueSnackbarMessage({
          message: "No entries available to duplicate",
          type: "error",
        })
      );
      return;
    }

    const lastEntry = entries[entriesCount - 1];
    if (!lastEntry.recordDate) {
      dispatch(
        enqueueSnackbarMessage({
          message: "Last entry must have a date to duplicate",
          type: "error",
        })
      );
      return;
    }

    let newDate = subDays(lastEntry.recordDate, 1);
    let attempts = 0;
    const maxAttempts = 7;

    while (attempts < maxAttempts) {
      if (isWeekend(newDate)) {
        newDate = subDays(newDate, 1);
        attempts++;
        continue;
      }

      if (isAfter(newDate, new Date())) {
        newDate = subDays(newDate, 1);
        attempts++;
        continue;
      }

      const entryExists = entries.some((entry) => entry.recordDate && isSameDay(entry.recordDate, newDate));
      if (entryExists) {
        newDate = subDays(newDate, 1);
        attempts++;
        continue;
      }

      break;
    }

    if (attempts >= maxAttempts) {
      dispatch(
        enqueueSnackbarMessage({
          message: "Could not find a valid weekday to duplicate",
          type: "error",
        })
      );
      return;
    }

    const newEntry: CreateUITimesheetRecord = {
      ...lastEntry,
      recordId: (newRecordId.current += 1),
      recordDate: newDate,
      overtimeDuration: 0,
    };

    if (lastEntry.clockInTime) {
      newEntry.clockInTime = new Date(
        newDate.getFullYear(),
        newDate.getMonth(),
        newDate.getDate(),
        lastEntry.clockInTime.getHours(),
        lastEntry.clockInTime.getMinutes()
      );
    }

    if (lastEntry.clockOutTime) {
      newEntry.clockOutTime = new Date(
        newDate.getFullYear(),
        newDate.getMonth(),
        newDate.getDate(),
        lastEntry.clockOutTime.getHours(),
        lastEntry.clockOutTime.getMinutes()
      );
    }

    const entryWithOvertime = calculateOvertime(newEntry);
    setEntries([...entries, entryWithOvertime]);

    dispatch(
      enqueueSnackbarMessage({
        message: `Duplicated last entry to ${format(newDate, "MMM dd, yyyy")}`,
        type: "success",
      })
    );
  };

  const handleSubmitRecordModalClose = () => {
    dialogContext.showConfirmation(
      "Do you want to close this window?",
      "Entries will be lost unless you submit them.",
      ConfirmationType.accept,
      () => {
        onClose?.();
      },
      "Yes",
      "No"
    );
  };

  const handleAddBulkEntries = () => {
    const errors = validateBulkEntry();
    if (Object.keys(errors).length > 0) {
      setErrors(errors);
      return;
    }

    if (!bulkStartDate || !bulkEndDate || !bulkClockInTime || !bulkClockOutTime) return;

    const dateRange = eachDayOfInterval({ start: bulkStartDate, end: bulkEndDate });
    const newEntries: CreateUITimesheetRecord[] = [];

    dateRange.forEach((date) => {
      // Skip weekends for bulk entry
      if (isWeekend(date)) return;

      // Check if date is in the future
      if (isAfter(date, new Date())) return;

      // Check if entry already exists for this date
      const existingEntry = entries.find((entry) => entry.recordDate && isSameDay(entry.recordDate, date));
      if (existingEntry) return;

      const clockInTime = new Date(date);
      clockInTime.setHours(bulkClockInTime.getHours(), bulkClockInTime.getMinutes());

      const clockOutTime = new Date(date);
      clockOutTime.setHours(bulkClockOutTime.getHours(), bulkClockOutTime.getMinutes());

      const newEntry: CreateUITimesheetRecord = {
        recordId: (newRecordId.current += 1),
        recordDate: date,
        clockInTime,
        clockOutTime,
        isLunchIncluded: bulkLunchIncluded,
        overtimeDuration: 0,
        overtimeReason: bulkOvertimeReason,
      };

      const entryWithOvertime = calculateOvertime(newEntry);
      newEntries.push(entryWithOvertime);
    });

    if (entriesCount + newEntries.length >= DEFAULT_TIME_ENTRY_SIZE) {
      dispatch(
        enqueueSnackbarMessage({
          message: `Exceeds the maximum allowed entry count of ${DEFAULT_TIME_ENTRY_SIZE}.`,
          type: "error",
        })
      );
      return;
    }

    if (newEntries.length === 0) {
      dispatch(
        enqueueSnackbarMessage({
          message: "No valid dates to add (weekends excluded or all dates already have entries)",
          type: "warning",
        })
      );
      return;
    }

    setEntries([...entries, ...newEntries]);
    setBulkStartDate(null);
    setBulkEndDate(null);
    setBulkClockInTime(null);
    setBulkClockOutTime(null);
    setBulkOvertimeReason("");
    setErrors({});

    dispatch(
      enqueueSnackbarMessage({
        message: `Added ${newEntries.length} new entries`,
        type: "success",
      })
    );
  };

  useEffect(() => {
    setEntriesCount(entries.length);
  }, [entries]);

  return (
    <Box sx={{ height: "100%", overflow: "auto" }}>
      <LocalizationProvider dateAdapter={AdapterDateFns}>
        <Card elevation={2} sx={{ height: "100%" }}>
          <CardHeader
            subheader="Record your work hours"
            titleTypographyProps={{ variant: "h5" }}
            action={
              <>
                <Box sx={{ display: "flex", justifyContent: "space-between", alignItems: "center", gap: 1 }}>
                  <Chip
                    title="Overtime Summary of Entries"
                    label={
                      <>
                        Total: {entriesCount} day{entriesCount !== 1 ? "s" : ""}
                        {totalOvertimeHours > 0 &&
                          ` with ${totalOvertimeHours.toFixed(2)} overtime hour${totalOvertimeHours !== 1 ? "s" : ""}`}
                      </>
                    }
                    icon={<ReceiptLongIcon />}
                    variant="outlined"
                    size="medium"
                    sx={{
                      borderWidth: 2,
                      px: 1,
                    }}
                  />
                  <IconButton color="secondary" onClick={handleSubmitRecordModalClose} sx={{ mx: 1 }}>
                    <CloseIcon />
                  </IconButton>
                </Box>
              </>
            }
          />
          <CardContent>
            {DEFAULT_TIME_ENTRY_SIZE - entriesCount > 1 && (
              <Accordion defaultExpanded={true}>
                <AccordionSummary expandIcon={<ExpandMoreIcon />}>
                  <Typography variant="h6" gutterBottom>
                    Bulk Time Entry
                  </Typography>
                </AccordionSummary>
                <AccordionDetails>
                  <Grid container spacing={2}>
                    <Grid item xs={12} md={6}>
                      <DatePicker
                        label="Start Date"
                        value={bulkStartDate}
                        onChange={(newDate) => setBulkStartDate(newDate)}
                        maxDate={new Date()}
                        slotProps={{
                          textField: {
                            fullWidth: true,
                            variant: "outlined",
                            error: !!errors.startDate,
                            helperText: errors.startDate,
                          },
                        }}
                      />
                    </Grid>
                    <Grid item xs={12} md={6}>
                      <DatePicker
                        label="End Date"
                        value={bulkEndDate}
                        onChange={(newDate) => setBulkEndDate(newDate)}
                        maxDate={new Date()}
                        slotProps={{
                          textField: {
                            fullWidth: true,
                            variant: "outlined",
                            error: !!errors.endDate,
                            helperText: errors.endDate,
                          },
                        }}
                      />
                    </Grid>
                    <Grid item xs={12} md={6}>
                      <TimePicker
                        label="Clock In Time"
                        value={bulkClockInTime}
                        onChange={(newTime) => setBulkClockInTime(newTime)}
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
                        label="Clock Out Time"
                        value={bulkClockOutTime}
                        onChange={(newTime) => setBulkClockOutTime(newTime)}
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
                    <Grid item xs={12}>
                      <FormControlLabel
                        control={
                          <Switch
                            checked={bulkLunchIncluded}
                            onChange={(e) => setBulkLunchIncluded(e.target.checked)}
                            name="bulkLunchIncluded"
                            color="primary"
                          />
                        }
                        label="Include Lunch Break"
                      />
                    </Grid>
                    <Grid item xs={12}>
                      <TextField
                        label="Overtime Reason (if applicable)"
                        value={bulkOvertimeReason}
                        onChange={(e) => setBulkOvertimeReason(e.target.value)}
                        variant="outlined"
                        fullWidth
                        multiline
                        error={!!errors.bulkOvertimeReason}
                        helperText={errors.bulkOvertimeReason}
                      />
                    </Grid>
                    <Grid item xs={12}>
                      <Tooltip
                        title={
                          entriesCount < DEFAULT_TIME_ENTRY_SIZE
                            ? `Add bulk entries excluding weekends.`
                            : "Max entries reached."
                        }
                      >
                        <span>
                          <Button
                            variant="contained"
                            color="primary"
                            onClick={handleAddBulkEntries}
                            disabled={entriesCount >= DEFAULT_TIME_ENTRY_SIZE}
                            fullWidth
                            startIcon={<AddIcon />}
                          >
                            Add Bulk Entries
                          </Button>
                        </span>
                      </Tooltip>
                    </Grid>
                  </Grid>
                </AccordionDetails>
              </Accordion>
            )}

            {entriesCount > 0 && (
              <Box sx={{ p: 2, border: "1px solid #eee", borderRadius: 1 }}>
                <Divider>
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
                    <TableBody sx={{ maxHeight: "50vh", overflowY: "auto" }}>
                      {entries.map((entry) => (
                        <TableRow key={entry.recordId}>
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
                                  label={`${entry.overtimeDuration.toFixed(2)} h${
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
              </Box>
            )}
          </CardContent>
          <CardActions>
            <Box sx={{ display: "flex", width: "100%", justifyContent: "space-between" }}>
              <Box>
                <Tooltip
                  title={
                    entriesCount < DEFAULT_TIME_ENTRY_SIZE
                      ? `Add a single entry including weekends.`
                      : "Max entries reached"
                  }
                >
                  <span>
                    <Button
                      variant="outlined"
                      color="primary"
                      onClick={handleAddNewEntry}
                      disabled={entriesCount >= DEFAULT_TIME_ENTRY_SIZE}
                      startIcon={<AddIcon />}
                      sx={{ mx: 1 }}
                    >
                      ADD A SINGLE ENTRY
                    </Button>
                  </span>
                </Tooltip>
                {/* Disabled until next development phase */}
                {/* <Tooltip
                  title={
                    entriesCount < DEFAULT_TIME_ENTRY_SIZE
                      ? `Duplicate the last entry with previous date.`
                      : "Max entries reached"
                  }
                >
                  <span>
                    <Button
                      variant="outlined"
                      color="secondary"
                      onClick={handleDuplicateLastEntry}
                      startIcon={<ReceiptLongIcon />}
                      disabled={entriesCount === 0 || entriesCount >= DEFAULT_TIME_ENTRY_SIZE}
                      sx={{ mx: 1 }}
                    >
                      DUPLICATE LAST ENTRY
                    </Button>
                  </span>
                </Tooltip> */}
              </Box>
              <Button
                variant="contained"
                color="secondary"
                onClick={handleBatchSubmit}
                sx={{ width: "160px", mx: 1 }}
                startIcon={<PublishIcon />}
                disabled={entriesCount === 0}
              >
                Submit Entries
              </Button>
            </Box>
          </CardActions>
        </Card>

        <Dialog open={editDialogOpen} onClose={() => setEditDialogOpen(false)} maxWidth="md" fullWidth>
          <DialogTitle>
            <Box sx={{ display: "flex", justifyContent: "space-between", alignItems: "center", gap: 1 }}>
              {isAddingNew ? "Add New Time Entry" : "Edit Time Entry"}{" "}
              <IconButton color="secondary" onClick={() => setEditDialogOpen(false)} sx={{ mx: 1 }}>
                <CloseIcon />
              </IconButton>
            </Box>
          </DialogTitle>
          <DialogContent>
            {editingEntry && (
              <Grid container spacing={2} sx={{ mt: 1 }}>
                <Grid item xs={12} md={6}>
                  <DatePicker
                    label="Date"
                    value={editingEntry.recordDate}
                    onChange={(newDate) => handleEditFieldChange("recordDate", newDate)}
                    maxDate={new Date()}
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
            <Button
              onClick={() => setEditDialogOpen(false)}
              color="secondary"
              variant="outlined"
              startIcon={<CloseIcon />}
            >
              Cancel
            </Button>
            <Button
              onClick={handleSaveEditedEntry}
              color="primary"
              startIcon={isAddingNew ? <AddIcon /> : <HourglassBottom />}
              variant="contained"
            >
              {isAddingNew ? "Add Entry" : "Save Changes"}
            </Button>
          </DialogActions>
        </Dialog>
      </LocalizationProvider>
    </Box>
  );
};

export default SubmitRecordModal;

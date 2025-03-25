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
  Typography,
  FormControl,
  CardContent,
  DialogTitle,
  DialogActions,
  DialogContent,
  TableContainer,
  InputAdornment,
  FormControlLabel,
} from "@mui/material";
import AddIcon from "@mui/icons-material/Add";
import EditIcon from "@mui/icons-material/Edit";
import CloseIcon from "@mui/icons-material/Close";
import React, { useState, useEffect } from "react";
import DeleteIcon from "@mui/icons-material/Delete";
import PublishIcon from "@mui/icons-material/Publish";
import { DatePicker } from "@mui/x-date-pickers/DatePicker";
import { TimePicker } from "@mui/x-date-pickers/TimePicker";
import RestartAltIcon from "@mui/icons-material/RestartAlt";
import { AdapterDateFns } from "@mui/x-date-pickers/AdapterDateFns";
import { format, differenceInMinutes, isWeekend, startOfDay } from "date-fns";
import { LocalizationProvider } from "@mui/x-date-pickers/LocalizationProvider";

interface TimeEntry {
  id: string;
  date: Date | null;
  clockInTime: Date | null;
  clockOutTime: Date | null;
  lunchBreakTaken: boolean;
  overtimeHours: number;
  overtimeReason: string;
}

interface TimeTrackingFormProps {
  regularWorkHoursPerDay?: number;
  onClose?: () => void;
}

const SubmitRecordModal: React.FC<TimeTrackingFormProps> = ({ regularWorkHoursPerDay = 8, onClose }) => {
  const regularWorkMinutes = regularWorkHoursPerDay * 60;
  const [entries, setEntries] = useState<TimeEntry[]>([]);
  const [currentEntry, setCurrentEntry] = useState<TimeEntry>(createNewEntry());
  const [errors, setErrors] = useState<Record<string, string>>({});
  const [editDialogOpen, setEditDialogOpen] = useState(false);
  const [editingEntry, setEditingEntry] = useState<TimeEntry | null>(null);

  function createNewEntry(): TimeEntry {
    return {
      id: Date.now().toString(),
      date: new Date(),
      clockInTime: null,
      clockOutTime: null,
      lunchBreakTaken: true,
      overtimeHours: 0,
      overtimeReason: "",
    };
  }

  useEffect(() => {
    setCurrentEntry(calculateOvertime(currentEntry));
  }, [
    currentEntry.clockInTime,
    currentEntry.clockOutTime,
    currentEntry.lunchBreakTaken,
    currentEntry.date,
    regularWorkMinutes,
  ]);

  const handleDateChange = (newDate: Date | null) => {
    setCurrentEntry({ ...currentEntry, date: newDate });
  };

  const handleClockInChange = (newTime: Date | null) => {
    setCurrentEntry({ ...currentEntry, clockInTime: newTime });
  };

  const handleClockOutChange = (newTime: Date | null) => {
    setCurrentEntry({ ...currentEntry, clockOutTime: newTime });
  };

  const handleSwitchChange = (event: React.ChangeEvent<HTMLInputElement>) => {
    setCurrentEntry({ ...currentEntry, lunchBreakTaken: event.target.checked });
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

  const handleDeleteEntry = (id: string) => {
    setEntries(entries.filter((entry) => entry.id !== id));
  };

  const handleBatchSubmit = () => {
    if (entries.length === 0) {
      const entryErrors = validateEntry(currentEntry);

      if (Object.keys(entryErrors).length === 0) {
        setCurrentEntry(createNewEntry());
      } else {
        setErrors(entryErrors);
      }
    } else {
      setEntries([]);
      setCurrentEntry(createNewEntry());
    }
  };

  const handleReset = () => {
    setCurrentEntry(createNewEntry());
    setErrors({});
  };

  const openEditDialog = (entry: TimeEntry) => {
    setEditingEntry(entry);
    setEditDialogOpen(true);
  };

  const calculateOvertime = (entry: TimeEntry): TimeEntry => {
    if (entry.clockInTime && entry.clockOutTime && entry.date) {
      const totalMinutes = differenceInMinutes(entry.clockOutTime, entry.clockInTime);
      const lunchBreakMinutes = entry.lunchBreakTaken ? 60 : 0;
      const workMinutes = Math.max(0, totalMinutes - lunchBreakMinutes);

      let overtimeMinutes = 0;
      if (isWeekend(entry.date)) {
        overtimeMinutes = workMinutes;
      } else {
        overtimeMinutes = Math.max(0, workMinutes - regularWorkMinutes);
      }

      const overtimeHours = parseFloat((overtimeMinutes / 60).toFixed(2));

      // Clear overtime reason if no overtime
      const overtimeReason =
        overtimeHours > 0 ? entry.overtimeReason || (isWeekend(entry.date) ? "Weekend work" : "") : "";

      return {
        ...entry,
        overtimeHours,
        overtimeReason,
      };
    }
    return entry;
  };

  // Update the handleSaveEditedEntry function to recalculate before saving
  const handleSaveEditedEntry = () => {
    if (editingEntry) {
      const updatedEntry = calculateOvertime(editingEntry);
      const entryErrors = validateEntry(updatedEntry);

      // Remove overtime reason error if there are no overtime hours
      if (updatedEntry.overtimeHours <= 0 && entryErrors.overtimeReason) {
        delete entryErrors.overtimeReason;
      }

      if (Object.keys(entryErrors).length === 0) {
        setEntries(entries.map((entry) => (entry.id === updatedEntry.id ? updatedEntry : entry)));
        setEditDialogOpen(false);
        setEditingEntry(null);
        setErrors({});
      } else {
        setErrors(entryErrors);
      }
    }
  };

  // Update the edit dialog to recalculate on field changes
  const handleEditFieldChange = (field: keyof TimeEntry, value: any) => {
    if (editingEntry) {
      const updatedEntry = {
        ...editingEntry,
        [field]: value,
      };

      // Recalculate overtime when time-related fields change
      if (["date", "clockInTime", "clockOutTime", "lunchBreakTaken"].includes(field)) {
        setEditingEntry(calculateOvertime(updatedEntry));
      } else {
        setEditingEntry(updatedEntry);
      }
    }
  };

  // Update the validateEntry function to not require reason when no overtime
  const validateEntry = (entry: TimeEntry): Record<string, string> => {
    const entryErrors: Record<string, string> = {};

    if (!entry.date) {
      entryErrors.date = "Date is required";
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

    // Only require reason if there are overtime hours
    if (entry.overtimeHours > 0 && !entry.overtimeReason.trim()) {
      entryErrors.overtimeReason = "Reason is required for overtime hours";
    }

    if (entry.date) {
      const entryDate = startOfDay(entry.date).getTime();
      const conflictingEntry = entries.find(
        (e) => e.id !== entry.id && e.date && startOfDay(e.date).getTime() === entryDate
      );

      if (conflictingEntry) {
        entryErrors.date = "You already have an entry for this date";
      }
    }

    return entryErrors;
  };

  const totalDays = entries.length;
  const totalOvertimeHours = entries.reduce((sum, entry) => sum + entry.overtimeHours, 0);

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
                    value={currentEntry.date}
                    onChange={handleDateChange}
                    slotProps={{
                      textField: {
                        fullWidth: true,
                        variant: "outlined",
                        error: !!errors.date,
                        helperText: errors.date || (currentEntry.date && isWeekend(currentEntry.date) ? "Weekend" : ""),
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
                        checked={currentEntry.lunchBreakTaken}
                        onChange={handleSwitchChange}
                        name="lunchBreakTaken"
                        color="primary"
                      />
                    }
                    label="Lunch Break"
                  />
                </Grid>
                <Grid item xs={12} md={6} lg={3}>
                  {currentEntry.overtimeHours > 0 && (
                    <FormControl fullWidth error={!!errors.overtimeReason} variant="outlined">
                      <TextField
                        label="Reason for Overtime"
                        value={currentEntry.overtimeReason}
                        onChange={handleOvertimeReasonChange}
                        error={!!errors.overtimeReason}
                        helperText={errors.overtimeReason}
                        variant="outlined"
                        multiline
                        rows={2}
                        required
                        sx={{ textAlign: "center" }}
                        InputProps={{
                          startAdornment: currentEntry.overtimeHours > 0 && (
                            <InputAdornment position="end">
                              <Tooltip title={currentEntry.overtimeReason}>
                                <Chip
                                  label={`${currentEntry.overtimeHours} hr${
                                    currentEntry.overtimeHours !== 1 ? "s" : ""
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
                        <TableRow key={entry.id}>
                          <TableCell>
                            {entry.date ? format(entry.date, "MMM dd, yyyy") : ""}
                            {entry.date && isWeekend(entry.date) && (
                              <Chip size="small" label="Weekend" color="secondary" sx={{ ml: 1 }} />
                            )}
                          </TableCell>
                          <TableCell>{entry.clockInTime ? format(entry.clockInTime, "hh:mm a") : ""}</TableCell>
                          <TableCell>{entry.clockOutTime ? format(entry.clockOutTime, "hh:mm a") : ""}</TableCell>
                          <TableCell>{entry.lunchBreakTaken ? "Yes" : "No"}</TableCell>
                          <TableCell>
                            {entry.overtimeHours > 0 ? (
                              <Tooltip title={entry.overtimeReason}>
                                <Chip
                                  label={`${entry.overtimeHours.toFixed(2)} hr${entry.overtimeHours !== 1 ? "s" : ""}`}
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
                              <IconButton size="small" color="error" onClick={() => handleDeleteEntry(entry.id)}>
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
                  <Typography variant="body2">
                    Total: {totalDays} day{totalDays !== 1 ? "s" : ""}
                    {totalOvertimeHours > 0 &&
                      ` with ${totalOvertimeHours.toFixed(2)} overtime hour${totalOvertimeHours !== 1 ? "s" : ""}`}
                  </Typography>
                </Box>
              </Box>
            )}
          </CardContent>
        </Card>

        {/* Dialog for editing entries */}
        <Dialog open={editDialogOpen} onClose={() => setEditDialogOpen(false)} maxWidth="md" fullWidth>
          <DialogTitle>Edit Time Entry</DialogTitle>
          <DialogContent>
            {editingEntry && (
              <Grid container spacing={2} sx={{ mt: 1 }}>
                <Grid item xs={12} md={6}>
                  <DatePicker
                    label="Date"
                    value={editingEntry.date}
                    onChange={(newDate) => handleEditFieldChange("date", newDate)}
                    slotProps={{
                      textField: {
                        fullWidth: true,
                        variant: "outlined",
                        error: !!errors.date,
                        helperText: errors.date,
                      },
                    }}
                  />
                </Grid>
                <Grid item xs={12} md={6}>
                  <FormControlLabel
                    control={
                      <Switch
                        checked={editingEntry.lunchBreakTaken}
                        onChange={(e) => handleEditFieldChange("lunchBreakTaken", e.target.checked)}
                        name="lunchBreakTaken"
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
                {editingEntry.overtimeHours > 0 && (
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
                      required={editingEntry.overtimeHours > 0}
                      InputProps={{
                        startAdornment: editingEntry.overtimeHours > 0 && (
                          <InputAdornment position="start">
                            <Chip
                              label={`OT: ${editingEntry.overtimeHours.toFixed(2)} hrs`}
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

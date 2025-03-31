import { useState, useEffect, ChangeEvent, FormEvent } from "react";
import {
  Box,
  Stack,
  Button,
  TextField,
  Typography,
  Autocomplete,
  CircularProgress,
  createFilterOptions,
} from "@mui/material";
import {
  DatePicker,
  TimePicker,
  LocalizationProvider,
} from "@mui/x-date-pickers";
import dayjs, { Dayjs } from "dayjs";
import { useAppDispatch, useAppSelector } from "@slices/store";
import { AdapterDayjs } from "@mui/x-date-pickers/AdapterDayjs";
import { enqueueSnackbarMessage } from "@slices/commonSlice/common";
import { addMeetings, fetchMeetingTypes } from "@slices/meetingSlice/meeting";

// Meeting Request data type
interface MeetingRequest {
  meetingType: string;
  customerName: string;
  customTitle: string;
  description: string;
  date: Dayjs | null;
  startTime: Dayjs | null;
  endTime: Dayjs | null;
  timeZone: string;
  internalParticipants: string;
  externalParticipants: string;
}

// Email validation function
const isValidEmail = (
  email: string,
  isInternalParticipant: boolean = false
): boolean => {
  const regex = /^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$/;
  return isInternalParticipant
    ? /^[a-z0-9._%+-]+@wso2\.com$/i.test(email)
    : regex.test(email);
};

// Custom hook for meeting form
function useMeetingForm() {
  const dispatch = useAppDispatch();
  const submitState = useAppSelector((state) => state.meeting.submitState);

  const [meetingRequest, setMeetingRequest] = useState<MeetingRequest>({
    meetingType: "",
    customerName: "",
    customTitle: "",
    description: "",
    date: null,
    startTime: null,
    endTime: null,
    timeZone: Intl.DateTimeFormat().resolvedOptions().timeZone,
    internalParticipants: "",
    externalParticipants: "",
  });

  // Participants email error states
  const [externalParticipantsError, setExternalParticipantsError] = useState<
    string | null
  >(null);
  const [internalParticipantsError, setInternalParticipantsError] = useState<
    string | null
  >(null);

  // Meeting form event handlers
  const handleTextChange = (
    e: ChangeEvent<HTMLInputElement | HTMLTextAreaElement>
  ) => {
    const { name, value } = e.target;
    setMeetingRequest((prev) => ({ ...prev, [name]: value }));
    if (name === "internalParticipants") {
      const wso2Emails = value.split(",").map((email) => email.trim());
      const allValidWso2Emails = wso2Emails.every(
        (email) => isValidEmail(email, true) || email === ""
      );
      setInternalParticipantsError(
        allValidWso2Emails ? null : "One or more emails are invalid."
      );
    } else if (name === "externalParticipants") {
      const externalEmails = value.split(",").map((email) => email.trim());
      const allValidExternalEmails = externalEmails.every(
        (email) => isValidEmail(email) || email === ""
      );
      setExternalParticipantsError(
        allValidExternalEmails ? null : "One or more emails are invalid."
      );
    }
  };
  const handleDateChange = (newDate: Dayjs | null) =>
    setMeetingRequest((prev) => ({ ...prev, date: newDate }));
  const handleStartTimeChange = (newTime: Dayjs | null) =>
    setMeetingRequest((prev) => ({ ...prev, startTime: newTime }));
  const handleEndTimeChange = (newTime: Dayjs | null) =>
    setMeetingRequest((prev) => ({ ...prev, endTime: newTime }));

  // Meeting form submit handler
  const handleSubmit = (e: FormEvent<HTMLFormElement>) => {
    e.preventDefault();

    // Validate required fields
    if (!meetingRequest.meetingType || !meetingRequest.customerName) {
      dispatch(
        enqueueSnackbarMessage({
          message: "Please fill the meeting type and customer name.",
          type: "error",
        })
      );
      return;
    }
    if (!meetingRequest.customTitle) {
      dispatch(
        enqueueSnackbarMessage({
          message: "Please fill the title.",
          type: "error",
        })
      );
      return;
    }
    if (
      !meetingRequest.date ||
      !meetingRequest.startTime ||
      !meetingRequest.endTime
    ) {
      dispatch(
        enqueueSnackbarMessage({
          message: "Please select a date, start time, and end time.",
          type: "error",
        })
      );
      return;
    }
    if (meetingRequest.date.isBefore(dayjs(), "day")) {
      dispatch(
        enqueueSnackbarMessage({
          message: "Meeting date cannot be in the past.",
          type: "error",
        })
      );
      return;
    }
    if (meetingRequest.startTime.isAfter(meetingRequest.endTime)) {
      dispatch(
        enqueueSnackbarMessage({
          message: "Start time cannot be later than end time.",
          type: "error",
        })
      );
      return;
    }
    if (internalParticipantsError || externalParticipantsError) {
      dispatch(
        enqueueSnackbarMessage({
          message: "One or more email addresses are invalid.",
          type: "error",
        })
      );
      return;
    }
    if (
      !meetingRequest.internalParticipants &&
      !meetingRequest.externalParticipants
    ) {
      dispatch(
        enqueueSnackbarMessage({
          message: "Please add at least one attendee.",
          type: "error",
        })
      );
      return;
    }

    // /Format meeting data and dispatch action
    const formattedData = {
      title:
        `${meetingRequest.meetingType} - ${meetingRequest.customerName} - ${meetingRequest.customTitle}`.trim(),
      description: meetingRequest.description,
      startTime:
        meetingRequest.date && meetingRequest.startTime
          ? meetingRequest.date
              .hour(meetingRequest.startTime.hour())
              .minute(meetingRequest.startTime.minute())
              .second(0)
              .toISOString()
          : "",
      endTime:
        meetingRequest.date && meetingRequest.endTime
          ? meetingRequest.date
              .hour(meetingRequest.endTime.hour())
              .minute(meetingRequest.endTime.minute())
              .second(0)
              .toISOString()
          : "",
      timeZone: meetingRequest.timeZone,
      internalParticipants: meetingRequest.internalParticipants
        .split(",")
        .map((email) => email.trim()),
      externalParticipants: meetingRequest.externalParticipants
        .split(",")
        .map((email) => email.trim()),
    };
    dispatch(addMeetings(formattedData));
  };

  return {
    setMeetingRequest,
    handleTextChange,
    handleDateChange,
    handleStartTimeChange,
    handleEndTimeChange,
    handleSubmit,
    meetingRequest,
    internalParticipantsError,
    externalParticipantsError,
    submitState,
  };
}

// Meeting form component
function MeetingForm() {
  // Fetch meeting types
  const dispatch = useAppDispatch();
  const meetingTypes =
    useAppSelector((state) => state.meeting.meetingTypes) || [];
  useEffect(() => {
    dispatch(fetchMeetingTypes());
  }, [dispatch]);

  // Autocomplete filter options
  const filter = createFilterOptions<string>();
  const [inputValue, setInputValue] = useState("");

  // Meeting form hooks
  const {
    setMeetingRequest,
    handleTextChange,
    handleDateChange,
    handleStartTimeChange,
    handleEndTimeChange,
    handleSubmit,
    meetingRequest,
    internalParticipantsError,
    externalParticipantsError,
    submitState,
  } = useMeetingForm();

  return (
    <LocalizationProvider dateAdapter={AdapterDayjs}>
      <Stack
        component="form"
        onSubmit={handleSubmit}
        spacing={1.5}
        sx={(theme) => ({
          width: "100%",
          maxWidth: 500,
          minWidth: 350,
          px: 2,
          pt: 1.5,
          pb: 2,
          borderRadius: 3,
          border: 1,
          borderColor: "divider",
          boxShadow:
            theme.palette.mode === "dark"
              ? "0px 0px 10px rgba(120, 125, 129, 0.5)"
              : 10,
          overflow: "auto",
        })}
      >
        <Typography
          variant="h5"
          fontWeight="bold"
          color="primary.main"
          align="center"
        >
          Create Meeting
        </Typography>

        <TextField
          name="customTitle"
          label="Title"
          value={meetingRequest.customTitle}
          onChange={handleTextChange}
          required
          fullWidth
        />

        <Box sx={{ display: "flex", gap: 2 }}>
          <Autocomplete
            sx={{ flex: 1 }}
            freeSolo
            clearOnEscape
            options={meetingTypes}
            filterOptions={(options, params) => {
              const filtered = filter(options, params);
              const { inputValue } = params;
              const isExisting = options.includes(inputValue);
              if (inputValue !== "" && !isExisting) {
                filtered.push(`Add "${inputValue}"`); // Add custom input option
              }
              return filtered;
            }}
            value={meetingRequest.meetingType}
            inputValue={inputValue} // Bind inputValue to state
            onInputChange={(_, newInputValue) => {
              setInputValue(newInputValue); // Update inputValue as the user types
              setMeetingRequest((prev) => ({
                ...prev,
                meetingType: newInputValue, // Immediately update meetingType in state
              }));
            }}
            onChange={(_, newValue) => {
              let finalValue = newValue;
              if (
                typeof newValue === "string" &&
                newValue.startsWith('Add "')
              ) {
                finalValue = newValue.slice(5, -1); // Extract custom input
              }
              setMeetingRequest((prev) => ({
                ...prev,
                meetingType: finalValue || "", // Update state when user selects from options
              }));
              setInputValue(finalValue || ""); // Immediately update input field
            }}
            renderInput={(params) => (
              <TextField
                {...params}
                name="meetingType"
                label="Meeting Type"
                autoCorrect="off"
                autoCapitalize="none"
                spellCheck={false}
                required
                fullWidth
              />
            )}
          />

          <TextField
            sx={{ flex: 1 }}
            name="customerName"
            label="Customer Name"
            value={meetingRequest.customerName}
            onChange={handleTextChange}
            autoCorrect="off"
            autoCapitalize="none"
            spellCheck={false}
            required
            fullWidth
          />
        </Box>

        <TextField
          name="description"
          label="Meeting Description"
          value={meetingRequest.description}
          onChange={handleTextChange}
          autoCorrect="off"
          autoCapitalize="none"
          spellCheck={false}
          fullWidth
          multiline
          rows={2}
        />

        <DatePicker
          format="DD/MM/YYYY"
          label="Meeting Date *"
          value={meetingRequest.date}
          onChange={handleDateChange}
          minDate={dayjs()}
        />

        <Box sx={{ display: "flex", gap: 2, pb: 0.5 }}>
          <TimePicker
            label="Start Time *"
            value={meetingRequest.startTime}
            onChange={handleStartTimeChange}
            sx={{ flex: 1 }}
          />

          <TimePicker
            label="End Time *"
            value={meetingRequest.endTime}
            onChange={handleEndTimeChange}
            sx={{ flex: 1 }}
          />
        </Box>

        <TextField
          name="internalParticipants"
          label="WSO2 Participants (comma-separated emails)"
          autoCorrect="off"
          autoCapitalize="none"
          spellCheck={false}
          value={meetingRequest.internalParticipants}
          onChange={handleTextChange}
          required
          fullWidth
          error={!!internalParticipantsError}
          helperText={internalParticipantsError || " "}
        />

        <TextField
          name="externalParticipants"
          label="External Participants (comma-separated emails)"
          autoCorrect="off"
          autoCapitalize="none"
          spellCheck={false}
          value={meetingRequest.externalParticipants}
          onChange={handleTextChange}
          required
          fullWidth
          error={!!externalParticipantsError}
          helperText={externalParticipantsError || " "}
        />

        <Button
          type="submit"
          variant="contained"
          fullWidth
          disabled={submitState === "loading"}
          sx={{ position: "relative", height: 40 }}
        >
          {submitState === "loading" ? (
            <CircularProgress size={24} sx={{ color: "white" }} />
          ) : (
            "Create Meeting"
          )}
        </Button>
      </Stack>
    </LocalizationProvider>
  );
}
function createMeeting() {
  return (
    <Box
      sx={{
        display: "grid",
        gridTemplateColumns: { xs: "1fr", md: "1fr 1fr" },
        gap: 2,
        height: "100%",
        alignItems: "center",
        justifyContent: "center",
      }}
    >
      <Box
        sx={{
          display: "flex",
          justifyContent: "center",
          alignItems: "center",
          height: "auto",
          px: 1.5,
          py: 1.5,
        }}
      >
        <MeetingForm />
      </Box>

      <Box
        sx={{
          display: { xs: "none", md: "block" },
          backgroundImage: `url(${
            require("@assets/images/sales-team.svg").default
          })`,
          backgroundSize: "cover",
          backgroundPosition: "center",
          height: "80%",
        }}
      />
    </Box>
  );
}

export default createMeeting;

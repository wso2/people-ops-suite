import { useEffect, useState } from "react";
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
import * as yup from "yup";
import { useFormik } from "formik";
import dayjs, { Dayjs } from "dayjs";
import { useAppDispatch, useAppSelector } from "@slices/store";
import { AdapterDayjs } from "@mui/x-date-pickers/AdapterDayjs";
import { addMeetings, fetchMeetingTypes } from "@slices/meetingSlice/meeting";

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

const validationSchema = yup.object({
  meetingType: yup.string().trim().required("Meeting type is required"),
  customerName: yup.string().trim().required("Customer name is required"),
  customTitle: yup.string().trim().required("Title is required"),
  description: yup.string().trim(),
  date: yup.date().typeError("Invalid date").required("Date is required"),
  startTime: yup
    .mixed<Dayjs>()
    .required("Start time is required")
    .test("is-future-time", "Start time must be in the future", (value) => {
      return value ? value.isAfter(dayjs()) : false;
    }),
  endTime: yup
    .mixed<Dayjs>()
    .required("End time is required")
    .test(
      "is-after-startTime",
      "End time must be after start time",
      function (value) {
        return value && this.parent.startTime
          ? value.isAfter(this.parent.startTime)
          : false;
      }
    ),
  timeZone: yup.string().required("Time zone is required"),
  internalParticipants: yup
    .string()
    .required("Required")
    .test("valid-internal-emails", "Only @wso2.com emails allowed", (value) => {
      if (!value) return false;
      const emails = value.split(",").map((email) => email.trim());
      return emails.every(
        (email) =>
          yup.string().email().isValidSync(email) && email.endsWith("@wso2.com")
      );
    }),
  externalParticipants: yup
    .string()
    .required("Required")
    .test("valid-external-emails", "Invalid email format", (value) => {
      if (!value) return false;
      const emails = value.split(",").map((email) => email.trim());
      return emails.every((email) => yup.string().email().isValidSync(email));
    }),
});

function MeetingForm() {
  const dispatch = useAppDispatch();

  const meetingTypes =
    useAppSelector((state) => state.meeting.meetingTypes) || [];

  useEffect(() => {
    if (!meetingTypes.length) {
      dispatch(fetchMeetingTypes());
    }
  }, [dispatch, meetingTypes.length]);

  const [loading, setLoading] = useState(false);

  const filter = createFilterOptions<string>();
  const [inputValue, setInputValue] = useState("");

  const formik = useFormik<MeetingRequest>({
    initialValues: {
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
    },
    validationSchema: validationSchema,
    validateOnChange: true,

    onSubmit: async (values, { resetForm }) => {
      setLoading(true);
      try {
        const formattedData = {
          title:
            `${values.meetingType} - ${values.customerName} - ${values.customTitle}`.trim(),
          description: values.description,
          startTime:
            values.date && values.startTime
              ? values.date
                  .hour(values.startTime.hour())
                  .minute(values.startTime.minute())
                  .second(0)
                  .toISOString()
              : "",
          endTime:
            values.date && values.endTime
              ? values.date
                  .hour(values.endTime.hour())
                  .minute(values.endTime.minute())
                  .second(0)
                  .toISOString()
              : "",
          timeZone: Intl.DateTimeFormat().resolvedOptions().timeZone,
          internalParticipants: values.internalParticipants
            .split(",")
            .map((email) => email.trim())
            .filter(Boolean),
          externalParticipants: values.externalParticipants
            .split(",")
            .map((email) => email.trim())
            .filter(Boolean),
        };
        await dispatch(addMeetings(formattedData));
        resetForm();
        setInputValue("");
      } finally {
        setLoading(false);
      }
    },
  });
  return (
    <LocalizationProvider dateAdapter={AdapterDayjs}>
      <Stack
        component="form"
        onSubmit={formik.handleSubmit}
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
          fullWidth
          required
          id="customTitle"
          name="customTitle"
          label="Title"
          value={formik.values.customTitle}
          onChange={formik.handleChange}
          onBlur={formik.handleBlur}
          error={
            formik.touched.customTitle && Boolean(formik.errors.customTitle)
          }
        />

        <Box sx={{ display: "flex", gap: 2 }}>
          <Autocomplete
            sx={{ flex: 1 }}
            freeSolo
            clearOnEscape
            options={[...new Set(meetingTypes)]}
            filterOptions={(options, params) => {
              const filtered = filter(options, params);
              const { inputValue } = params;
              if (inputValue !== "" && !options.includes(inputValue)) {
                filtered.push(`Add "${inputValue}"`);
              }
              return filtered;
            }}
            value={formik.values.meetingType}
            inputValue={inputValue}
            onInputChange={(_, newInputValue, reason) => {
              if (reason === "input") {
                setInputValue(newInputValue);
              }
            }}
            onChange={(_, newValue) => {
              let finalValue = newValue;
              if (
                typeof newValue === "string" &&
                newValue.startsWith('Add "')
              ) {
                finalValue = newValue.slice(5, -1);
              }
              setInputValue(finalValue || "");
              formik.setFieldValue("meetingType", finalValue || "");
            }}
            renderInput={(params) => (
              <TextField
                {...params}
                id="meetingType"
                name="meetingType"
                label="Meeting Type"
                value={formik.values.meetingType}
                onChange={formik.handleChange}
                onBlur={formik.handleBlur}
                error={
                  formik.touched.meetingType &&
                  Boolean(formik.errors.meetingType)
                }
                required
                fullWidth
              />
            )}
          />

          <TextField
            fullWidth
            required
            id="customerName"
            name="customerName"
            label="Customer Name"
            autoCorrect="off"
            autoCapitalize="none"
            spellCheck={false}
            value={formik.values.customerName}
            onChange={formik.handleChange}
            onBlur={formik.handleBlur}
            error={
              formik.touched.customerName && Boolean(formik.errors.customerName)
            }
            sx={{ flex: 1 }}
          />
        </Box>

        <TextField
          fullWidth
          id="description"
          name="description"
          label="Meeting Description"
          autoCorrect="off"
          autoCapitalize="none"
          spellCheck={false}
          multiline
          rows={2}
          value={formik.values.description}
          onChange={formik.handleChange}
          onBlur={formik.handleBlur}
          error={
            formik.touched.description && Boolean(formik.errors.description)
          }
        />

        <DatePicker
          name="date"
          format="DD/MM/YYYY"
          label="Meeting Date *"
          value={formik.values.date}
          minDate={dayjs()}
          onChange={(value) => {
            formik.setFieldValue("date", value);
            formik.setFieldTouched("date", true, false);
          }}
          onAccept={(value) => {
            formik.setFieldValue("date", value);
            formik.setFieldTouched("date", true, false);
          }}
          // onAccept={(value) => formik.setFieldValue("date", value)}
          slotProps={{
            textField: {
              error: Boolean(formik.touched.date && formik.errors.date),
            },
          }}
        />

        <Box sx={{ display: "flex", gap: 2, pb: 0.5 }}>
          <TimePicker
            name="startTime"
            label="Start Time *"
            value={formik.values.startTime}
            onChange={(value) => {
              formik.setFieldValue("startTime", value);
              formik.setFieldTouched("startTime", true, false);
            }}
            onAccept={(value) => {
              formik.setFieldValue("startTime", value);
              formik.setFieldTouched("startTime", true, false);
            }}
            slotProps={{
              textField: {
                error: Boolean(
                  formik.touched.startTime && formik.errors.startTime
                ),
              },
            }}
            sx={{ flex: 1 }}
          />

          <TimePicker
            name="endTime"
            label="End Time *"
            value={formik.values.endTime}
            onChange={(value) => {
              formik.setFieldValue("endTime", value);
              formik.setFieldTouched("endTime", true, false);
            }}
            onAccept={(value) => {
              formik.setFieldValue("endTime", value);
              formik.setFieldTouched("endTime", true, false);
            }}
            slotProps={{
              textField: {
                error: Boolean(formik.touched.endTime && formik.errors.endTime),
              },
            }}
            sx={{ flex: 1 }}
          />
        </Box>

        <TextField
          fullWidth
          required
          id="internalParticipants"
          name="internalParticipants"
          label="WSO2 Participants (comma-separated emails)"
          value={formik.values.internalParticipants}
          onChange={formik.handleChange}
          onBlur={formik.handleBlur}
          error={
            formik.touched.internalParticipants &&
            Boolean(formik.errors.internalParticipants)
          }
          helperText={
            formik.touched.internalParticipants &&
            formik.errors.internalParticipants
          }
          autoCorrect="off"
          autoCapitalize="none"
          spellCheck={false}
        />

        <TextField
          fullWidth
          required
          id="externalParticipants"
          name="externalParticipants"
          label="External Participants (comma-separated emails)"
          value={formik.values.externalParticipants}
          onChange={formik.handleChange}
          onBlur={formik.handleBlur}
          error={
            formik.touched.externalParticipants &&
            Boolean(formik.errors.externalParticipants)
          }
          helperText={
            formik.touched.externalParticipants &&
            formik.errors.externalParticipants
          }
          autoCorrect="off"
          autoCapitalize="none"
          spellCheck={false}
        />

        <Button
          type="submit"
          variant="contained"
          fullWidth
          disabled={loading || !formik.isValid || !formik.dirty}
          sx={{ position: "relative", height: 40 }}
        >
          {loading ? <CircularProgress size={24} /> : "Create Meeting"}
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

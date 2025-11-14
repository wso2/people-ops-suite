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
  Switch,
  Avatar,
  Button,
  Collapse,
  MenuItem,
  TextField,
  Typography,
  Autocomplete,
  FormHelperText,
  CircularProgress,
  createFilterOptions,
} from "@mui/material";
import * as yup from "yup";
import { useFormik } from "formik";
import dayjs, { Dayjs } from "dayjs";
import utc from "dayjs/plugin/utc";
import timezone from "dayjs/plugin/timezone";
import isSameOrAfter from "dayjs/plugin/isSameOrAfter";
import { useEffect, useState, useMemo } from "react";
import { ConfirmationType, State } from "@/types/types";
import { useAppDispatch, useAppSelector } from "@slices/store";
import { fetchCustomers } from "@slices/customerSlice/customer";
import { AdapterDayjs } from "@mui/x-date-pickers/AdapterDayjs";
import { fetchEmployees } from "@slices/employeeSlice/employee";
import { useConfirmationModalContext } from "@context/DialogContext";
import { fetchContacts, resetContacts } from "@slices/contactSlice/contact";
import { addMeetings, fetchMeetingTypes } from "@slices/meetingSlice/meeting";
import { DatePicker, TimePicker, LocalizationProvider } from "@mui/x-date-pickers";
import { useAppAuthContext } from "@root/src/context/AuthContext";
import ErrorHandler from "@root/src/component/common/ErrorHandler";

// Extend dayjs with timezone and UTC functionality
dayjs.extend(utc);
dayjs.extend(timezone);
dayjs.extend(isSameOrAfter);

const RECURRENCE_FREQUENCIES = ["DAILY", "WEEKLY", "MONTHLY"] as const;
type RecurrenceFrequencyCore = (typeof RECURRENCE_FREQUENCIES)[number];
type RecurrenceFrequency = RecurrenceFrequencyCore | "";

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
  isRecurring: boolean;
  recurrenceFrequency: RecurrenceFrequency;
  recurrenceCount: number | "";
}

function formatDateTime(date: Dayjs | null, time: Dayjs | null, timeZone: string): string | null {
  if (!date || !time || !dayjs(date).isValid() || !dayjs(time).isValid()) return null;
  
  try {
    const combined = date.hour(time.hour()).minute(time.minute()).second(0);
    const zonedTime = dayjs.tz(combined.format("YYYY-MM-DDTHH:mm:ss"), timeZone);
    return zonedTime.utc().toISOString();
  } catch (error) {
    console.warn("Error formatting date time:", error);
    return null;
  }
}

const validationSchema = yup.object({
  meetingType: yup.string().trim().required("Meeting type is required"),
  customerName: yup.string().trim().required("Customer name is required"),
  customTitle: yup.string().trim(),
  description: yup.string().trim(),
  date: yup
    .mixed<Dayjs>()
    .required("Date is required")
    .test("is-valid-date", "Invalid date", (value) => dayjs(value).isValid())
    .test("is-future-date", "Date must be in the future", function (value) {
      const selectedTimeZone = this.parent.timeZone;     
      if (!value || !selectedTimeZone) return false;
      const selectedDate = dayjs.tz(value.format("YYYY-MM-DD"), selectedTimeZone);
      const currentDate  = dayjs().tz(selectedTimeZone).startOf("day");
      return selectedDate.isSameOrAfter(currentDate, "day");
    }),
  startTime: yup
    .mixed<Dayjs>()
    .required("Start time is required")
    .test("is-valid-time", "Invalid time format", (value) => {
      return value ? dayjs(value).isValid() : false;})
    .test("is-future-time", "Start time must be in the future", function (value) {
      const { date, timeZone } = this.parent;
      if (!date || !value) return false;
      const selectedStartDateTime = dayjs.tz(
        `${date.format("YYYY-MM-DD")}T${value.format("HH:mm")}`,timeZone);
      return selectedStartDateTime.isAfter(dayjs());
    }),
  endTime: yup
    .mixed<Dayjs>()
    .required("End time is required")
    .test("is-valid-time", "Invalid time format", (value) => {
      return value ? dayjs(value).isValid() : false;})
    .test("is-after-startTime", "End time must be after start time", function (value) {
      const { startTime, date, timeZone } = this.parent;
      if (!date || !startTime || !value) return false;
      const start = dayjs.tz(
        `${date.format("YYYY-MM-DD")}T${startTime.format("HH:mm")}`,timeZone);
      const end = dayjs.tz(
        `${date.format("YYYY-MM-DD")}T${value.format("HH:mm")}`,
        timeZone);
      return end.isAfter(start);
    }),
  timeZone: yup.string().required("Timezone is required"),
  internalParticipants: yup
    .string()
    .test("internal-or-external", "At least one participant is required *", function (value) {
      const externalParticipants = this.parent.externalParticipants || "";
      return value?.trim() || externalParticipants.trim();
    })
    .test(
      "valid-internal-emails",
      "Only @wso2.com emails allowed",
      (value) =>
        !value ||
        value.split(",").every((email) => yup.string().email().isValidSync(email) && email.endsWith("@wso2.com"))
    ),
  externalParticipants: yup
    .string()
    .test("internal-or-external", "At least one participant is required *", function (value) {
      const internalParticipants = this.parent.internalParticipants || "";
      return value?.trim() || internalParticipants.trim();
    })
    .test(
      "valid-external-emails",
      "Invalid email format in external participants",
      (value) => !value || value.split(",").every((email) => yup.string().email().isValidSync(email))
    )
    .test(
      "no-wso2-emails",
      "External participants cannot have @wso2.com emails",
      (value) => !value || !value.split(",").some((email) => email.trim().endsWith("@wso2.com"))
    ),
  isRecurring: yup.boolean().default(false),
  recurrenceFrequency: yup
    .mixed<RecurrenceFrequency>()
    .oneOf(["", ...RECURRENCE_FREQUENCIES])
    .when("isRecurring", {
      is: true,
      then: (schema) => schema.required("Choose frequency"),
      otherwise: (schema) => schema.notRequired(),
    }),
  recurrenceCount: yup
    .mixed<number | "">()
    .when("isRecurring", {
      is: true,
      then: yup
        .number()
        .typeError("Enter occurrences")
        .integer("Must be a whole number")
        .min(2, "At least 2 occurrences")
        .max(365, "Too many occurrences")
        .required("Enter occurrences"),
      otherwise: yup.mixed().notRequired(),
    }),
});

function MeetingForm() {
  const auth = useAppAuthContext();
  const dispatch = useAppDispatch();
  const filter = createFilterOptions<string>();
  const [loading, setLoading] = useState(false);
  const dialogContext = useConfirmationModalContext();
  const [customerId, setCustomerId] = useState<string | null>(null);
  const contactsState = useAppSelector((state) => state.contact.state);
  const employeeState = useAppSelector((state) => state.employee.state);
  const contacts = useAppSelector((state) => state.contact.contacts) || [];
  const employees = useAppSelector((state) => state.employee.employees) || [];
  const customers = useAppSelector((state) => state.customer.customers) || [];
  const meetingTypes = useAppSelector((state) => state.meeting.meetingTypes) || [];
  const [customerInputValue, setCustomerInputValue] = useState("");
  const [meetingTypeInputValue, setMeetingTypeInputValue] = useState("");
  const [externalEmailInputValue, setExternalEmailInputValue] = useState<string[]>([]);
  const timeZones = useMemo(() => {
    return typeof (Intl as any).supportedValuesOf === "function" ? (Intl as any).supportedValuesOf("timeZone") : [];
  }, []);

  useEffect(() => {
    if (!meetingTypes.length) {
      dispatch(fetchMeetingTypes());
    }
  }, [dispatch, meetingTypes.length]);

  useEffect(() => {
    if (!employees.length) {
      dispatch(fetchEmployees());
    }
  }, [dispatch, employees.length]);

  useEffect(() => {
    if (!customers.length) {
      dispatch(fetchCustomers());
    }
  }, [dispatch, customers.length]);

  useEffect(() => {
    if (customerId) {
      dispatch(resetContacts());
      dispatch(fetchContacts({ customerId }));
    } else {
      dispatch(resetContacts());
    }
  }, [dispatch, customerId]);

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
      isRecurring: false,
      recurrenceFrequency: "",
      recurrenceCount: "",
    },
    validationSchema,
    validateOnChange: true,
    onSubmit: async (values, { resetForm }) => {
      setLoading(true);
      try {
        if (!formik.isValid) return;
        const isRecurring = values.isRecurring;
        const formattedData = {
          title: `WSO2: ${[values.customerName, values.meetingType, values.customTitle?.trim()]
            .filter(Boolean)
            .join(" - ")}`,
          description: values.description,
          startTime:
            values.date && values.startTime ? formatDateTime(values.date, values.startTime, values.timeZone) ?? "" : "",
          endTime:
            values.date && values.endTime ? formatDateTime(values.date, values.endTime, values.timeZone) ?? "" : "",
          timeZone: values.timeZone,
          internalParticipants: values.internalParticipants
            .split(",")
            .map((email) => email.trim())
            .filter(Boolean),
          externalParticipants: values.externalParticipants
            .split(",")
            .map((email) => email.trim())
            .filter(Boolean),
          isRecurring,
          recurrence: isRecurring
            ? {
              frequency: values.recurrenceFrequency as RecurrenceFrequencyCore,
              count: +values.recurrenceCount,
            }
            : undefined
        };
        await dispatch(addMeetings(formattedData)).unwrap();
        resetForm();
        setCustomerId(null);
        dispatch(resetContacts());
        setCustomerInputValue("");
        setMeetingTypeInputValue("");
        setExternalEmailInputValue([]);
      } finally {
        setLoading(false);
      }
    },
  });

  const handleSubmit = () => {
    dialogContext.showConfirmation(
      "Confirm Meeting Creation",
      <Box>
        {formik.values && (
          <>
            <Typography variant="body1">
              <strong>
                Are you sure you want to create the meeting <br />
              </strong>{" "}
              {[formik.values.meetingType, formik.values.customerName, formik.values.customTitle?.trim()]
                .filter(Boolean)
                .join(" - ")}
            </Typography>
          </>
        )}
      </Box>,
      ConfirmationType.accept,
      async () => {
        await formik.submitForm();
      },
      "Confirm",
      "Cancel"
    );
  };

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
          boxShadow: theme.palette.mode === "dark" ? "0px 0px 10px rgba(120, 125, 129, 0.5)" : 10,
          overflow: "auto",
        })}
      >
        <Typography variant="h5" fontWeight="bold" color="primary.main" align="center">
          Create Meeting
        </Typography>
        <Box sx={{ display: "flex", gap: 2 }}>
          <Autocomplete
            sx={{ flex: 1 }}
            freeSolo
            clearOnEscape
            loading={!meetingTypes.length}
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
            inputValue={meetingTypeInputValue}
            onInputChange={(_, newInputValue, reason) => {
              if (reason === "input") {
                setMeetingTypeInputValue(newInputValue);
              }
            }}
            onChange={(_, newValue) => {
              let finalValue = newValue;
              if (typeof newValue === "string" && newValue.startsWith('Add "')) {
                finalValue = newValue.slice(5, -1);
              }
              setMeetingTypeInputValue(finalValue || "");
              formik.setFieldValue("meetingType", finalValue || "");
            }}
            renderInput={(params) => (
              <TextField
                {...params}
                required
                fullWidth
                id="meetingType"
                name="meetingType"
                label="Meeting Type"
                value={formik.values.meetingType}
                onBlur={formik.handleBlur}
                onChange={formik.handleChange}
                error={formik.touched.meetingType && Boolean(formik.errors.meetingType)}
                helperText={formik.touched.meetingType && formik.errors.meetingType}
              />
            )}
          />

          <Autocomplete
            sx={{ flex: 1 }}
            freeSolo
            clearOnEscape
            loading={!customers.length}
            options={customers.map((customer) => customer.name)}
            filterOptions={(options, params) => {
              const filtered = filter(options, params);
              const { inputValue } = params;
              if (inputValue !== "" && !options.includes(inputValue)) {
                filtered.push(`Add "${inputValue}"`);
              }
              return filtered;
            }}
            value={formik.values.customerName}
            inputValue={customerInputValue}
            onInputChange={(_, newInputValue, reason) => {
              if (reason === "input") {
                setCustomerInputValue(newInputValue);
                setCustomerId(customers.find((customer) => customer.name === newInputValue)?.id || null);
              }
            }}
            onChange={(_, newValue) => {
              let finalValue = newValue;
              if (typeof newValue === "string" && newValue.startsWith('Add "')) {
                finalValue = newValue.slice(5, -1);
              }
              setCustomerInputValue(finalValue || "");
              setCustomerId(customers.find((customer) => customer.name === finalValue)?.id || null);
              formik.setFieldValue("customerName", finalValue || "");
            }}
            renderInput={(params) => (
              <TextField
                {...params}
                required
                fullWidth
                id="customerName"
                name="customerName"
                label="Customer Name"
                value={formik.values.customerName}
                onBlur={formik.handleBlur}
                onChange={formik.handleChange}
                error={formik.touched.customerName && Boolean(formik.errors.customerName)}
                helperText={formik.touched.customerName && formik.errors.customerName}
              />
            )}
          />
        </Box>
        <TextField
          fullWidth
          id="customTitle"
          name="customTitle"
          label="Title"
          value={formik.values.customTitle}
          onBlur={formik.handleBlur}
          onChange={formik.handleChange}
          error={formik.touched.customTitle && Boolean(formik.errors.customTitle)}
        />
        <TextField
          fullWidth
          id="description"
          name="description"
          label="Meeting Description"
          value={formik.values.description}
          onBlur={formik.handleBlur}
          onChange={formik.handleChange}
          error={formik.touched.description && Boolean(formik.errors.description)}
          autoCorrect="off"
          autoCapitalize="none"
          spellCheck={false}
          multiline
          rows={2}
        />
        <Box
          sx={{
            display: "flex",
            alignItems: "center",
            gap: 1,
            width: "100%",
            py: 0.5,
            flexWrap: "nowrap",
            paddingLeft: 0
          }}
        >
          <Typography variant="subtitle1" sx={{ opacity: 0.85, whiteSpace: "nowrap" }}>
            Recurring
          </Typography>
          <Switch
            size="small"
            checked={formik.values.isRecurring}
            onChange={(_, checked) => {
              formik.setFieldValue("isRecurring", checked);
              if (!checked) {
                formik.setFieldValue("recurrenceFrequency", "");
                formik.setFieldValue("recurrenceCount", "");
              }
            }}
            inputProps={{ "aria-label": "Recurring meeting" }}
          />
          <Collapse in={formik.values.isRecurring} orientation="horizontal" timeout={200} unmountOnExit>
            <Box sx={{ display: "flex", alignItems: "center", gap: 2 }}>
              <TextField
                select
                label="Repeat"
                name="recurrenceFrequency"
                value={formik.values.recurrenceFrequency}
                onChange={formik.handleChange}
                onBlur={formik.handleBlur}
                error={
                  formik.touched.recurrenceFrequency &&
                  Boolean(formik.errors.recurrenceFrequency)
                }
                helperText={
                  formik.touched.recurrenceFrequency && formik.errors.recurrenceFrequency
                }
                sx={{ width: 167 }}
                InputProps={{ sx: { height: 50 } }}
              >
                <MenuItem value="">Select</MenuItem>
                <MenuItem value="DAILY">Daily</MenuItem>
                <MenuItem value="WEEKLY">Weekly</MenuItem>
                <MenuItem value="MONTHLY">Monthly</MenuItem>
              </TextField>
              <TextField
                type="number"
                label="Occurrences"
                name="recurrenceCount"
                value={formik.values.recurrenceCount}
                onChange={(e) => {
                  const v = e.target.value;
                  formik.setFieldValue("recurrenceCount", v === "" ? "" : Number(v));
                }}
                onBlur={formik.handleBlur}
                inputProps={{ min: 2, step: 1 }}
                error={formik.touched.recurrenceCount && Boolean(formik.errors.recurrenceCount)}
                helperText={formik.touched.recurrenceCount && (formik.errors.recurrenceCount as string)}
                sx={{ width: 166 }}
                InputProps={{ sx: { height: 50 } }}
              />
            </Box>
          </Collapse>
        </Box>
        <Box sx={{ display: "flex", gap: 2, pb: 0.5 }}>
          <Autocomplete
            fullWidth
            options={timeZones}
            value={formik.values.timeZone}
            onChange={async (_, tz) => await formik.setFieldValue("timeZone", tz ?? Intl.DateTimeFormat().resolvedOptions().timeZone)}
            renderInput={(params) => (
              <TextField
                {...params}
                id="timeZone"
                name="timeZone"
                label="Timezone"
                onBlur={formik.handleBlur}
                error={formik.touched.timeZone && Boolean(formik.errors.timeZone)}
                helperText={formik.touched.timeZone && formik.errors.timeZone}
              />
            )}
            sx={{ flex: 1 }}
          />
          <DatePicker
            name="date"
            label="Meeting Date *"
            format="DD/MM/YYYY"
            value={formik.values.date}
            minDate={dayjs().tz(formik.values.timeZone).startOf("day")}
            onChange={async (value) => {
              await formik.setFieldValue("date", value);
              formik.setFieldTouched("date", true);
              await formik.setFieldValue("startTime", null);
              formik.setFieldTouched("startTime", false);
              await formik.setFieldValue("endTime", null);
              formik.setFieldTouched("endTime", false);
            }}
            onAccept={async (value) => {
              await formik.setFieldValue("date", value);
              formik.setFieldTouched("date", true);
              await formik.setFieldValue("startTime", null);
              formik.setFieldTouched("startTime", false);
              await formik.setFieldValue("endTime", null);
              formik.setFieldTouched("endTime", false);
            }}
            slotProps={{
              textField: {
                onBlur: () => formik.setFieldTouched("date", true),
                error: formik.touched.date && Boolean(formik.errors.date),
              },
            }}
            sx={{ flex: 1 }}
          />
        </Box>

        <Box sx={{ display: "flex", gap: 2, pb: 0.5 }}>
          <TimePicker
            name="startTime"
            label="Start Time *"
            value={formik.values.startTime}
            disabled={!formik.values.date || Boolean(formik.errors.date)}
            onChange={async (value) => {
              if (value && dayjs(value).isValid()) {
                await formik.setFieldValue("startTime", value);
                formik.setFieldTouched("startTime", true);
                await formik.setFieldValue("endTime", null);
                formik.setFieldTouched("endTime", false);
              } else if (value === null) {
                await formik.setFieldValue("startTime", null);
                formik.setFieldTouched("startTime", true);
              }
            }}
            onAccept={async (value) => {
              await formik.setFieldValue("startTime", value);
              formik.setFieldTouched("startTime", true);
              await formik.setFieldValue("endTime", null);
              formik.setFieldTouched("endTime", false);
            }}
            slotProps={{
              textField: {
                onBlur: () => formik.setFieldTouched("startTime", true),
                error: formik.touched.startTime && Boolean(formik.errors.startTime),
              },
            }}
            sx={{ flex: 1 }}
          />

          <TimePicker
            name="endTime"
            label="End Time *"
            value={formik.values.endTime}
            disabled={!formik.values.startTime || Boolean(formik.errors.startTime)}
            onChange={async (value) => {
              if (value && dayjs(value).isValid()) {
                await formik.setFieldValue("endTime", value);
                formik.setFieldTouched("endTime", true);
              } else if (value === null) {
                await formik.setFieldValue("endTime", null);
                formik.setFieldTouched("endTime", true);
              }
            }}
            onAccept={async (value) => {
              await formik.setFieldValue("endTime", value);
              formik.setFieldTouched("endTime", true);
            }}
            slotProps={{
              textField: {
                onBlur: () => formik.setFieldTouched("endTime", true),
                error: formik.touched.endTime && Boolean(formik.errors.endTime),
              },
            }}
            sx={{ flex: 1 }}
          />
        </Box>
        <FormHelperText
          error={
            (formik.touched.date && Boolean(formik.errors.date)) ||
            (formik.touched.startTime && Boolean(formik.errors.startTime)) ||
            (formik.touched.endTime && Boolean(formik.errors.endTime))
          }
          sx={{ marginX: "14px !important", marginBottom: "2px !important", marginTop: "0px !important" }}
        >
          {(formik.touched.date && formik.errors.date) ||
            (formik.touched.startTime && formik.errors.startTime) ||
            (formik.touched.endTime && formik.errors.endTime)}
        </FormHelperText>

        <Autocomplete
          multiple
          limitTags={1}
          loading={!employees.length}
          options={employees.map((emp) => emp.workEmail)}
          filterOptions={createFilterOptions({
            stringify: (email) => {
              const employee = employees.find((emp) => emp.workEmail === email);
              const fullName = `${employee?.firstName || ""} ${employee?.lastName || ""}`;
              return `${email} ${fullName}`;
            },
          })}
          filterSelectedOptions
          value={formik.values.internalParticipants.split(",").filter(Boolean)}
          onChange={(_, newValue) => {
            const emails = newValue.map((email) => email.trim()).filter(Boolean);
            formik.setFieldValue("internalParticipants", emails.join(","));
          }}
          renderInput={(params) => (
            <TextField
              {...params}
              fullWidth
              label="WSO2 Participants"
              id="internalParticipants"
              name="internalParticipants"
              onBlur={formik.handleBlur}
              error={
                (formik.touched.internalParticipants && Boolean(formik.errors.internalParticipants)) ||
                (formik.touched.externalParticipants && Boolean(formik.errors.externalParticipants))
              }
            />
          )}
          renderOption={(props, option) => {
            const { key, ...prop } = props;
            const employee = employees.find((emp) => emp.workEmail === option);
            const initials = option ? option.charAt(0).toUpperCase() : "";
            return (
              <li key={key} {...prop} style={{ display: "flex", alignItems: "center", gap: 8, padding: "8px 16px" }}>
                {employee?.employeeThumbnail ? (
                  <img
                    src={employee?.employeeThumbnail}
                    alt={employee.firstName}
                    style={{
                      width: 24,
                      height: 24,
                      borderRadius: "50%",
                      marginRight: 8,
                    }}
                    loading="lazy"
                  />
                ) : (
                  <Avatar sx={{ width: 24, height: 24, fontSize: 14, marginRight: 1, bgcolor: "#74b3ce" }}>
                    {initials}
                  </Avatar>
                )}
                <div>
                  <div>{`${employee?.firstName} ${employee?.lastName}`}</div>
                  <div style={{ fontSize: "12px", color: "#888" }}>{option}</div>
                </div>
              </li>
            );
          }}
          renderTags={(value, getTagProps) => {
            return value.map((selectedEmail, index) => {
              const { key, ...prop } = getTagProps({ index });
              const employee = employees.find((emp) => emp.workEmail === selectedEmail);
              const initials = selectedEmail.charAt(0).toUpperCase();
              return (
                <Chip
                  label={`${employee?.firstName} ${employee?.lastName}`}
                  avatar={
                    employee?.employeeThumbnail ? (
                      <img
                        src={employee?.employeeThumbnail}
                        alt={employee?.firstName}
                        style={{
                          width: 24,
                          height: 24,
                          borderRadius: "50%",
                        }}
                      />
                    ) : (
                      <Avatar sx={{ width: 24, height: 24, fontSize: 14, bgcolor: "#74b3ce" }}>{initials}</Avatar>
                    )
                  }
                  key={key}
                  {...prop}
                  style={{ margin: 4 }}
                />
              );
            });
          }}
          sx={{
            "& .MuiAutocomplete-inputRoot": {
              alignItems: "center",
              paddingTop: "7px !important",
              paddingBottom: "7px !important",
              flexWrap: "wrap",
            },
            "& .MuiChip-root": {
              height: 32,
              display: "flex",
              alignItems: "center",
            },
          }}
        />

        <Autocomplete
          multiple
          freeSolo
          limitTags={1}
          loading={contactsState === State.loading}
          options={[
            ...externalEmailInputValue.filter((email) => email.trim() !== ""),
            ...contacts.map((contact) => contact.email),
          ]}
          filterSelectedOptions
          value={formik.values.externalParticipants.split(",").filter((email) => email.trim())}
          onChange={async (_, newValue) => {
            const emails = newValue
              .flatMap((item) => {
                if (!item) return [];
                const emailMatches = item.match(/\b[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Z|a-z]{2,}\b/g);
                return emailMatches || [];
              })
              .filter((email, index, self): email is string => email !== undefined && self.indexOf(email) === index);
            await formik.setFieldValue("externalParticipants", emails.join(","));
            formik.setFieldTouched("externalParticipants", true);
          }}
          onInputChange={(_, newInputValue) => {
            setExternalEmailInputValue([newInputValue]);
          }}
          renderInput={(params) => (
            <TextField
              {...params}
              fullWidth
              label="External Participants"
              id="externalParticipants"
              name="externalParticipants"
              onBlur={formik.handleBlur}
              error={
                (formik.touched.internalParticipants &&
                  Boolean(formik.errors.internalParticipants) &&
                  formik.touched.externalParticipants &&
                  Boolean(formik.errors.externalParticipants)) ||
                (formik.touched.externalParticipants && Boolean(formik.errors.externalParticipants))
              }
              helperText={
                (formik.touched.internalParticipants &&
                  formik.errors.internalParticipants &&
                  formik.touched.externalParticipants &&
                  formik.errors.externalParticipants) ||
                (formik.touched.externalParticipants && formik.errors.externalParticipants)
              }
            />
          )}
          renderOption={(props, option) => {
            const initials = option?.charAt(0).toUpperCase() ?? "";
            const { key, ...prop } = props;

            return (
              <li key={key} {...prop} style={{ display: "flex", alignItems: "center", paddingLeft: 16 }}>
                <Avatar sx={{ width: 24, height: 24, fontSize: 14, marginRight: 2, bgcolor: "#74b3ce" }}>
                  {initials}
                </Avatar>
                <Typography variant="body2">{option}</Typography>
              </li>
            );
          }}
          renderTags={(value, getTagProps) =>
            value
              .filter((email): email is string => email !== undefined)
              .map((email: string, index: number) => {
                const initials = email.charAt(0).toUpperCase();
                const { key, ...prop } = getTagProps({ index });
                return (
                  <Chip
                    avatar={
                      <Avatar sx={{ width: 24, height: 24, fontSize: 14, bgcolor: "#74b3ce" }}>{initials}</Avatar>
                    }
                    label={email}
                    {...prop}
                    key={key}
                    style={{ margin: 4 }}
                  />
                );
              })
          }
          sx={{
            "& .MuiAutocomplete-inputRoot": {
              alignItems: "center",
              paddingTop: "7px !important",
              paddingBottom: "7px !important",
              flexWrap: "wrap",
            },
            "& .MuiChip-root": {
              height: 32,
              display: "flex",
              alignItems: "center",
            },
          }}
        />

        <Button
          type="button"
          variant="contained"
          fullWidth
          disabled={loading || !formik.isValid || !formik.dirty}
          onClick={handleSubmit}
          sx={{ position: "relative", height: 38 }}
        >
          {loading ? <CircularProgress size={24} /> : "Create Meeting"}
        </Button>
      </Stack>
    </LocalizationProvider>
  );
}

function CreateMeeting() {
  const employeeState = useAppSelector((s) => s.employee.state);
    if (employeeState === State.failed) {
    return (
      <Box
        sx={{
          display: "flex",
          justifyContent: "center",
          alignItems: "center",
          height: "100%",
          width: "100%",
        }}
      >
        <ErrorHandler message="Oops! Something went wrong. Please contact Internal Apps Team at internal-apps-team@wso2.com." />
      </Box>
    );
  }
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
          backgroundImage: `url(${require("@assets/images/sales-team.svg").default})`,
          backgroundSize: "cover",
          backgroundPosition: "center",
          height: "80%",
        }}
      />
    </Box>
  );
}

export default CreateMeeting;
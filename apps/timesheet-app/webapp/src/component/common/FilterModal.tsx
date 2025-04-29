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
  Menu,
  Chip,
  Stack,
  Paper,
  Button,
  MenuItem,
  TextField,
  IconButton,
  Typography,
  Autocomplete,
} from "@mui/material";
import {
  Add as AddIcon,
  Tune as TuneIcon,
  Close as CloseIcon,
  ExpandMore as ExpandMoreIcon,
} from "@mui/icons-material";
import { Filter } from "@utils/types";
import React, { useState } from "react";
import { useAppSelector } from "@slices/store";
import { DatePicker } from "@mui/x-date-pickers";

interface FieldConfig {
  field: string;
  label: string;
  type: string;
  options?: string[];
}

interface FilterComponentProps {
  availableFields: FieldConfig[];
  filters: Filter[];
  setFilters: (filters: Filter[]) => void;
  onApply: (employeeEmail?: string) => void;
  onReset: () => void;
  isLead?: boolean;
}

const FilterComponent: React.FC<FilterComponentProps> = ({
  filters,
  isLead,
  onApply,
  onReset,
  setFilters,
  availableFields,
}) => {
  const [filterAnchorEl, setFilterAnchorEl] = useState<null | HTMLElement>(null);
  const employeeArray = useAppSelector((state) => state.meteInfo.employeeArray);
  const userEmail = useAppSelector((state) => state.auth.userInfo!.email);
  const employees = isLead
    ? employeeArray.filter((employee) => employee.managerEmail?.toLowerCase() === userEmail?.toLowerCase())
    : employeeArray;

  const areAllFiltersValid = () => {
    return filters.every((filter) => {
      const fieldConfig = availableFields.find((f) => f.field === filter.field);
      if (!fieldConfig) return false;

      if (filter.value === null || filter.value === undefined || filter.value === "") {
        return false;
      }

      if (fieldConfig.type === "select" && !fieldConfig.options?.includes(filter.value as string)) {
        return false;
      }

      return true;
    });
  };

  const handleFilterChange = (id: string, field: string, value: any) => {
    if (field === "field") {
      const fieldConfig = availableFields.find((f) => f.field === value);

      if (fieldConfig?.type === "date") {
        setFilters(
          filters.map((filter) =>
            filter.id === id
              ? {
                  ...filter,
                  field: value,
                  value: formatDateForAPI(new Date()),
                }
              : filter
          )
        );
      } else {
        setFilters(filters.map((filter) => (filter.id === id ? { ...filter, field: value, value: "" } : filter)));
      }
      return;
    }

    const currentFilter = filters.find((f) => f.id === id);
    const fieldConfig = availableFields.find((f) => f.field === currentFilter?.field);

    if (fieldConfig?.type === "date" && value instanceof Date) {
      setFilters(filters.map((filter) => (filter.id === id ? { ...filter, value: formatDateForAPI(value) } : filter)));
    } else {
      setFilters(filters.map((filter) => (filter.id === id ? { ...filter, [field]: value } : filter)));
    }
  };

  const handleAddFilter = () => {
    const availableFieldOptions = availableFields.filter((field) => !filters.some((f) => f.field === field.field));

    if (availableFieldOptions.length === 0) return;

    const defaultField = availableFieldOptions[0].field;
    const fieldConfig = availableFields.find((f) => f.field === defaultField);

    setFilters([
      ...filters,
      {
        id: Date.now().toString(),
        field: defaultField,
        operator: "equals",
        value: fieldConfig?.type === "date" ? formatDateForAPI(new Date()) : "",
      },
    ]);
  };
  const handleRemoveFilter = (id: string) => {
    setFilters(filters.filter((filter) => filter.id !== id));
  };

  const resetFilters = () => {
    onReset();
    setFilterAnchorEl(null);
  };

  const applyFilters = () => {
    if (!areAllFiltersValid()) {
      return;
    }
    onApply();
    setFilterAnchorEl(null);
  };

  const formatDateForAPI = (date: Date): string => {
    if (!date || !(date instanceof Date)) return "";
    const year = date.getFullYear();
    const month = String(date.getMonth() + 1).padStart(2, "0");
    const day = String(date.getDate()).padStart(2, "0");
    return `${year}-${month}-${day}`;
  };

  const getFilterComponent = (filter: Filter) => {
    const fieldConfig = availableFields.find((f) => f.field === filter.field);
    if (!fieldConfig) return null;

    switch (fieldConfig.type) {
      case "select":
        return (
          <TextField
            select
            size="small"
            required
            value={filter.value}
            fullWidth
            onChange={(e) => handleFilterChange(filter.id, "value", e.target.value)}
            sx={{ minWidth: 150 }}
            error={!filter.value}
          >
            {fieldConfig.options?.map((option) => (
              <MenuItem key={option} value={option}>
                {option}
              </MenuItem>
            ))}
          </TextField>
        );
      case "date":
        const dateValue = filter.value ? new Date(filter.value) : null;
        return (
          <DatePicker
            value={dateValue}
            onChange={(newValue) => handleFilterChange(filter.id, "value", newValue)}
            slotProps={{
              textField: {
                size: "small",
                error: !filter.value,
              },
            }}
            sx={{ width: "100%" }}
            maxDate={new Date()}
          />
        );
      default:
        return (
          <Autocomplete
            loading={employees.length === 0}
            loadingText="No subordinates found"
            options={employees}
            getOptionLabel={(option) => option.workEmail}
            renderOption={(props, option) => <li {...props}>{option.workEmail}</li>}
            renderInput={(params) => (
              <TextField {...params} label="Employee Email" size="small" required error={!filter.value} />
            )}
            onChange={(_, value) => handleFilterChange(filter.id, "value", value?.workEmail)}
            value={employees.find((emp) => emp.workEmail === filter.value) || null}
          />
        );
    }
  };

  return (
    <>
      <Button
        variant="outlined"
        startIcon={<TuneIcon />}
        endIcon={<ExpandMoreIcon />}
        onClick={(e) => setFilterAnchorEl(e.currentTarget)}
        sx={{
          borderColor: "divider",
          "&:hover": { borderColor: "divider" },
        }}
      >
        Filters
        {filters.length > 0 && (
          <Chip
            label={filters.length}
            size="small"
            sx={{
              ml: 1,
              height: 20,
              fontSize: "0.75rem",
            }}
          />
        )}
      </Button>

      <Menu
        anchorEl={filterAnchorEl}
        open={Boolean(filterAnchorEl)}
        onClose={() => setFilterAnchorEl(null)}
        PaperProps={{
          sx: {
            p: 2,
            width: 600,
            maxWidth: "90vw",
            maxHeight: "80vh",
            overflow: "auto",
          },
        }}
      >
        <Stack direction="row" justifyContent="space-between" alignItems="center">
          <Typography variant="subtitle2">FILTERS</Typography>
          <Button size="small" startIcon={<AddIcon />} onClick={handleAddFilter}>
            Add Filter
          </Button>
        </Stack>

        {filters.length > 0 && (
          <>
            <Stack spacing={2}>
              {filters.map((filter) => (
                <Paper key={filter.id} variant="outlined" sx={{ p: 1.5, position: "relative" }}>
                  <Stack spacing={1.5} direction={"row"}>
                    <Box width={"45%"}>
                      <TextField
                        select
                        size="small"
                        fullWidth
                        label="Field"
                        value={filter.field}
                        onChange={(e) => handleFilterChange(filter.id, "field", e.target.value)}
                      >
                        {availableFields.map((field) => (
                          <MenuItem key={field.field} value={field.field}>
                            {field.label}
                          </MenuItem>
                        ))}
                      </TextField>
                    </Box>

                    <Box width={"50%"}>{getFilterComponent(filter)}</Box>
                    <Box width={"5%"} alignContent={"center"} display={"flex"}>
                      <IconButton
                        size="small"
                        onClick={() => handleRemoveFilter(filter.id)}
                        sx={{ color: "text.secondary" }}
                      >
                        <CloseIcon fontSize="small" />
                      </IconButton>
                    </Box>
                  </Stack>
                </Paper>
              ))}
              <Stack direction="row" spacing={1} justifyContent="flex-end">
                <Button size="small" onClick={resetFilters}>
                  Reset
                </Button>
                <Button variant="contained" size="small" onClick={applyFilters} disabled={!areAllFiltersValid()}>
                  Apply
                </Button>
              </Stack>
            </Stack>
          </>
        )}
      </Menu>
    </>
  );
};

export default FilterComponent;

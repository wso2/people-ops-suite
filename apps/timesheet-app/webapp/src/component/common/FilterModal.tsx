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
    Add as AddIcon,
    Tune as TuneIcon,
    Close as CloseIcon,
    ExpandMore as ExpandMoreIcon,
} from "@mui/icons-material";
import React, { useState } from "react";
import { DatePicker } from "@mui/x-date-pickers";
import { Stack, Button, Menu, Typography, TextField, MenuItem, Paper, IconButton, Chip, Box } from "@mui/material";

interface Filter {
  id: string;
  field: string;
  operator: string;
  value: any;
}

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
  onApply: () => void;
  onReset: () => void;
}

const FilterComponent: React.FC<FilterComponentProps> = ({
  availableFields,
  filters,
  setFilters,
  onApply,
  onReset,
}) => {
  const [filterAnchorEl, setFilterAnchorEl] = useState<null | HTMLElement>(null);

  const handleAddFilter = () => {
    const availableFieldOptions = availableFields.filter((field) => !filters.some((f) => f.field === field.field));

    if (availableFieldOptions.length === 0) {
      return;
    }

    const defaultField = availableFieldOptions[0].field;
    setFilters([
      ...filters,
      {
        id: Date.now().toString(),
        field: defaultField,
        operator: "equals",
        value: defaultField.includes("Date") ? new Date() : "",
      },
    ]);
  };

  const handleFilterChange = (id: string, field: string, value: any) => {
    if (field === "field") {
      if (filters.some((f) => f.field === value && f.id !== id)) {
        return;
      }
    }

    setFilters(filters.map((filter) => (filter.id === id ? { ...filter, [field]: value } : filter)));
  };

  const handleRemoveFilter = (id: string) => {
    setFilters(filters.filter((filter) => filter.id !== id));
  };

  const resetFilters = () => {
    onReset();
    setFilterAnchorEl(null);
  };

  const applyFilters = () => {
    onApply();
    setFilterAnchorEl(null);
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
            fullWidth
            value={filter.value}
            required
            type="email"
            onChange={(e) => handleFilterChange(filter.id, "value", e.target.value)}
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
            width: 400,
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
                <Button variant="contained" size="small" onClick={applyFilters}>
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

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
  MenuItem,
  Select,
  FormControl,
  InputLabel,
  SelectChangeEvent,
} from "@mui/material";

import { DropdownOption } from "@root/src/types/types";

interface DropdownProps {
  label: string;
  value: string;
  options: DropdownOption[];
  onChange: (event: SelectChangeEvent) => void;
  isLoading?: boolean;
  size:"small"|"medium";
}

const Dropdown = ({
  label,
  value,
  options,
  onChange,
  isLoading,
  size
}: DropdownProps) => {
  return (
    <FormControl size={size} sx={{ minWidth: 150 }}>
      <InputLabel sx={{ fontWeight: "bold", color: "text.primary" }}>
        {isLoading ? "Loading..." : label}
      </InputLabel>
      <Select
        value={isLoading ? "" : value}
        label={label}
        onChange={onChange}
        sx={{ fontWeight: "bold", color: "text.primary" }}
      >
        {isLoading ? (
          <MenuItem disabled value="">
            <em>Loading regions...</em>
          </MenuItem>
        ) : (
          options.map((opt) => (
            <MenuItem key={opt.value} value={opt.value}>
              {opt.label}
            </MenuItem>
          ))
        )}
      </Select>
    </FormControl>
  );
};

export default Dropdown;

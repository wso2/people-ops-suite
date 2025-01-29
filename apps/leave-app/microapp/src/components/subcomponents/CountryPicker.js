// Copyright (c) 2024 WSO2 LLC. (https://www.wso2.com).
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
import React, { useEffect, useState } from "react";

import Box from "@mui/material/Box";
import TextField from "@mui/material/TextField";
import Autocomplete from "@mui/material/Autocomplete";

import { LEAVE_APP } from "../../constants";

export default function CountryPicker(props) {
  const [value, setValue] = useState(null);
  const [filteredCountries, setFilteredCountries] = useState([]);
  const getOptionLabel = (option) => {
    return `${option.label} (${option.code})`;
  };

  const onChange = (event, value) => {
    setValue(value);
    props.onChange(value);
  };

  useEffect(() => {
    let tempCountries = [];
    props.visibleCountries.forEach((country) => {
      if (LEAVE_APP.COUNTRIES[country]) {
        tempCountries.push(LEAVE_APP.COUNTRIES[country]);
        return;
      }

      if (LEAVE_APP.COUNTRY_CODES[country]) {
        tempCountries.push(
          LEAVE_APP.COUNTRIES[LEAVE_APP.COUNTRY_CODES[country]]
        );
        return;
      }
    });
    setFilteredCountries(tempCountries);
  }, [props.visibleCountries]);

  return (
    <Autocomplete
      id="country-select-demo"
      sx={{ minWidth: 220 }}
      options={filteredCountries}
      autoHighlight
      value={value}
      onChange={onChange}
      getOptionLabel={(option) => getOptionLabel(option)}
      renderOption={(props, option) => (
        <Box
          component="li"
          sx={{ "& > img": { mr: 2, flexShrink: 0 } }}
          {...props}
        >
          <img
            loading="lazy"
            width="20"
            src={`https://flagcdn.com/w20/${option.code.toLowerCase()}.png`}
            srcSet={`https://flagcdn.com/w40/${option.code.toLowerCase()}.png 2x`}
            alt=""
          />
          {option.label} ({option.code})
        </Box>
      )}
      renderInput={(params) => (
        <TextField
          {...params}
          label="Choose a country"
          inputProps={{
            ...params.inputProps,
            autoComplete: "new-password",
          }}
        />
      )}
    />
  );
}

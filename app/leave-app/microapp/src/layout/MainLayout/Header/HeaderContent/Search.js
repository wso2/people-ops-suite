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
import React from "react";

import { Box, FormControl, InputAdornment, OutlinedInput } from "@mui/material";

import { SearchOutlined } from "@ant-design/icons";

const Search = () => (
  <Box sx={{ width: "100%", ml: { xs: 0, md: 1 } }}>
    <FormControl sx={{ width: { xs: "100%", md: 224 } }}>
      <OutlinedInput
        size="small"
        id="header-search"
        startAdornment={
          <InputAdornment position="start" sx={{ mr: -0.5 }}>
            <SearchOutlined />
          </InputAdornment>
        }
        aria-describedby="header-search-text"
        inputProps={{
          "aria-label": "weight",
        }}
        placeholder="Ctrl + K"
      />
    </FormControl>
  </Box>
);

export default Search;

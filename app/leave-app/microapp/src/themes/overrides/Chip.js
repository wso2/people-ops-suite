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
export default function Chip(theme) {
  return {
    MuiChip: {
      styleOverrides: {
        root: {
          borderRadius: 16,
          "&:active": {
            boxShadow: "none",
          },
        },
        sizeLarge: {
          fontSize: "1rem",
          height: 40,
        },
        light: {
          color: theme.palette.primary.main,
          backgroundColor: theme.palette.primary.lighter,
          borderColor: theme.palette.primary.light,
          "&.MuiChip-lightError": {
            color: theme.palette.error.main,
            backgroundColor: theme.palette.error.lighter,
            borderColor: theme.palette.error.light,
          },
          "&.MuiChip-lightSuccess": {
            color: theme.palette.success.main,
            backgroundColor: theme.palette.success.lighter,
            borderColor: theme.palette.success.light,
          },
          "&.MuiChip-lightWarning": {
            color: theme.palette.warning.main,
            backgroundColor: theme.palette.warning.lighter,
            borderColor: theme.palette.warning.light,
          },
        },
      },
    },
  };
}

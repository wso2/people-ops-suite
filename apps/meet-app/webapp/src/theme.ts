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

import { PaletteMode, alpha } from "@mui/material";

// Color Design Tokens
export const tokens = (mode: PaletteMode) => ({
  ...(mode === "dark"
    ? {
      grey: {
        100: "#d1d3d4",
        200: "#a8abad",
        300: "#7f8285",
        400: "#5a5d61",
        500: "#444a4e",
        600: "#363b40",
        700: "#2a2d31",
      },
      primary: {
        100: "#d1d3d4",
        200: "#555b5f",
        300: "#373c40",
      },
      secondary: {
        100: "#d1d4d8",
        200: "#52585c",
        300: "#3d4246",
      },
      success: { 100: "#4caf50" },
      warning: { 100: "#a89a63" },
      error: { 100: "#fe4336" },
      gradient: "linear-gradient(to bottom, #363b40, #2a2d31)",
    }
    : {
      grey: {
        100: "#ffffff",
        200: "#d1d3d4",
        300: "#b1b3b5",
        400: "#949698",
        500: "#777a7c",
        600: "#5a5d61",
        700: "#444a4e",
      },
      primary: {
        100: "#787d81",
        200: "#63696d",
        300: "#444a4e",
      },
      secondary: {
        100: "#868c90",
        200: "#6c7276",
        300: "#52585c",
      },
      success: { 100: "#388e3c" },
      warning: { 100: "#c1ad70" },
      error: { 100: "#fe4336" },
      gradient: "linear-gradient(to bottom, #f1f2f3, #d1d3d4)",
    }),
});

// Extend background type
declare module '@mui/material/styles' {
  interface TypeBackground {
    autocomplete?: string;
    dataGrid?: string;
    layout?: string;
    gradient?: string;
  }

  interface PaletteOptions {
    background?: Partial<TypeBackground>;
  }
}

// MUI Theme Settings
export const themeSettings = (mode: PaletteMode) => {
  const colors = tokens(mode);

  return {
    palette: {
      mode: mode,
      ...(mode === "dark"
        ? {
          primary: {
            main: colors.primary[100],
            dark: colors.primary[300],
          },
          secondary: {
            main: colors.grey[200],
            dark: colors.secondary[200],
          },
          success: { main: colors.success[100] },
          warning: { main: colors.warning[100] },
          error: { main: colors.error[100] },
          background: {
            default: colors.grey[700],
            form: colors.grey[600],
            banner: colors.primary[200],
            autocomplete: colors.grey[400],
            dataGrid: colors.grey[500],
            layout: colors.grey[100],
            gradient: colors.gradient,
          },
        }
        : {
          primary: {
            main: colors.primary[300],
            dark: colors.primary[300],
          },
          secondary: {
            main: colors.secondary[200],
            dark: colors.secondary[300],
          },
          success: { main: colors.success[100] },
          warning: { main: colors.warning[100] },
          error: { main: colors.error[100] },
          background: {
            default: colors.grey[100],
            form: colors.grey[100],
            banner: colors.primary[200],
            autocomplete: colors.grey[400],
            dataGrid: colors.grey[300],
            layout: colors.grey[100],
            gradient: colors.gradient,
          },
        }),
    },
    typography: {
      fontSize: 11,
      fontFamily: ["Poppins", "Inter", "sans-serif"].join(","),
      h1: { fontSize: 38, fontWeight: 700 },
      h2: { fontSize: 32, fontWeight: 600 },
      h3: { fontSize: 24, fontWeight: 500 },
      h4: { fontSize: 20 },
      h5: { fontSize: 16 },
      h6: { fontSize: 14 },
    },
    components: {
      MuiDataGrid: {
        styleOverrides: {
          columnHeader: {
            backgroundColor: mode === "dark"
              ? alpha(colors.primary[300], 0.9)  
              : alpha(colors.primary[300], 0.2),
            fontWeight: 1000,
          },
          columnHeaderTitle: {
            fontWeight: 1000,
          },
        },
      },
      MuiButton: {
        styleOverrides: {
          contained: {
            backgroundColor: "#ff7300",
            "&:hover": { backgroundColor: "#e76000" },
            fontWeight: "bold",
            letterSpacing: "2px",
            padding: "9px 12px",
            borderRadius: "8px",
            color: "white",
          },
        },
      },
      MuiCssBaseline: {
        styleOverrides: mode === "dark"
          ? `
            input:-webkit-autofill,
            input:-webkit-autofill:hover,
            input:-webkit-autofill:focus,
            input:-webkit-autofill:active {
              -webkit-box-shadow: 0 0 0 30px ${colors.grey[700]} inset !important;
            }`
          : `
            input:-webkit-autofill,
            input:-webkit-autofill:hover,
            input:-webkit-autofill:focus,
            input:-webkit-autofill:active {
              -webkit-box-shadow: 0 0 0 30px ${colors.grey[100]} inset !important;
            }`,
      },
    },
    breakpoints: {
      values: {
        xs: 0,
        sm: 600,
        md: 960,
        lg: 1280,
        xl: 1920,
      },
    },
  };
};

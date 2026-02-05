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
import AppHandler from "@app/AppHandler";
import { AsgardeoProvider } from "@asgardeo/react";
import { ThemeProvider, createTheme } from "@mui/material/styles";
import { SnackbarProvider } from "notistack";
import { Provider } from "react-redux";

import { createContext, useMemo, useState } from "react";

import { APP_NAME, AsgardeoConfig } from "@config/config";
import AppAuthProvider from "@context/AuthContext";
import { themeSettings } from "@root/src/theme";
import { store } from "@slices/store";
import { ThemeMode } from "@utils/types";

import "./index.css";

export const ColorModeContext = createContext({
  mode: ThemeMode.Light,
  toggleColorMode: () => {},
});

const processLocalThemeMode = (): ThemeMode => {
  try {
    const savedTheme = localStorage.getItem("internal-app-theme");
    if (savedTheme === ThemeMode.Light || savedTheme === ThemeMode.Dark) {
      return savedTheme;
    }

    const prefersDark = window.matchMedia("(prefers-color-scheme: dark)").matches;
    const systemTheme = prefersDark ? ThemeMode.Dark : ThemeMode.Light;

    localStorage.setItem("internal-app-theme", systemTheme);
    return systemTheme;
  } catch (err) {
    console.error("Theme detection failed, defaulting to light mode.", err);
    return ThemeMode.Light;
  }
};

function App() {
  document.title = APP_NAME;

  const [mode, setMode] = useState<ThemeMode>(processLocalThemeMode());

  const colorMode = useMemo(
    () => ({
      toggleColorMode: () => {
        const newMode = mode === ThemeMode.Light ? ThemeMode.Dark : ThemeMode.Light;
        // Update localStorage
        localStorage.setItem("internal-app-theme", newMode);
        // Update state
        setMode(newMode);
      },
    }),
    [mode],
  );

  const theme = useMemo(() => createTheme(themeSettings(mode)), [mode]);

  return (
    <ColorModeContext.Provider value={{ mode, toggleColorMode: colorMode.toggleColorMode }}>
      <SnackbarProvider maxSnack={3} preventDuplicate>
        <ThemeProvider theme={theme}>
          <Provider store={store}>
            <AsgardeoProvider {...AsgardeoConfig}>
              <AppAuthProvider>
                <AppHandler />
              </AppAuthProvider>
            </AsgardeoProvider>
          </Provider>
        </ThemeProvider>
      </SnackbarProvider>
    </ColorModeContext.Provider>
  );
}

export default App;

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

import { createContext, useState, useMemo } from "react";
import { Provider } from "react-redux";

// MUI imports
import { ThemeProvider, createTheme } from "@mui/material/styles";

// APP imports
import { store } from "@slices/store";
import { ThemeMode } from "@utils/types";
import { APP_NAME, AsgardeoConfig } from "@config/config";
import AppHandler from "@app/AppHandler";
import { themeSettings } from "@src/theme";
import "@src/App.scss";
import AppAuthProvider from "@context/AuthContext";

// Other imports
import { AuthProvider } from "@asgardeo/auth-react";
import { SnackbarProvider } from "notistack";

export const ColorModeContext = createContext({ toggleColorMode: () => {} });

function App() {
  document.title = APP_NAME;
  const processLocalThemeMode = (): ThemeMode => {
    var localMode: ThemeMode | null = localStorage.getItem(
      "internal-app-theme"
    ) as ThemeMode;

    if (localMode) {
      return localMode;
    } else {
      localStorage.setItem("internal-app-theme", ThemeMode.Dark);
      return ThemeMode.Dark;
    }
  };

  const [mode, setMode] = useState<ThemeMode>(processLocalThemeMode());

  const colorMode = useMemo(
    () => ({
      toggleColorMode: () => {
        localStorage.setItem(
          "internal-app-theme",
          mode === ThemeMode.Light ? ThemeMode.Dark : ThemeMode.Light
        );
        setMode((prevMode) =>
          prevMode === ThemeMode.Light ? ThemeMode.Dark : ThemeMode.Light
        );
      },
    }),
    [mode]
  );

  const theme = useMemo(() => createTheme(themeSettings(mode)), [mode]);

  return (
    <ColorModeContext.Provider value={colorMode}>
      <SnackbarProvider maxSnack={3} preventDuplicate>
        <ThemeProvider theme={theme}>
          <Provider store={store}>
            <AuthProvider config={AsgardeoConfig}>
              <AppAuthProvider>
                <AppHandler />
              </AppAuthProvider>
            </AuthProvider>
          </Provider>
        </ThemeProvider>
      </SnackbarProvider>
    </ColorModeContext.Provider>
  );
}

export default App;

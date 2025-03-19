// Copyright (c) 2024, WSO2 LLC. (https://www.wso2.com). All Rights Reserved.
//
// This software is the property of WSO2 LLC. and its suppliers, if any.
// Dissemination of any information or reproduction of any material contained
// herein in any form is strictly forbidden, unless permitted by WSO2 expressly.
// You may not alter or remove any copyright or other notice from copies of this content.

import { createContext, useState, useMemo } from "react";
import { Provider } from "react-redux";

// MUI imports
import { ThemeProvider, createTheme } from "@mui/material/styles";

// APP imports
import { store } from "./slices/store";
import { ThemeMode } from "@utils/types";
import { APP_NAME, AppConfig, AsgardeoConfig } from "./config/config";
import AppHandler from "@app/AppHandler";
import { themeSettings } from "./theme";
import "./App.scss";
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

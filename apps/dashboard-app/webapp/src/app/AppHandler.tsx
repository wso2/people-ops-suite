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
import { RouterProvider, createBrowserRouter } from "react-router-dom";

import { FC, memo, useMemo } from "react";

import { AppState } from "@/types/types";
import ErrorHandler from "@component/common/ErrorHandler";
import PreLoader from "@component/common/PreLoader";
import Layout from "@layout/Layout";
import NotFoundPage from "@layout/pages/404";
import MaintenancePage from "@layout/pages/Maintenance";
import { RootState } from "@slices/store";
import { useAppSelector } from "@slices/store";
import { getAllowedRoutes } from "@src/route";

const getAppState = (authStatus: string, authMode: string): AppState => {
  if (authMode === AppState.Maintenance) return AppState.Maintenance;
  if (authStatus === AppState.Loading) return AppState.Loading;
  if (authStatus === AppState.Failed) return AppState.Failed;
  return AppState.Success;
};

const AppHandler: FC = () => {
  const { status, mode, roles, statusMessage } = useAppSelector((state: RootState) => state.auth);

  const appState = useMemo(() => getAppState(status, mode), [status, mode]);

  const router = useMemo(
    () =>
      createBrowserRouter([
        {
          path: "/",
          element: <Layout />,
          errorElement: <NotFoundPage />,
          children: getAllowedRoutes(roles),
        },
      ]),
    [roles],
  );

  const renderApp = () => {
    if (appState === AppState.Loading) {
      return <PreLoader isLoading={true} message="We are getting things ready..." />;
    }

    if (appState === AppState.Maintenance) {
      return <MaintenancePage />;
    }

    if (appState === AppState.Failed) {
      return <ErrorHandler message={statusMessage} />;
    }

    return <RouterProvider router={router} />;
  };

  return renderApp();
};

export default memo(AppHandler);

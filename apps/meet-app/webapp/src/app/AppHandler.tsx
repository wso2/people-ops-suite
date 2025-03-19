// Copyright (c) 2024, WSO2 LLC. (https://www.wso2.com). All Rights Reserved.
//
// This software is the property of WSO2 LLC. and its suppliers, if any.
// Dissemination of any information or reproduction of any material contained
// herein in any form is strictly forbidden, unless permitted by WSO2 expressly.
// You may not alter or remove any copyright or other notice from copies of this content.

import Error from "../layout/pages/404";
import MaintenancePage from "../layout/pages/Maintenance";
import { getActiveRoutesV2, routes } from "../route";
import Layout from "../layout/Layout";
import { RootState, useAppSelector } from "@slices/store";
import PreLoader from "@component/common/PreLoader";
import ErrorHandler from "@component/common/ErrorHandler";
import { RouterProvider, createBrowserRouter } from "react-router-dom";

const AppHandler = () => {
  const auth = useAppSelector((state: RootState) => state.auth);

  const router = createBrowserRouter([
    {
      path: "/",
      element: <Layout />,
      errorElement: <Error />,
      children: getActiveRoutesV2(routes, auth.roles),
    },
  ]);

  return (
    <>
      {auth.status === "loading" && (
        <PreLoader isLoading={true} message={auth.statusMessage}></PreLoader>
      )}
      {auth.status === "success" && auth.mode === "active" && (
        <RouterProvider router={router} />
      )}
      {auth.status === "success" && auth.mode === "maintenance" && (
        <MaintenancePage />
      )}
      {auth.status === "failed" && (
        <ErrorHandler
          message={"Sometimes went wrong while authenticating the user :("}
        />
      )}
    </>
  );
};

export default AppHandler;

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
import React, { useEffect } from "react";
import { useDispatch } from "react-redux";

import {
  Avatar,
  Box,
  Card,
  CardContent,
  Skeleton,
  Typography,
} from "@mui/material";

import EmailPicker from "./EmailPicker";
import { setEmployeeData } from "../store/reducers/menu";
import useHttp from "../utils/http";
import { services } from "../config";
import { LEAVE_APP } from "../constants";

const AccountProfile = (props) => {
  const { employee, handleEmployeeChange } = props;
  const dispatch = useDispatch();
  const { handleRequest, handleRequestWithNewToken } = useHttp();

  const loadEmployeeData = () => {
    const successFn = (data) => {
      if (data) {
        dispatch(setEmployeeData({ employeeData: data }));
      }
    };

    const errorFunc = (error) => {
      // showAlert("Error", "Error while fetching employee data", "Close", () => { }, () => { });
    };

    handleRequestWithNewToken(() => {
      handleRequest(
        `${services.FETCH_EMPLOYEES}?employeeStatuses=${LEAVE_APP.EMPLOYEE_STATUS.Active.value},${LEAVE_APP.EMPLOYEE_STATUS["Marked leaver"].value},${LEAVE_APP.EMPLOYEE_STATUS.Left.value}`,
        "GET",
        null,
        successFn,
        errorFunc,
        null
      );
    });
  };

  useEffect(() => {}, [employee]);

  useEffect(() => {
    loadEmployeeData();
  }, []);

  return (
    <>
      <EmailPicker email={employee} handleEmailChange={handleEmployeeChange} />
      <Card>
        <CardContent>
          <Box
            sx={{
              alignItems: "center",
              display: "flex",
              flexDirection: "column",
            }}
          >
            {employee ? (
              <>
                <Avatar
                  src={employee.employeeThumbnail}
                  sx={{
                    height: 80,
                    mb: 2,
                    width: 80,
                  }}
                  alt={employee.firstName}
                />
                <Typography gutterBottom variant="h5">
                  {employee.firstName && employee.lastName
                    ? `${employee.firstName} ${employee.lastName}`
                    : employee.workEmail}
                </Typography>
              </>
            ) : (
              <>
                <Skeleton variant="circular" width={80} height={80} />
                <Skeleton variant="text" sx={{ fontSize: "1rem" }} width={80} />
              </>
            )}
          </Box>
        </CardContent>
      </Card>
    </>
  );
};

export default AccountProfile;

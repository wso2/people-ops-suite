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

import { CSVLink } from "react-csv";
import { v4 as uuidv4 } from "uuid";

import {
  ExpandMore as ExpandMoreIcon,
  FileDownload as FileDownloadIcon,
} from "@mui/icons-material";
import {
  Accordion,
  AccordionDetails,
  AccordionSummary,
  Button,
  Card,
  CardContent,
  Chip,
  CircularProgress,
  Paper,
  Stack,
  Typography,
  useTheme,
} from "@mui/material";

import EmptyListText from "./EmptyListText";
import {
  getDateFromDateObject,
  getLocalDisplayDateReadable,
  getUserFromEmail,
} from "../utils/formatting";
import { LEAVE_APP } from "../constants";
import { getLeaveTypes } from "../utils/utils";

export default function LeaveHistoryList(props) {
  const theme = useTheme();
  const [filteredLeaves, setFilteredLeaves] = useState([]);
  const {
    leaves,
    leaveType,
    leaveMap,
    employee,
    isLoading,
    isLeaveEntitlementLoading,
    leaveEntitlement,
  } = props;

  const headCells = [
    {
      id: "startDate",
      numeric: false,
      disablePadding: true,
      label: "Start Date",
    },
    {
      id: "endDate",
      numeric: false,
      disablePadding: true,
      label: "End Date",
    },
    {
      id: "leaveType",
      numeric: false,
      disablePadding: true,
      label: "Type",
    },
    {
      id: "numberOfDays",
      numeric: true,
      disablePadding: true,
      label: "Num of days",
    },
    {
      id: "periodType",
      numeric: true,
      disablePadding: true,
      label: "Period type",
    },
  ];

  useEffect(() => {
    if (leaveType === "all") {
      setFilteredLeaves(leaves.reverse());
    } else {
      setFilteredLeaves(
        leaves ? leaves.filter((e) => e.leaveType) : [].reverse()
      );
    }
  }, [leaves, leaveType, leaveMap]);

  useEffect(() => {}, [
    isLoading,
    employee,
    isLeaveEntitlementLoading,
    leaveEntitlement,
  ]);

  return (
    <>
      <Stack
        direction="column"
        justifyContent="center"
        alignItems="flex-start"
        spacing={2}
        sx={{ width: "100%" }}
      >
        <Stack
          direction="row"
          justifyContent="flex-end"
          alignItems="center"
          spacing={2}
          style={{ marginBottom: "10px" }}
        >
          {filteredLeaves.length !== 0 && employee && (
            <>
              {getLeaveTypes().map((type) => (
                <>
                  {leaveMap[type] ? (
                    <Typography variant="h6">
                      {LEAVE_APP.LEAVE_TYPES[type].title}:{" "}
                      {leaveMap[type].count}
                    </Typography>
                  ) : null}
                </>
              ))}
              {
                <Typography variant="h6">
                  Total: {leaveMap["all"] ? leaveMap["all"].count : 0}
                </Typography>
              }
              {
                <Typography variant="h6">
                  Total (Excl. Lieu):{" "}
                  {leaveMap["total"] ? leaveMap["total"].count : 0}
                </Typography>
              }
            </>
          )}

          {filteredLeaves.length !== 0 && employee && (
            <CSVLink
              headers={headCells.map((headCell) => ({
                label: headCell.label,
                key: headCell.id,
              }))}
              data={leaves}
              filename={`${getUserFromEmail(
                employee.workEmail
              )}-${getDateFromDateObject(new Date())}-leaves.csv`}
              className="btn btn-primary"
              target="_blank"
            >
              <Button
                variant="contained"
                color="secondary"
                size="small"
                endIcon={<FileDownloadIcon />}
              >
                Download as CSV
              </Button>
            </CSVLink>
          )}
        </Stack>
        <Stack
          direction="row"
          justifyContent="flex-start"
          alignItems="flex-start"
          spacing={2}
        >
          <span>
            {filteredLeaves.length !== 0 && employee && (
              <Paper
                elevation={3}
                sx={{
                  width: "100%",
                  p: 1,
                  backgroundColor: theme.palette.grey[200],
                }}
              >
                <Typography variant="h6" gutterBottom>
                  Entitled leave taken
                </Typography>
                {isLeaveEntitlementLoading ? (
                  <CircularProgress color="secondary" size={16} />
                ) : (
                  <Stack
                    direction="row"
                    justifyContent="flex-start"
                    alignItems="center"
                    spacing={1}
                    flexWrap="wrap"
                    useFlexGap
                  >
                    {leaveEntitlement.map((entitlement) => (
                      <Stack
                        direction="row"
                        justifyContent="flex-start"
                        alignItems="center"
                        spacing={1}
                      >
                        <span>
                          {entitlement.year && (
                            <Chip label={`${entitlement.year}`} size="small" />
                          )}
                        </span>
                        <span>
                          {entitlement.policyAdjustedLeave.casual !==
                            undefined && (
                            <Typography variant="caption">
                              {"Casual"}:{" "}
                              {entitlement.policyAdjustedLeave.casual}
                            </Typography>
                          )}
                        </span>
                        <span>
                          {entitlement.policyAdjustedLeave.annual !==
                            undefined && (
                            <Typography variant="caption">
                              {"Annual"}:{" "}
                              {entitlement.policyAdjustedLeave.annual}
                            </Typography>
                          )}
                        </span>
                      </Stack>
                    ))}
                  </Stack>
                )}
              </Paper>
            )}
          </span>
          <span>
            {filteredLeaves.length !== 0 && employee && (
              <Paper
                elevation={3}
                sx={{
                  width: "100%",
                  p: 1,
                  backgroundColor: theme.palette.grey[200],
                }}
              >
                <Typography variant="h6" gutterBottom>
                  Leave Policy
                </Typography>
                {isLeaveEntitlementLoading ? (
                  <CircularProgress color="secondary" size={16} />
                ) : (
                  <Stack
                    direction="row"
                    justifyContent="flex-start"
                    alignItems="center"
                    spacing={1}
                    flexWrap="wrap"
                    useFlexGap
                  >
                    {leaveEntitlement.map((entitlement) => (
                      <Stack
                        direction="row"
                        justifyContent="flex-start"
                        alignItems="center"
                        spacing={1}
                      >
                        <span>
                          {entitlement.year && (
                            <Chip label={`${entitlement.year}`} size="small" />
                          )}
                        </span>
                        <span>
                          {entitlement.leavePolicy.casual !== undefined && (
                            <Typography variant="caption">
                              {"Casual"}: {entitlement.leavePolicy.casual}
                            </Typography>
                          )}
                        </span>
                        <span>
                          {entitlement.leavePolicy.annual !== undefined && (
                            <Typography variant="caption">
                              {"Annual"}: {entitlement.leavePolicy.annual}
                            </Typography>
                          )}
                        </span>
                      </Stack>
                    ))}
                  </Stack>
                )}
              </Paper>
            )}
          </span>
        </Stack>
      </Stack>
      {filteredLeaves.length ? (
        filteredLeaves.map((leave, index) => (
          <Accordion key={uuidv4()} sx={{ mt: 2 }}>
            <AccordionSummary
              expandIcon={<ExpandMoreIcon />}
              aria-controls="panel1bh-content"
              id="panel1bh-header"
            >
              <Card sx={{ width: "100%" }} elevation={0}>
                <CardContent
                  sx={{
                    padding: 0,
                    paddingLeft: 1,
                    paddingBottom: "0px !important",
                  }}
                >
                  <Stack
                    direction="row"
                    justifyContent="space-between"
                    alignItems="center"
                    spacing={1}
                  >
                    <Stack
                      direction="column"
                      justifyContent="flex-start"
                      alignItems="stretch"
                      spacing={0}
                    >
                      <Typography sx={{ fontSize: 14 }} color="text.secondary">
                        {`${
                          LEAVE_APP.LEAVE_TYPES[leave.leaveType]
                            ? LEAVE_APP.LEAVE_TYPES[leave.leaveType].title
                            : ""
                        }`}
                      </Typography>
                      <Typography variant="h5" component="div">
                        {leave.numberOfDays > 1
                          ? `From ${getLocalDisplayDateReadable(
                              leave.startDate
                            )} to ${getLocalDisplayDateReadable(leave.endDate)}`
                          : `On ${getLocalDisplayDateReadable(
                              leave.startDate
                            )} ${
                              leave.numberOfDays === 0.5
                                ? leave.isMorningLeave
                                  ? "(First half)"
                                  : "(Second half)"
                                : ""
                            }`}
                      </Typography>
                    </Stack>
                    <Stack
                      direction="column"
                      justifyContent="center"
                      alignItems="stretch"
                      spacing={0}
                    >
                      <Typography variant="h5" color="text.secondary">
                        {`${leave.numberOfDays || "N/A"} ${
                          leave.numberOfDays === 1 ? "day" : "days"
                        }`}
                      </Typography>
                    </Stack>
                  </Stack>
                </CardContent>
              </Card>
            </AccordionSummary>
            <AccordionDetails
              sx={{ display: "flex", justifyContent: "flex-end" }}
            >
              <Stack
                direction="column"
                justifyContent="space-between"
                alignItems="flex-end"
                spacing={0}
              >
                <Typography sx={{ mt: 1 }} variant="body2">
                  {`Submitted on: ${getLocalDisplayDateReadable(
                    leave.createdDate
                  )}`}
                </Typography>
              </Stack>
            </AccordionDetails>
          </Accordion>
        ))
      ) : (
        <EmptyListText
          text={
            isLoading
              ? employee
                ? `Loading leaves${` for ${
                    employee.firstName && employee.lastName
                      ? `${employee.firstName} ${employee.lastName}`
                      : employee.workEmail
                  }`}...`
                : ""
              : employee
              ? "No leaves to view for provided filters."
              : "Please select an employee to view leaves"
          }
        />
      )}
    </>
  );
}

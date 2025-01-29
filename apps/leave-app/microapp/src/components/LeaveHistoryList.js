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

import {
  ClearOutlined as ClearOutlinedIcon,
  ExpandMore as ExpandMoreIcon,
} from "@mui/icons-material";
import {
  Accordion,
  AccordionDetails,
  AccordionSummary,
  Button,
  Card,
  CardContent,
  Stack,
  Typography,
} from "@mui/material";

import { v4 as uuidv4 } from "uuid";

import CalendarIcon from "./@extended/CalendarIcon";
import EmptyListText from "./EmptyListText";
import { getLocalDisplayDateReadable } from "../utils/formatting";
import { getLeaveTypeTitle } from "../utils/utils";

export default function LeaveHistoryList(props) {
  const [filteredLeaves, setFilteredLeaves] = useState([]);
  const { leaves, leaveType, isLoading } = props;

  useEffect(() => {
    if (leaveType === "all") {
      setFilteredLeaves(leaves.reverse());
    } else {
      setFilteredLeaves(
        leaves ? leaves.filter((e) => e.leaveType === leaveType) : [].reverse()
      );
    }
  }, [leaves, leaveType]);

  useEffect(() => {}, [leaves, isLoading]);

  return (
    <>
      {filteredLeaves.length ? (
        filteredLeaves.map((leave, index) => (
          <Accordion key={uuidv4()}>
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
                  <Typography
                    sx={{ fontSize: 14 }}
                    color="text.secondary"
                    gutterBottom
                  >
                    {`${getLeaveTypeTitle(leave.leaveType)}`}
                  </Typography>
                  <Stack
                    direction="row"
                    justifyContent="flex-start"
                    alignItems="stretch"
                    spacing={2}
                  >
                    <CalendarIcon date={leave.startDate} />
                    <Stack
                      direction="column"
                      justifyContent="flex-start"
                      alignItems="stretch"
                      spacing={2}
                    >
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
                      <Typography color="text.secondary">
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
                spacing={1}
              >
                <Typography sx={{ mt: 1 }} variant="body2">
                  {`Submitted on: ${getLocalDisplayDateReadable(
                    leave.createdDate
                  )}`}
                </Typography>
                <Button
                  onClick={() => props.onDelete(leave.id)}
                  color="error"
                  variant="contained"
                  size="small"
                  disabled={!leave.isCancelAllowed}
                  startIcon={<ClearOutlinedIcon />}
                >
                  Cancel leave
                </Button>
              </Stack>
            </AccordionDetails>
          </Accordion>
        ))
      ) : (
        <EmptyListText text={isLoading ? "Loading..." : "Nothing to show"} />
      )}
    </>
  );
}

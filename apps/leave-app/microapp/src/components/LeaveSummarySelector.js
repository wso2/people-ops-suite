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

import { styled } from "@mui/material/styles";
import Typography from "@mui/material/Typography";
import {
  Accordion,
  AccordionDetails,
  AccordionSummary,
  Chip,
  Divider,
  Paper,
  Stack,
} from "@mui/material";

import { getLeaveTypeTitle, getLeaveTypes } from "../utils/utils";

const ListItem = styled("li")(({ theme }) => ({
  margin: theme.spacing(0.5),
}));

export default function LeaveSummarySelector(props) {
  const { leaveType, handleLeaveType, leaveMap } = props;
  const [totalCount, setTotalCount] = useState(0);

  useEffect(() => {
    if (leaveMap.total) {
      setTotalCount(leaveMap.total.count || 0);
    }
  }, [leaveMap]);

  useEffect(() => {}, [leaveType]);

  useEffect(() => {}, [props.collapsed]);

  return (
    <>
      <Accordion
        sx={{
          position: "sticky",
          top: 1,
          width: "100%",
          marginTop: 2,
          marginLeft: 1,
          marginRight: 1,
          padding: "0px !important",
        }}
        expanded={props.collapsed}
      >
        <AccordionSummary
          sx={{
            padding: 0,
            "& .MuiAccordionSummary-content": {
              margin: "0px !important",
            },
          }}
          aria-controls="panel1a-content"
          id="panel1a-header"
        >
          <Stack
            sx={{ width: "100%" }}
            direction="row"
            justifyContent="space-between"
            alignItems="center"
            spacing={2}
          >
            {props.collapsed && (
              <>
                <Stack
                  sx={{ width: "100%", paddingLeft: 1 }}
                  direction="column"
                  justifyContent="space-between"
                  alignItems="stretch"
                >
                  <Typography variant="h3">{"Total Leave"}</Typography>
                  <Typography variant="h6">
                    {"(Excludes lieu leave)"}
                  </Typography>
                </Stack>
                <Stack
                  sx={{ width: "100%", paddingRight: 2 }}
                  direction="column"
                  justifyContent="center"
                  alignItems="flex-end"
                >
                  <Typography variant="h2" sx={{ color: "text.secondary" }}>
                    {totalCount}
                  </Typography>
                  <Typography variant="h6" sx={{ color: "text.secondary" }}>
                    {totalCount === 1 ? "Day" : "Days"}
                  </Typography>
                </Stack>
              </>
            )}
            {!props.collapsed && (
              <Paper
                elevation={0}
                sx={{
                  display: "flex",
                  justifyContent: "left",
                  flexWrap: "wrap",
                  listStyle: "none",
                  p: 0,
                  m: 0,
                }}
                component="ul"
              >
                <ListItem onClick={handleLeaveType("all")} key={"all"}>
                  <Chip
                    size="small"
                    color={"secondary"}
                    variant={leaveType === "all" ? "contained" : "outlined"}
                    clickable
                    label={"All"}
                  />
                </ListItem>
                {getLeaveTypes(true).map((type) => (
                  <ListItem
                    onClick={handleLeaveType(type.type)}
                    key={type.title}
                  >
                    <Chip
                      icon={type.icon}
                      size="small"
                      color={"secondary"}
                      variant={
                        leaveType === type.type ? "contained" : "outlined"
                      }
                      clickable
                      label={`${getLeaveTypeTitle(type.type)}: ${
                        leaveMap[type.type] ? leaveMap[type.type].count : 0
                      }`}
                    />
                  </ListItem>
                ))}
              </Paper>
            )}
          </Stack>
        </AccordionSummary>
        <AccordionDetails
          sx={{
            padding: "4px 8px 4px",
          }}
        >
          <Paper
            elevation={0}
            sx={{
              display: "flex",
              justifyContent: "left",
              flexWrap: "wrap",
              listStyle: "none",
              p: 0,
              m: 0,
            }}
            component="ul"
          >
            <ListItem onClick={handleLeaveType("all")} key={"all"}>
              <Chip
                size="small"
                color={"secondary"}
                variant={leaveType === "all" ? "contained" : "outlined"}
                clickable
                label={"All"}
              />
            </ListItem>
            {getLeaveTypes(true)
              .filter((e) => e.isCounted)
              .map((type) => (
                <ListItem onClick={handleLeaveType(type.type)} key={type.title}>
                  <Chip
                    icon={type.icon}
                    size="small"
                    color={"secondary"}
                    variant={leaveType === type.type ? "contained" : "outlined"}
                    clickable
                    label={`${getLeaveTypeTitle(type.type)}: ${
                      leaveMap[type.type] ? leaveMap[type.type].count : 0
                    }`}
                  />
                </ListItem>
              ))}
          </Paper>
          <Divider />
          <Paper
            elevation={0}
            sx={{
              display: "flex",
              justifyContent: "left",
              flexWrap: "wrap",
              listStyle: "none",
              p: 0,
              m: 0,
            }}
            component="ul"
          >
            {getLeaveTypes(true)
              .filter((e) => !e.isCounted)
              .map((type) => (
                <ListItem key={type.title}>
                  <Chip
                    onClick={handleLeaveType(type.type)}
                    icon={type.icon}
                    size="small"
                    color={"secondary"}
                    variant={leaveType === type.type ? "contained" : "outlined"}
                    label={`${getLeaveTypeTitle(type.type)}: ${
                      leaveMap[type.type] ? leaveMap[type.type].count : 0
                    }`}
                  />
                </ListItem>
              ))}
          </Paper>
        </AccordionDetails>
      </Accordion>
    </>
  );
}

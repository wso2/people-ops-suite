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
import React, { useState, useEffect } from "react";

import {
  Chip,
  Divider,
  Grid,
  List,
  ListItem,
  ListItemIcon,
  ListItemSecondaryAction,
  ListItemText,
  Paper,
  Typography,
} from "@mui/material";

import { getLeaveTypes } from "../utils/utils";

const TotalSummary = (props) => {
  const [totalLeave, setTotalLeave] = useState(0);
  const [totalLeaveUncounted, setTotalLeaveUncounted] = useState(0);

  const getTotal = () => {
    var count = 0;
    getLeaveTypes(true).forEach((leave) => {
      if (props.summaryMap[leave.type] && leave.isCounted) {
        count += props.summaryMap[leave.type].count;
      }
    });
    return count;
  };

  const getTotalOfUncounted = () => {
    var count = 0;
    getLeaveTypes(true).forEach((leave) => {
      if (props.summaryMap[leave.type] && !leave.isCounted) {
        count += props.summaryMap[leave.type].count;
      }
    });
    return count;
  };

  useEffect(() => {
    setTotalLeave(getTotal());
    setTotalLeaveUncounted(getTotalOfUncounted());
  }, [props.summaryMap]);

  return (
    <Grid container spacing={2}>
      <Grid item xs={12} md={6}>
        <Paper variant="outlined">
          <List>
            {getLeaveTypes(true).map((leave) => {
              if (!leave.isCounted) {
                return false;
              }
              return (
                <ListItem>
                  <ListItemIcon sx={{ marginRight: 1 }}>
                    {leave.icon}
                  </ListItemIcon>
                  <ListItemText primary={leave.title} />
                  <ListItemSecondaryAction>
                    <Chip
                      label={
                        props.summaryMap[leave.type] &&
                        props.summaryMap[leave.type].count
                          ? props.summaryMap[leave.type].count
                          : 0
                      }
                    ></Chip>
                  </ListItemSecondaryAction>
                </ListItem>
              );
            })}
            <Divider />
            <ListItem>
              <ListItemIcon sx={{ marginRight: 1 }}></ListItemIcon>
              <Typography variant="subtitle1">Total</Typography>
              <ListItemSecondaryAction>
                <Chip label={totalLeave} color="secondary"></Chip>
              </ListItemSecondaryAction>
            </ListItem>
          </List>
        </Paper>
      </Grid>
      <Grid item xs={12} md={6}>
        <Paper variant="outlined">
          <List>
            {getLeaveTypes(true).map((leave) => {
              if (leave.isCounted) {
                return false;
              }
              return (
                <ListItem>
                  <ListItemIcon sx={{ marginRight: 1 }}>
                    {leave.icon}
                  </ListItemIcon>
                  <ListItemText primary={leave.title} />
                  <ListItemSecondaryAction>
                    <Chip
                      label={
                        props.summaryMap[leave.type] &&
                        props.summaryMap[leave.type].count
                          ? props.summaryMap[leave.type].count
                          : 0
                      }
                    ></Chip>
                  </ListItemSecondaryAction>
                </ListItem>
              );
            })}
          </List>
        </Paper>
      </Grid>
    </Grid>
  );
};

export default TotalSummary;

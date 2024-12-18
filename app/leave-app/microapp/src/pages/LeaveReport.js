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
import React from "react";
import PropTypes from "prop-types";
import { useTheme } from "@mui/material/styles";
import {
  AppBar,
  Box,
  TableCell,
  TableHead,
  TableRow,
  TableSortLabel,
  Tab,
  Tabs,
} from "@mui/material";
import { styled } from "@mui/material/styles";

import LeaveReportUser from "./LeaveReportUser";
import LeaveReportOverall from "./LeaveReportOverall";
import { useSwipeable } from "react-swipeable";

const headCells = [
  {
    id: "num_days",
    numeric: true,
    disablePadding: false,
    label: "Number of days",
  },
  {
    id: "start_date",
    numeric: true,
    disablePadding: false,
    label: "Start Date",
  },
  { id: "end_date", numeric: true, disablePadding: false, label: "End Date" },
  {
    id: "created_date",
    numeric: true,
    disablePadding: false,
    label: "Submitted Date",
  },
];

const visuallyHiddenSx = {
  border: 0,
  clip: "rect(0 0 0 0)",
  height: 1,
  margin: -1,
  overflow: "hidden",
  padding: 0,
  position: "absolute",
  top: 20,
  width: 1,
};

const StyledTableCell = styled((props) => <TableCell {...props} />)(
  ({ theme }) => ({
    head: {
      backgroundColor: "#aaa",
      color: theme.palette.common.white,
    },
    body: {
      fontSize: 14,
    },
  })
);

function EnhancedTableHead(props) {
  const { order, orderBy, onRequestSort } = props;
  const createSortHandler = (property) => (event) => {
    onRequestSort(event, property);
  };

  return (
    <TableHead>
      <TableRow>
        {headCells.map((headCell) => (
          <StyledTableCell
            key={headCell.id}
            align={"center"}
            padding={headCell.disablePadding ? "none" : "default"}
            sortDirection={orderBy === headCell.id ? order : false}
          >
            <TableSortLabel
              active={orderBy === headCell.id}
              direction={orderBy === headCell.id ? order : "asc"}
              onClick={createSortHandler(headCell.id)}
            >
              {headCell.label}
              {orderBy === headCell.id ? (
                <span sx={visuallyHiddenSx}></span>
              ) : null}
            </TableSortLabel>
          </StyledTableCell>
        ))}
        <StyledTableCell align="right"></StyledTableCell>
      </TableRow>
    </TableHead>
  );
}

EnhancedTableHead.propTypes = {
  classes: PropTypes.object.isRequired,
  onRequestSort: PropTypes.func.isRequired,
  order: PropTypes.oneOf(["asc", "desc"]).isRequired,
  orderBy: PropTypes.string.isRequired,
};

function TabPanel(props) {
  const { children, value, index, ...other } = props;

  return (
    <div
      role="tabpanel"
      hidden={value !== index}
      id={`full-width-tabpanel-${index}`}
      aria-labelledby={`full-width-tab-${index}`}
      {...other}
    >
      {value === index && (
        <Box sx={{ p: 3 }}>
          <div>{children}</div>
        </Box>
      )}
    </div>
  );
}

TabPanel.propTypes = {
  children: PropTypes.node,
  index: PropTypes.number.isRequired,
  value: PropTypes.number.isRequired,
};

function a11yProps(index) {
  return {
    id: `full-width-tab-${index}`,
    "aria-controls": `full-width-tabpanel-${index}`,
  };
}

export default function LeaveHistory(props) {
  const theme = useTheme();
  const [value, setValue] = React.useState(0);

  const handleChange = (event, newValue) => {
    setValue(newValue);
  };

  const handleSwipe = (delta) => {
    if (delta > 0 && value > 0) {
      setValue(value - 1);
    } else if (delta < 0 && value < 1) {
      setValue(value + 1);
    }
  };

  const swipeHandlers = useSwipeable({
    onSwipedLeft: () => handleSwipe(-1),
    onSwipedRight: () => handleSwipe(1),
    preventDefaultTouchmoveEvent: true,
    trackMouse: true, // Enables swipe gestures for mouse input as well
  });

  return (
    <Box sx={{ bgcolor: "background.paper", height: "100%" }}>
      <AppBar position="static">
        <Tabs
          value={value}
          onChange={handleChange}
          indicatorColor="secondary"
          textColor="secondary"
          variant="fullWidth"
          aria-label="full width tabs example"
        >
          <Tab sx={{ color: "#fff" }} label="Employee" {...a11yProps(0)} />
          <Tab sx={{ color: "#fff" }} label="Overall" {...a11yProps(1)} />
        </Tabs>
      </AppBar>
      <div {...swipeHandlers}>
        <TabPanel
          sx={{ height: "100%" }}
          value={value}
          index={0}
          dir={theme.direction}
        >
          <LeaveReportUser />
        </TabPanel>
        <TabPanel value={value} index={1} dir={theme.direction}>
          <LeaveReportOverall />
        </TabPanel>
      </div>
    </Box>
  );
}

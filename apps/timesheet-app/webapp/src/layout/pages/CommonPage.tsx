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

//-------React Imports---------
import React from "react";
import { useEffect, useState } from "react";
import { useSearchParams } from "react-router-dom";

//-------MUI Imports---------
import {
  Box,
  IconButton,
  InputAdornment,
  Popper,
  Stack,
  Tab,
  Tabs,
  TextField,
  Typography,
} from "@mui/material";
import { alpha } from "@mui/material/styles";
import SendIcon from "@mui/icons-material/Send";
import SearchIcon from "@mui/icons-material/Search";
import FilterAltOutlinedIcon from "@mui/icons-material/FilterAltOutlined";

//-------App Imports---------
import SearchFilter from "@component/ui/SearchFilter";

interface CommonPageProps {
  title: string;
  commonPageTabs: TabProps[];
}

interface TabProps {
  tabTitle: string;
  tabPath: string;
  icon: React.ReactElement<any, string | React.JSXElementConstructor<any>>;
  page: React.ReactElement<any, string | React.JSXElementConstructor<any>>;
}

const CommonPage = ({ title, commonPageTabs }: CommonPageProps) => {
  const [searchParams, setSearchParams] = useSearchParams();
  const [value, setValue] = useState<number>(0);
  const tabs = commonPageTabs.map((tab) => tab.tabPath);
  const [searchContent, setSearchContent] = useState("");

  useEffect(() => {
    const currentTab = searchParams.get("tab");
    if (currentTab && tabs.indexOf(currentTab) !== -1) {
      setValue(tabs.indexOf(currentTab));
    } else {
      searchParams.set("tab", tabs[0]);
      setSearchParams(searchParams);
    }
  }, [searchParams]);

  const handleChange = (event: React.SyntheticEvent, newValue: number) => {
    setValue(newValue);
  };

  const [anchorEl, setAnchorEl] = useState<null | HTMLElement>(null);
  const handleClick = (event: React.MouseEvent<HTMLElement>) => {
    setAnchorEl(anchorEl ? null : event.currentTarget);
  };

  return (
    <Box
      sx={{
        height: "100%",
      }}
    >
      <Box
        sx={{
          display: "flex",
          flexDirection: "row",
          gap: 2,
          p: 0,
          alignItems: "center",
        }}
      >
        <SendIcon color="primary" />
        <Stack flexDirection="row" gap={1}>
          <Typography variant="h5" fontWeight="bold">
            {title}
          </Typography>
          <Typography variant="h6" color={"secondary.dark"}>
            /{searchParams.get("tab")}
          </Typography>
        </Stack>
        <Stack
          sx={{ ml: "auto" }}
          flexDirection={"row"}
          gap={1.2}
          alignItems={"center"}
        >
          {/* Search */}
          <TextField
            size="small"
            label="Search"
            variant="outlined"
            value={searchContent}
            onChange={(e) => setSearchContent(e.target.value)}
            InputProps={{
              startAdornment: (
                <InputAdornment position="start">
                  <SearchIcon />
                </InputAdornment>
              ),
            }}
            sx={{
              width: 250,
              "& .MuiInputBase-input": {
                borderColor: "secondary.dark",
              },
            }}
          />
          <IconButton
            sx={{
              border: 1,
              borderColor: "secondary.dark",
              borderRadius: 1.2,
              p: 0.8,
            }}
            onClick={handleClick}
          >
            <FilterAltOutlinedIcon />
          </IconButton>
        </Stack>
        <Popper
          open={Boolean(anchorEl)}
          anchorEl={anchorEl}
          placement="bottom-start"
        >
          <SearchFilter />
        </Popper>
      </Box>

      {/* -------Tabs--------- */}
      <Stack flexDirection="row" sx={{ mt: 1 }}>
        <Tabs
          value={value}
          onChange={handleChange}
          sx={{
            alignItems: "center",
            "&.MuiTabs-root": {
              minHeight: 0,
              borderTopLeftRadius: 5,
            },
            ".MuiTab-root": {
              borderTopLeftRadius: 5,
              borderTopRightRadius: 5,
            },
            "& .MuiTabs-indicator": {
              display: "none",
            },
          }}
        >
          {commonPageTabs.map((tab, index) => (
            <Tab
              icon={tab.icon}
              label={tab.tabTitle}
              onClick={() => setSearchParams({ tab: tabs[index] })}
              iconPosition="start"
              sx={{
                minHeight: 0,
                lineHeight: 0,
                background:
                  tabs[index] === searchParams.get("tab")
                    ? (theme) =>
                        alpha(
                          theme.palette.primary.main,
                          theme.palette.action.activatedOpacity
                        )
                    : "inherit",
              }}
            />
          ))}
        </Tabs>
        <Box
          sx={{
            ml: "auto",
            alignSelf: "center",
            display:
              searchParams.get("tab") === "send-offer" ? "block" : "none",
          }}
        ></Box>
      </Stack>

      {commonPageTabs.map((tab, index) => (
        <TabPanel value={value} index={index}>
          {tab.page}
        </TabPanel>
      ))}
    </Box>
  );
};
interface TabPanelProps {
  children?: React.ReactNode;
  index: number;
  value: number;
}

function TabPanel(props: TabPanelProps) {
  const { children, value, index, ...other } = props;

  return (
    <div
      role="tabpanel"
      hidden={value !== index}
      id={`simple-tabpanel-${index}`}
      aria-labelledby={`simple-tab-${index}`}
      {...other}
      style={{ height: `calc(100% - 85px)` }}
    >
      {value === index && (
        <Box
          sx={{
            p: 2,
            overflow: "auto",
            height: "100%",
            borderTop: "none",
            background: (theme) =>
              alpha(
                theme.palette.primary.main,
                theme.palette.action.activatedOpacity
              ),
            borderRadius: 3,
            borderTopLeftRadius: 0,
          }}
        >
          {children}
        </Box>
      )}
    </div>
  );
}

export default CommonPage;

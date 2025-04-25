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

import React from "react";
import { useEffect, useState } from "react";
import { alpha } from "@mui/material/styles";
import { useSearchParams } from "react-router-dom";
import { Box, Stack, Tab, Tabs, Typography } from "@mui/material";

interface CommonPageProps {
  title: string;
  commonPageTabs: TabProps[];
  icon?: React.ReactElement<any, string | React.JSXElementConstructor<any>>;
}

interface TabProps {
  tabTitle: string;
  tabPath: string;
  icon: React.ReactElement<any, string | React.JSXElementConstructor<any>>;
  page: React.ReactElement<any, string | React.JSXElementConstructor<any>>;
}

const CommonPage = ({ title, commonPageTabs, icon }: CommonPageProps) => {
  const [searchParams, setSearchParams] = useSearchParams();
  const [value, setValue] = useState<number>(0);
  const tabs = commonPageTabs.map((tab) => tab.tabPath);

  useEffect(() => {
    const currentTab = searchParams.get("tab");
    if (currentTab && tabs.indexOf(currentTab) !== -1) {
      setValue(tabs.indexOf(currentTab));
    } else {
      searchParams.set("tab", tabs[0]);
      setSearchParams(searchParams);
    }
  }, [searchParams, setSearchParams, tabs]);

  const handleChange = (event: React.SyntheticEvent, newValue: number) => {
    setValue(newValue);
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
          gap: 0.5,
          alignItems: "center",
        }}
      >
        {icon && <Box sx={{ ml: 0.8, mt: 0.5 }}>{icon}</Box>}
        <Stack
          sx={{
            p: 0.8,
          }}
          flexDirection="row"
          gap={1}
        >
          <Typography variant="h5" fontWeight="bold">
            {title}
          </Typography>
          <Typography variant="h6" color={"secondary.main"}>
            /{searchParams.get("tab")}
          </Typography>
        </Stack>
      </Box>

      {/* -------Tabs--------- */}
      <Stack flexDirection="row" sx={{ mt: 0.7 }}>
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
              key={index}
              icon={tab.icon}
              label={tab.tabTitle}
              onClick={() => setSearchParams({ tab: tabs[index] })}
              iconPosition="start"
              sx={(theme) => ({
                minHeight: 0,
                lineHeight: 0,
                py: 0.7,
                background:
                  tabs[index] === searchParams.get("tab") ? alpha(theme.palette.primary.light, 0.2) : "inherit",
              })}
            />
          ))}
        </Tabs>
      </Stack>
      {commonPageTabs.map((tab, index) => (
        <TabPanel key={tab.tabPath || index} value={value} index={index}>
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
      style={{ height: `calc(100% - 70px)` }}
    >
      {value === index && (
        <Box
          sx={(theme) => ({
            boxShadow: theme.palette.mode === "dark" ? "0px 3px 10px rgba(120, 125, 129, 0.5)" : 10,
            overflow: "auto",
            height: "100%",
            background: "background.paper",
            borderTopRightRadius: 12,
            borderTopLeftRadius: value === 0 ? 0 : 12,
            borderBottomLeftRadius: 12,
            borderBottomRightRadius: 12,
          })}
        >
          {children}
        </Box>
      )}
    </div>
  );
}

export default CommonPage;

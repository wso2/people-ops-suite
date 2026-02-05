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
import { Box, Button, Typography, useTheme } from "@mui/material";
import { AnimatePresence, motion } from "framer-motion";
import { useSearchParams } from "react-router-dom";

import React, { useEffect, useMemo, useState } from "react";

interface TabsPageProps {
  title: string;
  tabsPage: TabProps[];
}

interface TabProps {
  tabTitle: string;
  tabPath: string;
  icon: React.ReactElement<any, string | React.JSXElementConstructor<any>>;
  page: React.ReactElement<any, string | React.JSXElementConstructor<any>>;
}

export default function TabsPage({ tabsPage }: TabsPageProps) {
  const [searchParams, setSearchParams] = useSearchParams();
  const [value, setValue] = useState<number>(0);

  const tabs = useMemo(() => tabsPage.map((tab) => tab.tabPath), [tabsPage]);

  useEffect(() => {
    const currentTab = searchParams.get("tab");
    const tabIndex = currentTab ? tabs.indexOf(currentTab) : -1;

    if (tabIndex !== -1) {
      setValue(tabIndex);
    } else {
      setValue(0);
      setSearchParams({ tab: tabs[0] }, { replace: true });
    }
  }, [searchParams, tabs, setSearchParams]);

  const handleTabClick = (index: number) => {
    setValue(index);
    setSearchParams({ tab: tabs[index] });
  };

  return (
    <Box
      sx={{
        height: "100%",
        transition: "color 200ms",
        display: "flex",
        flexDirection: "column",
        gap: 3,
      }}
    >
      {/* Tab Navigation */}
      <Tabs tabs={tabsPage} activeIndex={value} handleTabClick={handleTabClick} />

      {/* Tab Content with animations */}
      <AnimatePresence mode="wait">
        {tabsPage.map(
          (tab, index) =>
            value === index && (
              <Box
                component={motion.div}
                key={index}
                initial={{ opacity: 0, x: 20 }}
                animate={{ opacity: 1, x: 0 }}
                exit={{ opacity: 0, x: -20 }}
                transition={{ duration: 0.3, ease: "easeInOut" }}
                sx={{ width: "100%" }}
              >
                <TabPanel value={value} index={index}>
                  {tab.page}
                </TabPanel>
              </Box>
            ),
        )}
      </AnimatePresence>
    </Box>
  );
}

interface TabToggleProps {
  tabs: TabProps[];
  activeIndex: number;
  handleTabClick: (index: number) => void;
}

export function Tabs({ tabs, activeIndex, handleTabClick }: TabToggleProps) {
  const theme = useTheme();

  return (
    <Box sx={{ display: "flex", flexDirection: "row" }}>
      <Box
        sx={{
          display: "flex",
          borderBottom: 1,
          borderColor: theme.palette.customBorder.territory.active,
          width: "100%",
          position: "relative",
          transition: "color 200ms",
          gap: 1,
        }}
        role="tablist"
        aria-orientation="horizontal"
      >
        {tabs.map((tab, index) => (
          <Box
            key={index}
            sx={{ display: "flex", flexDirection: "column", gap: 1, alignItems: "center" }}
          >
            <Button
              component={motion.button}
              onClick={() => handleTabClick(index)}
              disableRipple
              role="tab"
              id={`simple-tab-${index}`}
              aria-selected={activeIndex === index}
              aria-controls={`simple-tabpanel-${index}`}
              tabIndex={activeIndex === index ? 0 : -1}
              sx={{
                display: "flex",
                gap: 1,
                borderRadius: "6px",
                backgroundColor:
                  activeIndex === index ? theme.palette.fill.primary_light.active : "none",
                color:
                  activeIndex === index
                    ? theme.palette.customText.brand.p1.active
                    : theme.palette.customText.primary.p2.active,
                "&:hover": {
                  backgroundColor:
                    activeIndex === index ? theme.palette.fill.primary_light.active : "transparent",
                },
              }}
            >
              <Box
                component="span"
                sx={{ width: "fit-content", display: "flex", alignItems: "center" }}
              >
                {React.cloneElement(tab.icon)}
              </Box>
              <Typography
                variant={activeIndex === index ? "body1" : "body1"}
                sx={{
                  color: activeIndex === index ? theme.palette.customText.brand.p1.active : "none",
                }}
              >
                {tab.tabTitle}
              </Typography>
            </Button>
            <Box
              sx={{
                height: "2px",
                width: "75%",
                position: "relative",
                top: "1.5px",
                backgroundColor:
                  activeIndex === index ? theme.palette.customBorder.brand.active : "transparent",
              }}
            />
          </Box>
        ))}
      </Box>
    </Box>
  );
}

interface TabPanelProps {
  children?: React.ReactNode;
  index: number;
  value: number;
}

export function TabPanel(props: TabPanelProps) {
  const { children, value, index, ...other } = props;

  return (
    <Box
      role="tabpanel"
      id={`simple-tabpanel-${index}`}
      aria-labelledby={`simple-tab-${index}`}
      {...other}
      sx={{
        maxHeight: "calc(100vh - 150px)",
        overflowY: "auto",
        // Hide scrollbar for Chrome, Safari and Opera
        "&::-webkit-scrollbar": {
          display: "none",
        },
        // Hide scrollbar for IE, Edge and Firefox
        msOverflowStyle: "none",
        scrollbarWidth: "none",
      }}
    >
      <Box
        component={motion.div}
        initial={{ opacity: 0, y: 10 }}
        animate={{ opacity: 1, y: 0 }}
        transition={{ duration: 0.4, ease: "easeOut", delay: 0.1 }}
      >
        {children}
      </Box>
    </Box>
  );
}

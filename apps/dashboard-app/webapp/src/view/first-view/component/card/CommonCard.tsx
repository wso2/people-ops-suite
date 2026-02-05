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

import AccountCircleIcon from "@mui/icons-material/AccountCircle";
import BadgeIcon from "@mui/icons-material/Badge";
import BusinessIcon from "@mui/icons-material/Business";
import CalendarMonthIcon from "@mui/icons-material/CalendarMonth";
import CallIcon from "@mui/icons-material/Call";
import Diversity3Icon from "@mui/icons-material/Diversity3";
import EmailIcon from "@mui/icons-material/Email";
import EventIcon from "@mui/icons-material/Event";
import ExpandMoreIcon from "@mui/icons-material/ExpandMore";
import FunctionsIcon from "@mui/icons-material/Functions";
import Groups2Icon from "@mui/icons-material/Groups2";
import KeyboardIcon from "@mui/icons-material/Keyboard";
import LocationOnIcon from "@mui/icons-material/LocationOn";
import StoreIcon from "@mui/icons-material/Store";
import WorkIcon from "@mui/icons-material/Work";
import {
  Accordion,
  AccordionDetails,
  AccordionSummary,
  Avatar,
  Grid,
  Grow,
  IconButton,
  Stack,
  Typography,
} from "@mui/material";

import { useState } from "react";

import CandidateInfoCard from "@component/ui/common-card/components/CandidateInfoCard";
import CandidateMainInfoCard from "@component/ui/common-card/components/CandidateMainInfoCard";
import { CommonCardProps } from "@utils/types";

const DataCard = ({ collection, actions, dataCardIndex }: CommonCardProps) => {
  const [expand, setExpand] = useState(false);
  const toggleAccordion = () => {
    setExpand((prev) => !prev);
  };
  return (
    <Grow
      in={true}
      style={{ transformOrigin: "0 0 0" }}
      {...(dataCardIndex ? { timeout: dataCardIndex * 1000 } : {})}
    >
      <Stack>
        <Accordion
          variant="outlined"
          square
          expanded={expand}
          sx={{
            borderRadius: 3,
            "&.MuiAccordion-root:before": {
              backgroundColor: "transparent",
            },
            borderLeft: 8,
            borderLeftColor: "divider",
          }}
        >
          <AccordionSummary
            expandIcon={
              <IconButton onClick={toggleAccordion}>
                <ExpandMoreIcon />
              </IconButton>
            }
            sx={{ width: "100%" }}
          >
            <Stack flexDirection={"column"} sx={{ width: "100%" }}>
              <Stack flexDirection={"row"} sx={{ m: 0, width: "100%", alignItems: "center" }}>
                <Stack flexDirection={"row"} sx={{ alignItems: "center" }}>
                  <Avatar sx={{ width: 70, height: 70 }} color="primary.main">
                    {collection.name}
                  </Avatar>
                  <Stack sx={{ ml: 3, alignItems: "left" }} gap={0.3}>
                    <Typography variant="h5" sx={{ fontWeight: 650 }}>
                      {collection.name}
                    </Typography>

                    <Stack flexDirection={"row"} gap={0.5}>
                      <EmailIcon
                        sx={{
                          color: "primary.dark",
                          fontSize: 13,
                        }}
                      />
                      <Typography variant="body2" color="primary.dark">
                        {"sample data"}
                      </Typography>
                    </Stack>
                    <Stack flexDirection={"row"} gap={0.5}>
                      <CallIcon
                        sx={{
                          color: "secondary.dark",
                          fontSize: 13,
                        }}
                      />
                      <Typography variant="body2" color="secondary.dark">
                        {"sample data"}
                      </Typography>
                    </Stack>
                    <Stack flexDirection={"row"} gap={0.5}>
                      <LocationOnIcon
                        sx={{
                          color: "secondary.dark",
                          fontSize: 13,
                        }}
                      />
                      <Typography variant="body2" color="secondary.dark">
                        {"sample data"}
                      </Typography>
                    </Stack>
                  </Stack>
                </Stack>
                <Stack sx={{ ml: "auto" }}>
                  <Stack
                    flexDirection={"row"}
                    gap={2}
                    sx={{ ml: "auto", mb: 1.5 }}
                    alignItems={"center"}
                  >
                    {actions}
                  </Stack>
                  <Grid
                    container
                    flexDirection={"row"}
                    sx={{ width: "auto", ml: "auto", mr: 1 }}
                    gap={2}
                  >
                    <CandidateMainInfoCard
                      title={"Sample Data"}
                      subTitle={"sample data"}
                      icon={<WorkIcon />}
                    />
                    <CandidateMainInfoCard
                      title={"Sample Data"}
                      subTitle={"sample data"}
                      icon={<BadgeIcon />}
                    />
                    <CandidateMainInfoCard
                      title={"Sample Data"}
                      subTitle={"sample data"}
                      icon={<AccountCircleIcon />}
                    />
                    <CandidateMainInfoCard
                      title={"Sample Data"}
                      subTitle={"sample data"}
                      icon={<CalendarMonthIcon />}
                    />
                  </Grid>
                </Stack>
              </Stack>
            </Stack>
          </AccordionSummary>
          <AccordionDetails>
            <Grid container flexDirection={"row"} columns={{ xs: 4 }} gap={4}>
              <CandidateInfoCard
                title={"Sample Data"}
                items={[
                  {
                    title: "Sample Data",
                    subTitle: "sample data",
                    icon: <AccountCircleIcon />,
                  },
                  {
                    title: "Sample Data",
                    subTitle: "sample data",
                    icon: <EmailIcon />,
                  },
                  {
                    title: "Sample Data",
                    subTitle: "sample data",
                    icon: <WorkIcon />,
                  },
                  {
                    title: "Sample Data",
                    subTitle: "sample data",
                    icon: <CalendarMonthIcon />,
                  },
                  {
                    title: "sample data",
                    subTitle: "sample data",
                    icon: <EventIcon />,
                  },
                ]}
              />
              <CandidateInfoCard
                title={"Sample Data"}
                items={[
                  {
                    title: "Sample Data",
                    subTitle: "sample data",
                    icon: <WorkIcon />,
                  },
                  {
                    title: "Sample Data",
                    subTitle: "sample data",
                    icon: <FunctionsIcon />,
                  },
                  {
                    title: "Sample Data",
                    subTitle: "sample data",
                    icon: <LocationOnIcon />,
                  },
                  {
                    title: "Sample Data",
                    subTitle: "sample data",
                    icon: <EmailIcon />,
                  },
                  {
                    title: "Sample Data",
                    subTitle: "sample data",
                    icon: <BadgeIcon />,
                  },
                ]}
              />
              <CandidateInfoCard
                title={"Sample Data"}
                items={[
                  {
                    title: "Sample Data",
                    subTitle: "sample data",
                    icon: <BusinessIcon />,
                  },
                  {
                    title: "Sample Data",
                    subTitle: "sample data",
                    icon: <StoreIcon />,
                  },
                  {
                    title: "Sample Data",
                    subTitle: "sample data",
                    icon: <Groups2Icon />,
                  },
                  {
                    title: "Sample Data",
                    subTitle: "sample data",
                    icon: <Diversity3Icon />,
                  },
                  {
                    title: "Sample Data",
                    subTitle: "sample data",
                    icon: <AccountCircleIcon />,
                  },
                  {
                    title: "Sample Data",
                    subTitle: "sample data",
                    icon: <KeyboardIcon />,
                  },
                ]}
              />
            </Grid>
          </AccordionDetails>
        </Accordion>
      </Stack>
    </Grow>
  );
};

export default DataCard;

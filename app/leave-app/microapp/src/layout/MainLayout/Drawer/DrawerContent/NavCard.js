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

import { Box, Button, Collapse, Link, Stack, Typography } from "@mui/material";

import MainCard from "../../../../components/MainCard";
import { getGmailMailTo } from "../../../../utils/formatting";
import { LEAVE_APP } from "../../../../constants";

const NavCard = () => (
  <MainCard sx={{ bgcolor: "grey.50", m: 3 }}>
    <Stack alignItems="center" spacing={2.5}>
      <Collapse
        in={true}
        orientation="horizontal"
        classes={{ wrapperInner: { width: "100%" } }}
        timeout={2}
      >
        <Box
          sx={{
            backgroundColor: "background.default",
            m: 2,
            p: 2,
          }}
        >
          <Typography align="center" gutterBottom variant="h4" noWrap>
            Need help?
          </Typography>
          <Typography align="center" variant="body2" noWrap>
            Contact Internal Apps
          </Typography>
          <Box
            sx={{
              display: "flex",
              justifyContent: "center",
              pt: 2,
            }}
          >
            <Link
              href={getGmailMailTo(
                LEAVE_APP.EMAILS.GET_HELP_EMAIL_TO,
                LEAVE_APP.EMAILS.GET_HELP_EMAIL_SUBJECT
              )}
              target="_blank"
              rel="noreferrer"
            >
              <Button color="primary" variant="contained">
                Get Help
              </Button>
            </Link>
          </Box>
        </Box>
      </Collapse>
    </Stack>
  </MainCard>
);

export default NavCard;

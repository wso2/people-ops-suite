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

import DuoIcon from "@mui/icons-material/Duo";
import CommonPage from "@layout/pages/CommonPage";
import HistoryIcon from "@mui/icons-material/History";
import VideoCallIcon from "@mui/icons-material/VideoCall";
import CreateMeeting from "@view/meetings/panel/createMeeting";
import MeetingHistory from "@view/meetings/panel/meetingHistory";

export default function Meetings() {
  return (
    <CommonPage
      title="Meetings"
      icon={<DuoIcon />}
      commonPageTabs={[
        {
          tabTitle: "Create Meeting",
          tabPath: "create-meeting",
          icon: <VideoCallIcon />,
          page: <CreateMeeting />,
        },
        {
          tabTitle: "Meeting History",
          tabPath: "meeting-history",
          icon: <HistoryIcon />,
          page: <MeetingHistory />,
        },
      ]}
    />
  );
}

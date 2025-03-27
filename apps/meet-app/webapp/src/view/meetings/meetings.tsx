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

// MUI imports
import VideoCallIcon from "@mui/icons-material/VideoCall";
import HistoryIcon from "@mui/icons-material/History";

// App imports
import CommonPage from "@layout/pages/CommonPage";
import CreateMeeting from "./panel/createMeeting";
import MeetingHistory from "./panel/meetingHistory";

export default function OfferLetter() {
  return (
    <CommonPage
      title="Meetings"
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

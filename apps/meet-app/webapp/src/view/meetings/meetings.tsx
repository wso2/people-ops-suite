// Copyright (c) 2025, WSO2 LLC. (https://www.wso2.com). All Rights Reserved.
//
// This software is the property of WSO2 LLC. and its suppliers, if any.
// Dissemination of any information or reproduction of any material contained
// herein in any form is strictly forbidden, unless permitted by WSO2 expressly.
// You may not alter or remove any copyright or other notice from copies of this content.

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

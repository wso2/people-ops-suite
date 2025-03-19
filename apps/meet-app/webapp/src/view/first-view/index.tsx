// Copyright (c) 2024, WSO2 LLC. (https://www.wso2.com). All Rights Reserved.
//
// This software is the property of WSO2 LLC. and its suppliers, if any.
// Dissemination of any information or reproduction of any material contained
// herein in any form is strictly forbidden, unless permitted by WSO2 expressly.
// You may not alter or remove any copyright or other notice from copies of this content.

import React from "react";

// MUI imports
import AttachEmailIcon from "@mui/icons-material/AttachEmail";
import MarkEmailReadIcon from "@mui/icons-material/MarkEmailRead";

// App imports
import CommonPage from "../../layout/pages/CommonPage";
import TabOnePanel from "./panel/TabOnePanel";

export default function OfferLetter() {
  return (
    <CommonPage
      title="Menu 1"
      commonPageTabs={[
        {
          tabTitle: "Tab 1",
          tabPath: "tab-one",
          icon: <AttachEmailIcon />,
          page: <TabOnePanel />,
        },
        {
          tabTitle: "Tab 2",
          tabPath: "tab-two",
          icon: <MarkEmailReadIcon />,
          page: <></>,
        },
      ]}
    />
  );
}

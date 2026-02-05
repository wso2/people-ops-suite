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

import AttachEmailIcon from "@mui/icons-material/AttachEmail";
import MarkEmailReadIcon from "@mui/icons-material/MarkEmailRead";

import TabsPage from "@layout/pages/TabsPage";

import TabOnePanel from "./panel/TabOnePanel";

export default function OfferLetter() {
  return (
    <TabsPage
      title="Menu 1"
      tabsPage={[
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

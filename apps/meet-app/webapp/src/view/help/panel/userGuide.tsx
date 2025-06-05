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

import { Box } from "@mui/material";
import { useState, useEffect } from "react";
import { useTheme } from "@mui/material/styles";
import MarkdownPreview from "@uiw/react-markdown-preview";
import { fetchAppConfig } from "@slices/configSlice/config";
import { useAppDispatch, useAppSelector } from "@slices/store";

function UserGuide() {
  const theme = useTheme();
  const dispatch = useAppDispatch();
  const imageStyle = {
    maxWidth: "80%",
    height: "auto",
    display: "block",
    margin: "0 auto",
  };
  const [markdownContent, setMarkdownContent] = useState("");

  useEffect(() => {
    dispatch(fetchAppConfig());
    fetch("/README.md")
      .then((response) => response.text())
      .then((text) => setMarkdownContent(text))
      .catch((error) => console.error("Error fetching README.md file:", error));
  }, [dispatch]);

  const supportTeamEmails = useAppSelector((state) => state.appConfig.config?.supportTeamEmails) || [];
  const supportTeams = supportTeamEmails
    .map(({ team, email }) => `- For **${team.toLowerCase()}**, email: [${email}](mailto:${email})`)
    .join("\n");
  const doc = markdownContent + supportTeams;

  return (
    <Box>
      <Box
        sx={{
          display: "grid",
          gridTemplateColumns: "1fr",
          paddingX: 2,
          paddingY: 2,
        }}
      >
        <MarkdownPreview
          source={doc}
          style={{
            backgroundColor: theme.palette.background.default,
            overflow: "auto",
            padding: theme.spacing(3),
            color: theme.palette.primary.main,
          }}
          rehypeRewrite={(node, index, parent) => {
            if (
              node.type === "element" &&
              node.tagName === "a" &&
              parent?.type === "element" &&
              /^h(1|2|3|4|5|6)/.test(parent.tagName)
            ) {
              parent.children = parent.children.slice(1);
            }
          }}
          components={{
            img: ({ ...props }) => <img {...props} style={imageStyle} />,
          }}
        />
      </Box>
    </Box>
  );
}

export default UserGuide;

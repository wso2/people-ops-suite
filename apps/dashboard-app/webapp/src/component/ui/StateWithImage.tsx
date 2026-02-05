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
import { Box, Typography } from "@mui/material";

function StateWithImage(props: { message: string; imageUrl: string; hideImage?: boolean }) {
  return (
    <Box sx={{ display: "flex", flexDirection: "column", alignItems: "center", gap: 5 }}>
      {!props.hideImage && <img alt="logo" width="140" height="auto" src={props.imageUrl}></img>}

      <Typography
        variant="h5"
        sx={(theme) => ({
          color: theme.palette.grey[500],
          textAlign: "center",
        })}
      >
        {props.message}
      </Typography>
    </Box>
  );
}

export default StateWithImage;

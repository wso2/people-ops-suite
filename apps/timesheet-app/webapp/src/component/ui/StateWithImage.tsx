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

import { GridOverlay } from "@mui/x-data-grid";
import { Box, Typography } from "@mui/material";
import { StateWithImageProps } from "@utils/types";

export function StateWithImageFunction({ message, imageUrl }: StateWithImageProps) {
  return (
    <GridOverlay>
      <StateWithImage message={message} imageUrl={imageUrl} />
    </GridOverlay>
  );
}

function StateWithImage(props: { message: string; imageUrl: string }) {
  return (
    <Box width="100%" display="flex" flexDirection="column" alignItems="center" justifyContent="center" mt={2} gap={2}>
      <Box
        component="img"
        alt="logo"
        src={props.imageUrl}
        sx={{ width: "10%", height: "auto", maxWidth: "150px", maxHeight: "150px" }}
      />
      <Typography variant="h5" sx={{ color: (theme) => theme.palette.secondary.dark, textAlign: "center" }}>
        {props.message}
      </Typography>
    </Box>
  );
}
export default StateWithImage;

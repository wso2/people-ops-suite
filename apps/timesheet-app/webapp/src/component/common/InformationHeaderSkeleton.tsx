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
// under the License.import React from "react";
import { Box, Card, Grid, Stack, Divider, useTheme, Skeleton, CardContent } from "@mui/material";
import React from "react";

interface InformationHeaderSkeletonProps {
  isLeadView?: boolean;
  isEmployeeView?: boolean;
}

const InformationHeaderSkeleton: React.FC<InformationHeaderSkeletonProps> = ({ isLeadView, isEmployeeView }) => {
  const theme = useTheme();

  return (
    <Card
      sx={{
        borderRadius: 2,
        boxShadow: theme.shadows[3],
      }}
    >
      <CardContent>
        <Stack
          direction="row"
          spacing={1}
          sx={{
            flexWrap: "wrap",
            gap: 1,
            justifyContent: "center",
          }}
        >
          {[1, 2, 3, 4].map((index) => (
            <Skeleton key={`chip-${index}`} variant="rounded" width={120} height={32} sx={{ borderRadius: 16 }} />
          ))}
          {!isLeadView && !isEmployeeView && (
            <>
              <Skeleton variant="rounded" width={180} height={32} sx={{ borderRadius: 16 }} />
              <Skeleton variant="rounded" width={220} height={32} sx={{ borderRadius: 16 }} />
              <Skeleton variant="rounded" width={150} height={32} sx={{ borderRadius: 16 }} />
            </>
          )}
        </Stack>

        {!isLeadView && (
          <>
            <Divider sx={{ my: 1 }} />
            <Grid container spacing={3}>
              {[1, 2, 3, 4, 5].map((index) => (
                <Grid item xs={12} sm={2.4} md={2.4} lg={2.4} key={`stat-${index}`}>
                  <Box sx={{ display: "flex", alignItems: "center", mb: 1 }}>
                    <Box>
                      <Skeleton variant="text" width={80} height={30} />
                    </Box>
                  </Box>
                  <Skeleton variant="text" width={140} height={20} />
                  <Skeleton variant="rounded" width="100%" height={6} sx={{ borderRadius: 3}} />
                </Grid>
              ))}
            </Grid>
          </>
        )}
      </CardContent>
    </Card>
  );
};

export default InformationHeaderSkeleton;

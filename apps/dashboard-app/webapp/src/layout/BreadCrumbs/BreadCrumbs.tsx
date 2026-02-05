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
import { Box, Breadcrumbs, Tooltip, Typography, useTheme } from "@mui/material";
import { Link, useLocation } from "react-router-dom";

const MAX_LENGTH = 10;
const TRUNCATE_LENGTH = 4;

export default function BasicBreadcrumbs() {
  const location = useLocation();
  const theme = useTheme();

  const { pathname } = location;
  const pathnames = pathname === "/" ? [] : pathname.split("/");

  const styles = {
    breadcrumbItem: {
      textDecoration: "none",
      padding: theme.spacing(0.5),
      borderRadius: "4px",
      transition: "all 0.2s",
      display: "flex",
      alignItems: "center",
      "&:hover": {
        color: theme.palette.customText.primary.p2.active,
      },
    },
  };

  const createLabel = (path: string, shouldTruncate: boolean) => (
    <Typography variant="caption" sx={{ color: theme.palette.customText.primary.p3.active }}>
      {shouldTruncate ? `${path.slice(0, TRUNCATE_LENGTH)}...` : path}
    </Typography>
  );

  const buildRouteTo = (index: number) => {
    return "/" + pathnames.slice(1, index + 1).join("/");
  };

  const renderBreadcrumbItem = (path: string, index: number) => {
    const isLast = index === pathnames.length - 1;
    const isLong = path.length > MAX_LENGTH;
    const shouldTruncate = !isLast && isLong;
    const routeTo = buildRouteTo(index);

    const label = createLabel(path, shouldTruncate);

    const breadcrumbLink = (
      <Box component={Link} to={routeTo} sx={styles.breadcrumbItem}>
        {label}
      </Box>
    );

    if (isLast) {
      return (
        <Box key={`breadcrumb-${index}`} sx={styles.breadcrumbItem}>
          {label}
        </Box>
      );
    }

    if (shouldTruncate) {
      return (
        <Tooltip key={`breadcrumb-${index}`} title={path} placement="bottom">
          {breadcrumbLink}
        </Tooltip>
      );
    }

    return <Box key={`breadcrumb-${index}`}>{breadcrumbLink}</Box>;
  };

  return (
    <Box sx={{ ml: -0.5 }}>
      <Breadcrumbs
        separator="›"
        aria-label="breadcrumb"
        sx={{
          "& .MuiBreadcrumbs-separator": {
            mx: "8px",
          },
        }}
      >
        {pathnames.map(renderBreadcrumbItem)}
      </Breadcrumbs>
    </Box>
  );
}

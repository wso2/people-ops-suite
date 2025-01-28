// Copyright (c) 2024 WSO2 LLC. (https://www.wso2.com).
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
import PropTypes from "prop-types";

import { useTheme } from "@mui/material/styles";
import { Box } from "@mui/material";

const Dot = ({ color, size }) => {
  const theme = useTheme();
  let main;
  switch (color) {
    case "secondary":
      main = theme.palette.secondary.main;
      break;
    case "error":
      main = theme.palette.error.main;
      break;
    case "warning":
      main = theme.palette.warning.main;
      break;
    case "info":
      main = theme.palette.info.main;
      break;
    case "success":
      main = theme.palette.success.main;
      break;
    case "primary":
    default:
      main = theme.palette.primary.main;
  }

  return (
    <Box
      sx={{
        width: size || 8,
        height: size || 8,
        borderRadius: "50%",
        bgcolor: main,
      }}
    />
  );
};

Dot.propTypes = {
  color: PropTypes.string,
  size: PropTypes.number,
};

export default Dot;

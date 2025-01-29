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
import { merge } from "lodash";

import Badge from "./Badge";
import Box from "./Box";
import Button from "./Button";
import CardContent from "./CardContent";
import Checkbox from "./Checkbox";
import Chip from "./Chip";
import IconButton from "./IconButton";
import InputLabel from "./InputLabel";
import LinearProgress from "./LinearProgress";
import Link from "./Link";
import ListItemIcon from "./ListItemIcon";
import OutlinedInput from "./OutlinedInput";
import Tab from "./Tab";
import TableCell from "./TableCell";
import Tabs from "./Tabs";
import Typography from "./Typography";

export default function ComponentsOverrides(theme) {
  return merge(
    Badge(theme),
    Box(theme),
    Button(theme),
    Badge(theme),
    CardContent(),
    Checkbox(theme),
    Chip(theme),
    IconButton(theme),
    InputLabel(theme),
    LinearProgress(),
    Link(),
    ListItemIcon(),
    OutlinedInput(theme),
    Tab(theme),
    TableCell(theme),
    Tabs(),
    Typography()
  );
}

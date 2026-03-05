// Copyright (c) 2026 WSO2 LLC. (https://www.wso2.com).
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

import React from "react";
import { styled } from "@mui/material/styles";
import Radio from "@mui/material/Radio";
import FormControlLabel, {
  FormControlLabelProps,
} from "@mui/material/FormControlLabel";
import { useRadioGroup } from "@mui/material/RadioGroup";

// Renamed for clarity and removed requirement for 'control'
interface StyledRadioProps extends Omit<FormControlLabelProps, "control"> {
  activeColor?: string;
}

const StyledLabel = styled(FormControlLabel, {
  shouldForwardProp: (prop) => prop !== "checked" && prop !== "activeColor",
})<{ checked: boolean; activeColor: string }>(({ checked, activeColor }) => ({
  ".MuiFormControlLabel-label": {
    color: checked ? activeColor : "inherit",
    fontWeight: checked ? 600 : 400,
    transition: "color 0.2s ease-in-out",
  },
}));

export default function StyledRadio({
  activeColor = "#ff7300",
  ...props
}: StyledRadioProps) {
  const radioGroup = useRadioGroup();
  let checked = false;

  if (radioGroup) {
    checked = radioGroup.value === props.value;
  }

  return (
    <StyledLabel
      checked={checked}
      activeColor={activeColor}
      {...props}
      control={
        <Radio
          sx={{
            "&.Mui-checked": {
              color: activeColor,
            },
          }}
        />
      }
    />
  );
}
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
import React, { useState, useEffect } from "react";
import PropTypes from "prop-types";
import { VariableSizeList } from "react-window";
import { useSelector } from "react-redux";

import TextField from "@mui/material/TextField";
import Autocomplete, { createFilterOptions } from "@mui/material/Autocomplete";
import useMediaQuery from "@mui/material/useMediaQuery";
import { useTheme } from "@mui/material/styles";
import { Avatar, Box, Stack } from "@mui/material";
import { Person as PersonIcon } from "@mui/icons-material";

import { checkIfValidEmailAddress } from "../utils/formatting";

const filter = createFilterOptions();

const LISTBOX_PADDING = 8;

function renderRow(props) {
  const { data, index, style } = props;
  const dataSet = data[index][0];
  const item = data[index][1];
  const inlineStyle = {
    ...style,
    top: style.top + LISTBOX_PADDING,
  };

  return (
    <Box
      component="li"
      {...dataSet}
      sx={{ "& > img": { mr: 2, flexShrink: 0 } }}
      {...props}
      style={inlineStyle}
    >
      <Stack direction="row" alignItems="center" spacing={1}>
        {item && (item.employeeThumbnail || item.employeeThumbnail === "") ? (
          <span>
            <Avatar
              size="small"
              loading="lazy"
              sx={{ width: 24, height: 24 }}
              src={item.employeeThumbnail}
              alt={item.workEmail}
            />
          </span>
        ) : (
          <Avatar sx={{ width: 24, height: 24 }}>
            <PersonIcon fontSize="small" />
          </Avatar>
        )}
        <span>{item.workEmail}</span>
      </Stack>
    </Box>
  );
}

const OuterElementContext = React.createContext({});

const OuterElementType = React.forwardRef((props, ref) => {
  const outerProps = React.useContext(OuterElementContext);
  return <div ref={ref} {...props} {...outerProps} />;
});

function useResetCache(data) {
  const ref = React.useRef(null);
  useEffect(() => {
    if (ref.current != null) {
      ref.current.resetAfterIndex(0, true);
    }
  }, [data]);
  return ref;
}

const ListboxComponent = React.forwardRef(function ListboxComponent(
  props,
  ref
) {
  const { children, ...other } = props;
  const itemData = [];
  children.forEach((item) => {
    itemData.push(item);
    itemData.push(...(item.children || []));
  });

  const theme = useTheme();
  const smUp = useMediaQuery(theme.breakpoints.up("sm"), {
    noSsr: true,
  });
  const itemCount = itemData.length;
  const itemSize = smUp ? 36 : 48;

  const getChildSize = (child) => {
    if (child.hasOwnProperty("group")) {
      return 48;
    }

    return itemSize;
  };

  const getHeight = () => {
    if (itemCount > 8) {
      return 8 * itemSize;
    }
    return itemData.map(getChildSize).reduce((a, b) => a + b, 0);
  };

  const gridRef = useResetCache(itemCount);

  return (
    <div ref={ref}>
      <OuterElementContext.Provider value={other}>
        <VariableSizeList
          itemData={itemData}
          height={getHeight() + 2 * LISTBOX_PADDING}
          width="100%"
          ref={gridRef}
          outerElementType={OuterElementType}
          innerElementType="ul"
          itemSize={(index) => getChildSize(itemData[index])}
          overscanCount={5}
          itemCount={itemCount}
        >
          {renderRow}
        </VariableSizeList>
      </OuterElementContext.Provider>
    </div>
  );
});

ListboxComponent.propTypes = {
  children: PropTypes.node,
};

export default function EmailPicker(props) {
  const { email, handleEmailChange } = props;
  const { employeeData } = useSelector((state) => state.menu);
  const [isValidEmail, setIsValidEmail] = useState(true);

  const handleChange = (event, newValue) => {
    let isValid = true;
    if (typeof newValue === "string") {
      handleEmailChange(newValue);
    } else if (newValue && newValue.inputValue) {
      if (checkIfValidEmailAddress(newValue.inputValue.trim())) {
        newValue.workEmail = newValue.inputValue.trim();
        handleEmailChange(newValue);
      } else {
        isValid = false;
      }
    } else {
      handleEmailChange(newValue);
    }
    setIsValidEmail(isValid);
  };

  useEffect(() => {}, [employeeData]);

  useEffect(() => {}, [email]);

  return (
    <Autocomplete
      id="employee-selector"
      sx={{ width: 300 }}
      autoHighlight
      ListboxComponent={ListboxComponent}
      options={employeeData}
      onChange={handleChange}
      renderInput={(params) => (
        <TextField
          error={!isValidEmail}
          helperText={isValidEmail ? null : "Incorrect email."}
          {...params}
          label="Employee email"
        />
      )}
      getOptionLabel={(option) => {
        if (typeof option === "string") {
          return option;
        }
        if (option.inputValue) {
          return option.inputValue;
        }
        return option.workEmail;
      }}
      renderOption={(props, option, state) => [props, option, state.index]}
      filterOptions={(options, params) => {
        const filtered = filter(options, params);

        const { inputValue } = params;
        const isExisting = options.some(
          (option) => inputValue === option.workEmail
        );
        if (inputValue !== "" && !isExisting) {
          filtered.push({
            inputValue,
            workEmail: `Add "${inputValue}"`,
          });
        }

        return filtered;
      }}
      selectOnFocus
      clearOnBlur
      handleHomeEndKeys
      // TODO: Post React 18 update - validate this conversion, look like a hidden bug
      renderGroup={(params) => params}
    />
  );
}

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
import React, { useState, useEffect, forwardRef } from "react";
import { useSelector } from "react-redux";
import { VariableSizeList } from "react-window";

import Autocomplete, { createFilterOptions } from "@mui/material/Autocomplete";
import {
  Avatar,
  Chip,
  CircularProgress,
  Divider,
  Grid,
  FormControlLabel,
  FormGroup,
  IconButton,
  Paper,
  Stack,
  Switch,
  TextField,
  Toolbar,
  Typography,
  useTheme,
  useMediaQuery,
  Box,
} from "@mui/material";
import {
  Person as PersonIcon,
  Refresh as RefreshIcon,
} from "@mui/icons-material";

import AdditionalComment from "./AdditionalComment";
import { LEAVE_APP, PRIVATE_EMAIL_TEXT, PUBLIC_EMAIL_TEXT } from "../constants";

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

const OuterElementType = forwardRef((props, ref) => {
  const outerProps = React.useContext(OuterElementContext);
  return <div ref={ref} {...props} {...outerProps} />;
});

const OuterElementContext = React.createContext({});

function useResetCache(data) {
  const ref = React.useRef(null);
  React.useEffect(() => {
    if (ref.current != null) {
      ref.current.resetAfterIndex(0, true);
    }
  }, [data]);
  return ref;
}

const ListboxComponent = forwardRef((props, ref) => {
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

const NotifyPeople = (props) => {
  const {
    defaultRecipients,
    emailRecipients,
    savedRecipients,
    handleAddRecipient,
    handleRemoveEmail,
    comment,
    isPublicComment,
    handleComment,
    handlePublicComment,
  } = props;
  const { employeeData, employeeMap } = useSelector((state) => state.menu);
  const [fixedOptions, setFixedOptions] = useState(
    LEAVE_APP.DEFAULT_EMAIL_RECIPIENTS
  );
  const [options, setOptions] = useState([]);
  const filter = createFilterOptions();

  const handleResetRecipients = () => {
    handleAddRecipient([
      ...LEAVE_APP.DEFAULT_EMAIL_RECIPIENTS,
      ...defaultRecipients,
      ...savedRecipients,
    ]);
  };

  const handleOnChange = (newValues) => {
    var valuesToBeAdded = [];
    fixedOptions.forEach((option) => {
      if (
        !newValues.some((newValue) => option.workEmail === newValue.workEmail)
      ) {
        valuesToBeAdded.push(option);
      }
    });
    valuesToBeAdded = [...valuesToBeAdded, ...newValues];
    handleAddRecipient(valuesToBeAdded);
  };

  const handleOnDelete = (email) => () => {
    handleRemoveEmail(email);
  };

  const checkIfDefaultRecipients = () => {
    // Checks the same order of recipients. Not individual recipients
    const resetRecipients = [
      ...LEAVE_APP.DEFAULT_EMAIL_RECIPIENTS,
      ...defaultRecipients,
      ...savedRecipients,
    ];
    const defaultRecipientEmails = resetRecipients.map((e) => e.workEmail);
    return emailRecipients.every((e) =>
      defaultRecipientEmails.includes(e.workEmail)
    );
  };

  useEffect(() => {
    const fixedOptions = [
      ...LEAVE_APP.DEFAULT_EMAIL_RECIPIENTS,
      ...defaultRecipients,
    ];
    setFixedOptions(fixedOptions);
    var options = [];
    employeeData.forEach((employee) => {
      if (
        fixedOptions.some((option) => option.workEmail === employee.workEmail)
      ) {
        return;
      }
      options.push(employee);
    });

    setOptions(options);
  }, [props.isLoading, emailRecipients, defaultRecipients, employeeData]);

  useEffect(() => {}, [comment, isPublicComment]);

  return (
    <Grid container spacing={1}>
      <Grid item xs={12}>
        <Paper>
          <Stack
            direction="row"
            justifyContent="space-between"
            alignItems="center"
            spacing={2}
          >
            <Typography
              sx={{ padding: 1 }}
              variant="button"
              display="block"
              align="left"
            >
              {`Email Recipients (${emailRecipients.length})`}
            </Typography>
            {props.isLoading ? (
              <CircularProgress
                color="secondary"
                sx={{
                  height: "20px !important",
                  width: "20px !important",
                  marginRight: "10px !important",
                }}
              />
            ) : (
              !checkIfDefaultRecipients() && (
                <IconButton
                  onClick={handleResetRecipients}
                  color="primary"
                  aria-label="Refresh recipients"
                >
                  <RefreshIcon />
                </IconButton>
              )
            )}
          </Stack>

          <Divider />
          <Autocomplete
            multiple
            // limitTags={4}
            id="tags-standard"
            value={emailRecipients}
            onChange={(event, newValue) => {
              handleOnChange(newValue);
            }}
            ListboxComponent={ListboxComponent}
            options={options}
            getOptionLabel={(option) => {
              // Value selected with enter, right from the input
              if (typeof option === "string") {
                return option;
              }
              if (option.inputValue) {
                return option.inputValue;
              }
              return option.workEmail;
            }}
            renderOption={(props, option, state) => [
              props,
              option,
              state.index,
            ]}
            renderTags={(tagValue, getTagProps) => {
              return tagValue.map((option, index) => {
                const isFixed = fixedOptions.some(
                  (e) => e.workEmail === option.workEmail
                );
                return (
                  <Toolbar
                    sx={{
                      paddingTop: 0,
                      paddingBottom: 0,
                      paddingLeft: "2px !important",
                      paddingRight: "2px !important",
                      minHeight: "30px !important",
                    }}
                    title={option.workEmail}
                    key={index}
                  >
                    <Chip
                      clickable
                      onDelete={!isFixed ? handleOnDelete(option) : null}
                      key={option.workEmail}
                      color={"secondary"}
                      avatar={
                        employeeMap[option.workEmail] &&
                        employeeMap[option.workEmail].employeeThumbnail ? (
                          <Avatar
                            size="small"
                            loading="lazy"
                            sx={{ width: 24, height: 24 }}
                            src={
                              employeeMap[option.workEmail].employeeThumbnail
                            }
                            alt={option.workEmail}
                          />
                        ) : (
                          <Avatar>
                            <PersonIcon fontSize="small" />
                          </Avatar>
                        )
                      }
                      variant="outlined"
                      label={
                        employeeMap[option.workEmail] &&
                        employeeMap[option.workEmail].firstName &&
                        employeeMap[option.workEmail].lastName
                          ? employeeMap[option.workEmail].firstName +
                            " " +
                            employeeMap[option.workEmail].lastName
                          : option.workEmail
                      }
                    />
                  </Toolbar>
                );
              });
            }}
            selectOnFocus
            clearOnBlur
            handleHomeEndKeys
            autoHighlight
            freeSolo
            filterOptions={(options, params) => {
              const filtered = filter(options, params);
              const { inputValue } = params;
              // Suggest the creation of a new value
              const isExisting = options.some(
                (option) => inputValue === option.title
              );
              if (inputValue !== "" && !isExisting) {
                filtered.push({
                  inputValue: `Add "${inputValue}"`,
                  workEmail: inputValue,
                });
              }

              return filtered;
            }}
            renderInput={(params) => (
              <TextField
                {...params}
                variant="standard"
                placeholder="Type or select"
              />
            )}
            renderGroup={(params) => params}
          />
        </Paper>
      </Grid>
      <Grid item xs={12}>
        <Paper>
          <Stack
            direction="column"
            justifyContent="center"
            alignItems="flex-start"
          >
            <Typography sx={{ padding: 1 }} variant="button" display="block">
              Additional Comment (Optional):
            </Typography>
            <AdditionalComment
              comment={comment}
              handleComment={handleComment}
            />
            <FormGroup sx={{ paddingLeft: 1 }}>
              <FormControlLabel
                control={
                  <Switch
                    color="secondary"
                    checked={isPublicComment}
                    onChange={handlePublicComment}
                  />
                }
                label="Public Comment"
              />
              <Typography variant="caption">
                {isPublicComment ? PUBLIC_EMAIL_TEXT : PRIVATE_EMAIL_TEXT}
              </Typography>
            </FormGroup>
          </Stack>
        </Paper>
      </Grid>
    </Grid>
  );
};

export default NotifyPeople;

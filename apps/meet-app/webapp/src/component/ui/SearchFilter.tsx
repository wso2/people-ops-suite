// Copyright (c) 2024, WSO2 LLC. (https://www.wso2.com). All Rights Reserved.
//
// This software is the property of WSO2 LLC. and its suppliers, if any.
// Dissemination of any information or reproduction of any material contained
// herein in any form is strictly forbidden, unless permitted by WSO2 expressly.
// You may not alter or remove any copyright or other notice from copies of this content.

import {
  Button,
  Divider,
  FormControl,
  FormHelperText,
  Paper,
  Stack,
  TextField,
  Typography,
  useTheme,
} from "@mui/material";
import FilterAltOutlinedIcon from "@mui/icons-material/FilterAltOutlined";
import CloseIcon from "@mui/icons-material/Close";

interface SearchFilter {
  onClose: () => void;
  setFilter: (filter: any) => void;
}

const SearchFilter = () => {
  return (
    <Paper variant="outlined" sx={{ boxShadow: 1, borderRadius: 3 }}>
      <Stack
        flexDirection="row"
        alignItems={"center"}
        gap={0.6}
        p={1}
        sx={{ borderBottom: 1, borderColor: "divider" }}
      >
        <FilterAltOutlinedIcon fontSize="small" />
        <Typography variant="body2" sx={{ fontWeight: 600 }}>
          Filter
        </Typography>
        <CloseIcon fontSize="small" sx={{ cursor: "pointer", ml: "auto" }} />
      </Stack>
      <Stack sx={{ p: 1.5 }} gap={0.1}>
        <Stack flexDirection={"row"} alignItems={"center"}>
          <Typography
            variant="body2"
            sx={{ fontWeight: 600 }}
            color="secondary.dark"
          >
            Sample range
          </Typography>
          <Button size="small" sx={{ ml: "auto" }}>
            Reset
          </Button>
        </Stack>
        <Stack flexDirection={"row"} gap={2}>
          <FormControl>
            <FormHelperText sx={{ m: 0, p: 0 }}>From:</FormHelperText>
            <TextField type="date" variant="outlined" size="small" />
          </FormControl>
          <FormControl>
            <FormHelperText sx={{ m: 0, p: 0 }}>To:</FormHelperText>
            <TextField type="date" variant="outlined" size="small" />
          </FormControl>
        </Stack>
      </Stack>
      <Stack sx={{ p: 1.5 }} gap={1}>
        <Typography
          variant="body2"
          sx={{ fontWeight: 600 }}
          color="secondary.dark"
        >
          Sample Range
        </Typography>
        <Stack gap={2} flexDirection={"row"}>
          <TextField
            label="Sample filter"
            variant="outlined"
            size="small"
            sx={{
              width: 150,
            }}
          />
          <TextField
            label="Sample filter"
            variant="outlined"
            size="small"
            sx={{
              width: 150,
            }}
          />
        </Stack>
      </Stack>
      <Stack sx={{ p: 1.5 }} gap={2}>
        <Typography
          variant="body2"
          sx={{ fontWeight: 600 }}
          color="secondary.dark"
        >
          Sample filter
        </Typography>
        <Stack gap={2} flexDirection={"row"}>
          <TextField
            label="Sample filter"
            variant="outlined"
            size="small"
            sx={{
              width: 150,
            }}
          />
          <TextField
            label="Sample filter"
            variant="outlined"
            size="small"
            sx={{
              width: 150,
            }}
          />
        </Stack>
        <Stack gap={2} flexDirection={"row"}>
          <TextField
            label="Sample filter"
            variant="outlined"
            size="small"
            sx={{
              width: 150,
            }}
          />
          <TextField
            label="Sample filter"
            variant="outlined"
            size="small"
            sx={{
              width: 150,
            }}
          />
        </Stack>
      </Stack>
      <Divider />
      <Stack
        sx={{ p: 1.5 }}
        gap={1}
        flexDirection={"row"}
        justifyContent={"space-between"}
      >
        <Button variant="contained" size="small" sx={{ boxShadow: 1 }}>
          Reset
        </Button>
        <Button variant="contained" size="small" sx={{ boxShadow: 1 }}>
          Apply
        </Button>
      </Stack>
    </Paper>
  );
};

export default SearchFilter;

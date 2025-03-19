// Copyright (c) 2024, WSO2 LLC. (https://www.wso2.com). All Rights Reserved.
//
// This software is the property of WSO2 LLC. and its suppliers, if any.
// Dissemination of any information or reproduction of any material contained
// herein in any form is strictly forbidden, unless permitted by WSO2 expressly.
// You may not alter or remove any copyright or other notice from copies of this content.

import { useEffect, useState } from "react";

// MUI imports
import { Box, Fab, Fade, Stack, Typography } from "@mui/material";
import AddIcon from "@mui/icons-material/Add";
import { green } from "@mui/material/colors";

// APP imports
import { useAppDispatch, useAppSelector } from "@slices/store";
import { State } from "../../../types/types";
import { fetchCollections } from "@slices/collectionSlice/collection";
import DataCard from "../component/card/CommonCard";
import SkeletonCard from "@component/ui/common-card/SkeletonCard";
import PanelOneToolBar from "@view/first-view/tool-bar/PanelOneToolbar";
import AddCollectionModal from "../component/modal/AddCollectionModal";

const TabOnePanel = () => {
  const dispatch = useAppDispatch();
  const collection = useAppSelector((state) => state.collection);
  const [showAddCollectionPopUp, setShowAddCollectionPopUp] = useState(false);

  useEffect(() => {
    dispatch(fetchCollections());
  }, []);

  const toggleClose = () => {
    setShowAddCollectionPopUp(false);
  };

  return (
    <>
      {/* Loading component */}
      {collection.state === State.loading && (
        <>
          <SkeletonCard />
          <SkeletonCard />
          <SkeletonCard />
          <SkeletonCard />
        </>
      )}

      {/* Failed component */}
      {collection.state === State.failed && (
        <Fade in={collection.state === State.failed}>
          <Stack
            sx={{
              p: 2,
              backgroundColor: "background.default",
              width: "100%",
              height: "100%",
              borderRadius: 3,
              border: 1,
              borderColor: "divider",
            }}
            flexDirection={"column"}
            justifyContent={"center"}
            alignItems={"center"}
            gap={2}
          >
            <Box>
              <img
                src={require("../../../assets/images/error.svg").default}
                height={"120px"}
              />
            </Box>
            <Box sx={{ mt: 1 }}>
              <Typography
                align="center"
                variant="h3"
                color={"secondary.dark"}
              >{`Oops! Internal Server Error`}</Typography>
              <Typography
                align="center"
                fontWeight={500}
                sx={{ mt: 2 }}
                variant="body1"
              >{`we are trying to fix the problem`}</Typography>
            </Box>
          </Stack>
        </Fade>
      )}

      {/* Success component */}
      {collection.state == State.success && (
        <>
          {/* Add new section */}
          <Fab
            size="small"
            color="primary"
            aria-label="add"
            variant="extended"
            sx={{
              position: "absolute",
              bottom: "8%",
              right: "2%",
              color: "common.white",
              bgcolor: green[500],
              "&:hover": {
                bgcolor: green[600],
              },
            }}
            onClick={() => {
              setShowAddCollectionPopUp(true);
            }}
          >
            <AddIcon />
          </Fab>

          {/* No data component */}
          {collection.collections?.count === 0 && (
            <Fade in={collection.state === State.success}>
              <Stack
                sx={{
                  p: 2,
                  backgroundColor: "background.default",
                  width: "100%",
                  height: "100%",
                  borderRadius: 3,
                  border: 1,
                  borderColor: "divider",
                }}
                flexDirection={"column"}
                justifyContent={"center"}
                alignItems={"center"}
                gap={2}
              >
                <Box>
                  <img
                    src={require("../../../assets/images/no-data.svg").default}
                    height={"120px"}
                  />
                </Box>
                <Box>
                  <Typography
                    align="center"
                    variant="h4"
                    color={"secondary.dark"}
                  >{`No data available`}</Typography>
                  <Typography
                    align="center"
                    fontWeight={500}
                    sx={{ mt: 2 }}
                    variant="body2"
                  >{`There are no collections to display`}</Typography>
                </Box>
              </Stack>
            </Fade>
          )}

          {/* Data component */}
          {collection.collections!.count! > 0 && (
            <Fade in={collection.state === State.success}>
              <Box
                sx={{
                  height: "100%",
                  overflowY: "auto",
                  display: "flex",
                  paddingX: 1,
                  gap: 2,
                  flexDirection: "column",
                }}
              >
                {collection.collections!.collections.map((collection, idx) => (
                  <DataCard
                    key={collection.id}
                    collection={collection}
                    actions={<PanelOneToolBar />}
                    dataCardIndex={idx}
                  />
                ))}
              </Box>
            </Fade>
          )}
        </>
      )}
      {/* Add new collection popup */}
      {showAddCollectionPopUp && (
        <AddCollectionModal toggleClose={toggleClose} />
      )}
    </>
  );
};

export default TabOnePanel;

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
import AddIcon from "@mui/icons-material/Add";
import { Box, Fab } from "@mui/material";
import { green } from "@mui/material/colors";

import { useState } from "react";

import ErrorHandler from "@component/common/ErrorHandler";
import PreLoader from "@component/common/PreLoader";
import { useGetCollectionsQuery } from "@services/collections.api";
import PanelOneToolBar from "@view/first-view/tool-bar/PanelOneToolbar";

import DataCard from "../component/card/CommonCard";
import AddCollectionModal from "../component/modal/AddCollectionModal";

const TabOnePanel = () => {
  const [showAddCollectionPopUp, setShowAddCollectionPopUp] = useState(false);

  const { data, error, isLoading } = useGetCollectionsQuery();

  const toggleClose = () => {
    setShowAddCollectionPopUp(false);
  };

  const count = data?.count ?? 0;

  if (isLoading) {
    return <PreLoader />;
  }

  if (error) {
    return <ErrorHandler message={"Error while retrieving collections"} />;
  }

  if (!data || count === 0) {
    return <ErrorHandler message={"No data"} />;
  }

  return (
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

      {/* Data component */}
      {count > 0 && data.collections && (
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
          {data.collections.map((collection, idx) => (
            <DataCard
              key={collection.id}
              collection={collection}
              actions={<PanelOneToolBar />}
              dataCardIndex={idx}
            />
          ))}
        </Box>
      )}

      {/* Add new collection popup */}
      {showAddCollectionPopUp && <AddCollectionModal toggleClose={toggleClose} />}
    </>
  );
};

export default TabOnePanel;

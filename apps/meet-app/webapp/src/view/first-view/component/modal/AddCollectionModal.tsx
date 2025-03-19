// Copyright (c) 2024, WSO2 LLC. (https://www.wso2.com). All Rights Reserved.
//
// This software is the property of WSO2 LLC. and its suppliers, if any.
// Dissemination of any information or reproduction of any material contained
// herein in any form is strictly forbidden, unless permitted by WSO2 expressly.
// You may not alter or remove any copyright or other notice from copies of this content.
import React, { useEffect, useState } from "react";

// MUI imports
import {
  Dialog,
  DialogContent,
  DialogTitle,
  DialogContentText,
  IconButton,
  Box,
  Grid,
  Stack,
  Alert,
  FormControl,
  Tooltip,
  TextField,
  FormHelperText,
  Button,
} from "@mui/material";

// APP imports
import {
  RootState,
  useAppDispatch,
  useAppSelector,
} from "../../../../slices/store";
import CloseIcon from "@mui/icons-material/Close";
import {
  addCollections,
  resetSubmitSate,
} from "@slices/collectionSlice/collection";
import { useConfirmationModalContext } from "@context/DialogContext";
import { ConfirmationType } from "../../../../types/types";

// Other imports
import { useFormik } from "formik";
import * as yup from "yup";
import LoadingButton from "@mui/lab/LoadingButton";

const AddCollectionModal: React.FC<{ toggleClose: () => void }> = ({
  toggleClose,
}) => {
  const dispatch = useAppDispatch();
  const dialogContext = useConfirmationModalContext();
  const collection = useAppSelector((state: RootState) => state.collection);

  const validationSchema = yup.object().shape({
    collectionName: yup.string().required("Collection Name is required"),
    collectionType: yup.string().required("Collection Type is required"),
  });

  useEffect(() => {
    if (collection.submitState === "success") {
      dispatch(resetSubmitSate()); // Resetting the submit state
      toggleClose();
    }
  }, [collection.submitState]);

  const formik = useFormik({
    initialValues: {
      collectionName: "",
      collectionType: "",
    },
    validationSchema: validationSchema,

    onSubmit: (values: any) => {
      dialogContext.showConfirmation(
        "Do you want to Action 1?",
        "Please note that once done, this cannot be undone.",
        ConfirmationType.send,
        () => {
          dispatch(addCollections({ name: values.collectionName }));
        }
      );
    },
  });

  return (
    <Dialog
      keepMounted={false}
      open={true}
      sx={{
        backdropFilter: "blur(5px)",
        ".MuiDialog-paper": {
          maxWidth: 450,
          minHeight: 500,
          borderRadius: 4,
        },
      }}
    >
      <DialogTitle variant="h5">Add Collection</DialogTitle>

      <DialogContent
        sx={{
          p: 0.5,
          pt: 1,
          width: "100%",
          borderTop: 1,
          borderTopColor: "divider",
        }}
      >
        <DialogContentText variant="body2" sx={{ m: 1 }}>
          To proceed , please enter the following details of the collection.
        </DialogContentText>

        {/* Collection Details */}
        <Grid item xs={12}>
          <Box
            //updated
            component="span"
            sx={{
              "& .MuiTextField-root": { m: 1, width: "25ch" },
            }}
          >
            <Alert severity="warning">
              Please make sure to enter your collection name
              <br />
            </Alert>
            <br />
            <form onSubmit={formik.handleSubmit}>
              <div>
                <>
                  <>
                    {/* Collection name */}
                    <FormControl>
                      <Tooltip title="Collection x" placement="top">
                        <TextField
                          id="collectionName"
                          label="Collection Name"
                          value={formik.values.collectionName}
                          error={
                            formik.touched.collectionName &&
                            Boolean(formik.errors.collectionName)
                          }
                          name="collectionName"
                          onChange={(e) => {
                            formik.setFieldValue(
                              "collectionName",
                              e.target.value
                            );
                          }}
                        />
                      </Tooltip>
                      <FormHelperText
                        error={
                          formik.touched.collectionName &&
                          Boolean(formik.errors.collectionName)
                        }
                      >
                        <>
                          {formik.touched.collectionName &&
                            Boolean(formik.errors.collectionName) &&
                            formik.errors.collectionName}
                        </>
                      </FormHelperText>
                    </FormControl>

                    {/* Collection type */}
                    <FormControl>
                      <Tooltip title="Category A" placement="top">
                        <TextField
                          id="collectionType"
                          label="Collection Type"
                          value={formik.values.collectionType}
                          error={
                            formik.touched.collectionType &&
                            Boolean(formik.errors.collectionType)
                          }
                          name="collectionType"
                          onChange={(e) => {
                            formik.setFieldValue(
                              "collectionType",
                              e.target.value
                            );
                          }}
                        />
                      </Tooltip>
                      <FormHelperText
                        error={
                          formik.touched.collectionType &&
                          Boolean(formik.errors.collectionType)
                        }
                      >
                        <>
                          {formik.touched.collectionType &&
                            Boolean(formik.errors.collectionType) &&
                            formik.errors.collectionType}
                        </>
                      </FormHelperText>
                    </FormControl>
                  </>
                </>
              </div>
              <br />
              <br />
              <Stack direction="row" spacing={2}>
                <Button
                  variant="outlined"
                  color="secondary"
                  type="button"
                  onClick={() => toggleClose()}
                >
                  {" "}
                  Cancel{" "}
                </Button>
                <LoadingButton
                  type="submit"
                  variant="contained"
                  color="primary"
                  loading={collection.submitState == "loading"}
                >
                  {" "}
                  Submit{" "}
                </LoadingButton>
              </Stack>
            </form>
          </Box>
        </Grid>

        <IconButton
          aria-label="close"
          onClick={() => toggleClose()}
          sx={{
            position: "absolute",
            right: 8,
            top: 8,
            color: (theme) => theme.palette.grey[500],
          }}
        >
          <CloseIcon />
        </IconButton>
      </DialogContent>
    </Dialog>
  );
};

export default AddCollectionModal;

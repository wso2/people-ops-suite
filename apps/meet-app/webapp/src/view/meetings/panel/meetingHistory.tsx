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

import {
  Box,
  Button,
  Dialog,
  Tooltip,
  Backdrop,
  TextField,
  IconButton,
  Typography,
  DialogTitle,
  DialogActions,
  DialogContent,
  CircularProgress,
} from "@mui/material";
import { State } from "@/types/types";
import { useEffect, useState } from "react";
import { ConfirmationType } from "@/types/types";
import { DataGrid, GridColDef } from "@mui/x-data-grid";
import ErrorHandler from "@component/common/ErrorHandler";
import { useAppDispatch, useAppSelector } from "@slices/store";
import { useConfirmationModalContext } from "@context/DialogContext";
import { Delete, Visibility, CheckCircle, DeleteForever, Search } from "@mui/icons-material";
import { fetchMeetings, deleteMeeting, fetchAttachments } from "@slices/meetingSlice/meeting";

interface Attachment {
  title: string;
  fileId: string;
  fileUrl: string;
  iconLink: string;
  mimeType: string;
}

const formatDateTime = (dateTimeStr: string) => {
  const utcDate = new Date(dateTimeStr + " UTC");
  const day = String(utcDate.getDate()).padStart(2, "0");
  const month = String(utcDate.getMonth() + 1).padStart(2, "0");
  const year = utcDate.getFullYear();
  const hours = String(utcDate.getHours()).padStart(2, "0");
  const minutes = String(utcDate.getMinutes()).padStart(2, "0");
  return `${day}/${month}/${year}, ${hours}:${minutes}`;
};

function MeetingHistory() {
  const dispatch = useAppDispatch();
  const meeting = useAppSelector((state) => state.meeting);
  const totalMeetings = meeting.meetings?.count || 0;
  const [page, setPage] = useState(0);
  const [pageSize, setPageSize] = useState(10);
  const dialogContext = useConfirmationModalContext();
  const [loadingDelete, setLoadingDelete] = useState(false);
  const [loadingAttachments, setLoadingAttachments] = useState(false);
  const [attachments, setAttachments] = useState<Attachment[]>([]);
  const [openAttachmentDialog, setOpenAttachmentDialog] = useState(false);
  const [searchQuery, setSearchQuery] = useState<string>("");
  const [filteredSearchQuery, setFilteredSearchQuery] = useState<string | null>(null);

  useEffect(() => {
    dispatch(fetchMeetings({ title: filteredSearchQuery, limit: pageSize, offset: page * pageSize }));
  }, [dispatch, filteredSearchQuery, page, pageSize]);

  const handleDeleteMeeting = (meetingId: number, meetingTitle: string) => {
    dialogContext.showConfirmation(
      "Confirm Deletion",
      <Box>
        <>
          <Typography variant="body1">
            <strong>
              Are you sure you want to delete the meeting <br />
            </strong>{" "}
            {`${meetingTitle} ?`}
          </Typography>
        </>
      </Box>,
      ConfirmationType.accept,
      async () => {
        setLoadingDelete(true);
        await dispatch(deleteMeeting(meetingId)).then(() => {
          setLoadingDelete(false);
          dispatch(
            fetchMeetings({
              title: filteredSearchQuery,
              limit: pageSize,
              offset: page * pageSize,
            })
          );
        });
      },
      "Yes",
      "No"
    );
  };

  const handleViewAttachments = (meetingId: number) => {
    setLoadingAttachments(true);
    dispatch(fetchAttachments(meetingId)).then((data: any) => {
      setAttachments(data.payload.attachments);
      setOpenAttachmentDialog(true);
      setLoadingAttachments(false);
    });
  };

  const handleCloseAttachmentDialog = () => {
    setOpenAttachmentDialog(false);
    setAttachments([]);
  };

  const columns: GridColDef[] = [
    {
      field: "title",
      headerName: "Title",
      minWidth: 300,
      flex: 5,
    },
    {
      field: "meetingStatus",
      headerName: "Status",
      minWidth: 100,
      flex: 1,
      headerAlign: "center",
      align: "center",
      disableColumnMenu: true,
      renderCell: (params) => {
        const status = params.value;
        return (
          <Tooltip title={status === "ACTIVE" ? "Active" : "Cancelled"} arrow>
            <Box
              sx={{
                display: "flex",
                alignItems: "center",
                justifyContent: "center",
                height: "100%",
              }}
            >
              {status === "ACTIVE" ? <CheckCircle color="success" /> : <Delete color="disabled" />}
            </Box>
          </Tooltip>
        );
      },
    },
    {
      field: "host",
      headerName: "Host",
      minWidth: 120,
      flex: 2,
    },
    {
      field: "internalParticipants",
      headerName: "WSO2 Participants",
      minWidth: 200,
      flex: 4,
    },
    {
      field: "startTime",
      headerName: "Start Time",
      minWidth: 120,
      flex: 1,
      renderCell: (params) => formatDateTime(params.value),
    },
    {
      field: "endTime",
      headerName: "End Time",
      minWidth: 120,
      flex: 1,
      renderCell: (params) => formatDateTime(params.value),
    },
    {
      field: "attachments",
      headerName: "Attachments",
      minWidth: 100,
      flex: 1,
      headerAlign: "center",
      align: "center",
      disableColumnMenu: true,
      renderCell: (params) => {
        return (
          <>
            <Tooltip title="View Attachments" arrow>
              <IconButton color="info" onClick={() => handleViewAttachments(params.row.meetingId)}>
                <Visibility />
              </IconButton>
            </Tooltip>
          </>
        );
      },
    },
    {
      field: "delete",
      headerName: "Delete",
      minWidth: 90,
      flex: 1,
      headerAlign: "center",
      align: "center",
      disableColumnMenu: true,
      renderCell: (params) => {
        const isCancelled = params.row.meetingStatus === "CANCELLED";
        return (
          <>
            {!isCancelled && (
              <Tooltip title="Delete Meeting" arrow>
                <IconButton
                  color="error"
                  onClick={() => {
                    handleDeleteMeeting(params.row.meetingId, params.row.title);
                  }}
                >
                  <DeleteForever />
                </IconButton>
              </Tooltip>
            )}
          </>
        );
      },
    },
  ];

  const meetingList = meeting.meetings?.meetings ?? [];

  return (
    <Box>
      <Box
        sx={{
          display: "flex",
          justifyContent: "flex-end",
          alignItems: "flex-start",
          gap: 1,
          px: 2,
          pt: 1.5,
        }}
      >
        <TextField
          label="Search by Title"
          size="small"
          value={searchQuery}
          onChange={(e) => setSearchQuery(e.target.value)}
          onKeyDown={(e) => {
            if (e.key === "Enter") {
              setFilteredSearchQuery(searchQuery);
              setPage(0);
            }
          }}
          autoCorrect="off"
          autoCapitalize="none"
          spellCheck={false}
          sx={{
            width: 300,
            "& .MuiInputBase-root": {
              paddingRight: 0,
            },
          }}
          InputProps={{
            endAdornment: (
              <IconButton
                onClick={() => {
                  setFilteredSearchQuery(searchQuery);
                  setPage(0);
                }}
                sx={{
                  justifyContent: "center",
                  borderRadius: 0,
                }}
              >
                <Search />
              </IconButton>
            ),
          }}
        />
      </Box>
      {meeting.state === State.loading ? (
        <Box
          sx={{
            display: "flex",
            flexDirection: "column",
            alignItems: "center",
            py: 4,
          }}
        >
          <CircularProgress />
          <Typography mt={2} color="textSecondary">
            Loading meetings, please wait...
          </Typography>
        </Box>
      ) : meeting.state === State.failed ? (
        <ErrorHandler message="Failed to fetch meetings." />
      ) : meeting.state === State.success ? (
        meetingList.length === 0 ? (
          <ErrorHandler message="No Meetings Found." />
        ) : (
          <Box
            sx={{
              display: "grid",
              gridTemplateColumns: "1fr",
              paddingX: 2,
              paddingY: 2,
            }}
          >
            <DataGrid
              pagination
              columns={columns}
              rows={meetingList}
              rowCount={totalMeetings}
              paginationMode="server"
              pageSizeOptions={[5, 10, 20]}
              rowHeight={47}
              columnHeaderHeight={48}
              getRowId={(row) => row.meetingId}
              disableRowSelectionOnClick
              paginationModel={{ pageSize, page }}
              onPaginationModelChange={(model) => {
                setPageSize(model.pageSize);
                setPage(model.page);
              }}
              sx={{
                border: 0,
                width: "100%",
              }}
            />
          </Box>
        )
      ) : null}

      <Backdrop
        open={loadingAttachments || loadingDelete}
        sx={{
          color: "#fff",
          zIndex: (theme) => theme.zIndex.drawer + 1,
          backdropFilter: "blur(4px)",
        }}
      >
        <CircularProgress color="inherit" />
      </Backdrop>
      <Dialog open={openAttachmentDialog} onClose={handleCloseAttachmentDialog}>
        <DialogTitle>Attachments</DialogTitle>
        <DialogContent>
          {attachments.length === 0 ? (
            <Typography>No attachments found.</Typography>
          ) : (
            <Box>
              {attachments.map((attachment, index) => (
                <Box key={index} sx={{ display: "flex", alignItems: "center", mb: 1 }}>
                  <img
                    src={attachment.iconLink}
                    alt={attachment.title}
                    style={{ width: 24, height: 24, marginRight: 8 }}
                  />
                  <Button
                    onClick={() => window.open(attachment.fileUrl, "_blank")}
                    sx={{
                      textDecoration: "underline",
                      color: "primary.main",
                    }}
                  >
                    {attachment.title}
                  </Button>
                </Box>
              ))}
            </Box>
          )}
        </DialogContent>
        <DialogActions>
          <Button onClick={handleCloseAttachmentDialog} color="primary">
            Close
          </Button>
        </DialogActions>
      </Dialog>
    </Box>
  );
}

export default MeetingHistory;

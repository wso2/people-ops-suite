import React, { useEffect, useState } from "react";
import { DataGrid, GridColDef } from "@mui/x-data-grid";
import {
  Box,
  CircularProgress,
  Typography,
  IconButton,
  Dialog,
  DialogTitle,
  DialogContent,
  DialogActions,
  Button,
  Backdrop,
  Tooltip,
} from "@mui/material";
import {
  DeleteForever,
  Visibility,
  CheckCircle,
  Delete,
} from "@mui/icons-material";
import { useAppDispatch, useAppSelector } from "@slices/store";
import {
  fetchMeetings,
  fetchAttachments,
  deleteMeeting,
} from "@slices/meetingSlice/meeting";
import { State } from "@/types/types";
import ErrorHandler from "@component/common/ErrorHandler";

interface Attachment {
  fileUrl: string;
  title: string;
  mimeType: string;
  iconLink: string;
  fileId: string;
}

const formatDateTime = (dateTimeStr: string) => {
  const utcDate = new Date(dateTimeStr + " UTC");
  const year = utcDate.getFullYear();
  const month = String(utcDate.getMonth() + 1).padStart(2, "0");
  const day = String(utcDate.getDate()).padStart(2, "0");
  const hours = String(utcDate.getHours()).padStart(2, "0");
  const minutes = String(utcDate.getMinutes()).padStart(2, "0");
  return `${day}/${month}/${year}, ${hours}:${minutes}`;
};

function MeetingHistory() {
  const dispatch = useAppDispatch();
  const meeting = useAppSelector((state) => state.meeting);
  const [page, setPage] = useState(0);
  const [pageSize, setPageSize] = useState(10);
  const [attachments, setAttachments] = useState<Attachment[]>([]);
  const [loadingAttachments, setLoadingAttachments] = useState(false);
  const [openAttachmentDialog, setOpenAttachmentDialog] = useState(false);
  const [meetingToDelete, setMeetingToDelete] = useState<number | null>(null);
  const [loadingDelete, setLoadingDelete] = useState(false);
  const [openDeleteDialog, setOpenDeleteDialog] = useState(false);
  const totalMeetings = meeting.meetings?.count || 0;

  useEffect(() => {
    dispatch(fetchMeetings({ limit: pageSize, offset: page * pageSize }));
  }, [dispatch, page, pageSize]);

  const handleViewAttachments = (meetingId: number) => {
    setLoadingAttachments(true);
    dispatch(fetchAttachments(meetingId)).then((data: any) => {
      setAttachments(data.payload.attachments);
      setOpenAttachmentDialog(true);
      setLoadingAttachments(false);
    });
  };

  const handleConfirmDelete = () => {
    if (meetingToDelete !== null) {
      handleDeleteMeeting(meetingToDelete);
      setOpenDeleteDialog(false);
      setMeetingToDelete(null);
    }
  };

  const handleDeleteMeeting = (meetingId: number) => {
    setLoadingDelete(true);
    dispatch(deleteMeeting(meetingId)).then(() => {
      setLoadingDelete(false);
      dispatch(fetchMeetings({ limit: pageSize, offset: page * pageSize }));
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
              {status === "ACTIVE" ? (
                <CheckCircle color="success" />
              ) : (
                <Delete color="disabled" />
              )}
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
      field: "wso2Participants",
      headerName: "WSO2 Participants",
      minWidth: 200,
      flex: 3,
    },
    {
      field: "actions",
      headerName: "",
      minWidth: 90,
      flex: 1,
      renderCell: (params) => {
        const isCancelled = params.row.meetingStatus === "CANCELLED";

        return (
          <>
            <Tooltip title="View Attachments" arrow>
              <IconButton
                color="info"
                onClick={() => handleViewAttachments(params.row.meetingId)}
              >
                <Visibility />
              </IconButton>
            </Tooltip>
            {!isCancelled && (
              <Tooltip title="Delete Meeting" arrow>
                <IconButton
                  color="error"
                  onClick={() => {
                    setMeetingToDelete(params.row.meetingId);
                    setOpenDeleteDialog(true);
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
      <Dialog
        open={openDeleteDialog}
        onClose={() => setOpenDeleteDialog(false)}
      >
        <DialogTitle>Confirm Deletion</DialogTitle>
        <DialogContent>
          <Typography>Are you sure you want to delete this meeting?</Typography>
        </DialogContent>
        <DialogActions>
          <Button onClick={() => setOpenDeleteDialog(false)} color="primary">
            Cancel
          </Button>
          <Button onClick={handleConfirmDelete} color="error">
            Delete
          </Button>
        </DialogActions>
      </Dialog>
      <Dialog open={openAttachmentDialog} onClose={handleCloseAttachmentDialog}>
        <DialogTitle>Attachments</DialogTitle>
        <DialogContent>
          {attachments.length === 0 ? (
            <Typography>No attachments found.</Typography>
          ) : (
            <Box>
              {attachments.map((attachment, index) => (
                <Box
                  key={index}
                  sx={{ display: "flex", alignItems: "center", mb: 1 }}
                >
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

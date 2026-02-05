import {
  Dialog,
  DialogTitle,
  DialogContent,
  DialogContentText,
  DialogActions,
  Button,
} from "@mui/material";

interface SessionWarningDialogProps {
  open: boolean;
  handleContinue: () => void;
  appSignOut: () => void;
}

function SessionWarningDialog(props: SessionWarningDialogProps) {
  const { open, handleContinue, appSignOut } = props;
  return (
    <Dialog
      open={open}
      onClose={handleContinue}
      aria-labelledby="alert-dialog-title"
      aria-describedby="alert-dialog-description"
    >
      <DialogTitle id="alert-dialog-title">
        {"Are you still there?"}
      </DialogTitle>
      <DialogContent>
        <DialogContentText id="alert-dialog-description">
          It looks like you've been inactive for a while. Would you like to
          continue?
        </DialogContentText>
      </DialogContent>
      <DialogActions>
        <Button onClick={handleContinue}>Continue</Button>
        <Button onClick={() => appSignOut()}>Logout</Button>
      </DialogActions>
    </Dialog>
  );
}

export default SessionWarningDialog;

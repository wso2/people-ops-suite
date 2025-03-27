
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

import React from "react";
import { Button, Paper, Box } from "@mui/material";
import { Typography } from "@mui/material";
import { FileQuestion, Search, RefreshCw } from "lucide-react";

interface NoDataViewProps {
  message?: string;
  description?: string;
  actionLabel?: string;
  onAction?: () => void;
  type?: "search" | "empty" | "error";
}

const NoDataView: React.FC<NoDataViewProps> = ({
  message = "No Data Found",
  description,
  actionLabel,
  onAction,
  type = "empty",
}) => {
  const handleRefresh = () => {
    window.location.reload();
  };

  const getIcon = () => {
    switch (type) {
      case "search":
        return <Search className="text-primary" size={48} />;
      case "error":
        return (
          <RefreshCw
            className="text-error cursor-pointer hover:opacity-80"
            size={48}
            onClick={() => handleRefresh()}
            style={{ cursor: "pointer", position: "relative", zIndex: 2 }}
          />
        );
      default:
        return <FileQuestion className="text-primary" size={48} />;
    }
  };

  return (
    <Paper
      elevation={0}
      sx={{
        p: 6,
        textAlign: "center",
        backgroundColor: "background.primary",
        // border: "1px dashed rgba(0, 0, 0, 0.1)",
        height: "100%",
        width: "100%",
        display: "flex",
        flexDirection: "column",
        alignItems: "center",
        justifyContent: "center",
        position: "relative",
        overflow: "hidden",
      }}
    >
      {/* Background Pattern */}
      <Box
        sx={{
          position: "absolute",
          top: 0,
          left: 0,
          right: 0,
          bottom: 0,
          opacity: 0.05,
          backgroundImage: `radial-gradient(circle at 1px 1px, rgba(0,0,0,0.2) 1px, transparent 0)`,
          backgroundSize: "36px 36px",
          animation: "fade-in 0.5s ease-out",
        }}
      />

      {/* Main Content */}
      <Box
        sx={{
          position: "relative",
          zIndex: 1,
          maxWidth: "400px",
        }}
      >
        {/* Icon with animated background */}
        <Box
          sx={{
            position: "relative",
            mb: 3,
            "&::before": {
              content: '""',
              position: "absolute",
              top: "50%",
              left: "50%",
              transform: "translate(-50%, -50%)",
              width: "80px",
              height: "80px",
              borderRadius: "50%",
              backgroundColor: "primary.light",
              opacity: 0.1,
              animation: "pulse 2s infinite",
            },
          }}
        >
          {getIcon()}
        </Box>

        {/* Message */}
        <Typography
          variant="h5"
          sx={{
            mb: 1,
            background: (theme) =>
              `linear-gradient(90deg, ${theme.palette.mode === "dark" ? "#ffffff" : "#000000"} 25%, ${
                theme.palette.mode === "dark" ? "#888888" : "#444444"
              } 50%, ${theme.palette.mode === "dark" ? "#ffffff" : "#000000"} 75%)`,
            backgroundSize: "2000px 100%",

            backgroundClip: "text",
            WebkitBackgroundClip: "text",
            color: "transparent",
            textShadow: (theme) =>
              theme.palette.mode === "dark" ? "0px 2px 6px rgba(255,255,255,0.3)" : "0px 2px 6px rgba(0,0,0,0.3)",
          }}
        >
          {message}
        </Typography>

        {/* Description */}
        {description && (
          <Typography
            variant="body1"
            sx={{
              color: "text.secondary",
              mb: 3,
              animation: "slide-up 5s ease-out 2s",
              animationFill: "forwards",
              opacity: 0,
            }}
          >
            {description}
          </Typography>
        )}

        {/* Action Button */}
        {actionLabel && onAction && (
          <Button
            variant="outlined"
            onClick={onAction}
          >
            {actionLabel}
          </Button>
        )}
      </Box>

      <style>
        {`
          @keyframes pulse {
           0% {
             transform: translate(-50%, -50%) scale(0.9);
             opacity: 0.1;
           }
           50% {
             transform: translate(-50%, -50%) scale(1.2);
             opacity: 0.15;
           }
           100% {
             transform: translate(-50%, -50%) scale(0.9);
             opacity: 0.1;
           }
         }
          @keyframes slide-up {
            0% {
              transform: translateY(20px);
              opacity: 0;
            }
            60% {
              transform: translateY(-5px);
            }
            80% {
              transform: translateY(2px);
            }
            100% {
              transform: translateY(0);
              opacity: 1;
            }
          }

          @keyframes fade-in {
            0% {
              opacity: 0;
              transform: scale(0.98);
            }
            50% {
              opacity: 0.03;
            }
            100% {
              opacity: 0.05;
              transform: scale(1);
            }
          }

          @keyframes float {
            0% {
              transform: translateY(0);
            }
            50% {
              transform: translateY(-5px);
            }
            100% {
              transform: translateY(0);
            }
          }

          .icon-container {
            animation: float 3s ease-in-out infinite;
          }

          .action-button {
            transition: all 0.2s ease;
          }

          .action-button:hover {
            transform: translateY(-2px);
            box-shadow: 0 4px 12px rgba(0,0,0,0.1);
          }

          .pattern-background {
            background-image: linear-gradient(
              45deg,
              rgba(0,0,0,0.05) 25%,
              transparent 25%
            ),
            linear-gradient(
              -45deg,
              rgba(0,0,0,0.05) 25%,
              transparent 25%
            ),
            linear-gradient(
              45deg,
              transparent 75%,
              rgba(0,0,0,0.05) 75%
            ),
            linear-gradient(
              -45deg,
              transparent 75%,
              rgba(0,0,0,0.05) 75%
            );
            background-size: 20px 20px;
            background-position: 0 0, 0 10px, 10px -10px, -10px 0px;
            animation: pattern-shift 20s linear infinite;
          }

          @keyframes pattern-shift {
            0% {
              background-position: 0 0, 0 10px, 10px -10px, -10px 0px;
            }
            100% {
              background-position: -20px -20px, -20px -10px, -10px -30px, -30px -20px;
            }
          }
        `}
      </style>
    </Paper>
  );
};

export default NoDataView;

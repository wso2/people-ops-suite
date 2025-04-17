
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
import { Loader2 } from "lucide-react";
import { CircularProgress } from "@mui/material";
import { Box, Typography, keyframes } from "@mui/material";

interface LoadingScreenProps {
  message?: string;
}

const shimmer = keyframes`
  0% {
    background-position: -1000px 0;
  }
  100% {
    background-position: 1000px 0;
  }
`;

const pulse = keyframes`
  0% {
    opacity: 1;
    transform: scale(0.9);
  }
  50% {
    opacity: 0.5;
    transform: scale(1.1);
  }
  100% {
    opacity: 1;
    transform: scale(0.9);
  }
`;

const rotate = keyframes`
  from {
    transform: rotate(0deg);
  }
  to {
    transform: rotate(360deg);
  }
`;

const LoadingScreen: React.FC<LoadingScreenProps> = ({
  message = "Loading",
}) => {
  return (
    <Box
      sx={{
        width: "100%",
        height: "100%",
        display: "flex",
        flexDirection: "column",
        alignItems: "center",
        justifyContent: "center",
        gap: 3,
        position: "relative",
        overflow: "hidden",
        backgroundColor: "background.default",
        minHeight: "300px",
      }}
    >
      <Box
        sx={{
          position: "relative",
          display: "flex",
          alignItems: "center",
          justifyContent: "center",
        }}
      >
        <CircularProgress
          size={80}
          thickness={2}
          sx={{
            color: "primary.light",
            animation: `${pulse} 2s ease-in-out infinite`,
          }}
        />
        <Loader2
          size={40}
          className="text-primary"
          style={{
            position: "absolute",
            animation: `${rotate} 3s linear infinite`,
          }}
        />
      </Box>
      {/* Loading Text */}
      <Box
        sx={{
          textAlign: "center",
          zIndex: 1,
        }}
      >
        <Typography
          variant="h5"
          sx={{
            mb: 1,
            background: (theme) =>
              `linear-gradient(90deg, ${
                theme.palette.mode === "dark" ? "#ffffff" : "#000000"
              } 25%, ${
                theme.palette.mode === "dark" ? "#888888" : "#444444"
              } 50%, ${
                theme.palette.mode === "dark" ? "#ffffff" : "#000000"
              } 75%)`,
            backgroundSize: "2000px 100%",
            animation: `${shimmer} 2s linear infinite`,
            backgroundClip: "text",
            WebkitBackgroundClip: "text",
            color: "transparent",
            textShadow: (theme) =>
              theme.palette.mode === "dark"
                ? "0px 2px 6px rgba(255,255,255,0.3)"
                : "0px 2px 6px rgba(0,0,0,0.3)",
          }}
        >
          {message}
        </Typography>
      </Box>

      {/* Loading Progress Indicators */}
      <Box
        sx={{
          display: "flex",
          gap: 1,
          mt: 1,
        }}
      >
        {[0, 1, 2].map((i) => (
          <Box
            key={i}
            sx={{
              width: 8,
              height: 8,
              borderRadius: "50%",
              backgroundColor: "primary.main",
              animation: `${pulse} 1s ease-in-out infinite`,
              animationDelay: `${i * 0.2}s`,
            }}
          />
        ))}
      </Box>
    </Box>
  );
};

export default LoadingScreen;

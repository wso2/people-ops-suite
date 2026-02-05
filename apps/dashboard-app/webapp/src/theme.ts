// Copyright (c) 2026 WSO2 LLC. (https://www.wso2.com).
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
// MUI Import
import { type PaletteMode, alpha } from "@mui/material";

import designTokens from "./styles/design-tokens.json";

// Helper function to remove 'ff' suffix from hex colors
const cleanHexColor = (color: string): string => {
  if (color.endsWith("ff")) {
    return color.slice(0, -2);
  }
  return color;
};

// Extract and transform color tokens from design tokens
const extractColors = () => {
  const { variables } = designTokens;

  return {
    neutral: Object.entries(variables.colors.neutral).reduce(
      (acc, [key, token]: [string, any]) => {
        acc[key] = cleanHexColor(token.value);
        return acc;
      },
      {} as Record<string, string>,
    ),

    primary: Object.entries(variables.colors.primary).reduce(
      (acc, [key, token]: [string, any]) => {
        acc[key] = cleanHexColor(token.value);
        return acc;
      },
      {} as Record<string, string>,
    ),

    secondary: Object.entries(variables.colors.secondary).reduce(
      (acc, [key, token]: [string, any]) => {
        acc[key] = cleanHexColor(token.value);
        return acc;
      },
      {} as Record<string, string>,
    ),
  };
};

// Extract font/typography tokens
const extractTypography = () => {
  const { font } = designTokens;

  return {
    h1: font.h1.value,
    h2: font.h2.value,
    h3: font.h3.value,
    h4: font.h4.value,
    h5: font.h5.value,
    h6: font.h6.value,
    body1: font["p-r"].value,
    body2: font["p-m"].value,
    caption: font["p-s"].value,
    overline: font["p-xs"].value,
  };
};

// Color Design Tokens with mode support
export const tokens = (mode: PaletteMode) => {
  const colors = extractColors();

  return {
    ...(mode === "dark"
      ? {
          // Colors - Dark mode
          neutral: colors.neutral,
          secondary: colors.secondary,
          primary: colors.primary,

          // Text colors - Dark mode
          text: {
            primary: {
              p1: { active: colors.neutral.white, hover: "#ffffff" },
              p2: { active: colors.neutral["300"], hover: "#ffffff" },
              p3: { active: colors.neutral["800"], hover: "#ffffff" },
              p4: { active: colors.neutral["1300"], hover: "#ffffff" },
            },
            secondary: {
              p1: { active: colors.secondary["900"], hover: "#FF6A0096", disabled: "#ff730096" },
              p2: { active: colors.secondary["1000"], hover: "#FF6A0096", disabled: "#ff730096" },
            },
            brand: {
              p1: { active: colors.primary["1200"], hover: "#FF6A0096", disabled: "#ff730096" },
              p2: { active: colors.primary.main, hover: "#FF6A0096", disabled: "#ff73005c" },
            },
          },

          // Border colors - Dark mode
          border: {
            primary: {
              active: colors.neutral["1400"],
              hover: colors.neutral.white,
              clicked: colors.neutral.white,
              disabled: colors.neutral.white,
            },
            secondary: {
              active: "#0099CC",
              hover: "#2ECBFF",
              clicked: "#06B1F4",
              disabled: "#0099CC96",
            },
            territory: {
              active: colors.neutral["1600"],
              hover: colors.neutral["1400"],
              clicked: colors.neutral.white,
              disabled: alpha(colors.neutral["1600"], 0.35),
            },
            brand: {
              active: colors.primary["1300"],
              hover: "#FF730F",
              clicked: "#F55A00",
              disabled: "#F55A0096",
            },
          },

          // Navigation colors - Dark mode
          navigation: {
            text: colors.neutral["800"],
            hover: colors.neutral["400"],
            textClicked: colors.neutral.white,
            hoverBg: colors.neutral["1800"],
            clickedBg: colors.primary["1200"],
            border: colors.neutral["1700"],
          },

          // Surface colors - Dark mode
          surface: {
            primary: {
              active: colors.neutral["1800"],
              hover: colors.neutral["1900"],
            },
            secondary: {
              active: "#171717",
            },
            navbar: {
              active: colors.neutral["1900"],
              hover: colors.secondary["1700"],
            },
          },

          // Fill colors - Dark mode
          fill: {
            primary: {
              active: colors.primary["1600"],
              hover: colors.primary["1500"],
              clicked: colors.primary["1700"],
              disabled: "#3D190196",
            },
            primary_light: {
              active: colors.primary["1800"],
              hover: colors.primary["1500"],
            },
            primary_dark: {
              active: colors.primary["1400"],
              hover: colors.primary["1500"],
            },
            secondary: {
              active: colors.secondary["1000"],
              hover: colors.secondary["1100"],
              clicked: colors.secondary["1200"],
              disabled: "#0A475C96",
            },
            secondary_light: {
              active: colors.secondary["1400"],
              hover: "#fff",
            },
            neutral_light: {
              active: colors.secondary["1700"],
              hover: "#fff",
            },
            neutral_dark: {
              active: colors.secondary["1700"],
              hover: "#fff",
            },
            xmas: {
              active: "#B8D3E0d7",
            },
          },

          // Shadow colors - Dark mode
          shadow: {
            primary: {
              active: "#000000CC",
              hover: colors.neutral["1900"],
            },
          },
        }
      : {
          // Light mode colors
          neutral: colors.neutral,
          primary: colors.primary,
          secondary: colors.secondary,

          // Text colors - Light mode
          text: {
            primary: {
              p1: { active: colors.neutral.black, hover: "#FFFFFF" },
              p2: { active: colors.neutral["1600"], hover: "#FFFFFF" },
              p3: { active: colors.neutral["1200"], hover: "#FFFFFF" },
              p4: { active: colors.neutral["700"], hover: "#FFFFFF" },
            },
            secondary: {
              p1: { active: colors.secondary["800"], hover: "#FFFFFF", disabled: "#FFFFFF" },
              p2: { active: colors.secondary.main, hover: "#FFFFFF", disabled: "#FFFFFF" },
            },
            brand: {
              p1: { active: colors.primary["1100"], hover: "#FFFFFF", disabled: "#ff730096" },
              p2: { active: colors.neutral.white, hover: "#FF6A0096", disabled: "#ffffff96" },
            },
          },

          // Border colors - Light mode
          border: {
            primary: {
              active: colors.neutral["700"],
              hover: colors.neutral.white,
              clicked: colors.neutral.white,
              disabled: colors.neutral.white,
            },
            secondary: {
              active: "#00BFFF",
              hover: "#2ECBFF",
              clicked: "#06B1F4",
              disabled: "#00BFFF96",
            },
            territory: {
              active: colors.neutral["200"],
              hover: colors.neutral["400"],
              clicked: colors.neutral.white,
              disabled: alpha(colors.neutral["200"], 0.35),
            },
            brand: {
              active: colors.primary.main,
              hover: "#FF730F",
              clicked: "#F55A00",
              disabled: "#F55A0096",
            },
          },

          // Surface colors - Light mode
          surface: {
            primary: {
              active: colors.neutral.light_white,
              hover: colors.neutral.white,
            },
            secondary: {
              active: colors.neutral.white,
            },
            navbar: {
              active: colors.neutral["1900"],
              hover: "#FFFFFF",
            },
          },

          // Fill colors - Light mode
          fill: {
            primary: {
              active: colors.primary.main,
              hover: colors.primary["900"],
              clicked: colors.primary["1100"],
              disabled: "#FF730096",
            },
            primary_light: {
              active: colors.primary["100"],
              hover: colors.primary["1500"],
            },
            primary_dark: {
              active: colors.primary["1200"],
              hover: colors.primary["1500"],
            },
            secondary: {
              active: colors.secondary.main,
              hover: colors.secondary["600"],
              clicked: colors.secondary["800"],
              disabled: "#00CEFF96",
            },
            secondary_light: {
              active: colors.secondary["100"],
              hover: "#FFFFFF",
            },
            neutral_light: {
              active: colors.neutral["100"],
              hover: "#FFFFFF",
            },
            neutral_dark: {
              active: colors.neutral["1700"],
              hover: "#FFFFFF",
            },
            xmas: {
              active: "#A6C8D9",
            },
          },

          // Navigation colors - Light mode
          navigation: {
            text: colors.neutral["800"],
            hover: colors.neutral["400"],
            textClicked: colors.neutral.white,
            hoverBg: colors.neutral["1800"],
            clickedBg: colors.primary["1200"],
            border: colors.neutral["1700"],
          },

          // Shadow colors - Light mode
          shadow: {
            primary: {
              active: "#00000014",
              hover: colors.neutral["1900"],
            },
          },
        }),
  };
};

// Extend MUI Button variant types
declare module "@mui/material/Button" {
  interface ButtonPropsVariantOverrides {
    submit: true;
  }
}

// Extend MUI theme types
declare module "@mui/material/styles" {
  interface TypeBackground {
    primary?: string;
    secondary?: string;
    secondaryLight?: string;
    primaryLight?: string;
    lightWhite?: string;
  }

  interface TypeText {
    brand?: string;
  }

  interface Palette {
    neutral: Record<string | number, string | undefined>;
    primaryShades: Record<string, string>;
    secondaryShades: Record<string, string>;
    customBorder: {
      primary: {
        active: string;
        hover: string;
        clicked: string;
        disabled: string;
      };
      secondary: {
        active: string;
        hover: string;
        clicked: string;
        disabled: string;
      };
      territory: {
        active: string;
        hover: string;
        clicked: string;
        disabled: string;
      };
      brand: {
        active: string;
        hover: string;
        clicked: string;
        disabled: string;
      };
    };
    customNavigation: {
      text: string;
      textClicked: string;
      hover: string;
      hoverBg: string;
      clicked: string;
      clickedBg: string;
      border: string;
    };
    surface: {
      primary: Record<string, string>;
      navbar: Record<string, string>;
      secondary: Record<string, string>;
    };
    fill: {
      primary: Record<string, string>;
      primary_light: Record<string, string>;
      primary_dark: Record<string, string>;
      secondary: Record<string, string>;
      secondary_light: Record<string, string>;
      neutral_light: Record<string, string>;
      neutral_dark: Record<string, string>;
      xmas: Record<string, string>;
    };
    shadow: {
      primary: Record<string, string>;
    };
    customText: {
      primary: {
        p1: { active: string; hover: string };
        p2: { active: string; hover: string };
        p3: { active: string; hover: string };
        p4: { active: string; hover: string };
      };
      secondary: {
        p1: { active: string; hover: string; disabled?: string };
        p2: { active: string; hover: string; disabled?: string };
      };
      brand: {
        p1: { active: string; hover: string; disabled?: string };
      };
    };
  }

  interface PaletteOptions {
    neutral?: Record<string | number, string | undefined>;
    primaryShades?: Record<string, string>;
    secondaryShades?: Record<string, string>;
    customBorder?: {
      primary?: {
        active: string;
        hover: string;
        clicked: string;
        disabled: string;
      };
      secondary?: {
        active: string;
        hover: string;
        clicked: string;
        disabled: string;
      };
      territory?: {
        active: string;
        hover: string;
        clicked: string;
        disabled: string;
      };
      brand?: {
        active: string;
        hover: string;
        clicked: string;
        disabled: string;
      };
    };
    customNavigation?: {
      text?: string;
      textClicked?: string;
      bg?: string;
      hover?: string;
      hoverBg?: string;
      clicked?: string;
      clickedBg?: string;
      border: string;
    };
    surface?: {
      primary?: Record<string, string>;
      navbar?: Record<string, string>;
      secondary?: Record<string, string>;
    };
    fill?: {
      primary?: Record<string, string>;
      primary_light?: Record<string, string>;
      primary_dark?: Record<string, string>;
      secondary?: Record<string, string>;
      secondary_light?: Record<string, string>;
      neutral_light?: Record<string, string>;
      neutral_dark?: Record<string, string>;
      xmas?: Record<string, string>;
    };
    shadow?: {
      primary?: Record<string, string>;
    };
    customText?: {
      primary?: {
        p1?: { active: string; hover: string };
        p2?: { active: string; hover: string };
        p3?: { active: string; hover: string };
        p4?: { active: string; hover: string };
      };
      secondary?: {
        p1?: { active: string; hover: string; disabled?: string };
        p2?: { active: string; hover: string; disabled?: string };
      };
      brand?: {
        p1?: { active: string; hover: string; disabled?: string };
        p2?: { active: string; hover: string; disabled?: string };
      };
    };
  }
}

// MUI Theme Settings
export const themeSettings = (mode: PaletteMode) => {
  const colors = tokens(mode);
  const typography = extractTypography();

  return {
    palette: {
      mode: mode,
      primary: {
        main: colors.primary.main,
        light: colors.primary["400"],
        dark: colors.primary["1000"],
        contrastText: "#ffffff",
      },
      secondary: {
        main: colors.secondary.main,
        light: colors.secondary["400"],
        dark: colors.secondary["900"],
        contrastText: "#ffffff",
      },
      error: {
        main: "#F23B0D",
        light: "#FF704D",
        dark: "#BD1C0F",
      },
      warning: {
        main: "#ff9800",
        light: "#ffb74d",
        dark: "#f57c00",
      },
      info: {
        main: colors.secondary.main,
        light: colors.secondary["400"],
        dark: colors.secondary["900"],
      },
      success: {
        main: "#4caf50",
        light: "#81c784",
        dark: "#388e3c",
      },
      neutral: colors.neutral,
      primaryShades: colors.primary,
      secondaryShades: colors.secondary,
      customBorder: colors.border,
      customNavigation: colors.navigation,
      surface: colors.surface,
      fill: colors.fill,
      customText: colors.text,
      shadow: colors.shadow,
    },
    typography: {
      fontSize: 14,
      h1: {
        fontSize: typography.h1.fontSize,
        fontWeight: typography.h1.fontWeight,
        lineHeight: `${typography.h1.lineHeight}px`,
        letterSpacing: `${typography.h1.letterSpacing}px`,
      },
      h2: {
        fontSize: typography.h2.fontSize,
        fontWeight: typography.h2.fontWeight,
        lineHeight: `${typography.h2.lineHeight}px`,
        letterSpacing: `${typography.h2.letterSpacing}px`,
      },
      h3: {
        fontSize: typography.h3.fontSize,
        fontWeight: typography.h3.fontWeight,
        lineHeight: `${typography.h3.lineHeight}px`,
        letterSpacing: `${typography.h3.letterSpacing}px`,
      },
      h4: {
        fontSize: typography.h4.fontSize,
        fontWeight: typography.h4.fontWeight,
        lineHeight: `${typography.h4.lineHeight}px`,
        letterSpacing: `${typography.h4.letterSpacing}px`,
      },
      h5: {
        fontSize: typography.h5.fontSize,
        fontWeight: typography.h5.fontWeight,
        lineHeight: `${typography.h5.lineHeight}px`,
        letterSpacing: `${typography.h5.letterSpacing}px`,
      },
      h6: {
        fontSize: typography.h6.fontSize,
        fontWeight: typography.h6.fontWeight,
        lineHeight: `${typography.h6.lineHeight}px`,
        letterSpacing: `${typography.h6.letterSpacing}px`,
      },
      body1: {
        fontSize: typography.body1.fontSize,
        fontWeight: typography.body1.fontWeight,
        lineHeight: `${typography.body1.lineHeight}px`,
        letterSpacing: `${typography.body1.letterSpacing}px`,
      },
      body2: {
        fontSize: typography.body2.fontSize,
        fontWeight: typography.body2.fontWeight,
        lineHeight: `${typography.body2.lineHeight}px`,
        letterSpacing: `${typography.body2.letterSpacing}px`,
      },
      caption: {
        fontSize: typography.caption.fontSize,
        fontWeight: typography.caption.fontWeight,
        lineHeight: `${typography.caption.lineHeight}px`,
        letterSpacing: `${typography.caption.letterSpacing}px`,
      },
      overline: {
        fontSize: typography.overline.fontSize,
        fontWeight: typography.overline.fontWeight,
        lineHeight: `${typography.overline.lineHeight}px`,
        letterSpacing: `${typography.overline.letterSpacing}px`,
      },
    },
    components: {
      MuiButton: {
        styleOverrides: {
          root: {
            textTransform: "none" as const,
            borderRadius: 8,
            fontWeight: 500,
          },
          contained: {
            backgroundColor: colors.fill.primary.clicked,
            color: colors.text.brand.p2.active,
            boxShadow: "none" as const,
            "&:hover": {
              backgroundColor: colors.fill.primary.hover,
              boxShadow: "none" as const,
            },
            "&:active": {
              backgroundColor: colors.fill.primary.active,
            },
            "&.Mui-disabled": {
              backgroundColor: colors.fill.primary.disabled,
              color: colors.text.brand.p2.disabled,
            },
          },
          outlined: {
            borderColor: colors.border.primary.active,
            color: colors.text.primary.p1.active,
            "&:hover": {
              borderColor: colors.border.territory.hover,
              backgroundColor: colors.surface.primary.hover,
            },
          },
          text: {
            color: colors.text.primary.p1.active,
            "&:hover": {
              backgroundColor: colors.surface.primary.hover,
            },
          },
        },
        variants: [
          {
            props: { variant: "submit" as const },
            style: {
              padding: "8px 16px",
              backgroundColor: colors.fill.primary.active,
              boxShadow: "none" as const,
              width: "fit-content",
              "&:hover": {
                backgroundColor: colors.fill.primary.hover,
                boxShadow: "none" as const,
              },
              "&.Mui-disabled": {
                backgroundColor: colors.fill.primary.disabled,
                color: colors.text.brand.p1.disabled,
              },
            },
          },
        ],
      },
      MuiTextField: {
        styleOverrides: {
          root: {
            "& .MuiOutlinedInput-root": {
              borderRadius: 8,
              fontSize: "14px",
              fontWeight: 400,
              "& .MuiOutlinedInput-input": {
                color: colors.text.primary.p3.active,
              },
              "& fieldset": {
                borderColor: colors.border.territory.active,
                borderWidth: "1px",
              },
              "&:hover fieldset": {
                borderColor: colors.border.territory.hover,
              },
              "&.Mui-focused fieldset": {
                borderColor: colors.border.secondary.active,
                borderWidth: "2px",
              },
              "&.Mui-error fieldset": {
                borderColor: "#F23B0D",
              },
              "&.Mui-disabled fieldset": {
                borderColor: colors.border.territory.disabled,
              },
            },
            "& .MuiInputLabel-root": {
              color: colors.text.primary.p2.active,
              fontSize: "14px",
              fontWeight: 400,
              "&.Mui-focused": {
                color: colors.border.brand.active,
              },
              "&.Mui-error": {
                color: "#F23B0D",
              },
            },
            "& .MuiFormHelperText-root": {
              fontSize: "12px",
              fontWeight: 400,
              marginLeft: "2px",
              marginTop: "4px",
              "&.Mui-error": {
                color: "#F23B0D",
              },
            },
          },
        },
      },
      MuiSwitch: {
        styleOverrides: {
          root: {
            width: 58,
            height: 38,
            padding: 0.5,
            "& .MuiSwitch-switchBase": {
              padding: 0,
              margin: "7px",
              transitionDuration: "300ms",
              color: alpha(colors.fill.secondary.active, 0.59),
              "&.Mui-checked": {
                transform: "translateX(20px)",
                color: colors.fill.secondary.active,
                "& + .MuiSwitch-track": {
                  backgroundColor: colors.fill.secondary_light.active,
                },
              },
              "&.Mui-disabled": {
                color: alpha(colors.fill.secondary.active, 0.35),
                "& + .MuiSwitch-track": {
                  backgroundColor: colors.fill.secondary.disabled,
                },
              },
            },
            "& .MuiSwitch-thumb": {
              width: 24,
              height: 24,
            },
            "& .MuiSwitch-track": {
              borderRadius: 38 / 2,
              backgroundColor: alpha(colors.fill.secondary_light.active, 0.59),
              opacity: 1,
            },
          },
        },
      },
      MuiTooltip: {
        defaultProps: {
          arrow: true,
          placement: "right" as const,
        },
        styleOverrides: {
          tooltip: {
            backgroundColor: colors.neutral["1700"],
            color: colors.neutral.white,
            padding: "6px 8px",
            borderRadius: "4px",
            fontSize: "12px",
            boxShadow: "0px 4px 8px rgba(0, 0, 0, 0.16), 0px 0px 2px rgba(0, 0, 0, 0.08)",
          },
          arrow: {
            color: colors.neutral["1700"],
          },
        },
      },
    },
    breakpoints: {
      values: {
        xs: 0,
        sm: 700,
        md: 960,
        lg: 1280,
        xl: 1920,
      },
    },
    shape: {
      borderRadius: 8,
    },
    spacing: 8,
  };
};

export default themeSettings;

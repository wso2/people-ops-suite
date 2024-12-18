// Copyright (c) 2024 WSO2 LLC. (https://www.wso2.com).
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

const Typography = (fontFamily) => ({
  htmlFontSize: 16,
  fontFamily,
  fontWeightLight: 300,
  fontWeightRegular: 400,
  fontWeightMedium: 500,
  fontWeightBold: 600,
  h1: {
    fontWeight: 600,
    fontSize: "2.375rem",
    lineHeight: 1.21,
  },
  h2: {
    fontWeight: 600,
    fontSize: "1.875rem",
    lineHeight: 1.27,
  },
  h3: {
    fontWeight: 600,
    fontSize: "1.5rem",
    lineHeight: 1.33,
  },
  h4: {
    fontWeight: 600,
    fontSize: "1.25rem",
    lineHeight: 1.4,
  },
  h5: {
    fontWeight: 600,
    fontSize: "1rem",
    lineHeight: 1.5,
  },
  h6: {
    fontWeight: 400,
    fontSize: "0.875rem",
    lineHeight: 1.57,
  },
  caption: {
    fontWeight: 400,
    fontSize: "0.75rem",
    lineHeight: 1.66,
  },
  body1: {
    fontSize: "0.875rem",
    lineHeight: 1.57,
  },
  body2: {
    fontSize: "0.75rem",
    lineHeight: 1.66,
  },
  subtitle1: {
    fontSize: "0.875rem",
    fontWeight: 600,
    lineHeight: 1.57,
  },
  subtitle2: {
    fontSize: "0.75rem",
    fontWeight: 500,
    lineHeight: 1.66,
  },
  overline: {
    lineHeight: 1.66,
  },
  button: {
    textTransform: "capitalize",
  },
});

export default Typography;

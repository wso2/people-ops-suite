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

import { BaseURLAuthClientConfig } from "@asgardeo/auth-react";

declare global {
  interface Window {
    config: {
      APP_NAME: string;
      ASGARDEO_BASE_URL: string;
      ASGARDEO_CLIENT_ID: string;
      ASGARDEO_REVOKE_ENDPOINT: string;
      AUTH_SIGN_IN_REDIRECT_URL: string;
      AUTH_SIGN_OUT_REDIRECT_URL: string;
      REACT_APP_BACKEND_BASE_URL: string;
      RECRUITMENT_ADMIN: string;
      RECRUITMENT_TEAM: string;
    };
  }
}

export const AsgardeoConfig: BaseURLAuthClientConfig = {
  signInRedirectURL: window.config?.AUTH_SIGN_IN_REDIRECT_URL ?? "",
  signOutRedirectURL: window.config?.AUTH_SIGN_OUT_REDIRECT_URL ?? "",
  clientID: window.config?.ASGARDEO_CLIENT_ID ?? "",
  baseUrl: window.config?.ASGARDEO_BASE_URL ?? "",
  scope: ["openid", "email", "groups"],
};

export const ServiceBaseUrl = window.config?.REACT_APP_BACKEND_BASE_URL ?? "";
export const APP_NAME = window.config?.APP_NAME ?? "";
export const RECRUITMENT_ADMIN = window.config?.RECRUITMENT_ADMIN ?? "";
export const RECRUITMENT_TEAM = window.config?.RECRUITMENT_TEAM ?? "";

export const AppConfig = {
  serviceUrls: {
    collections: ServiceBaseUrl + "/collections",
    getUserInfo: ServiceBaseUrl + "/user-info",
  },
};

// Copyright (c) 2024, WSO2 LLC. (https://www.wso2.com). All Rights Reserved.
//
// This software is the property of WSO2 LLC. and its suppliers, if any.
// Dissemination of any information or reproduction of any material contained
// herein in any form is strictly forbidden, unless permitted by WSO2 expressly.
// You may not alter or remove any copyright or other notice from copies of this content.

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

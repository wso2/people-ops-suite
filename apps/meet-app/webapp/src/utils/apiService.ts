// Copyright (c) 2024, WSO2 LLC. (https://www.wso2.com). All Rights Reserved.
//
// This software is the property of WSO2 LLC. and its suppliers, if any.
// Dissemination of any information or reproduction of any material contained
// herein in any form is strictly forbidden, unless permitted by WSO2 expressly.
// You may not alter or remove any copyright or other notice from copies of this content.

import axios, { AxiosInstance, CancelTokenSource } from "axios";
import * as rax from "retry-axios";

export class APIService {
  private static _instance: AxiosInstance;
  private static _idToken: string;
  private static _cancelTokenSource = axios.CancelToken.source();
  private static _cancelTokenMap: Map<string, CancelTokenSource> = new Map();
  private static callback: () => Promise<{ idToken: string }>;

  private static _isRefreshing = false;
  private static _refreshPromise: Promise<{ idToken: string }> | null = null;

  constructor(idToken: string, callback: () => Promise<{ idToken: string }>) {
    APIService._instance = axios.create();
    rax.attach(APIService._instance);

    APIService._idToken = idToken;
    APIService.updateRequestInterceptor();
    APIService.callback = callback;
    (APIService._instance.defaults as unknown as rax.RaxConfig).raxConfig = {
      retry: 3,
      instance: APIService._instance,
      httpMethodsToRetry: ["GET", "HEAD", "OPTIONS", "DELETE", "POST", "PATCH", "PUT"],
      statusCodesToRetry: [[401, 401]],
      retryDelay: 100,

      onRetryAttempt: async (err) => {
        if (!APIService._isRefreshing) {
          APIService._isRefreshing = true;
          APIService._refreshPromise = APIService.callback()
            .then((res) => {
              APIService.updateTokens(res.idToken);
              APIService._instance.interceptors.request.clear();
              APIService.updateRequestInterceptor();
              return res;
            })
            .finally(() => {
              APIService._isRefreshing = false;
              APIService._refreshPromise = null;
            });
        }
        return APIService._refreshPromise;
      },
    };
  }

  public static getInstance(): AxiosInstance {
    return APIService._instance;
  }

  public static getCancelToken() {
    return APIService._cancelTokenSource;
  }

  public static updateCancelToken(): CancelTokenSource {
    APIService._cancelTokenSource = axios.CancelToken.source();
    return APIService._cancelTokenSource;
  }

  private static updateTokens(idToken: string) {
    APIService._idToken = idToken;
  }

  private static updateRequestInterceptor() {
    APIService._instance.interceptors.request.use(
      (config) => {
        config.headers.set("Authorization", "Bearer " + APIService._idToken);

        const endpoint = config.url || "";

        const existingToken = APIService._cancelTokenMap.get(endpoint);
        if (existingToken) {
          existingToken.cancel(`Request canceled for endpoint: ${endpoint}`);
        }

        const newTokenSource = axios.CancelToken.source();
        APIService._cancelTokenMap.set(endpoint, newTokenSource);
        config.cancelToken = newTokenSource.token;
        return config;
      },
      (error) => {
        Promise.reject(error);
      }
    );
  }
}

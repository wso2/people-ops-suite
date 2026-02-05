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
import { fetchBaseQuery, retry } from "@reduxjs/toolkit/query";
import type { BaseQueryFn, FetchArgs, FetchBaseQueryError } from "@reduxjs/toolkit/query";
import { Mutex } from "async-mutex";

import { SERVICE_BASE_URL } from "@config/config";

let ACCESS_TOKEN: string;
let REFRESH_TOKEN_CALLBACK: () => Promise<{ accessToken: string }>;
let LOGOUT_CALLBACK: () => void;

export const setTokens = (
  accessToken: string,
  refreshCallback: () => Promise<{ accessToken: string }>,
  logoutCallBack: () => void,
) => {
  ACCESS_TOKEN = accessToken;
  REFRESH_TOKEN_CALLBACK = refreshCallback;
  LOGOUT_CALLBACK = logoutCallBack;
};

const baseQuery = fetchBaseQuery({
  baseUrl: SERVICE_BASE_URL,
  prepareHeaders: (headers) => {
    if (ACCESS_TOKEN) {
      headers.set("Authorization", `Bearer ${ACCESS_TOKEN}`);
    }
  },
});

const mutex = new Mutex();
export const baseQueryWithReauth: BaseQueryFn<
  string | FetchArgs,
  unknown,
  FetchBaseQueryError
> = async (args, api, extraOptions) => {
  await mutex.waitForUnlock();
  let result = await baseQuery(args, api, extraOptions);
  if (result.error && result.error.status === 401) {
    if (!mutex.isLocked()) {
      const release = await mutex.acquire();

      try {
        const refreshResult = await REFRESH_TOKEN_CALLBACK();
        if (refreshResult?.accessToken) {
          ACCESS_TOKEN = refreshResult.accessToken;
          result = await baseQuery(args, api, extraOptions);
        } else {
          console.error("Token refresh failed - no access token returned");
          LOGOUT_CALLBACK();
        }
      } catch (error) {
        console.error("Error refreshing token:", error);
        LOGOUT_CALLBACK();
      } finally {
        release();
      }
    } else {
      // wait until the mutex is available without locking it
      await mutex.waitForUnlock();
      result = await baseQuery(args, api, extraOptions);
    }
  }
  return result;
};

/*
 * Base query with retry logic and automatic token refresh
 * Retries failed requests up to 3 times
 */
export const baseQueryWithRetry = retry(
  async (args: string | FetchArgs, api, extraOptions) => {
    const result = await baseQueryWithReauth(args, api, extraOptions);

    if (result.error) {
      if (result.error.status !== 400 && result.error.status !== 404) {
        retry.fail(result.error, result.meta);
      }
    }

    return result;
  },
  {
    maxRetries: 3,
    backoff: async (attempt: number = 0, maxRetries: number = 3) => {
      const delay = Math.min(1000 * 2 ** attempt, 10000);
      await new Promise((resolve) => setTimeout(resolve, delay));
    },
  },
);

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
import {
  getAccessToken,
  setIdToken,
  setAccessToken,
  getIdToken,
} from "./oauth";
import { INPUT_INVALID_MSG_GATEWAY } from "../constants";
import { APPLICATION_CONFIG } from "../config";
import { handleTokenFailure } from "../components/webapp-bridge";

const useHttp = () => {
  const MAX_TRIES = 2;

  const handleRequest = async (
    url,
    method,
    body,
    successFn,
    failFn,
    loadingFn,
    headers,
    currentTry
  ) => {
    if (!currentTry) {
      currentTry = 1;
    }

    try {
      if (loadingFn) {
        loadingFn(true);
      }

      var encodedUrl = encodeURI(url);
      const response = await fetch(encodedUrl, {
        method: method,
        body: body ? JSON.stringify(body) : null,
        headers: headers || {
          "Content-Type": "application/json",
          Authorization: `Bearer ${getAccessToken()}`
        },
      });

      let responseBody = "";
      let isGatewayForbidden = false;

      // Assumptions
      // The only reason we may get 403 responses from Gateway is due to user input validation issues (rules blocking certain user inputs).
      // The other reasons may be due to code-level issues. But we assume they are already fixed after testing.
      // We only show the custom error msg for post / patch / put requests
      // We also assume that the gateway is sending a html page in response (therefore no json body and therefore handled in catch)
      try {
        responseBody = await response.json();
      } catch (e) {
        if (response.status === 403) {
          isGatewayForbidden = true;
        }
      } finally {
        let customErrMsg = "";

        if (isGatewayForbidden) {
          customErrMsg = INPUT_INVALID_MSG_GATEWAY;
        }

        if (
          response.status === 200 ||
          response.status === 201 ||
          response.status === 202
        ) {
          successFn(responseBody);

          if (loadingFn) {
            loadingFn(false);
          }
        } else {
          if (
            (response.status === 401 || response.status === 403) &&
            currentTry < MAX_TRIES
          ) {
            handleRequestWithNewToken(
              () =>
                handleRequest(
                  url,
                  method,
                  body,
                  successFn,
                  failFn,
                  loadingFn,
                  ++currentTry
                ),
              true
            );
          } else if (currentTry < MAX_TRIES) {
            handleRequest(
              url,
              method,
              body,
              successFn,
              failFn,
              loadingFn,
              ++currentTry
            );
          } else {
            console.error(
              (responseBody && responseBody.error) || response.status
            );
            if (failFn) {
              failFn(customErrMsg);
            }
            if (loadingFn) {
              loadingFn(false);
            }
          }
        }
      }
    } catch (err) {
      console.error(err);
      if (failFn) {
        failFn();
      }
      if (loadingFn) {
        loadingFn(false);
      }
    }
  };

  const handleRequestWithNewToken = (callback, isRefresh) => {
    if (APPLICATION_CONFIG.isMicroApp) {
      var idToken = getIdToken(Boolean(isRefresh));
      setIdToken(idToken);
      setAccessToken(idToken);
      callback();
    } else {
      if (isRefresh) {
        handleTokenFailure(callback);
      }
      callback();
    }
  };

  return {
    handleRequest,
    handleRequestWithNewToken,
  };
};

export default useHttp;

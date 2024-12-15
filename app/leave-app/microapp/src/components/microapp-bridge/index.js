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

const nativebridge = require("@nrk/nativebridge");

export function getToken(callback) {
  nativebridge.rpc({
    topic: "token",
    data: {},
    resolve: (data) => {
      callback(data.data);
    },
    reject: (err) => {
      callback();
    },
    timeout: 3000,
  });
}

export function showAlert(
  title,
  message,
  buttonText,
  successCallback,
  failedToRespondCallback
) {
  nativebridge.rpc({
    topic: "alert",
    data: {
      title: title,
      message: message,
      buttonText: buttonText,
    },
    resolve: () => {
      successCallback();
    },
    reject: (err) => {
      failedToRespondCallback(err);
    },
    timeout: 120000,
  });
}

export function showConfirmAlert(
  title,
  message,
  confirmButtonText,
  cancelButtonText,
  confirmCallback,
  cancelCallback,
  failedToRespondCallback
) {
  nativebridge.rpc({
    topic: "confirmAlert",
    data: {
      title: title,
      message: message,
      confirmButtonText: confirmButtonText,
      cancelButtonText: cancelButtonText,
    },
    resolve: (data) => {
      if (data.action === "confirm") {
        confirmCallback();
      } else if (data.action === "cancel") {
        cancelCallback();
      } else {
        failedToRespondCallback();
      }
    },
    reject: (err) => {
      failedToRespondCallback(err);
    },
    timeout: 120000,
  });
}

export function scanQRCode(successCallback, failedToRespondCallback) {
  nativebridge.rpc({
    topic: "scanQrCode",
    data: {},
    resolve: (data) => {
      successCallback(data.qrData);
    },
    reject: (err) => {
      failedToRespondCallback(err);
    },
    timeout: 120000,
  });
}

export function saveLocalData(key, value, callback, failedToRespondCallback) {
  key = key.toString().replace(" ", "-").toLowerCase();
  var encodedValue = btoa(JSON.stringify(value));

  nativebridge.rpc({
    topic: "saveLocalData",
    data: {
      key: key,
      value: encodedValue,
    },
    resolve: () => {
      callback();
    },
    reject: (err) => {
      failedToRespondCallback(err);
    },
    timeout: 5000,
  });
}

export function getLocalData(key, callback, failedToRespondCallback) {
  key = key.toString().replace(" ", "-").toLowerCase();
  nativebridge.rpc({
    topic: "getLocalData",
    data: {
      key: key,
    },
    resolve: (encodedData) => {
      console.log("return encoded " + encodedData.value);
      if (!encodedData.value) {
        callback(null);
        return;
      }
      var jsonObject = JSON.parse(atob(encodedData.value));
      console.log("json object" + jsonObject);
      callback(jsonObject);
    },
    reject: (err) => {
      failedToRespondCallback(err);
    },
    timeout: 5000,
  });
}

export function totpQrMigrationData(callback, failedToRespondCallback) {
  nativebridge.rpc({
    topic: "getTotpQrMigrationData",
    data: {},
    resolve: (encodedData) => {
      console.log(encodedData);
      var data = encodedData.data;

      if (data !== undefined && data != null && data !== "") {
        var trimmed = data.replace(" ", "");
        callback(trimmed.split(","));
      } else {
        callback([]);
      }
    },
    reject: (err) => {
      failedToRespondCallback(err);
    },
    timeout: 5000,
  });
}

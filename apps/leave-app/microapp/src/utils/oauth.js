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
import { APPLICATION_CONFIG } from "../config";
import {
  getAccessToken as getAccessTokenWeb,
  setAccessToken as setAccessTokenWeb,
  refreshToken as refreshTokenWeb,
} from "../components/webapp-bridge/index";

var isAdmin = false;
var idToken = null;
var userName = "";
var country = "";
var userRoles = [];
var userPrivileges = [];

// eslint-disable-next-line
var refreshTokenFunction = null;
// eslint-disable-next-line
var sessionClearFunction = null;


var refreshToken = null;

var logoutFunction = null;

var isLoggedOut = false;

export function setIsAdmin(userIsAdmin, callback) {
  isAdmin = userIsAdmin;
  callback && callback();
}

export function getIsAdmin() {
  return isAdmin;
}

export function setLogoutFunction(func) {
  logoutFunction = func;
}

export function logout() {
  if (logoutFunction) {
    logoutFunction();
  }
}

export function setIsLoggedOut(status) {
  isLoggedOut = status;
}

export function getIsLoggedOut() {
  return isLoggedOut;
}

export function setIdToken(token) {
  idToken = token;
}

export function getIdToken(isTokenRefresh) {
  if (APPLICATION_CONFIG.isMicroApp) {
    return idToken;
  }

  if (isTokenRefresh) {
    refreshTokenWeb()
      .then((newToken) => {
        return getAccessTokenWeb();
      })
      .catch((error) => {
        console.error("Error while refreshing token!", error);
      });
  }
}

export function setUserName(user) {
  userName = user;
}

export function getUserName() {
  return userName;
}

export function setCountry(location) {
  country = location;
}

export function getCountry() {
  return country;
}

export function setUserPrivileges(privileges) {
  userPrivileges = privileges;
}

export function getUserPrivileges() {
  return userPrivileges;
}

export function setUserRoles(rolesFromJWT) {
  if (typeof rolesFromJWT === "string") {
    userRoles = rolesFromJWT.split(",");
  } else if (Array.isArray(rolesFromJWT)) {
    userRoles = rolesFromJWT.slice();
  }
}

export function getUserRoles() {
  return userRoles;
}

export function checkIfRolesExist(roles, customRoles) {
  var isTrue = false;
  if (roles) {
    roles.forEach((role) => {
      if (
        userRoles.includes(role) ||
        (customRoles && customRoles.includes(role))
      ) {
        isTrue = true;
        return;
      }
    });
  }

  return isTrue;
}

export function setRefreshTokenFunction(refreshFunction) {
  refreshTokenFunction = refreshFunction;
}

export function setSessionClearFunction(sessionClearFn) {
  sessionClearFunction = sessionClearFn;
}

export function setAccessToken(token) {
  setAccessTokenWeb(token);
}

export function getAccessToken() {
  return getAccessTokenWeb();
}

export function getRefreshToken() {
  return refreshToken;
}

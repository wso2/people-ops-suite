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

export const formatDateTime = (dateTimeStr: string) => {
  const utcDate = new Date(dateTimeStr);
  if (Number.isNaN(utcDate.getTime())) return "";
  return utcDate.toLocaleString("en-GB", {
    day: "2-digit",
    month: "short",
    year: "numeric",
    hour: "2-digit",
    minute: "2-digit",
  });
};

export const formatDateForInput = (date: Date) => {
  return date.toLocaleDateString("en-CA");
};

export const formatForAPI = (dateStr: string) => {
  const date = new Date(dateStr);
  return Number.isNaN(date.getTime()) ? "" : new Date(dateStr).toISOString();
};

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

const oneDay = 24 * 60 * 60 * 1000;

export function getCurrentYear() {
  return new Date().getFullYear();
}

export function getLocalDisplayDate(date) {
  return new Date(date).toLocaleDateString();
}

function isValidDate(d) {
  return d instanceof Date && !isNaN(d);
}

function arrangeDisplayDate(date) {
  var comma = ",";
  var position = 3;
  var output = [date.slice(0, position), comma, date.slice(position)].join("");

  return output;
}

export function getLocalDisplayDateWithTZReadable(date) {
  var localISOTime = "";
  var dateToBeUsed = new Date(date);
  if (isValidDate(dateToBeUsed)) {
    var tzoffset = dateToBeUsed.getTimezoneOffset() * 60000; //offset in milliseconds
    localISOTime = arrangeDisplayDate(
      new Date(dateToBeUsed.getTime() - tzoffset).toDateString()
    );
  }

  return localISOTime;
}

export function getLocalDisplayDateReadable(date) {
  var dateToBeUsed = new Date(date);
  var dateToBeDisplayed = "";
  if (isValidDate(dateToBeUsed)) {
    dateToBeDisplayed = arrangeDisplayDate(dateToBeUsed.toDateString());
  }
  return dateToBeDisplayed;
}

export function getDateFromTZString(date) {
  var index = date.indexOf("T");

  return date.substring(0, index > 0 ? index : 0);
}

export function getDateFromDateObject(date) {
  return getDateFromDateString(date);
}

export function countDaysInRange(startDate, endDate) {
  return Math.round(
    Math.abs((endDate.getTime() - startDate.getTime()) / oneDay) + 1
  );
}

/**
 * To format a date string to remove the timezone and return the date in dd/MM/yyyy format.
 * 01/01/2020 => 2020-01-01
 * @param {String} dateString
 */
export function getDateFromDateString(date) {
  var d = new Date(date),
    month = "" + (d.getMonth() + 1),
    day = "" + d.getDate(),
    year = d.getFullYear();

  if (month.length < 2) month = "0" + month;
  if (day.length < 2) day = "0" + day;

  return [year, month, day].join("-");
}

export function checkIfValidEmailAddress(email) {
  var re = /^[a-zA-Z0-9._%+-]+@wso2\.com$/;
  return re.test(email);
}

export function getUserFromEmail(email) {
  var index = email.indexOf("@");
  return email.substring(0, index > 0 ? index : 0);
}

/**
 * To sort an array of employees or people using the 'workEmail' field
 * @param {Array} people
 */
export function getSortedPeople(people) {
  var tempPeople = people.slice();
  tempPeople = tempPeople.sort((a, b) => {
    if (!a.workEmail || !b.workEmail) {
        return a.workEmail ? -1 : 1;
    }
    var emailA = a.workEmail.toUpperCase();
    var emailB = b.workEmail.toUpperCase();
    if (emailA < emailB) {
      return -1;
    }
    if (emailA > emailB) {
      return 1;
    }
    return 0;
  });
  return tempPeople;
}

export function getGmailMailTo(email, subject) {
  var urlToReturn =
    "https://mail.google.com/mail/?view=cm&fs=1&tf=1&to=" + email;
  if (subject) {
    urlToReturn += "&su=" + subject;
  }
  return urlToReturn;
}

export function getStartYear() {
  const startDate = new Date(new Date().getFullYear(), 0, 1);
  return getDateFromDateObject(startDate);
}

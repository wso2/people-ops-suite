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
import { createSlice } from "@reduxjs/toolkit";

import { getSortedPeople } from "../../utils/formatting";

const initialState = {
  isAdmin: false,
  isLead: false,
  openItem: ["form"],
  openComponent: "buttons",
  drawerOpen: false,
  componentDrawerOpen: true,
  navigatedView: "form",
  employeeData: [],
  employeeMap: {},
};

const menu = createSlice({
  name: "menu",
  initialState,
  reducers: {
    setIsAdmin(state, action) {
      state.isAdmin = action.payload.isAdmin;
    },

    setIsLead(state, action) {
      state.isLead = action.payload.isLead;
    },

    activeItem(state, action) {
      state.openItem = action.payload.openItem;
    },

    activeComponent(state, action) {
      state.openComponent = action.payload.openComponent;
    },

    openDrawer(state, action) {
      state.drawerOpen = action.payload.drawerOpen;
    },

    openComponentDrawer(state, action) {
      state.componentDrawerOpen = action.payload.componentDrawerOpen;
    },

    navigateToView(state, action) {
      state.navigatedView = action.payload.navigatedView;
    },

    setEmployeeData(state, action) {
      const sortedPeople = getSortedPeople(action.payload.employeeData);
      state.employeeData = sortedPeople;
      var tempMap = {};
      sortedPeople.forEach((person) => {
        if (person.workEmail) {
          tempMap[person.workEmail] = person;
        }
      });
      state.employeeMap = tempMap;
    },
  },
});

export default menu.reducer;

export const {
  setIsAdmin,
  setIsLead,
  activeItem,
  activeComponent,
  openDrawer,
  openComponentDrawer,
  navigateToView,
  setEmployeeData,
} = menu.actions;

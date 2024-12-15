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
  AppstoreAddOutlined,
  AntDesignOutlined,
  BarcodeOutlined,
  BgColorsOutlined,
  FontSizeOutlined,
  LoadingOutlined,
} from "@ant-design/icons";

const icons = {
  FontSizeOutlined,
  BgColorsOutlined,
  BarcodeOutlined,
  AntDesignOutlined,
  LoadingOutlined,
  AppstoreAddOutlined,
};

const utilities = {
  id: "utilities",
  title: "Utilities",
  type: "group",
  children: [
    {
      id: "util-typography",
      title: "Typography",
      type: "item",
      url: "/typography",
      icon: icons.FontSizeOutlined,
    },
    {
      id: "util-color",
      title: "Color",
      type: "item",
      url: "/color",
      icon: icons.BgColorsOutlined,
    },
    {
      id: "util-shadow",
      title: "Shadow",
      type: "item",
      url: "/shadow",
      icon: icons.BarcodeOutlined,
    },
    {
      id: "ant-icons",
      title: "Ant Icons",
      type: "item",
      url: "/icons/ant",
      icon: icons.AntDesignOutlined,
      breadcrumbs: false,
    },
  ],
};

export default utilities;

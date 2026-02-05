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
import { AnimatePresence, motion } from "framer-motion";

import type { RouteDetail } from "@/types/types";

import SubLink from "./SubLink";

const container = {
  open: {
    opacity: 1,
    transition: { staggerChildren: 0.07, delayChildren: 0.1 },
  },
  closed: {
    opacity: 0,
    transition: { staggerChildren: 0.05, staggerDirection: -1 },
  },
};

const item = {
  open: { opacity: 1, x: 0 },
  closed: { opacity: 0, x: -20 },
};

function SidebarSubMenu({ parentRoute, open }: { parentRoute: RouteDetail; open: boolean }) {

  return (
    <AnimatePresence>
      {parentRoute.children && parentRoute.children.length > 0 && (
        <motion.div
          key="submenu"
          variants={container}
          initial="closed"
          animate="open"
          exit="closed"
          style={{
            display: "flex",
            flexDirection: "column",
            gap: "8px",
            width: "100%",
            overflow: "hidden",
          }}
        >
          {parentRoute.children!.map((child) => (
            <motion.div
              key={child.path}
              variants={item}
              style={{ width: "100%" }}
            >
              <SubLink
                to={child.path as string}
                parentPath={parentRoute.path}
                primary={child.text}
                icon={child.icon}
                open={open}
              />
            </motion.div>
          ))}
        </motion.div>
      )}
    </AnimatePresence>
  );
}

export default SidebarSubMenu;

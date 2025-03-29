const path = require("path");

module.exports = function override(config) {
  config.resolve.alias = {
    ...config.resolve.alias,
    "@root": path.resolve(__dirname),
    "@src": path.resolve(__dirname, "src"),
    "@app": path.resolve(__dirname, "src/app"),
    "@assets": path.resolve(__dirname, "src/assets"),
    "@component": path.resolve(__dirname, "src/component"),
    "@config": path.resolve(__dirname, "src/config"),
    "@context": path.resolve(__dirname, "src/context"),
    "@layout": path.resolve(__dirname, "src/layout"),
    "@slices": path.resolve(__dirname, "src/slices"),
    "@view": path.resolve(__dirname, "src/view"),
    "@utils": path.resolve(__dirname, "src/utils"),
    "@/types": path.resolve(__dirname, "src/types"),
  };
  return config;
};

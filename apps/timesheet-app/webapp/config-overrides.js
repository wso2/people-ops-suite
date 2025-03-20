const path = require("path");
module.exports = function override(config) {
  config.resolve = {
    ...config.resolve,
    alias: {
      ...config.alias,
      "@config": path.resolve(__dirname, "src/config"),
      "@component": path.resolve(__dirname, "src/component"),
      "@app": path.resolve(__dirname, "src/app"),
      "@view": path.resolve(__dirname, "src/view"),
      "@utils": path.resolve(__dirname, "src/utils"),
      "@context": path.resolve(__dirname, "src/context"),
      "@slices": path.resolve(__dirname, "src/slices"),
      types: path.resolve(__dirname, "src/types"),
    },
  };
  return config;
};

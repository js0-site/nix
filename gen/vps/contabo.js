#!/usr/bin/env bun

import * as CONTABO from "../../../conf/gen/conf/contabo.js";
import contabo from "@3-/contabo";
import pageIter from "@3-/contabo/pageIter.js";

export default async (SSH_CONFIG) => {
  const api = await contabo(CONTABO);
  for await (const i of pageIter(api, "compute/instances")) {
    SSH_CONFIG.push([i.displayName || i.name, i.ipConfig.v4.ip]);
  }
};

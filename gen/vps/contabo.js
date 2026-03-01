#!/usr/bin/env bun

import ipaddr from "ipaddr.js";
import * as CONTABO from "../../../conf/gen/conf/contabo.js";
import contabo from "@3-/contabo";
import pageIter from "@3-/contabo/pageIter.js";

export default async (SSH_CONFIG, IP) => {
  const api = await contabo(CONTABO);
  for await (const i of pageIter(api, "compute/instances")) {
    const { ipConfig } = i;
    SSH_CONFIG.push([i.displayName || i.name, ipConfig.v4.ip]);
    IP[i.displayName] = {
      v4: ipConfig.v4.ip,
      v6: ipaddr.parse(ipConfig.v6.ip).toString(),
    };
  }
};

#!/usr/bin/env bun

import hwdns from "@3-/hwdns";
import HW_CONF from "../../conf/nix/HW.js";
// import CF_CONF from "../../conf/nix/cf.js";
// import Cf from "@3-/cf";
// import Zone from "@3-/cf/Zone.js";
import HOST from "../../conf/nix/host.js";
import read from "@3-/read";
import { join } from "node:path";

const ROOT = import.meta.dirname,
  DIR_VPS = join(ROOT, "../nix/vps"),
  DNS = await hwdns(...HW_CONF)(HOST),
  // DNS = await Zone(Cf(...CF_CONF), HOST),
  A = [],
  AAAA = [],
  TO_SET = { A, AAAA },
  HOST_IP = JSON.parse(read(join(DIR_VPS, "ip.json"))),
  ING = [],
  MX = [];

JSON.parse(read(join(DIR_VPS, "enable.json")))
  .smtp.toSorted()
  .forEach((name, pos) => {
    const { v4, v6 } = HOST_IP[name],
      to_set = {},
      mx = "mx" + ++pos;
    if (v4) {
      A.push(v4);
      to_set.A = [v4];
    }
    if (v6) {
      AAAA.push(v6);
      to_set.AAAA = [v6];
    }
    ING.push(DNS.reset(mx, to_set));
    MX.push(pos * 5 + " " + mx + "." + HOST + ".");
  });

await DNS.reset("smtp", TO_SET);
await Promise.all(ING);
await DNS.reset("", { MX });

process.exit();

#!/usr/bin/env bun

import CF_CONF from "../../conf/nix/cf.js";
import HOST from "../../conf/nix/host.js";
import Cf from "@3-/cf";
import Zone from "@3-/cf/Zone.js";
import read from "@3-/read";
import { join } from "node:path";

const ROOT = import.meta.dirname,
  DIR_VPS = join(ROOT, "../nix/vps"),
  CF = Cf(...CF_CONF),
  ZONE = await Zone(CF, HOST),
  A = [],
  AAAA = [],
  TO_SET = { A: { smtp: A }, AAAA: { smtp: AAAA } },
  HOST_IP = JSON.parse(read(join(DIR_VPS, "ip.json")));

JSON.parse(read(join(DIR_VPS, "enable.json"))).smtp.forEach((name) => {
  const ip = HOST_IP[name];
  if (ip.v4) {
    A.push(ip.v4);
  }
  if (ip.v6) {
    AAAA.push(ip.v6);
  }
});

await ZONE.reset("smtp", TO_SET);
process.exit();

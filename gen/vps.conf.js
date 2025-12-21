#!/usr/bin/env bun

import read from "@3-/read";
import write from "@3-/write";
import { join, dirname } from "node:path";

const ROOT = dirname(import.meta.dirname),
  DIR_VPS = join(ROOT, "nix/vps"),
  DIR_ETC = join(DIR_VPS, "disk/etc"),
  load = (name) => JSON.parse(read(join(DIR_VPS, name + ".json"))),
  HOST_IP = load("ip"),
  ENABLE = load("enable"),
  writeEtc = (fp, txt) => {
    write(join(DIR_ETC, fp), txt);
  },
  enable = (name) => ENABLE[name].map((i) => HOST_IP[i].v4).join(" ");

writeEtc(
  "ipv6_proxy/host_li.env",
  `IPV6_PROXY_IP_LI='${enable("ipv6_proxy")}'`,
);
writeEtc("kvrocks/ip_li.env", `KVROCKS_IP_LI='${enable("kvrocks")}'`);

#!/usr/bin/env bun

import read from "@3-/read";
import write from "@3-/write";
import { $ } from "zx";
import { join } from "node:path";

const ROOT = import.meta.dirname,
  DIR_VPS = join(ROOT, "nix/vps"),
  DIR_ETC = join(DIR_VPS, "disk/etc"),
  HOST_JSON = JSON.parse(read(join(DIR_VPS, "host.json"))),
  IP_LI = Object.keys(HOST_JSON).toSorted().join(" "),
  writeEtc = (fp, txt) => {
    write(join(DIR_ETC, fp), txt);
  };

writeEtc("ipv6_proxy/host_li.env", `IPV6_PROXY_HOST_LI='${IP_LI}'`);
writeEtc("kvrocks/ip_li.env", `KVROCKS_IP_LI='${IP_LI}'`);

await $`gci`;

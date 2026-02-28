#!/usr/bin/env bun

import smtp from "./smtp.js";
import DNS from "../../nix/vps/DNS.js";
import { hostDns } from "./CONST.js";

await Promise.all(
  Object.entries(DNS).map(async ([host, dns]) => {
    const { reset } = await hostDns(host);
    for (const [prefix, to_set] of Object.entries(dns)) {
      console.log(prefix, host, to_set);
      await reset(prefix, to_set);
    }
  }),
);

await smtp();

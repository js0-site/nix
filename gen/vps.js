#!/usr/bin/env bun

import contabo from "@3-/contabo";
import pageIter from "@3-/contabo/pageIter.js";
import write from "@3-/write";
import { dirname, join } from "node:path";
import { homedir } from "node:os";
import { readdirSync } from "node:fs";

const CONF = join(homedir(), ".config/contabo"),
  LI = await Promise.all(
    readdirSync(CONF)
      .filter((i) => i.endsWith(".js"))
      .map((i) => import(join(CONF, i)).then(contabo)),
  ),
  SSH_CONFIG = [];

await Promise.all(
  LI.map(async (api) => {
    for await (const i of pageIter(api, "compute/instances")) {
      SSH_CONFIG.push([i.displayName || i.name, i.ipConfig.v4.ip]);
    }
  }),
);

const GEN = SSH_CONFIG.map(
  (i) => `Host ${i[0]}
HostName ${i[1]}
User root`,
).join("\n\n");

const ROOT = join(dirname(import.meta.dirname), "nix/vps");

write(join(ROOT, "ssh.conf"), GEN);
write(
  join(ROOT, "host.json"),
  "{\n" + SSH_CONFIG.map((i) => `  "${i[1]}" : "${i[0]}";\n`).join("") + "}",
);

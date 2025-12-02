#!/usr/bin/env bun

import { dirname, join } from "node:path";
import write from "@3-/write";

const SSH_CONFIG = [],
  IP = {},
  ROOT = join(dirname(import.meta.dirname), "nix/vps");

await Promise.all(
  ["gcloud", "contabo"].map(async (name) =>
    (await import("./vps/" + name + ".js")).default(SSH_CONFIG, IP),
  ),
);

SSH_CONFIG.sort();

SSH_CONFIG.map((i) => console.log(...i));

const GEN = SSH_CONFIG.map(
  (i) => `Host ${i[0]}
HostName ${i[1]}
User root`,
).join("\n\n");

write(join(ROOT, "ssh.conf"), GEN);
write(
  join(ROOT, "host.json"),
  JSON.stringify(Object.fromEntries(SSH_CONFIG.map((i) => [i[1], i[0]]))),
);
write(join(ROOT, "ip.json"), JSON.stringify(IP));

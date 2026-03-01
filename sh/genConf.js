#!/usr/bin/env bun

import fs from "fs";
import reqJson from "@3-/req/reqJson.js";
import write from "@3-/write";
import { homedir } from "os";
import { join, dirname } from "path";

export default async () => {
  const HOME = homedir(),
    PWD = import.meta.dirname,
    { env } = process,
    { SSHPASS, LANG } = env;

  let conf = `
{
  nixosVersion = "${(await reqJson("https://endoflife.date/api/nixos.json"))[0].cycle}";
  sshPublicKey = "${fs.readFileSync(join(HOME, ".ssh/id_ed25519.pub"), "utf8").trim()}";
  timezone = "${new Intl.DateTimeFormat().resolvedOptions().timeZone}";
  language = "${LANG || "en_US.UTF-8"}";`;

  if (SSHPASS) {
    conf += `\nsshpwd = "${SSHPASS}";`;
  }

  write(join(dirname(PWD), "nix/vps/conf.nix"), conf + "\n}");
};

#!/usr/bin/env bun

import reqJson from "@3-/req/reqJson.js";
import fs from "fs";
import { join, dirname } from "path";
import { homedir } from "os";
import write from "@3-/write";

export default async () => {
  const HOME = homedir(),
    PWD = import.meta.dirname;

  const { env } = process,
    SSHPASS = env.SSHPASS;
  let conf = `
{
  nixosVersion = "${(await reqJson("https://endoflife.date/api/nixos.json"))[0].cycle}";
  sshPublicKey = "${fs
    .readFileSync(join(HOME, ".ssh/id_ed25519.pub"), "utf8")
    .trim()}";
  timezone = "${new Intl.DateTimeFormat().resolvedOptions().timeZone}";
  language = "${env.LANG || "en_US.UTF-8"}";`;

  if (SSHPASS) {
    conf += `\nsshpwd = "${SSHPASS}";`;
  }

  write(join(dirname(PWD), "nix/vps/conf.nix"), conf + "\n}");
};

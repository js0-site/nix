#!/usr/bin/env bun

import "zx/globals";
import genConf from "./sh/genConf.js";
import inquirer from "inquirer";
import mktmp from "@3-/mktmp";
import read from "@3-/read";
import write from "@3-/write";
import yargs from "yargs";
import { exit } from "process";
import { hideBin } from "yargs/helpers";
import { join } from "node:path";
import { rm, cp } from "node:fs/promises";

$.verbose = true;

const { dirname: ROOT, filename: $0 } = import.meta,
  argv = await yargs(hideBin(process.argv))
    .scriptName($0)
    .usage("用法: SSHPASS=密码 $0 <IP/主机名> [IP/主机名...] [--yes]")
    .option("yes", {
      alias: "y",
      type: "boolean",
      description: "跳过确认提示",
    })
    .demandCommand(1, "请至少提供一个IP/主机名")
    .help()
    .parse(),
  IP_LI = argv._,
  YES = argv.yes,
  { SSHPASS } = process.env,
  DIR_NIX = join(ROOT, "nix"),
  DIR_SH = join(ROOT, "sh"),
  DIR_VPS = join(DIR_NIX, "vps"),
  FLAKE = read(join(ROOT, "flake.nix"));

if (IP_LI.length === 0) {
  yargs.showHelp();
  exit();
}

await $`${join(DIR_SH, "init_git.sh")}`;

await genConf();

const setup = async (ip, hostname) => {
  const vps = "root@" + ip;

  if (SSHPASS) {
    await $`ssh-keygen -R ${ip} >/dev/null || true`;
    await $`sshpass -e ssh-copy-id -i ~/.ssh/id_ed25519.pub -o StrictHostKeyChecking=accept-new ${vps}`;
  }

  // 获取操作系统元信息
  const p = $`ssh -o ConnectTimeout=10 -o BatchMode=yes -q ${vps} bash -s ${ip}`;
  p.stdin.write(read(join(DIR_SH, "vpsMeta.sh")));
  p.stdin.end();
  const result = await p;

  if (result.exitCode) {
    console.error(result.stdout + "\n" + result.stderr);
    exit(1);
  }
  const li = result.stdout.trim().split("\n"),
    os = li
      .pop()
      .toLocaleLowerCase()
      .replace("\\l", "")
      .replace("\\n", "")
      .trim();
  if (os.includes("nixos")) {
    console.log(`⚠️ ${hostname} ${ip} 已经是 NixOS 了 ！( 无法安装 )`);
    return;
  }
  const tip = `主机: ${hostname}\nIP: ${ip}\n系统: ${os}`;
  if (YES) {
    console.log(`\n${tip}\n开始重装…\n`);
  } else {
    const { yes } = await inquirer.prompt([
      {
        type: "confirm",
        name: "yes",
        message:
          "⚠️ 警告:\n" +
          tip +
          " \n重装系统 NixOs 将清空硬盘，请确认主机是否正确！",
        default: false,
      },
    ]);
    if (!yes) {
      exit(1);
    }
  }
  write(
    join(DIR_VPS, "conf", hostname + ".nix"),
    `{
  hostname = "${hostname}";
  ${li.join("\n  ")}
}`,
  );
  await $`cd ${DIR_VPS} && git add . && git commit -m'${hostname}' && git pull && git push || true`;

  const temp = mktmp("nixos-anywhere-");
  try {
    await nixosAnywhere(ip, hostname, temp);
  } finally {
    await rm(temp, { recursive: true });
  }
};

const nixosAnywhere = async (ip, hostname, temp) => {
  write(
    join(temp, "flake.nix"),
    FLAKE.replace("/dev/null", `./nix/vps/conf/${hostname}.nix`),
  );
  await cp(DIR_NIX, join(temp, "nix"), { recursive: true });
  cd(temp);
  await $`nix --extra-experimental-features 'nix-command flakes' run github:nix-community/nixos-anywhere -- -i ~/.ssh/id_ed25519 --flake 'path:.#I' root@${ip}`;
};

const IP_HOSTNAME = JSON.parse(read(join(DIR_VPS, "host.json")));

for (const ip of IP_LI) {
  const hostname = IP_HOSTNAME[ip];
  if (!hostname) {
    console.error(`未找到主机名: ${ip}`);
    exit(1);
  }
  await setup(ip, hostname);
}

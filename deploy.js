#!/usr/bin/env bun

import "zx/globals";
import { hideBin } from "yargs/helpers";
import { join } from "node:path";
import { exit } from "process";
import inquirer from "inquirer";
import read from "@3-/read";
import yargs from "yargs";

$.verbose = true;

const { dirname: ROOT, filename: $0 } = import.meta,
  argv = await yargs(hideBin(process.argv))
    .scriptName($0)
    .usage("用法: $0 [IP/主机名...]")
    .option("yes", {
      alias: "y",
      type: "boolean",
      description: "跳过确认提示",
    })
    .help()
    .parse(),
  TARGETS = argv._,
  DIR_SH = join(ROOT, "sh"),
  DIR_VPS = join(ROOT, "nix", "vps"),
  YES = argv.yes,
  HOSTS_MAP = JSON.parse(read(join(DIR_VPS, "host.json"))),
  HOSTS_BY_HOSTNAME = Object.fromEntries(
    Object.entries(HOSTS_MAP).map(([ip, hostname]) => [hostname, ip]),
  );

await $`${join(DIR_SH, "init_git.sh")}`;
await $`git pull`;

let target_ips = [];
if (TARGETS.length > 0) {
  for (const host_or_ip of TARGETS) {
    if (HOSTS_MAP[host_or_ip]) {
      target_ips.push(host_or_ip);
    } else if (HOSTS_BY_HOSTNAME[host_or_ip]) {
      target_ips.push(HOSTS_BY_HOSTNAME[host_or_ip]);
    } else {
      console.error(`错误: 在 host.json 中未找到主机或IP: ${host_or_ip}`);
      exit(1);
    }
  }
} else {
  target_ips = Object.keys(HOSTS_MAP);
  const targets_str = target_ips
    .map((ip) => `${HOSTS_MAP[ip]} (${ip})`)
    .join("\n");
  if (!YES) {
    const { confirmed } = await inquirer.prompt([
      {
        type: "confirm",
        name: "confirmed",
        message: `将部署到以下所有主机:\n${targets_str}\n确定要继续吗?`,
        default: false,
      },
    ]);
    if (!confirmed) {
      console.log("操作已取消.");
      exit(0);
    }
  }
}

const deploy = async (ip) => {
  const host_name = HOSTS_MAP[ip];
  if (!host_name) {
    console.error(`错误: IP ${ip} 找不到对应的主机名.`);
    return;
  }
  console.log(`\n🚀 开始部署到 ${host_name} (${ip})...`);
  await $`nixos-rebuild switch --target-host root@${ip} --override-input I path:./nix/vps/conf/${host_name}.nix --flake path:.#I`;
  console.log(`✅ 成功部署到 ${host_name} (${ip})`);
};

for (const ip of target_ips) {
  await deploy(ip);
}

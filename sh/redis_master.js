#!/usr/bin/env bun

import Redis from "@3-/ioredis";
import int from "@3-/int";

const { R_NODE, R_SENTINEL_NAME, R_PASSWORD, R_SENTINEL_PASSWORD } =
    process.env,
  redis = Redis({
    sentinels: R_NODE.split(" ").map((i) => {
      const [host, port] = i.split(":");
      return { host, port: int(port) };
    }),
    password: R_PASSWORD,
    sentinelPassword: R_SENTINEL_PASSWORD,
    name: R_SENTINEL_NAME,
    role: "slave",
  }),
  INFO = new Map(
    (await redis.info("replication"))
      .trimEnd()
      .split("\n")
      .slice(1)
      .map((i) => i.trim().split(":")),
  ),
  get = INFO.get.bind(INFO);

console.log(`redis-cli -h ${get("master_host")} -p ${get("master_port")}`);

process.exit();

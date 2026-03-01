#!/usr/bin/env bun

import { RedisClient } from "bun";
import { readFileSync, writeFileSync } from "node:fs";
import { networkInterfaces } from "node:os";

const conf = async (name, redis) => {
  for (let line of (await redis.send("INFO", ["sentinel"])).split("\n")) {
    if (line.startsWith("master")) {
      const conf = new Map(
        line
          .slice(line.indexOf(":") + 1)
          .trimEnd()
          .split(",")
          .map((i) => i.split("=")),
      );
      if (conf.get("name") == name) {
        const address = conf.get("address");
        if (address) {
          const kvrocks_conf = "/etc/kvrocks/kvrocks.conf",
            replicaof = "replicaof ",
            conf_li = readFileSync(kvrocks_conf, "utf8")
              .trim()
              .split("\n")
              .filter((i) => !(i.startsWith("slaveof ") || i.startsWith(replicaof)));

          let is_slave = 1;
          for (const i of networkInterfaces().eth0) {
            if (address.startsWith(i.address + ":")) {
              is_slave = 0;
              break;
            }
          }
          let info;
          if (is_slave) {
            info = replicaof + address.replace(":", " ");
            conf_li.push(info);
          } else {
            info = "master";
          }
          writeFileSync(kvrocks_conf, conf_li.join("\n") + "\n");
          console.log("✅ " + name + " → " + info);
        }
        return;
      }
    }
  }
};

await (async () => {
  const { R_SENTINEL_PASSWORD, R_SENTINEL_NAME, R_NODE } = process.env;
  for (const node of R_NODE.split(" ")) {
    const redis = new RedisClient("redis://:" + R_SENTINEL_PASSWORD + "@" + node);
    try {
      await redis.connect();
      await conf(R_SENTINEL_NAME, redis);
      return;
    } catch (e) {
      console.error(node, e);
    } finally {
      redis.close();
    }
  }
})();

process.exit();

#!/usr/bin/env bun

import { InstancesClient } from "@google-cloud/compute";
import read from "@3-/read";
import { join } from "path";

export default async (SSH_CONFIG, IP) => {
  const creds = JSON.parse(read(join(import.meta.dirname, "../../../conf/gen/conf/gcloud.json"))),
    client = new InstancesClient({
      credentials: creds,
      projectId: creds.project_id,
    }),
    project = creds.project_id;

  for await (const [scope, entry] of client.aggregatedListAsync({ project })) {
    for (const vm of entry.instances) {
      if (vm.status !== "RUNNING") continue;
      const ni = vm.networkInterfaces?.[0] || {};
      const ipnat = ni.accessConfigs?.[0]?.natIP || "";
      SSH_CONFIG.push([vm.name, ipnat]);
      IP[vm.name] = {
        v4: ipnat,
      };
    }
  }
};

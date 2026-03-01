import hwdns from "@3-/hwdns";
import { join } from "node:path";
import read from "@3-/read";
import HW_CONF from "../../../conf/nix/HW.js";
import _HOST from "../../../conf/nix/host.js";
// import CF_CONF from "../../conf/nix/cf.js";
// import Cf from "@3-/cf";
// import Zone from "@3-/cf/Zone.js";
// DNS = await Zone(Cf(...CF_CONF), HOST),

export const HOST = _HOST,
  DNS = hwdns(...HW_CONF),
  ROOT = import.meta.dirname,
  DIR_VPS = join(ROOT, "../../nix/vps"),
  loadJson = (name) => JSON.parse(read(join(DIR_VPS, name + ".json"))),
  CACHE = new Map(),
  hostDns = async (domain) => {
    const r = CACHE.get(domain);
    if (r) return r;
    const dns = await DNS(domain);
    CACHE.set(domain, dns);
    return dns;
  };

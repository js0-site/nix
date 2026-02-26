import { hostDns, HOST, loadJson } from "./CONST.js";

export default async () => {
  const A = [],
    AAAA = [],
    TO_SET = { A, AAAA },
    HOST_IP = loadJson("ip"),
    ING = [],
    MX = [],
    SPF = [], // SPF ip4/ip6 列表
    DNS = await hostDns(HOST);

  loadJson("enable")
    .smtp.toSorted()
    .forEach((name, pos) => {
      const { v4, v6 } = HOST_IP[name],
        to_set = {},
        mx = "mx" + ++pos;

      if (v4) {
        A.push(v4);
        to_set.A = [v4];
        SPF.push("ip4:" + v4);
      }
      if (v6) {
        AAAA.push(v6);
        to_set.AAAA = [v6];
        SPF.push("ip6:" + v6);
      }

      ING.push(DNS.reset(mx, to_set));
      MX.push(pos * 5 + " " + mx + "." + HOST);
    });

  await DNS.reset("smtp", TO_SET);
  await Promise.all(ING);
  await DNS.reset("", { MX });
  await DNS.reset("_spf", { TXT: ["v=spf1 " + SPF.join(" ") + " ~all"] });
};

{
  config,
  pkgs,
  lib,
  ...
}: {
  systemd.services.ipv6_proxy = {
    description = "IPv6 Proxy Service";
    after = ["network.target"];
    wantedBy = ["multi-user.target"];

    unitConfig = {
      ConditionPathExists = [
        "/etc/ipv6_proxy.env"
        "/opt/bin/ipv6_proxy"
      ];
    };

    serviceConfig = {
      Type = "simple";
      User = "root";
      Group = "root";
      Restart = "on-failure";
      RestartSec = "5s";
    };

    script = ''
      set -a
      source /etc/ipv6_proxy.env
      RUST_LOG=debug
      set +a
      exec /opt/bin/ipv6_proxy -b 0.0.0.0:$IPV6_PROXY_PORT -i $(${pkgs.iproute2}/bin/ip -6 addr show dev eth0 | ${pkgs.gawk}/bin/awk '/inet6.*scope global/ {print $2}')
    '';
  };
}

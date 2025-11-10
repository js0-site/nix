{
  config,
  lib,
  pkgs,
  vps,
  hosts,
  ...
}: {
  networking.useDHCP = false;

  networking.extraHosts = lib.concatStringsSep "\n" (lib.mapAttrsToList (ip: name: "${ip} ${name}") hosts);

  networking.interfaces.${vps.interface} = {
    useDHCP = false;
    ipv4.addresses = [
      {
        address = builtins.elemAt (lib.strings.splitString "/" vps.ip.v4.addr) 0;
        prefixLength = builtins.fromJSON (builtins.elemAt (lib.strings.splitString "/" vps.ip.v4.addr) 1);
      }
    ];
    ipv6.addresses = lib.mkIf (vps.ip.v6.addr != "false") [
      {
        address = builtins.elemAt (lib.strings.splitString "/" vps.ip.v6.addr) 0;
        prefixLength = builtins.fromJSON (builtins.elemAt (lib.strings.splitString "/" vps.ip.v6.addr) 1);
      }
    ];
  };

  networking.defaultGateway = lib.mkIf (vps.ip.v4.gateway != "false") vps.ip.v4.gateway;
  networking.defaultGateway6 = lib.mkIf (vps.ip.v6.gateway != "false") {
    address = vps.ip.v6.gateway;
    interface = vps.interface;
  };

  # Add local route for IPv6 subnet to allow using any IP in the range
  systemd.services.ipv6-local-route = lib.mkIf (vps.ip.v6.addr != "false") (let
    ipv6Addr = vps.ip.v6.addr;
    iface = vps.interface;
  in {
    description = "Add IPv6 local route for subnet";
    after = ["network.target" "network-addresses-${iface}.service"];
    wants = ["network.target"];
    wantedBy = ["multi-user.target"];
    script = ''
      set -e
      # Delete existing route if present
      ${pkgs.iproute2}/bin/ip -6 route del local ${ipv6Addr} dev ${iface} 2>/dev/null || true
      # Add the local route
      ${pkgs.iproute2}/bin/ip -6 route add local ${ipv6Addr} dev ${iface}
    '';
    serviceConfig = {
      Type = "oneshot";
      RemainAfterExit = true;
    };
  });

  # Enable IPv6
  networking.enableIPv6 = true;

  # DNS configuration - Google and Cloudflare
  networking.nameservers = [
    "8.8.8.8" # Google DNS IPv4
    "8.8.4.4" # Google DNS IPv4 secondary
    "1.1.1.1" # Cloudflare DNS IPv4
    "1.0.0.1" # Cloudflare DNS IPv4 secondary
    "2001:4860:4860::8888" # Google DNS IPv6
    "2001:4860:4860::8844" # Google DNS IPv6 secondary
    "2606:4700:4700::1111" # Cloudflare DNS IPv6
    "2606:4700:4700::1001" # Cloudflare DNS IPv6 secondary
  ];
}

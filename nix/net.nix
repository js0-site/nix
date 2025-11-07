{
  config,
  lib,
  pkgs,
  vps,
  hosts,
  ...
}: {
  networking.useDHCP = false;

  networking.extraHosts = lib.concatStringsSep "\n" (lib.mapAttrsToList (name: ip: "${ip} ${name}") hosts);

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
  networking.defaultGateway6 = lib.mkIf (vps.ip.v6.gateway != "false") (
    if lib.strings.hasPrefix "fe80::" vps.ip.v6.gateway
    then {
      address = vps.ip.v6.gateway;
      interface = vps.interface;
    }
    else vps.ip.v6.gateway
  );

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

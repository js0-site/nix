{
  config,
  lib,
  pkgs,
  vps,
  hosts,
  ...
}: let
  # Native IPv6 configuration / 原生 IPv6 配置
  ipv6 = if (vps.ip ? "v6") then vps.ip.v6 else null;

  # HE tunnel auto-detection / HE 隧道自动检测
  ipv4Addr = if (vps.ip != 0) then builtins.elemAt (lib.strings.splitString "/" vps.ip.v4.addr) 0 else null;
  heConfigPath = ../vps/he_ipv6 + "/${ipv4Addr}.json";
  heConfig = 
    if ipv4Addr != null && builtins.pathExists heConfigPath
    then builtins.fromJSON (builtins.readFile heConfigPath)
    else null;
  
  # Use HE tunnel when native IPv6 unavailable / 无原生 IPv6 时使用 HE 隧道
  useHeTunnel = ipv6 == null && heConfig != null;
  hasIpv6 = ipv6 != null || useHeTunnel;
in {
  networking.useDHCP = vps.ip == 0;
  boot.kernelModules = [
    "tls"
  ];

  networking.extraHosts = lib.concatStringsSep "\n" (lib.mapAttrsToList (ip: name: "${ip} ${name}") hosts);

  # HE IPv6 tunnel (SIT) / HE IPv6 隧道
  networking.sits.he-ipv6 = lib.mkIf useHeTunnel {
    remote = heConfig.remote;
    local = ipv4Addr;
    dev = vps.interface;
  };

  networking.interfaces.${vps.interface} = lib.mkIf (vps.ip != 0) {
    ipv4.addresses = [
      {
        address = builtins.elemAt (lib.strings.splitString "/" vps.ip.v4.addr) 0;
        prefixLength = builtins.fromJSON (builtins.elemAt (lib.strings.splitString "/" vps.ip.v4.addr) 1);
      }
    ];
    ipv6.addresses = lib.mkIf (ipv6 != null) [
      {
        address = ipv6.addr;
        prefixLength = builtins.fromJSON (builtins.elemAt (lib.strings.splitString "/" ipv6.segment) 1);
      }
    ];
  };

  # HE tunnel IPv6 address / HE 隧道地址
  networking.interfaces.he-ipv6 = lib.mkIf useHeTunnel {
    ipv6.addresses = [{
      address = heConfig.ipv6_address;
      prefixLength = heConfig.prefix_len;
    }
    ];
  };

  networking.defaultGateway = lib.mkIf (vps.ip != 0 && vps.ip.v4.gateway != "false") vps.ip.v4.gateway;

  # IPv6 gateway / IPv6 网关
  networking.defaultGateway6 = 
    if ipv6 != null then {
      address = ipv6.gateway;
      interface = vps.interface;
    }
    else if useHeTunnel then {
      address = heConfig.gateway;
      interface = "he-ipv6";
    }
    else null;

  # Local route for native IPv6 subnet / 原生 IPv6 子网本地路由
  systemd.services.ipv6-local-route = lib.mkIf (ipv6 != null) {
    description = "Add IPv6 local route for subnet";
    after = ["network.target" "network-addresses-${vps.interface}.service"];
    wants = ["network.target"];
    wantedBy = ["multi-user.target"];
    script = ''
      set -e
      ${pkgs.iproute2}/bin/ip -6 route del local ${ipv6.segment} dev ${vps.interface} 2>/dev/null || true
      ${pkgs.iproute2}/bin/ip -6 route add local ${ipv6.segment} dev ${vps.interface}
    '';
    serviceConfig = {
      Type = "oneshot";
      RemainAfterExit = true;
    };
  };

  networking.enableIPv6 = hasIpv6;

  # Prioritize IPv4 over IPv6 / IPv4 优先
  environment.etc."gai.conf".text = lib.mkIf hasIpv6 ''
    precedence ::ffff:0:0/96  100
  '';

  # DNS servers (IPv4 + IPv6 when available) / DNS 服务器
  networking.nameservers = [
    "8.8.8.8" "8.8.4.4"     # Google IPv4
    "1.1.1.1" "1.0.0.1"     # Cloudflare IPv4
  ] ++ lib.optionals hasIpv6 [
    "2001:4860:4860::8888" "2001:4860:4860::8844"  # Google IPv6
    "2606:4700:4700::1111" "2606:4700:4700::1001"  # Cloudflare IPv6
  ];

  # Firewall / 防火墙
  networking.firewall = {
    enable = true;
    allowedUDPPorts = [
      443 # HTTP3
    ];
    allowedTCPPorts = [
      22 # SSH
      80 # HTTP
      443 # HTTPS
    ];
  };
}

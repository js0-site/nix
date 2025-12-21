# Network configuration for VPS / VPS 网络配置
#
# ip=0: Use DHCP for dynamic IP allocation (required for Google Cloud VPS)
# ip=0: 使用 DHCP 动态分配 IP（谷歌云 VPS 必须使用）
{
  config,
  lib,
  pkgs,
  vps,
  hosts,
  ...
}: let
  # Helper: parse CIDR address / 解析 CIDR 地址
  parseAddr = cidr: builtins.elemAt (lib.strings.splitString "/" cidr) 0;
  parsePrefix = cidr: builtins.fromJSON (builtins.elemAt (lib.strings.splitString "/" cidr) 1);

  # Native IPv6 configuration / 原生 IPv6 配置
  ipv6 =
    if (vps.ip ? "v6")
    then vps.ip.v6
    else null;

  # HE tunnel auto-detection (by hostname) / HE 隧道自动检测（按主机名）
  hePath = ./vps/he_ipv6 + ("/" + vps.hostname + ".json");
  he =
    if builtins.pathExists hePath
    then builtins.fromJSON (builtins.readFile hePath)
    else null;

  # Use HE tunnel when native IPv6 unavailable / 无原生 IPv6 时使用 HE 隧道
  useHeTunnel = ipv6 == null && he != null;
  hasIpv6 = ipv6 != null || useHeTunnel;
in
  lib.mkMerge [
    {
      warnings = [
        (vps.hostname
          + " "
          + (
            if useHeTunnel
            then "🌐 HE IPv6 Tunnel ${he.v6} / HE IPv6 隧道 ${he.v6}"
            else if ipv6 != null
            then "✅ Native IPv6 ${ipv6.addr} / 原生 IPv6 ${ipv6.addr}"
            else "ℹ️ No IPv6 / 没有 IPv6"
          ))
      ];

      networking.useDHCP = vps.ip == 0;
      boot.kernelModules = ["tls"];

      # Network performance optimization / 网络性能优化
      boot.kernel.sysctl = {
        # TCP connection optimization / TCP 连接优化
        "net.ipv4.tcp_syn_retries" = 6; # SYN 重试次数
        "net.ipv4.tcp_synack_retries" = 5; # SYN-ACK 重试次数
        "net.ipv4.tcp_retries1" = 3; # 第一阶段重试次数
        "net.ipv4.tcp_retries2" = 8; # 第二阶段重试次数
        "net.ipv4.tcp_orphan_retries" = 1; # 孤儿连接重试次数 (1-2 次较合理)
        "net.ipv4.tcp_fin_timeout" = 15; # FIN 超时时间 (秒)

        # TCP keepalive optimization / TCP keepalive 优化
        "net.ipv4.tcp_keepalive_time" = 600; # keepalive 探测间隔
        "net.ipv4.tcp_keepalive_intvl" = 30; # keepalive 重试间隔
        "net.ipv4.tcp_keepalive_probes" = 3; # keepalive 探测次数

        # TCP performance tuning / TCP 性能调优
        "net.ipv4.tcp_congestion_control" = "bbr"; # 使用 BBR 拥塞控制
        "net.ipv4.tcp_fastopen" = 3; # 启用 TCP Fast Open
        "net.ipv4.tcp_window_scaling" = 1; # 启用窗口缩放
        "net.ipv4.tcp_timestamps" = 1; # 启用时间戳
        "net.ipv4.tcp_sack" = 1; # 启用选择性确认
        "net.ipv4.tcp_fack" = 1; # 启用前向确认
        "net.ipv4.tcp_no_metrics_save" = 1; # 不保存连接指标
        "net.ipv4.tcp_moderate_rcvbuf" = 1; # 自动调整接收缓冲区

        # Network buffer optimization for 12GB RAM / 12GB 内存网络缓冲区优化
        "net.core.rmem_default" = 262144; # 默认接收缓冲区 256KB
        "net.core.rmem_max" = 33554432; # 最大接收缓冲区 32MB (12GB RAM)
        "net.core.wmem_default" = 262144; # 默认发送缓冲区 256KB
        "net.core.wmem_max" = 33554432; # 最大发送缓冲区 32MB (12GB RAM)
        "net.ipv4.tcp_rmem" = "4096 131072 33554432"; # TCP 接收缓冲区 (32MB max)
        "net.ipv4.tcp_wmem" = "4096 131072 33554432"; # TCP 发送缓冲区 (32MB max)
        "net.ipv4.udp_rmem_min" = 8192; # UDP 最小接收缓冲区
        "net.ipv4.udp_wmem_min" = 8192; # UDP 最小发送缓冲区

        # Connection limits for high-performance server / 高性能服务器连接限制
        "net.core.somaxconn" = 65536; # 监听队列最大长度 (提升到 64K)
        "net.ipv4.tcp_max_syn_backlog" = 16384; # SYN 队列最大长度 (提升到 16K)
        "net.core.netdev_max_backlog" = 10000; # 网卡队列最大长度 (提升到 10K)
        "net.ipv4.tcp_max_orphans" = 262144; # 最大孤儿连接数 (256K)
        "net.ipv4.tcp_max_tw_buckets" = 1440000; # TIME_WAIT 连接数限制

        # Memory and performance tuning / 内存和性能调优
        "net.ipv4.tcp_mem" = "786432 1048576 26777216"; # TCP 内存限制 (页数)
        "net.ipv4.ip_local_port_range" = "1024 65535"; # 本地端口范围
        "net.ipv4.tcp_tw_reuse" = 1; # 启用 TIME_WAIT 重用
        "net.ipv4.tcp_rfc1337" = 1; # 启用 RFC1337 TIME_WAIT 保护
        "net.ipv4.tcp_slow_start_after_idle" = 0; # 禁用空闲后慢启动

        # File descriptor limits / 文件描述符限制
        "fs.file-max" = 2097152; # 系统最大文件描述符 (2M)
        "fs.nr_open" = 2097152; # 进程最大文件描述符 (2M)

        # IPv6 optimization / IPv6 优化
        "net.ipv6.conf.all.use_tempaddr" = lib.mkForce 0; # 禁用临时地址
        "net.ipv6.conf.default.use_tempaddr" = lib.mkForce 0; # 禁用临时地址
        "net.ipv6.conf.all.accept_ra" = 1; # 接受路由通告
        "net.ipv6.conf.default.accept_ra" = 1; # 接受路由通告
      };

      networking.extraHosts = lib.concatStringsSep "\n" (lib.mapAttrsToList (ip: name: "${ip} ${name}") hosts);

      networking.interfaces.${vps.interface}.ipv4.addresses = lib.mkIf (vps.ip != 0) [
        {
          address = parseAddr vps.ip.v4.addr;
          prefixLength = parsePrefix vps.ip.v4.addr;
        }
      ];

      networking.defaultGateway = lib.mkIf (vps.ip != 0 && vps.ip.v4.gateway != "false") vps.ip.v4.gateway;

      networking.nameservers =
        [
          "8.8.8.8" # Google IPv4
          "8.8.4.4"
          "1.1.1.1" # Cloudflare IPv4
          "1.0.0.1"
        ]
        ++ lib.optionals hasIpv6 [
          "2001:4860:4860::8888" # Google IPv6
          "2001:4860:4860::8844"
          "2606:4700:4700::1111" # Cloudflare IPv6
          "2606:4700:4700::1001"
        ];

      networking.firewall = {
        enable = true;
        allowedUDPPorts = [443];
        allowedTCPPorts = [22 80 443];
      };
    }

    (lib.optionalAttrs (he != null) {
      etc."gai.conf".text = ''
        label  ::1/128       0
        label  ::/0          1
        label  2002::/16     2
        label  ::/96         3
        label  ::ffff:0:0/96 4
        precedence  ::1/128       50
        precedence  ::/0          40
        precedence  ::ffff:0:0/96 100
      '';
    })

    (lib.optionalAttrs hasIpv6 {
      networking.enableIPv6 = true;

      # HE IPv6 tunnel / HE IPv6 隧道
      networking.sits.he-ipv6 = lib.mkIf useHeTunnel {
        remote = he.remote;
        local = he.v4;
        dev = vps.interface;
      };

      networking.interfaces.he-ipv6 = lib.mkIf useHeTunnel {
        ipv6.addresses = [
          {
            address = he.v6;
            prefixLength = he.prefix_len;
          }
        ];
      };

      # Native IPv6 / 原生 IPv6
      networking.interfaces.${vps.interface}.ipv6.addresses = lib.mkIf (ipv6 != null) [
        {
          address = ipv6.addr;
          prefixLength = parsePrefix ipv6.segment;
        }
      ];

      networking.defaultGateway6 =
        if ipv6 != null
        then {
          address = ipv6.gateway;
          interface = vps.interface;
        }
        else {
          address = he.gateway;
          interface = "he-ipv6";
        };

      # 让 ipv6 支持网段
      systemd.services.ipv6-local-route = lib.mkIf (ipv6 != null) {
        description = "Add IPv6 local route for subnet";
        after = ["network.target" "network-addresses-${vps.interface}.service"];
        wants = ["network.target"];
        wantedBy = ["multi-user.target"];
        script = ''
          ${pkgs.iproute2}/bin/ip -6 route del local ${ipv6.segment} dev ${vps.interface} 2>/dev/null || true
          ${pkgs.iproute2}/bin/ip -6 route add local ${ipv6.segment} dev ${vps.interface}
        '';
        serviceConfig = {
          Type = "oneshot";
          RemainAfterExit = true;
        };
      };
    })
  ]

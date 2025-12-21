{
  config,
  pkgs,
  lib,
  ...
}: let
  etc_conf = {
    "reconf.sh" = "0755";
    "reconf.js" = "0644";
  };
in {
  networking.firewall.allowedTCPPorts = [2010];

  environment.etc = lib.mapAttrs' (name: mode:
    lib.nameValuePair "kvrocks/${name}" {
      source = ./kvrocks/${name};
      inherit mode;
      user = "kvrocks";
      group = "kvrocks";
    })
  etc_conf;

  users.users.kvrocks = {
    isSystemUser = true;
    group = "kvrocks";
    description = "kvrocks service user";
  };

  users.groups.kvrocks = {};

  systemd.tmpfiles.rules = [
    "d /var/lib/kvrocks 0750 kvrocks kvrocks -"
    "d /var/run/kvrocks 0750 kvrocks kvrocks -"
    "d /etc/kvrocks 0750 kvrocks kvrocks -"
  ];

  systemd.services.kvrocks = {
    description = "kvrocks";
    after = ["network.target"];
    wantedBy = ["multi-user.target"];

    unitConfig = {
      ConditionPathExists = [
        "/etc/kvrocks/kvrocks.conf"
        "/opt/bin/kvrocks"
      ];
      # 重启次数限制：1分钟内最多重启3次
      StartLimitBurst = 3;
      StartLimitIntervalSec = 60;
    };

    serviceConfig = {
      Type = "simple";
      User = "kvrocks";
      Group = "kvrocks";
      Restart = "on-failure";
      RestartSec = "1s";

      ReadWritePaths = [
        "/var/lib/kvrocks"
        "/var/run/kvrocks"
        "/etc/kvrocks"
      ];

      NoNewPrivileges = true;
      PrivateTmp = true;
      ProtectSystem = "strict";
      ProtectHome = true;

      ExecStart = "${pkgs.bash}/bin/bash -c 'set -ex && export PATH=/run/current-system/sw/bin && /etc/kvrocks/reconf.sh && exec /opt/bin/kvrocks -c /etc/kvrocks/kvrocks.conf'";
    };
  };
}

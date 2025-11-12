{
  config,
  pkgs,
  lib,
  ...
}: {
  users.users.kvrocks = {
    isSystemUser = true;
    group = "kvrocks";
    description = "kvrocks service user";
  };

  users.groups.kvrocks = {};

  systemd.tmpfiles.rules = [
    "d /var/lib/kvrocks 0750 kvrocks kvrocks -"
    "d /var/log/kvrocks 0750 kvrocks kvrocks -"
    "d /var/run/kvrocks 0750 kvrocks kvrocks -"
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
    };

    serviceConfig = let
      pidFile = "/var/run/kvrocks/kvrocks.pid";
    in {
      Type = "forking";
      User = "kvrocks";
      Group = "kvrocks";
      PIDFile = pidFile;
      Restart = "on-failure";
      RestartSec = "1s";

      # 重启次数限制：1分钟内最多重启3次
      StartLimitBurst = 3;
      StartLimitIntervalSec = 60;

      ReadWritePaths = [
        "/var/lib/kvrocks"
        "/var/log/kvrocks"
        "/var/run/kvrocks"
      ];

      NoNewPrivileges = true;
      PrivateTmp = true;
      ProtectSystem = "strict";
      ProtectHome = true;
    };

    script = let
      pidFile = "/var/run/kvrocks/kvrocks.pid";
    in ''
      exec kvrocks -c /etc/kvrocks/kvrocks.conf --pidfile ${pidFile}
    '';
  };
}

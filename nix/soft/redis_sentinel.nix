{
  config,
  pkgs,
  lib,
  ...
}: {
  users.users.redis_sentinel = {
    isSystemUser = true;
    group = "redis_sentinel";
    description = "redis sentinel";
  };

  users.groups.redis_sentinel = {};

  systemd.tmpfiles.rules = [
    "d /var/log/redis_sentinel 0750 redis_sentinel redis_sentinel -"
    "d /var/run/redis_sentinel 0750 redis_sentinel redis_sentinel -"
  ];

  systemd.services.redis_sentinel = {
    description = "redis_sentinel";
    after = ["network.target"];
    wantedBy = ["multi-user.target"];

    unitConfig = {
      ConditionPathExists = [
        "/etc/redis_sentinel.conf"
        "/opt/bin/redis_sentinel"
      ];
    };

    serviceConfig = {
      Type = "simple";
      User = "redis_sentinel";
      Group = "redis_sentinel";
      Restart = "on-failure";
      RestartSec = "1s";

      # 重启次数限制：1分钟内最多重启3次
      StartLimitBurst = 3;
      StartLimitIntervalSec = 60;

      ReadWritePaths = [
        "/etc/redis_sentinel.conf"
        "/var/log/redis_sentinel"
        "/var/run/redis_sentinel"
      ];

      NoNewPrivileges = true;
      PrivateTmp = true;
      ProtectHome = true;
      ProtectSystem = "strict";
    };

    script = ''
      exec redis-sentinel /etc/redis_sentinel.conf
    '';
  };
}

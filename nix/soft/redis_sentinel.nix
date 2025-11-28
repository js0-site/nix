{
  config,
  pkgs,
  lib,
  ...
}: {
  networking.firewall.allowedTCPPorts = [2011];

  users.users.redis_sentinel = {
    isSystemUser = true;
    group = "redis_sentinel";
    description = "redis sentinel";
  };

  users.groups.redis_sentinel = {};

  systemd.tmpfiles.rules = [
    "d /var/log/redis_sentinel 0750 redis_sentinel redis_sentinel -"
    "d /var/run/redis_sentinel 0750 redis_sentinel redis_sentinel -"
    "d /etc/redis_sentinel 0750 redis_sentinel redis_sentinel -"
  ];

  systemd.services.redis_sentinel = {
    description = "redis_sentinel";
    after = ["network.target"];
    wantedBy = ["multi-user.target"];

    unitConfig = {
      ConditionPathExists = [
        "/etc/redis_sentinel/conf"
        "/opt/bin/redis-sentinel"
      ];
      # 重启次数限制：10秒最多重启3次
      StartLimitBurst = 3;
      StartLimitIntervalSec = 10;
    };

    serviceConfig = {
      Type = "simple";
      User = "redis_sentinel";
      Group = "redis_sentinel";
      Restart = "on-failure";
      RestartSec = "1s";

      ReadWritePaths = [
        "/etc/redis_sentinel"
        "/var/log/redis_sentinel"
        "/var/run/redis_sentinel"
      ];

      NoNewPrivileges = true;
      PrivateTmp = true;
      ProtectHome = true;
      ProtectSystem = "strict";

      ExecStartPre = [
        "+${pkgs.coreutils}/bin/chown -R redis_sentinel /etc/redis_sentinel"
      ];
    };

    script = ''
      exec /opt/bin/redis-sentinel /etc/redis_sentinel/conf
    '';
  };
}

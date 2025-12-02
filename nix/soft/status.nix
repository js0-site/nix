{
  config,
  pkgs,
  lib,
  ...
}: {
  users.users.status = {
    isSystemUser = true;
    group = "status";
    description = "status service user";
  };

  users.groups.status = {};

  systemd.services.status = {
    description = "status";
    after = ["network.target"];
    wantedBy = ["multi-user.target"];

    unitConfig = {
      ConditionPathExists = [
        "/opt/status/src/main.js"
      ];
      StartLimitBurst = 3;
      StartLimitIntervalSec = 60;
    };

    serviceConfig = {
      Type = "simple";
      User = "status";
      Group = "status";
      Restart = "on-failure";
      RestartSec = "1s";

      ReadWritePaths = [
        "/opt/status"
      ];

      NoNewPrivileges = true;
      PrivateTmp = true;
      ProtectSystem = "strict";
      ProtectHome = true;
      WorkingDirectory = "/opt/status";
      ExecStart = "${pkgs.bash}/bin/bash -c 'set -ex && export PATH=/run/current-system/sw/bin && ./src/main.js'";
    };
  };
}

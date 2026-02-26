{
  config,
  pkgs,
  lib,
  ...
}: {
  networking.firewall.allowedTCPPorts = [25 465];

  users.users.smtp = {
    isSystemUser = true;
    group = "smtp";
    home = "/var/lib/smtp";
    createHome = true;
  };

  users.groups.smtp = {};

  systemd.tmpfiles.rules = [
    "d /var/lib/smtp 0750 smtp smtp -"
    "d /etc/smtp 0755 smtp smtp -"
    "z /etc/smtp/dkim.env 0640 smtp smtp -"
    "z /etc/smtp/smtp.env 0640 smtp smtp -"
    "z /etc/kvrocks 0755 - - -"
    "z /etc/kvrocks/conf.sh 0755 - - -"
    "d /opt/bin 0755 - - -"
    "z /opt/bin/smtp_srv 0755 smtp smtp -"
  ];

  systemd.sockets.smtp = {
    description = "SMTP Socket";
    wantedBy = ["sockets.target"];
    socketConfig = {
      ListenStream = [465 25];
      Accept = "no";
      KeepAlive = true;
      KeepAliveTimeSec = 15;
      KeepAliveIntervalSec = 12;
      KeepAliveProbes = 3;
      Backlog = 2048;
      BindIPv6Only = "both";
    };
  };

  systemd.services.smtp = {
    description = "SMTP Service";
    requires = ["smtp.socket"];
    after = ["network.target" "smtp.socket"];

    unitConfig = {
      ConditionPathExists = [
        "/etc/smtp/dkim.env"
        "/etc/smtp/smtp.env"
        "/etc/kvrocks/conf.sh"
        "/opt/bin/smtp_srv"
      ];
    };

    serviceConfig = {
      Type = "notify";
      NotifyAccess = "all";
      User = "smtp";
      Group = "smtp";
      SupplementaryGroups = ["smtp"];
      ProtectSystem = false;
      Restart = "always";
      RestartSec = "5s";
      TimeoutStopSec = "60s";
      KillMode = "mixed";

      Environment = [
        "PATH=/run/current-system/sw/bin"
        "RUST_LOG=debug,rustls=warn"
      ];

      ExecStart = "${pkgs.bash}/bin/bash -c 'set -a && . /etc/smtp/dkim.env && . /etc/smtp/smtp.env && . /etc/kvrocks/conf.sh && set +a && exec /opt/bin/smtp_srv'";
      ExecReload = "${pkgs.coreutils}/bin/kill -HUP $MAINPID";
    };
  };
}

{
  config,
  pkgs,
  lib,
  ...
}: {
  networking.firewall.allowedTCPPorts = [465];

  systemd.services.smtp = {
    description = "SMTP Service";
    after = ["network.target"];
    wantedBy = ["multi-user.target"];

    unitConfig = {
      ConditionPathExists = [
        "/etc/smtp/dkim.env"
        "/opt/bin/smtp_srv"
      ];
    };

    serviceConfig = {
      Type = "simple";
      User = "root";
      Group = "root";
      Restart = "on-failure";
      RestartSec = "5s";

      ExecStart = "${pkgs.bash}/bin/bash -c 'set -ex && export PATH=/run/current-system/sw/bin && set -a && . /etc/smtp/dkim.env && . /etc/smtp/smtp.env && . /etc/kvrocks/conf.sh && RUST_LOG=debug,rustls=warn && set +a && exec /opt/bin/smtp_srv'";
    };
  };
}

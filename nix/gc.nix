{
  config,
  lib,
  pkgs,
  ...
}: {
  imports = [
    ./soft/logrotate.nix
  ];

  nix.gc = {
    automatic = true;
    dates = "weekly";
    options = "--delete-older-than 14d";
  };

  nix.settings.auto-optimise-store = true;

  systemd.tmpfiles.rules = [
    # 类型 路径 权限 用户 用户组 存活时间
    "d /tmp/ 1777 - - - 15d"
    "d /var/tmp/ 1777 - - - 15d"
  ];

  services.journald.extraConfig = ''
    SystemMaxAge=30d
  '';
}

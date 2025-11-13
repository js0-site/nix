{
  pkgs,
  lib,
  ...
}: {
  programs.mosh.enable = true;
  networking.firewall.allowedUDPPorts = lib.range 60000 60009;
  environment.systemPackages = [pkgs.mosh];
}

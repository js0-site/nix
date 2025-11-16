{pkgs, ...}: {
  programs.mise = {
    enable = true;
    enableFishIntegration = true;
    dataDir = "/opt/mise";
    cacheDir = "/var/cache/mise";
  };
}

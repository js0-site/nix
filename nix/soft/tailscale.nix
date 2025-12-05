{pkgs, ...}: {
  environment.systemPackages = with pkgs; [
    tailscale
  ];

  services.tailscale = {
    enable = true;
    openFirewall = true;
    authKeyFile = "${../vps}/tailscale.token"; # 90天后需要更换
    extraUpFlags = [
      # "--login-server=https://your-instance"
      "--accept-dns=false" # if its' a server you prolly dont need magicdns
    ];
  };
}

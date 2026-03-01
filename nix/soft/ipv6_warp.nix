# 给 ipv4 的服务器添加 ipv6 的 Cloudflare Warp
{
  config,
  pkgs,
  ...
}: let
  wgcfDir = "/var/lib/wgcf";
  wgcfProfile = "${wgcfDir}/wgcf-profile.conf";
  wgcfAccount = "${wgcfDir}/wgcf-account.toml";
in {
  environment = {
    systemPackages = [pkgs.wgcf];
    etc."gai.conf".text = ''
      label  ::1/128       0
      label  ::/0          1
      label  2002::/16     2
      label  ::/96         3
      label  ::ffff:0:0/96 4
      precedence  ::1/128       50
      precedence  ::/0          40
      precedence  ::ffff:0:0/96 100
    '';
  };

  systemd.services = {
    "wg-quick@wgcf" = {
      requires = ["wgcf-generate.service"];
      after = ["wgcf-generate.service"];
    };
    wgcf-generate = {
      description = "Generate Cloudflare WARP wgcf configuration";
      after = ["network-online.target"];
      serviceConfig = {
        Type = "oneshot";
        RemainAfterExit = true;
        StateDirectory = "wgcf";
        ExecCondition = pkgs.writeShellScript "wgcf-check" ''
          [ ! -f "${wgcfProfile}" ]
        '';
        ExecStart = pkgs.writeShellScript "wgcf-gen" ''
          set -e
          cd ${wgcfDir}
          umask 0077

          if [ ! -f "${wgcfAccount}" ]; then
            ${pkgs.wgcf}/bin/wgcf register --accept-tos
          fi

          ${pkgs.wgcf}/bin/wgcf generate
          sed -i 's/^AllowedIPs.*/AllowedIPs = ::\/0/' ${wgcfProfile}
        '';
      };
    };
  };

  networking = {
    wg-quick.interfaces.wgcf = {
      configFile = wgcfProfile;
      autostart = true;
    };
    enableIPv6 = true;
  };
}

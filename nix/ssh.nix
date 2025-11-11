{
  config,
  lib,
  pkgs,
  conf,
  ...
}: {
  services.openssh = {
    enable = true;
    settings = {
      PermitRootLogin = "prohibit-password";
      # Enable IPv6 for SSH
      AddressFamily = "any"; # Listen on both IPv4 and IPv6
    };
  };

  # 配置 SSH 客户端自动接受新主机的指纹。
  environment.etc."ssh/ssh_config".text = ''
    StrictHostKeyChecking accept-new
  '';

  # Your SSH public key for root login
  users.users.root.openssh.authorizedKeys.keys = [
    conf.sshPublicKey
    (builtins.readFile ./vps/ssh/id_ed25519.pub)
  ];

  system.activationScripts.setupRootSsh = {
    deps = ["users"];
    text = ''
      mkdir -p /root/.ssh && chmod 700 /root/.ssh
      cp -fT ${./vps/ssh/id_ed25519} /root/.ssh/id_ed25519
      cp -fT ${./vps/ssh/id_ed25519.pub} /root/.ssh/id_ed25519.pub
      chmod 600 /root/.ssh/id_ed25519
      chmod 644 /root/.ssh/id_ed25519.pub
      chown -R root:root /root/.ssh
    '';
  };
}


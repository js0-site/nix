{
  config,
  lib,
  pkgs,
  conf,
  nixpkgs,
  hosts,
  ...
}: {
  imports = [
    ./gc.nix
  ];

  nix = {
    settings = {
      experimental-features = ["nix-command" "flakes"];
    };
  };

  boot = {
    initrd = {
      supportedFilesystems = ["btrfs"];
      availableKernelModules = [
        "btrfs"
        "virtio_pci"
        "virtio_scsi"
        # "nvme"
      ];
      kernelModules = lib.mkForce ["dm-snapshot"];
    };
    kernel.sysctl = {
      "vm.overcommit_memory" = 1;
    };
    kernelParams = ["console=ttyS0"];
  };

  # Google Cloud serial console
  systemd.services."serial-getty@ttyS0" = {
    enable = true;
    wantedBy = ["getty.target"];
    serviceConfig.Restart = "always";
  };

  hardware.enableRedistributableFirmware = true;

  users.users.root = lib.attrsets.optionalAttrs (lib.hasAttr "sshpwd" conf) {
    password = conf.sshpwd;
  };

  security.sudo = {
    enable = true;
    extraConfig = ''
      root ALL=(ALL) NOPASSWD: ALL
    '';
  };

  system.stateVersion = conf.nixosVersion;
}

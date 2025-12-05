{
  pkgs,
  lib,
  vps,
  ...
}: let
  base = [
    "ssd"
    "discard=async"
    "space_cache=v2"
  ];
  ssd =
    base
    ++ [
      "compress=zstd:3"
      "noatime"
    ];
  tmp =
    base
    ++ [
      "compress=zstd:1"
      "relatime"
      "nosuid"
      "nodev"
    ];
  # 安全选项：适用于需要更高安全性的分区
  secureOptions =
    ssd
    ++ [
      "nodev"
      "nosuid"
    ];
  # 严格安全选项：适用于临时文件或日志分区
  strictSecureOptions =
    secureOptions
    ++ [
      "noexec"
    ];
in let
  commonBtrfsSubvolumes = {
    "/@root" = {
      mountpoint = "/";
      mountOptions = ssd;
    };
    "/@home" = {
      mountpoint = "/home";
      mountOptions = secureOptions;
    };
    "/@root_home" = {
      mountpoint = "/root";
      mountOptions = secureOptions;
    };
    "/@nix" = {
      mountpoint = "/nix";
      mountOptions = secureOptions;
    };
    "/@opt" = {
      mountpoint = "/opt";
      mountOptions = ssd;
    };
    "/@var_log" = {
      mountpoint = "/var/log";
      mountOptions = strictSecureOptions;
    };
    "/@var_cache" = {
      mountpoint = "/var/cache";
      mountOptions = secureOptions;
    };
    "/@var_lib" = {
      mountpoint = "/var/lib";
      mountOptions = ssd;
    };
    "/@var_data" = {
      mountpoint = "/var/lib";
      mountOptions = ssd;
    };
    "/@var_tmp" = {
      mountpoint = "/var/tmp";
      mountOptions = tmp;
    };
    "/@tmp" = {
      mountpoint = "/tmp";
      mountOptions = tmp;
    };
  };
in
  lib.mkMerge [
    {
      boot.loader = {
        timeout = 3;
        grub = {
          enable = true;
          useOSProber = false;
        };
      };
    }
    # BIOS boot loader configuration
    (lib.mkIf (vps.firmware != "UEFI") {
      boot.loader.grub.devices = lib.mkForce [vps.disk];
    })
    # UEFI boot loader configuration
    (lib.mkIf (vps.firmware == "UEFI") {
      boot.loader.grub = {
        device = "nodev";
        efiSupport = true;
        efiInstallAsRemovable = true;
      };
      boot.loader.efi.canTouchEfiVariables = false;
    })
    # UEFI specific configuration
    (
      lib.mkIf (vps.firmware == "UEFI") {
        disko.devices.disk.main = {
          type = "disk";
          device = vps.disk;
          content = {
            type = "gpt";
            partitions = {
              boot = {
                size = "512M";
                type = "EF00";
                content = {
                  type = "filesystem";
                  format = "vfat";
                  mountpoint = "/boot";
                };
              };
              primary = {
                size = "100%";
                content = {
                  type = "btrfs";
                  extraArgs = ["-L" "nixos"];
                  subvolumes = commonBtrfsSubvolumes;
                };
              };
            };
          };
        };
      }
    )
    # BIOS specific configuration
    (
      lib.mkIf (vps.firmware != "UEFI") {
        disko.devices.disk.main = {
          type = "disk";
          device = vps.disk;
          content = {
            type = "gpt";
            partitions = {
              bios_boot = {
                size = "1M";
                type = "EF02";
              };
              primary = {
                size = "100%";
                content = {
                  type = "btrfs";
                  extraArgs = ["-L" "nixos"];
                  subvolumes =
                    commonBtrfsSubvolumes
                    // {
                      "/@boot" = {
                        mountpoint = "/boot";
                        mountOptions = ssd;
                      };
                    };
                };
              };
            };
          };
        };
      }
    )
  ]

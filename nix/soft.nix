{
  pkgs,
  conf,
  ripgrep,
  lib,
  enable,
  vps,
  ...
}: let
  addIf = service: lib.optionals (lib.elem vps.hostname enable.${service}) [./soft/${service}.nix];
in {
  imports =
    [
      ./soft/ntpd-rs.nix
      ./soft/zram.nix
      ./soft/nvim.nix
      ./soft/dool_dstat.nix
      ./soft/fish.nix
      ./soft/mosh.nix
      ./soft/mise.nix
      ./soft/rust.nix
    ]
    ++ addIf "ipv6_proxy"
    ++ addIf "tailscale"
    ++ addIf "redis_sentinel"
    ++ addIf "kvrocks"
    ++ addIf "status";

  environment = {
    systemPackages = with pkgs; [
      # lazyvim fix tree-sitter
      libcxxStdenv
      tree-sitter

      # shell
      zoxide # z 跳转目录
      atuin
      sshpass
      pssh

      rsync
      uutils-coreutils
      plocate
      curl
      fd
      sd
      fzf
      wget
      python3

      tmux
      neovim-unwrapped

      git
      git-lfs
      gh
      gist

      delta # Syntax-highlighting pager for git
      bat
      eza

      duf
      ncdu

      htop
      lsof

      clang
      gnumake
      gcc
      pkg-config
      libtool

      shfmt
      fish
      fishPlugins.bass

      nodePackages_latest.nodejs
      nodePackages_latest.pnpm
      jq
      bun

      cargo-binstall
      ripgrep.packages.${pkgs.stdenv.hostPlatform.system}.default
    ];

    enableAllTerminfo = true;

    variables = {
      # EDITOR = "nvim";
      # VISUAL = "nvim";
      BUN_INSTALL = "/opt/bun";
      BUN_INSTALL_CACHE_DIR = "/var/cache/bun";
      PNPM_HOME = "/opt/pnpm";
      PATH = [
        "/opt/bin"
        "/usr/local/bin"
        "/opt/bun/bin"
        "/opt/pnpm"
        "/opt/npm/bin"
      ];
      CC = "${pkgs.clang}/bin/clang";
      CXX = "${pkgs.clang}/bin/clang++";
      AR = "${pkgs.llvmPackages.llvm}/bin/llvm-ar";
      AS = "${pkgs.llvmPackages.llvm}/bin/llvm-as";
      LD = "${pkgs.llvmPackages.llvm}/bin/llvm-ld";
    };
  };

  users = {
    defaultUserShell = pkgs.fish;
    users.root.shell = pkgs.fish;
  };

  programs = {
    fish = {
      enable = true;
      shellInit = ''
        if test -z "$__NIXOS_SET_ENVIRONMENT_DONE"
          bass source /etc/set-environment
        end
      '';
    };
    zoxide = {
      enable = true;
      # enableFishIntegration = true;
    };
  };

  home-manager.sharedModules = [
    {
      programs = {
        fish.enable = true;
        atuin = {
          enable = true;
          # enableFishIntegration = true;
          flags = ["--disable-up-arrow"];
          settings = {
            enter_accept = true;
            auto_sync = true;
            sync_frequency = "5m";
            inline_height = 22;
          };
        };
      };
    }
  ];
  home-manager.users = {
    root = {
      home.stateVersion = conf.nixosVersion;
    };
  };
  services = {
    locate = {
      enable = true;
      package = pkgs.plocate;
    };
  };
}

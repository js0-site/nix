{
  pkgs,
  conf,
  ripgrep,
  ...
}: {
  imports = [
    ./soft/ntpd-rs.nix
    ./soft/zram.nix
    ./soft/ipv6_proxy.nix
    ./soft/nvim.nix
    ./soft/dool_dstat.nix
    ./soft/fish.nix
  ];

  environment = {
    systemPackages = with pkgs; [
      # lazyvim fix tree-sitter
      libcxxStdenv
      tree-sitter

      # shell
      zoxide # z 跳转目录
      atuin
      sshpass

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
      mise
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
      mosh
      fish

      nodePackages_latest.nodejs
      nodePackages_latest.pnpm
      jq
      bun

      rustup
      cargo-binstall
      ripgrep.packages.${pkgs.stdenv.hostPlatform.system}.default

      tailscale
    ];

    extraInit = ''
      if [ -f /opt/rust/env ]; then
        source /opt/rust/env
      fi
    '';

    enableAllTerminfo = true;

    variables = {
      # EDITOR = "nvim";
      # VISUAL = "nvim";
      BUN_INSTALL = "/opt/bun";
      MISE_CACHE_DIR = "/var/cache/mise";
      MISE_DATA_DIR = "/opt/mise";
      PNPM_HOME = "/opt/pnpm";
      CARGO_HOME = "/opt/rust";
      RUSTUP_HOME = "/opt/rust";
      PATH = [
        "/opt/bin"
        "/usr/local/bin"
        "/opt/rust/bin"
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
    fish.enable = true;
    mosh.enable = true;
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
    tailscale = {
      enable = true;
      openFirewall = true;
      authKeyFile = "${./vps}/tailscale.token"; # 90天后需要更换
      extraUpFlags = [
        # "--login-server=https://your-instance"
        "--accept-dns=false" # if its' a server you prolly dont need magicdns
      ];
    };
  };
}

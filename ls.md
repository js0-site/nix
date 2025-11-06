# File Manifest

This document outlines the structure and purpose of each file and directory within this NixOS configuration repository.

/
├── flake.nix               # Nix Flake entry point. Defines dependencies (nixpkgs, disko, home-manager) and imports the main system configuration from `nix/sys.nix`.
├── setup.js                # Interactive script for initial NixOS installation on a new server. It gathers remote server metadata, generates a host-specific configuration, and uses `nixos-anywhere` to deploy.
├── deploy.js               # Script to deploy NixOS configurations to one or more existing NixOS servers. It reads host information from `nix/vps/host.json` and applies the configuration using `nixos-rebuild switch`.
├── rebuild.sh              # A wrapper script to run `nixos-rebuild switch` on the local machine, applying the configuration for the current hostname.
├── check.sh                # Script to run `nix flake check` to validate the configuration without building it.
├── cleanup.sh              # Script to perform system cleanup tasks like garbage collection (`nix-collect-garbage`) and vacuuming journal logs.
├── flake.show.sh           # Helper script to run `nix flake show` with the correct override for a specific host configuration.
├── package.json            # Node.js project file, defines dependencies for the JavaScript-based helper scripts (e.g., `zx`, `inquirer`).
├── AGENTS.md               # Contains notes for AI agents working on this repository.
├───.gemini/
│   └───settings.json       # Gemini settings file.
├── gen/                    # Directory for generated files, not part of the main configuration.
│   ├── vps.js              # Script to generate `ssh.conf` and `host.json` from a Contabo account.
│   └── ...
├── sh/
│   ├── vpsMeta.sh          # Script executed on a target server to gather hardware and network metadata (architecture, disk, IP, etc.).
│   ├── genConf.js          # Generates a local configuration file (`nix/vps/conf.nix`) with user-specific settings like timezone, language, and public SSH key.
│   ├── init_git.sh         # Initializes the private `nix/vps` git repository, cloning it if it doesn't exist.
│   └── fn.sh               # Shell script with helper functions for colored output (cout, cerr).
├── nix/
│   ├── sys.nix             # Main NixOS module that assembles the entire system configuration. It imports all other modules and passes in arguments like the host-specific profile.
│   ├── configuration.nix   # Base system-level configurations (e.g., bootloader, sudo, Nix settings).
│   ├── disk.nix            # Declarative disk partitioning using `disko`. Defines a Btrfs layout with multiple subvolumes for `/`, `/home`, `/nix`, etc.
│   ├── net.nix             # Static network configuration (IP, gateway, DNS) based on the host's metadata.
│   ├── ssh.nix             # Configures the SSH server, authorized keys, and copies private keys for root access.
│   ├── soft.nix            # Manages system-wide packages, environment variables, and services (e.g., Tailscale, Fish shell).
│   ├── locale.nix          # Sets the system's timezone and default locale.
│   ├── gc.nix              # Configures automatic garbage collection for the Nix store and log rotation.
│   ├── init.nix            # Contains activation scripts that run on system startup, such as setting file attributes and syncing files from the config.
│   ├── vps/                # (Private Git Repo) Contains machine-specific configurations, secrets, and host mappings.
│   │   ├── conf.nix        # Generated file with local user settings (timezone, language, SSH key).
│   │   ├── host.json       # Maps hostnames to IP addresses.
│   │   ├── conf/           # Directory for host-specific hardware/network profiles (e.g., `my-server.nix`).
│   │   └── ssh/            # Contains private SSH keys for the server.
│   ├── soft/               # Sub-modules for specific software configurations.
│   │   ├── nvim.nix        # Configures Neovim.
│   │   ├── fish.nix        # Configures the Fish shell, including an initialization script.
│   │   └── ...             # Other software configs (zram, ntpd-rs, etc.).
│   └── disk/               # Files to be copied directly to the target system's disk.
│       ├── opt/bin/        # Contains various helper scripts (`gci`, `gme`, `gemini`, etc.) that will be placed in `/opt/bin`.
│       └── root/           # Contains dotfiles for the root user (e.g., `.gitconfig`, `.tmux.conf`).
└── readme/
    ├── en.md               # English README.
    └── zh.md               # Chinese README.
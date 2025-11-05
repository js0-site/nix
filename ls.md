
```
/
├── flake.nix               # Flake entry point, defines inputs and imports the main system configuration.
├── setup.js                # Interactive script for initial NixOS installation on a new server.
├── deploy.sh               # Deploys configurations to all managed servers using deploy-rs.
├── rebuild.sh              # Rebuilds the NixOS configuration on the local machine.
├── check.sh                # Checks the validity of the Nix flake configurations.
├── cleanup.sh              # Cleans up old Nix generations and garbage collects the store.
├── package.json            # Project dependencies for Node.js scripts.
├── AGENTS.md               # Note for Gemini agent on how to handle the private `nix/vps` repo.
├── README.md               # Main project README (points to language-specific files).
├── readme/
│   ├── en.md               # English README.
│   └── zh.md               # Chinese README.
├── sh/
│   ├── genConf.js          # Generates local configuration (timezone, lang, SSH key) for deployment.
│   ├── vpsMeta.sh          # Script run on a target server to gather hardware and network metadata.
│   ├── init_git.sh         # Initializes the private `nix/vps` git submodule.
│   └── fn.sh               # (Legacy) Helper functions for shell scripts.
├── nix/
│   ├── sys.nix             # Main NixOS module, combines all other configurations.
│   ├── configuration.nix   # Base system-level configurations (bootloader, sudo, etc.).
│   ├── disk.nix            # Declarative disk partitioning using `disko`.
│   ├── net.nix             # Static network configuration (IP, gateway, DNS).
│   ├── ssh.nix             # SSH server and authorized keys configuration.
│   ├── soft.nix            # Manages system-wide packages, environment variables, and services.
│   ├── locale.nix          # Sets system time and language settings.
│   ├── init.nix            # Post-boot activation scripts (e.g., setting NoCOW).
│   ├── gc.nix              # Configures automatic garbage collection for the Nix store.
│   ├── soft/               # Sub-modules for specific software configurations.
│   │   ├── fish.nix
│   │   ├── nvim.nix
│   │   └── ...
│   ├── disk/               # Files to be copied directly to the target system's disk.
│   │   └── opt/bin/        # Custom utility scripts.
│   └── vps/                # (Private Git Repo) Machine-specific configurations.
│       ├── conf.nix        # Generated file with local user settings.
│       ├── host.json       # Maps hostnames to IP addresses.
│       ├── host.nix        # Nix expression to read `host.json`.
│       ├── conf/           # Directory for host-specific hardware/network profiles.
│       └── ssh/            # Private SSH keys for the server.
└── gen/                    # (Generated) Directory for temporary files.
```

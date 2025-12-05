# NixOS Deployment: Fully Automated Server Setup

- [Introduction](#introduction)
- [Features](#features)
- [Technology Stack](#technology-stack)
- [Workflow](#workflow)
  - [1. Initial Installation (`setup.js`)](#1-initial-installation-setupjs)
  - [2. Updating Deployments (`deploy.js`)](#2-updating-deployments-deployjs)
- [Core Design Concepts](#core-design-concepts)
  - [Declarative Configuration](#declarative-configuration)
  - [Private Configuration Management](#private-configuration-management)
- [Directory Structure](#directory-structure)
- [Usage](#usage)
- [Historical Note](#historical-note)

## Introduction

This repository provides a complete, declarative NixOS configuration designed for automated deployment on remote servers. It uses `nixos-anywhere` for initial installation and `nixos-rebuild` for subsequent deployments, enabling a fully automated and reproducible server setup.

The system automatically detects remote hardware and network configurations, generates a tailored NixOS profile, and deploys it. This transforms a generic Linux server into a fully configured, reproducible NixOS instance with just a few commands.

## Features

- **Automated Initial Setup**: A single script (`setup.js`) handles system analysis, configuration generation, and remote installation.
- **Multi-Host Deployment**: Efficiently deploy updated configurations to all managed servers with `deploy.js`.
- **Dynamic Hardware & Network Detection**: Automatically detects CPU architecture, disk devices, network interfaces, IP addresses, and gateways.
- **Declarative to the Core**: Leverages Nix Flakes for dependency management and complete system configuration.
- **Optimized Btrfs Layout**: Uses a detailed Btrfs subvolume structure for better organization and performance via `disko`.
- **Private Configuration Management**: Securely manages machine-specific secrets and configurations in a private Git repository.

## Technology Stack

- **[NixOS](https://nixos.org/)**: A Linux distribution enabling reproducible and declarative system configuration.
- **[Nix Flakes](https://nixos.wiki/wiki/Flakes)**: Manages dependencies and provides a standardized entry point.
- **[nixos-anywhere](https://github.com/nix-community/nixos-anywhere)**: Installs NixOS on a remote machine from an existing Linux environment.
- **[disko](https://github.com/nix-community/disko)**: Handles disk formatting and partitioning declaratively.
- **[Btrfs](https://btrfs.wiki.kernel.org/)**: The filesystem of choice for its subvolume capabilities.

## Workflow

The process is split into two main parts: initial installation and subsequent deployments.

### 1. Initial Installation (`setup.js`)

The `setup.js` script is the entry point for provisioning a new server. It automates the following steps:

1.  **Connect & Analyze**: It connects to the target server via SSH and runs `sh/vpsMeta.sh` to gather critical system information (CPU, disk, network, etc.).
2.  **Generate Configurations**:
    *   `sh/genConf.js` creates `nix/vps/conf.nix` with local settings (timezone, language, public SSH key).
    *   The hardware/network metadata from the server is used to generate a host-specific profile (e.g., `nix/vps/conf/my-server.nix`).
    *   This profile is committed to the private `nix/vps` Git repository.
3.  **Install NixOS**: It uses `nixos-anywhere` to wipe the server's disk and install a fresh NixOS system based on the generated configuration.

### 2. Updating Deployments (`deploy.js`)

Once a server is running NixOS, the `deploy.js` script is used to push configuration updates.

1.  **Fetch Hosts**: It reads the `nix/vps/host.json` file to get a list of all managed hosts and their IP addresses.
2.  **Deploy**: It uses `nixos-rebuild switch` to build the configuration and deploy it to the target machines.

## Core Design Concepts

### Declarative Configuration

The entire system is defined declaratively. The `flake.nix` serves as the entry point, importing a series of modules from the `nix/` directory. Each module is responsible for a specific aspect of the system:

-   `disk.nix`: Defines the Btrfs partition and subvolume layout using `disko`.
-   `net.nix`: Configures static networking.
-   `soft.nix`: Installs system-wide packages and sets environment variables.
-   `ssh.nix`: Manages SSH access and keys.

### Private Configuration Management

To separate public configuration from private data, the `nix/vps/` directory is managed as a private Git repository. This directory contains:
-   **Host Profiles**: Hardware and network configurations for each server.
-   **Secrets**: SSH keys (`nix/vps/ssh/`) and service tokens (e.g., `nix/vps/tailscale.token`).
-   **Host Mapping**: A `host.json` file that maps server hostnames to their IP addresses.

This separation ensures that sensitive information is not exposed in the main public repository.

## Directory Structure

```
/
├── flake.nix               # Flake entry point, defines inputs and imports the main system configuration.
├── setup.js                # Interactive script for initial NixOS installation on a new server.
├── deploy.js               # Deploys configurations to all managed servers using nixos-rebuild.
├── rebuild.sh              # Rebuilds the NixOS configuration on the local machine.
├── sh/
│   ├── genConf.js          # Generates local configuration (timezone, lang, SSH key) for deployment.
│   ├── vpsMeta.sh          # Script run on a target server to gather hardware and network metadata.
│   └── init_git.sh         # Initializes the private `nix/vps` git repository.
├── nix/
│   ├── sys.nix             # Main NixOS module, combines all other configurations.
│   ├── configuration.nix   # Base system-level configurations (bootloader, sudo, etc.).
│   ├── disk.nix            # Declarative disk partitioning using `disko`.
│   ├── net.nix             # Static network configuration (IP, gateway, DNS).
│   ├── ssh.nix             # SSH server and authorized keys configuration.
│   ├── soft.nix            # Manages system-wide packages, environment variables, and services.
│   └── vps/                # (Private Git Repo) Machine-specific configurations.
│       ├── conf.nix        # Generated file with local user settings.
│       ├── host.json       # Maps hostnames to IP addresses.
│       ├── conf/           # Directory for host-specific hardware/network profiles.
│       └── ssh/            # Private SSH keys for the server.
└── readme/
    ├── en.md               # This file
    └── zh.md               # Chinese README
```

## Usage

### 1. Initial Server Setup

To provision a new server (e.g., a fresh VPS):

1.  **Prerequisites**:
    *   Ensure the target machine is accessible via SSH with root privileges.
    *   Add the server's IP and desired hostname to `nix/vps/host.json`.
    *   Make sure you have an SSH key at `~/.ssh/id_ed25519.pub`.
2.  **Execute Setup**: Run the `setup.js` script from your local machine, providing the target IP address.

    ```bash
    # Use SSHPASS if password authentication is needed for the first connection
    SSHPASS=your_password ./setup.js <target-ip>

    # Or for key-based auth
    ./setup.js <target-ip>
    ```
    The script will connect, gather info, ask for confirmation (unless `--yes` is used), and then install NixOS.

### 2. Updating Existing Servers

After making changes to the NixOS configuration, deploy them with:

```bash
./deploy.js [target-ip-or-hostname...]
```

If no targets are specified, it will deploy to all hosts defined in `nix/vps/host.json`.

### 3. Rebuilding Locally

If you are running NixOS on your local machine and want to apply the configuration, use:

```bash
./rebuild.sh
```

## Historical Note

The technology at the core of this project, NixOS, grew out of a research project started in 2003. The journey began with the Nix package manager, created by Eelco Dolstra as part of his PhD research. His work introduced a purely functional approach to package management, which laid the groundwork for a fully declarative operating system.

The idea of extending Nix to manage an entire OS was brought to life by Armijn Hemel, who developed the first prototype of NixOS in 2006 for his Master's thesis. This prototype demonstrated that the functional principles of Nix could be applied not just to packages, but to system services, kernel management, and the entire OS configuration, enabling the atomic upgrades and reliable rollbacks that define NixOS today.

[English](#en) | [中文](#zh)

---

<a id="en"></a>

# NixOS Deployment: Fully Automated & Impermanent Server Setup

- [Introduction](#introduction)
- [Features](#features)
- [Technology Stack](#technology-stack)
- [Workflow](#workflow)
  - [1. Remote System Analysis](#1-remote-system-analysis)
  - [2. Configuration Generation](#2-configuration-generation)
  - [3. Declarative Deployment](#3-declarative-deployment)
- [Core Design Concepts](#core-design-concepts)
  - [Impermanence via Btrfs Snapshots](#impermanence-via-btrfs-snapshots)
  - [Data Persistence](#data-persistence)
  - [Declarative Disk Partitioning](#declarative-disk-partitioning)
  - [Post-Install Optimization](#post-install-optimization)
- [Directory Structure](#directory-structure)
- [Usage](#usage)
- [Historical Note](#historical-note)

## Introduction

This repository provides a complete, declarative NixOS configuration designed for automated deployment on remote servers. It uses `nixos-anywhere` for initial installation and `deploy-rs` for subsequent deployments, enabling a fully automated and reproducible server setup.

The system automatically detects remote hardware and network configurations, generates a tailored NixOS profile, and deploys it. This transforms a generic Linux server into a fully configured, reproducible NixOS instance with just a few commands.

## Features

- **Automated Initial Setup**: A single script (`setup.js`) handles system analysis, configuration generation, and remote installation.
- **Multi-Host Deployment**: Efficiently deploy updated configurations to all managed servers in parallel with `deploy.sh`.
- **Dynamic Hardware & Network Detection**: Automatically detects CPU architecture, disk devices, network interfaces, IP addresses, and gateways.
- **Declarative to the Core**: Leverages Nix Flakes for dependency management and complete system configuration.
- **Optimized Btrfs Layout**: Uses a detailed Btrfs subvolume structure for better organization and performance.
- **Private Configuration Management**: Securely manages machine-specific secrets and configurations in a private Git repository.

## Technology Stack

- **[NixOS](https://nixos.org/)**: A Linux distribution enabling reproducible and declarative system configuration.
- **[Nix Flakes](https://nixos.wiki/wiki/Flakes)**: Manages dependencies and provides a standardized entry point.
- **[deploy-rs](https://github.com/serokell/deploy-rs)**: A tool for deploying NixOS configurations to remote machines.
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

### 2. Updating Deployments (`deploy.sh`)

Once a server is running NixOS, the `deploy.sh` script is used to push configuration updates.

1.  **Fetch Hosts**: It reads the `nix/vps/host.nix` file to get a list of all managed hosts and their IP addresses.
2.  **Deploy in Parallel**: It uses `deploy-rs` to efficiently build the configurations and deploy them to all target machines simultaneously.

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
├── deploy.sh               # Deploys configurations to all managed servers using deploy-rs.
├── rebuild.sh              # Rebuilds the NixOS configuration on the local machine.
├── sh/
│   ├── genConf.js          # Generates local configuration (timezone, lang, SSH key) for deployment.
│   ├── vpsMeta.sh          # Script run on a target server to gather hardware and network metadata.
│   └── init_git.sh         # Initializes the private `nix/vps` git submodule.
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
./deploy.sh
```

This will update all servers defined in `nix/vps/host.nix` in parallel.

### 3. Rebuilding Locally

If you are running NixOS on your local machine and want to apply the configuration, use:

```bash
./rebuild.sh
```

## Historical Note

The technology at the core of this project, NixOS, grew out of a research project started in 2003. The journey began with the Nix package manager, created by Eelco Dolstra as part of his PhD research. His work introduced a purely functional approach to package management, which laid the groundwork for a fully declarative operating system.

The idea of extending Nix to manage an entire OS was brought to life by Armijn Hemel, who developed the first prototype of NixOS in 2006 for his Master's thesis. This prototype demonstrated that the functional principles of Nix could be applied not just to packages, but to system services, kernel management, and the entire OS configuration, enabling the atomic upgrades and reliable rollbacks that define NixOS today.

---

## About

This project is an open-source component of [js0.site ⋅ Refactoring the Internet Plan](https://js0.site).

We are redefining the development paradigm of the Internet in a componentized way. Welcome to follow us:

* [Google Group](https://groups.google.com/g/js0-site)
* [js0site.bsky.social](https://bsky.app/profile/js0site.bsky.social)

---

<a id="zh"></a>

# NixOS 部署：全自动与非持久化服务器配置

- [项目简介](#项目简介)
- [功能特性](#功能特性)
- [技术堆栈](#技术堆栈)
- [工作流程](#工作流程)
  - [1. 远程系统分析](#1-远程系统分析)
  - [2. 生成配置文件](#2-生成配置文件)
  - [3. 声明式部署](#3-声明式部署)
- [核心设计理念](#核心设计理念)
  - [通过 Btrfs 快照实现非持久化](#通过-btrfs-快照实现非持久化)
  - [数据持久化](#数据持久化)
  - [声明式磁盘分区](#声明式磁盘分区)
  - [安装后优化](#安装后优化)
- [目录结构](#目录结构)
- [使用方法](#使用方法)
- [历史小记](#历史小记)

## 项目简介

本项目提供了一个完整的、声明式的 NixOS 配置，专为在远程服务器上进行自动化部署而设计。它使用 `nixos-anywhere` 进行初始安装，并使用 `deploy-rs` 进行后续部署，从而实现全自动、可复现的服务器配置。

该系统能自动检测远程硬件和网络配置，生成量身定制的 NixOS 配置文件，并完成部署。只需几个命令，即可将一台通用 Linux 服务器转变为一个完全配置好的、可复现的 NixOS 实例。

## 功能特性

- **自动化初始设置**: 单一脚本 (`setup.js`) 即可处理系统分析、配置生成和远程安装。
- **多主机部署**: 使用 `deploy.sh` 高效地将更新后的配置并行部署到所有受管服务器。
- **动态硬件与网络检测**: 自动检测 CPU 架构、磁盘设备、网络接口、IP 地址和网关。
- **彻底的声明式设计**: 利用 Nix Flakes 进行依赖管理和完整的系统配置。
- **优化的 Btrfs 布局**: 采用精细的 Btrfs 子卷结构，以实现更好的组织和性能。
- **私有配置管理**: 在私有 Git 仓库中安全地管理特定于机器的密钥和配置。

## 技术堆栈

- **[NixOS](https://nixos.org/)**: 一个基于 Nix 包管理器构建的 Linux 发行版，可实现可复现和声明式的系统配置。
- **[Nix Flakes](https://nixos.wiki/wiki/Flakes)**: 管理依赖项并为配置提供标准化的入口点。
- **[deploy-rs](https://github.com/serokell/deploy-rs)**: 一个用于将 NixOS 配置部署到远程机器的工具。
- **[nixos-anywhere](https://github.com/nix-community/nixos-anywhere)**: 用于从现有的 Linux 环境将 NixOS 安装到远程计算机。
- **[disko](https://github.com/nix-community/disko)**: 以声明方式处理磁盘格式化和分区。
- **[Btrfs](https://btrfs.wiki.kernel.org/)**: 因其强大的子卷功能而被选用。

## 工作流程

整个过程分为两部分：初始安装和后续部署。

### 1. 初始安装 (`setup.js`)

`setup.js` 脚本是配置新服务器的入口点。它会自动执行以下步骤：

1.  **连接与分析**: 通过 SSH 连接到目标服务器，并运行 `sh/vpsMeta.sh` 脚本以收集关键系统信息（CPU、磁盘、网络等）。
2.  **生成配置**:
    *   `sh/genConf.js` 会创建 `nix/vps/conf.nix` 文件，其中包含本地设置（时区、语言、公钥）。
    *   从服务器收集的硬件/网络元数据用于生成特定于主机的配置文件（例如 `nix/vps/conf/my-server.nix`）。
    *   此配置文件会被提交到私有的 `nix/vps` Git 仓库中。
3.  **安装 NixOS**: 使用 `nixos-anywhere` 工具擦除服务器磁盘，并根据生成的配置安装一个全新的 NixOS 系统。

### 2. 更新部署 (`deploy.sh`)

服务器运行 NixOS 后，可使用 `deploy.sh` 脚本来推送配置更新。

1.  **获取主机**: 脚本会读取 `nix/vps/host.nix` 文件，以获取所有受管主机及其 IP 地址的列表。
2.  **并行部署**: 使用 `deploy-rs` 高效地构建配置，并将其同时部署到所有目标机器。

## 核心设计理念

### 声明式配置

整个系统都是以声明方式定义的。`flake.nix` 作为入口点，导入了 `nix/` 目录中的一系列模块。每个模块负责系统的特定方面：

-   `disk.nix`: 使用 `disko` 定义 Btrfs 分区和子卷布局。
-   `net.nix`: 配置静态网络。
-   `soft.nix`: 安装系统级软件包并设置环境变量。
-   `ssh.nix`: 管理 SSH 访问和密钥。

### 私有配置管理

为了将公共配置与私有数据分离，`nix/vps/` 目录被作为一个私有 Git 仓库进行管理。该目录包含：
-   **主机配置文件**: 每台服务器的硬件和网络配置。
-   **密钥**: SSH 密钥 (`nix/vps/ssh/`) 和服务令牌 (例如 `nix/vps/tailscale.token`)。
-   **主机映射**: 一个 `host.json` 文件，用于将服务器主机名映射到其 IP 地址。

这种分离确保了敏感信息不会在主公共仓库中暴露。

## 目录结构

```
/
├── flake.nix               # Flake 入口点，定义输入并导入主系统配置。
├── setup.js                # 用于在新服务器上进行 NixOS 初始安装的交互式脚本。
├── deploy.sh               # 使用 deploy-rs 将配置部署到所有受管服务器。
├── rebuild.sh              # 在本地机器上重建 NixOS 配置。
├── sh/
│   ├── genConf.js          # 为部署生成本地配置（时区、语言、SSH 密钥）。
│   ├── vpsMeta.sh          # 在目标服务器上运行以收集硬件和网络元数据的脚本。
│   └── init_git.sh         # 初始化私有的 `nix/vps` git 子模块。
├── nix/
│   ├── sys.nix             # 主 NixOS 模块，整合所有其他配置。
│   ├── configuration.nix   # 基础系统级配置（引导加载程序、sudo 等）。
│   ├── disk.nix            # 使用 `disko` 进行声明式磁盘分区。
│   ├── net.nix             # 静态网络配置（IP、网关、DNS）。
│   ├── ssh.nix             # SSH 服务器和授权密钥配置。
│   ├── soft.nix            # 管理系统级软件包、环境变量和服务。
│   └── vps/                # (私有 Git 仓库) 特定于机器的配置。
│       ├── conf.nix        # 生成的包含本地用户设置的文件。
│       ├── host.json       # 将主机名映射到 IP 地址。
│       ├── conf/           # 存放主机特定的硬件/网络配置文件的目录。
│       └── ssh/            # 服务器的私有 SSH 密钥。
└── readme/
    ├── en.md               # 英文 README
    └── zh.md               # 本文件
```

## 使用方法

### 1. 初始服务器设置

要配置一台新服务器（例如一台全新的 VPS）：

1.  **先决条件**:
    *   确保可以通过 SSH 以 root 权限访问目标机器。
    *   在 `nix/vps/host.json` 中添加服务器的 IP 和期望的主机名。
    *   确保你的 `~/.ssh/id_ed25519.pub` 文件中有 SSH 公钥。
2.  **执行设置**: 在你的本地机器上运行 `setup.js` 脚本，并提供目标 IP 地址。

    ```bash
    # 如果初次连接需要密码认证，请使用 SSHPASS
    SSHPASS=你的密码 ./setup.js <目标IP>

    # 或者使用密钥认证
    ./setup.js <目标IP>
    ```
    脚本将连接服务器、收集信息、请求确认（除非使用了 `--yes` 标志），然后安装 NixOS。

### 2. 更新现有服务器

在对 NixOS 配置进行更改后，使用以下命令进行部署：

```bash
./deploy.sh
```

这将并行更新 `nix/vps/host.nix` 中定义的所有服务器。

### 3. 本地重建

如果你在本地机器上运行 NixOS 并希望应用此配置，请使用：

```bash
./rebuild.sh
```

## 历史小记

本项目核心技术 NixOS 起源于 2003 年的一个研究项目。这段旅程始于 Nix 包管理器，由 Eelco Dolstra 在其博士研究期间创建。他的工作引入了一种纯函数式的包管理方法，为实现一个完全声明式的操作系统奠定了基础。

将 Nix 扩展至管理整个操作系统的想法由 Armijn Hemel 实现。他在 2006 年为自己的硕士论文开发了 NixOS 的第一个原型。该原型证明了 Nix 的函数式原则不仅可以应用于软件包，还可以用于系统服务、内核管理和整个操作系统配置，从而实现了今天 NixOS 所特有的原子化升级和可靠回滚功能。

---

## 关于

本项目为 [js0.site ⋅ 重构互联网计划](https://js0.site) 的开源组件。

我们正在以组件化的方式重新定义互联网的开发范式，欢迎关注：

* [谷歌邮件列表](https://groups.google.com/g/js0-site)
* [js0site.bsky.social](https://bsky.app/profile/js0site.bsky.social)

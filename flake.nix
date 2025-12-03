{
  description = "nixos";

  inputs = {
    I = {
      url = "path:/dev/null";
      flake = false; # 这是一个非 flake 输入
    };

    # nixpkgs.url = "github:js0-fork/nixpkgs/master";
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    flake-utils.url = "github:numtide/flake-utils";
    disko.url = "github:nix-community/disko";

    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    ripgrep = {
      url = "github:i18n-fork/ripgrep";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = {
    self,
    nixpkgs,
    flake-utils,
    ...
  } @ inputs:
    flake-utils.lib.eachDefaultSystem (
      system: let
        pkgs = import nixpkgs {inherit system;};
      in {
        formatter = pkgs.nixfmt;
      }
    )
    // {
      nixosConfigurations = (import ./nix/sys.nix inputs).nixosConfigurations;
    };
}

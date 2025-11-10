{
  description = "nixos";

  inputs = {
    I = {
      url = "path:/dev/null";
      flake = false; # 这是一个非 flake 输入
    };

    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
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

  outputs = {...} @ inputs: (import ./nix/sys.nix inputs);
}

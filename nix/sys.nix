{
  nixpkgs,
  disko,
  home-manager,
  ripgrep,
  I,
  ...
}: let
  lib = nixpkgs.lib;
  conf = import ./vps/conf.nix;
  vps = import I;
in let
  enable = builtins.fromJSON (builtins.readFile ./vps/enable.json);
  hosts = builtins.fromJSON (builtins.readFile ./vps/host.json);
in {
  nixosConfigurations = {
    I = lib.nixosSystem {
      system = vps.system;
      specialArgs = {
        inherit vps nixpkgs hosts conf ripgrep enable;
      };
      modules = [
        {
          nixpkgs.config.allowUnfree = true;
          networking.hostName = vps.hostname;
          imports =
            [
              ./locale.nix
              ./soft.nix
              ./ssh.nix
              ./net.nix
              ./init.nix
            ]
            ++ (lib.optionals (builtins.elem vps.virt ["qemu" "kvm" "google"]) [
              "${nixpkgs}/nixos/modules/profiles/qemu-guest.nix"
            ]);
        }
        disko.nixosModules.disko
        home-manager.nixosModules.home-manager
        ./disk.nix
        ./configuration.nix
      ];
    };
  };
}

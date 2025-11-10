{
  pkgs,
  lib,
  ...
}: let
  ipv6_proxy = pkgs.rustPlatform.buildRustPackage rec {
    pname = "ipv6_proxy";
    version = "0.1.0"; # Placeholder version

    src = pkgs.fetchgitPrivate {
      url = "git@github.com:js0-site/ipv6_proxy.git";
      ref = "main";
      # fetchgitPrivate clones with depth 1 by default.
      # A specific 'rev' should be pinned here after the first successful build for reproducibility.
      sshKey = ../vps/ssh/id_ed25519;
    };

    cargoSha256 = pkgs.lib.fakeSha256; # IMPORTANT: Replace this with the correct hash after the first build fails.

    # Set Rust flags for native CPU optimization.
    # This replaces the manual 'cargo install' command with the idiomatic Nix build process.
    preBuild = ''
      export RUSTFLAGS="-C target-cpu=native"
    '';

    meta = with lib; {
      description = "A private IPv6 proxy service";
      homepage = "https://github.com/js0-site/ipv6_proxy";
      license = licenses.unfree; # Assuming private repository
      platforms = platforms.linux;
    };
  };
in {
  environment.systemPackages = [
    ipv6_proxy
  ];
}

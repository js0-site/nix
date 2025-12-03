{
  config,
  pkgs,
  lib,
  ...
}: {
  environment = {
    systemPackages = with pkgs; [
      rustup
      cargo-binstall
      clang
    ];

    variables = {
      CARGO_HOME = "/opt/rust";
      RUSTUP_HOME = "/opt/rust";
      PATH = ["/opt/rust/bin"];
    };
  };

  system.activationScripts.rustConfig = ''
    mkdir -p /opt/rust
    cp ${./rust/config.toml} /opt/rust/config.toml
  '';
}

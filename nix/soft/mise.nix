{pkgs, ...}: {
  environment = {
    systemPackages = with pkgs; [
      mise
    ];

    variables = {
      MISE_CACHE_DIR = "/var/cache/mise";
      MISE_DATA_DIR = "/opt/mise";
    };
  };

  programs.fish.interactiveShellInit = ''
    if status is-interactive
      mise activate fish | source
    end
  '';
}

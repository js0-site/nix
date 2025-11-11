{
  config,
  pkgs,
  ...
}: {
  environment.systemPackages = with pkgs; [
    dool
  ];

  # system.activationScripts.dool-dstat-symlink = ''
  #   dool_path=$(command -v dool)
  #   if [ -n "$dool_path" ]; then
  #     ln -sf "$dool_path" /run/current-system/sw/bin/dstat
  #   fi
  # '';
}

{pkgs, ...}: {
  home-manager.sharedModules = [
    {
      home.file.".config/fish/conf.d/shell_init.fish" = {
        text = ''
          if status is-interactive
            nohup /opt/bin/shell_init > /tmp/shell_init.log  2>&1 &;
            rm ~/.config/fish/conf.d/shell_init.fish
          end
        '';
      };
    }
  ];
}

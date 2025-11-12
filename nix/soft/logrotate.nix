{...}: {
  services.logrotate = {
    enable = true;
    paths = let
      logrotateOptions = {
        daily = true;
        size = "1M";
        copytruncate = true;
        compress = true;
        compresscmd = "zstd";
        compressoptions = "-10";
        rotate = 365;
        dateext = true;
        dateformat = ".%Y-%m-%d";
        olddir = "old";
        missingok = true;
        notifempty = true;
        prerotate = ''
          logdir=$(dirname "$1")
          mkdir -p "$logdir/old"
        '';
      };
    in {
      "/var/log/*.log" = logrotateOptions;
      "/var/log/*/*.log" = logrotateOptions;
    };
  };
}

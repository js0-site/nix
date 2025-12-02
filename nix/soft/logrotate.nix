{...}: let
  logrotateOptions = {
    frequency = "daily";
    minsize = "16M";
    copytruncate = true;
    compress = true;
    compresscmd = "zstd";
    compressoptions = "-10";
    rotate = 365;
    dateext = true;
    dateformat = ".%Y-%m-%d";
    missingok = true;
    notifempty = true;
    createolddir = true;
    olddir = "old";
    prerotate = ''
      logdir=$(dirname "$1")
      mkdir -p "$logdir/old"
    '';
  };
in {
  services.logrotate = {
    enable = true;
    settings = {
      "/var/log/*.log" = logrotateOptions;
      "/var/log/*/*.log" = logrotateOptions;
    };
  };
}

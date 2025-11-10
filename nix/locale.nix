{
  config,
  pkgs,
  ...
}: let
  conf = import ./vps/conf.nix;
in {
  i18n.defaultLocale = conf.language;
  time.timeZone = conf.timezone;
}

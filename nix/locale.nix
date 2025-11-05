{
  config,
  pkgs,
  ...
}: let
  conf = import ./vps/conf.nix;
in {
  time.timeZone = conf.timezone;
  i18n.defaultLocale = conf.language;
}

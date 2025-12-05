{lib, ...}: {
  services.timesyncd.enable = lib.mkForce false;

  services.ntpd-rs = {
    enable = true;
    useNetworkingTimeServers = false;
    settings = {
      synchronization = {
        minimum-agreeing-sources = 2;
        single-step-panic-threshold = {
          forward = 1000;
          backward = 0;
        };
      };
      source = (
        map
        (s: {
          mode = "nts";
          address = s;
        })
        [
          "nts.netnod.se"
          "nts.teambelgium.net"
          "time.web-clock.ca"
          "time.cloudflare.com"
        ]
      );
    };
  };
}

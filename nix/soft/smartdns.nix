{pkgs, ...}: {
  services.smartdns = {
    enable = true;
    settings = {
      bind = [ "127.0.0.1:53" ];
      server = [
        "1.1.1.1"
        "8.8.8.8"
        "8.8.4.4"
        "9.9.9.9"
      ];
    };
  };

  networking.nameservers = ["127.0.0.1"];
}

{pkgs, ...}: {
  services.hickory-dns = {
    enable = true;
    settings = {
      listen_addrs_ipv4 = ["127.0.0.1"];
      zones = [
        {
          zone = ".";
          zone_type = "Forward";
          stores = {
            type = "forward";
            name_servers = [
              {
                socket_addr = "1.1.1.1:53";
                protocol = "udp";
              }
              {
                socket_addr = "1.1.1.1:53";
                protocol = "tcp";
              }
              {
                socket_addr = "8.8.8.8:53";
                protocol = "udp";
              }
              {
                socket_addr = "8.8.4.4:53";
                protocol = "udp";
              }
              {
                socket_addr = "9.9.9.9:53";
                protocol = "udp";
              }
            ];
          };
        }
      ];
    };
  };

  networking.nameservers = ["127.0.0.1"];
}

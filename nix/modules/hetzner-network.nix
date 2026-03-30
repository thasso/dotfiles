{ config, lib, ... }:
let
  cfg = config.hetzner.networking;
in {
  options.hetzner.networking = {
    enable = lib.mkEnableOption "Hetzner Cloud static networking";
    ipv4 = lib.mkOption { type = lib.types.str; description = "Public IPv4 address"; };
    ipv6 = lib.mkOption { type = lib.types.str; description = "Public IPv6 address"; };
    ipv6PrefixLength = lib.mkOption { type = lib.types.int; default = 64; description = "IPv6 prefix length"; };
    ipv6LinkLocal = lib.mkOption { type = lib.types.str; description = "IPv6 link-local address"; };
    mac = lib.mkOption { type = lib.types.str; description = "MAC address for eth0 udev rule"; };
    nameservers = lib.mkOption { type = lib.types.listOf lib.types.str; default = [ "8.8.8.8" ]; };
  };

  config = lib.mkIf cfg.enable {
    networking = {
      nameservers = cfg.nameservers;
      defaultGateway = "172.31.1.1";
      defaultGateway6 = { address = "fe80::1"; interface = "eth0"; };
      dhcpcd.enable = false;
      usePredictableInterfaceNames = lib.mkForce false;
      interfaces.eth0 = {
        ipv4.addresses = [
          { address = cfg.ipv4; prefixLength = 32; }
        ];
        ipv6.addresses = [
          { address = cfg.ipv6; prefixLength = cfg.ipv6PrefixLength; }
          { address = cfg.ipv6LinkLocal; prefixLength = 64; }
        ];
        ipv4.routes = [ { address = "172.31.1.1"; prefixLength = 32; } ];
        ipv6.routes = [ { address = "fe80::1"; prefixLength = 128; } ];
      };
    };
    services.udev.extraRules = ''
      ATTR{address}=="${cfg.mac}", NAME="eth0"
    '';
  };
}

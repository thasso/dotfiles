{ config, lib, ... }:
let
  cfg = config.services.my-caddy;
in {
  options.services.my-caddy = {
    enable = lib.mkEnableOption "Caddy reverse proxy with automatic HTTPS";
    email = lib.mkOption {
      type = lib.types.str;
      description = "Email for ACME / Let's Encrypt registration";
    };
  };

  config = lib.mkIf cfg.enable {
    services.caddy = {
      enable = true;
      email = cfg.email;
    };

    networking.firewall.allowedTCPPorts = [ 80 443 ];
  };
}

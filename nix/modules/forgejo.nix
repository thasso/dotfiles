{ config, lib, ... }:
let
  cfg = config.services.my-forgejo;
in {
  options.services.my-forgejo = {
    enable = lib.mkEnableOption "Forgejo git hosting (self-hosted GitHub replacement)";
    domain = lib.mkOption {
      type = lib.types.str;
      description = "Public domain name (used for ROOT_URL, DOMAIN and cookies)";
      example = "git.example.com";
    };
    port = lib.mkOption {
      type = lib.types.port;
      default = 3000;
      description = "Port Forgejo's HTTP server listens on (localhost only; Caddy proxies to it)";
    };
  };

  config = lib.mkIf cfg.enable {
    services.forgejo = {
      enable = true;
      # SQLite is plenty for a single-user personal instance; the module
      # creates and manages the DB under stateDir automatically.
      database.type = "sqlite3";
      lfs.enable = true;

      settings = {
        server = {
          DOMAIN = cfg.domain;
          ROOT_URL = "https://${cfg.domain}/";
          # Bind to localhost only — Caddy terminates TLS and reverse-proxies.
          HTTP_ADDR = "127.0.0.1";
          HTTP_PORT = cfg.port;
        };
        # Personal instance: no open sign-ups. The admin user is created
        # out-of-band via the forgejo CLI after first activation.
        service.DISABLE_REGISTRATION = true;
      };
    };
  };
}

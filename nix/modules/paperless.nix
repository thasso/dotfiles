{ config, lib, ... }:
let
  cfg = config.services.my-paperless;
in {
  options.services.my-paperless = {
    enable = lib.mkEnableOption "Paperless-ngx document management";
    domain = lib.mkOption {
      type = lib.types.str;
      description = "Public domain name for Paperless (used for ALLOWED_HOSTS and CSRF)";
      example = "paperless.example.com";
    };
    port = lib.mkOption {
      type = lib.types.port;
      default = 28981;
      description = "Port Paperless listens on (localhost only)";
    };
    dataDir = lib.mkOption {
      type = lib.types.str;
      default = "/var/lib/paperless";
      description = "Directory for Paperless data, media, and consumption";
    };
  };

  config = lib.mkIf cfg.enable {
    sops.secrets.paperless_admin_password = {
      owner = "paperless";
      group = "paperless";
    };
    sops.secrets.paperless_secret_key = {
      owner = "paperless";
      group = "paperless";
    };

    services.paperless = {
      enable = true;
      port = cfg.port;
      dataDir = cfg.dataDir;
      settings = {
        PAPERLESS_URL = "https://${cfg.domain}";
        PAPERLESS_ALLOWED_HOSTS = cfg.domain;
        PAPERLESS_CORS_ALLOWED_HOSTS = "https://${cfg.domain}";
        PAPERLESS_OCR_LANGUAGE = "deu+eng";
        PAPERLESS_TIME_ZONE = config.time.timeZone;
        PAPERLESS_ADMIN_USER = "admin";
        PAPERLESS_ADMIN_PASSWORD = config.sops.secrets.paperless_admin_password.path;
        PAPERLESS_SECRET_KEY = config.sops.secrets.paperless_secret_key.path;
      };
    };
  };
}

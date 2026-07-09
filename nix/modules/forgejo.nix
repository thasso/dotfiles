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
    sshPort = lib.mkOption {
      type = lib.types.port;
      default = 2222;
      description = ''
        Port for Forgejo's built-in SSH server (git-over-SSH). Not 22, which
        belongs to the host's sshd. Advertised in clone URLs. The listener
        binds all interfaces; restrict external reachability at the firewall.
      '';
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

          # git-over-SSH via Forgejo's built-in server (authenticates by SSH
          # key against the Forgejo account — no `git` unix user needed).
          START_SSH_SERVER = true;
          SSH_PORT = cfg.sshPort;
          SSH_LISTEN_PORT = cfg.sshPort;
          # Accept the conventional `git@` login name on the built-in server
          # (defaults to RUN_USER = "forgejo"). SSH_USER — the name shown in
          # clone URLs — defaults to this, so URLs read `git@` too. Still
          # key-authenticated; no `git` unix account involved.
          BUILTIN_SSH_SERVER_USER = "git";
        };
        # Personal instance: no open sign-ups. The admin user is created
        # out-of-band via the forgejo CLI after first activation.
        service.DISABLE_REGISTRATION = true;

        # Forgejo Actions (CI). DEFAULT_ACTIONS_URL defaults to "github", so
        # `uses: actions/checkout@v4` etc. resolve from github.com.
        actions.ENABLED = true;
      };
    };
  };
}

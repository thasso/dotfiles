{ config, lib, pkgs, ... }:
let
  cfg = config.services.my-caddy;
in {
  options.services.my-caddy = {
    enable = lib.mkEnableOption "Caddy reverse proxy with automatic HTTPS";
    email = lib.mkOption {
      type = lib.types.str;
      description = "Email for ACME / Let's Encrypt registration";
    };
    acmeDnsProvider = lib.mkOption {
      type = lib.types.nullOr (lib.types.enum [ "hetzner" ]);
      default = null;
      description = ''
        DNS provider for the ACME DNS-01 challenge. When null (default), Caddy
        uses the HTTP-01 challenge, which needs the box to be publicly reachable
        on port 80 (the immobox model). Set to a provider to use DNS-01 instead:
        certs are proven by writing a TXT record via the provider API, so it
        works behind NAT / on a private tailnet and supports wildcard certs
        (the devbox model).
      '';
    };
    dnsTokenSecret = lib.mkOption {
      type = lib.types.nullOr lib.types.str;
      default = null;
      description = ''
        Name of the sops secret holding the DNS provider API token. Required
        when acmeDnsProvider is set. Exposed to Caddy as the HETZNER_API_TOKEN
        environment variable via a sops template.
      '';
    };
  };

  config = lib.mkIf cfg.enable (lib.mkMerge [
    {
      services.caddy = {
        enable = true;
        email = cfg.email;
      };
      networking.firewall.allowedTCPPorts = [ 80 443 ];
    }

    # ── DNS-01 via the Hetzner Cloud DNS API ────────────────────────────
    (lib.mkIf (cfg.acmeDnsProvider == "hetzner") {
      assertions = [{
        assertion = cfg.dnsTokenSecret != null;
        message = "services.my-caddy.dnsTokenSecret must be set when acmeDnsProvider is used.";
      }];

      # caddy-dns/hetzner v2 targets the Hetzner Cloud DNS API and needs a
      # Hetzner Cloud API token. The hash covers the plugin's vendored Go deps;
      # bump it alongside the plugin version (get it from a failing build).
      services.caddy.package = pkgs.caddy.withPlugins {
        plugins = [ "github.com/caddy-dns/hetzner/v2@v2.0.1" ];
        hash = "sha256-BSTuZx5Em2hAQ2+mGj02IAwgLUV6sE77RRffpbyapHc=";
      };

      # Explicit ACME (Let's Encrypt) issuer with the Hetzner DNS-01 challenge.
      # propagation_delay is essential here: the zone is served by Hetzner's
      # legacy multi-nameserver setup, so the challenge TXT record takes a while
      # to appear on all authoritative servers. Without the delay, Let's Encrypt
      # validates too early and fails with "No/Incorrect TXT record found".
      # Using a single explicit issuer also drops the noisy ZeroSSL fallback.
      services.caddy.globalConfig = ''
        cert_issuer acme {
          dns hetzner {env.HETZNER_API_TOKEN}
          propagation_delay 120s
          propagation_timeout 300s
        }
      '';

      # Feed the token to Caddy's unit from sops (never on disk in plaintext).
      sops.secrets.${cfg.dnsTokenSecret} = { };
      sops.templates."caddy-dns.env".content =
        "HETZNER_API_TOKEN=${config.sops.placeholder.${cfg.dnsTokenSecret}}";
      systemd.services.caddy.serviceConfig.EnvironmentFile =
        config.sops.templates."caddy-dns.env".path;
    })
  ]);
}

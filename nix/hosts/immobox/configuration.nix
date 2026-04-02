{ config, pkgs, ... }:

{
  imports = [
    ./hardware-configuration.nix
    ../../modules/common.nix
    ../../modules/hetzner-network.nix
    ../../modules/paperless.nix
    ../../modules/caddy.nix
  ];

  # Workaround for https://github.com/NixOS/nix/issues/8502
  services.logrotate.checkConfig = false;

  # Boot
  boot.tmp.cleanOnBoot = true;
  zramSwap.enable = true;

  # Network
  networking.hostName = "immobox";
  hetzner.networking = {
    enable = true;
    ipv4 = "91.99.157.222";
    ipv6 = "2a01:4f8:c012:9a37::1";
    ipv6LinkLocal = "fe80::9000:7ff:fe78:153a";
    mac = "92:00:07:78:15:3a";
  };

  # SSH hardening
  services.openssh.settings = {
    PermitRootLogin = "prohibit-password";
    PasswordAuthentication = false;
  };
  users.users.thasso.openssh.authorizedKeys.keys = [
    "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIG+CLIkUMfm+8w4AFuVES+o9z124opVlyRfTbwUxwiUV"
  ];
  users.users.root.openssh.authorizedKeys.keys = [
    "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIG+CLIkUMfm+8w4AFuVES+o9z124opVlyRfTbwUxwiUV"
  ];

  # Firewall
  networking.firewall.enable = true;

  # Secrets
  sops.defaultSopsFile = ../../secrets/immobox.yaml;
  sops.age.sshKeyPaths = [ "/etc/ssh/ssh_host_ed25519_key" ];

  # Caddy reverse proxy
  services.my-caddy = {
    enable = true;
    email = "thasso@gmail.com"; # TODO: replace with your actual email
  };

  # Paperless-ngx
  services.my-paperless = {
    enable = true;
    domain = "paperless.example.com"; # TODO: replace with your actual domain
  };

  # Wire Paperless into Caddy
  services.caddy.virtualHosts."paperless.example.com".extraConfig = ''
    reverse_proxy localhost:${toString config.services.my-paperless.port}
  '';

  system.stateVersion = "23.11";
}

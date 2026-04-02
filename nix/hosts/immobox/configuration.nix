{ config, pkgs, ... }:

{
  imports = [
    ../../modules/hetzner-base.nix
    ../../modules/paperless.nix
    ../../modules/caddy.nix
  ];

  # Network
  networking.hostName = "immobox";

  hetzner.disk = {
    enable = true;
    device = "/dev/sda";
  };

  hetzner.networking = {
    enable = true;
    ipv4 = "178.104.109.60";
    ipv6 = "2a01:4f8:c2c:7bf8::2";
    ipv6LinkLocal = "fe80::9000:7ff:fe7d:8df1";
    mac = "92:00:07:7d:8d:f1";
  };

  users.users.thasso.openssh.authorizedKeys.keys = [
    "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIG+CLIkUMfm+8w4AFuVES+o9z124opVlyRfTbwUxwiUV"
  ];
  users.users.root.openssh.authorizedKeys.keys = [
    "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIG+CLIkUMfm+8w4AFuVES+o9z124opVlyRfTbwUxwiUV"
  ];
  # Secrets
  sops.defaultSopsFile = ../../secrets/immobox.yaml;
  sops.age.sshKeyPaths = [ "/etc/ssh/ssh_host_ed25519_key" ];

  # Caddy reverse proxy
  services.my-caddy = {
    enable = true;
    email = "thasso.griebel@gmail.com";
  };

  # Paperless-ngx
  services.my-paperless = {
    enable = true;
    domain = "docs.griebel-immobilien.de"; # TODO: replace with your actual domain
  };

  # Wire Paperless into Caddy
  services.caddy.virtualHosts."docs.griebel-immobilien.de".extraConfig = ''
    reverse_proxy localhost:${toString config.services.my-paperless.port}
  '';

  system.stateVersion = "23.11";
}

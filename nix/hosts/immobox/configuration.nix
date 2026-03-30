{ config, pkgs, ... }:

{
  imports = [
    ./hardware-configuration.nix
    ../../modules/common.nix
    ../../modules/hetzner-network.nix
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

  system.stateVersion = "23.11";
}

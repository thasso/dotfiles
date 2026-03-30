{ config, pkgs, ... }:

{
  imports = [
    ../../modules/hetzner-base.nix
  ];

  networking.hostName = "testbox";

  hetzner.networking = {
    enable = true;
    ipv4 = "138.199.157.235";
    ipv6 = "2a01:4f8:c17:98fe::2";
    ipv6LinkLocal = "fe80::9000:7ff:fe78:8839";
    mac = "92:00:07:78:88:39";
  };

  hetzner.disk = {
    enable = true;
    device = "/dev/sda";
  };

  users.users.thasso.openssh.authorizedKeys.keys = [
    "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIG+CLIkUMfm+8w4AFuVES+o9z124opVlyRfTbwUxwiUV"
  ];
  users.users.root.openssh.authorizedKeys.keys = [
    "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIG+CLIkUMfm+8w4AFuVES+o9z124opVlyRfTbwUxwiUV"
  ];

  system.stateVersion = "24.11";
}

{ config, pkgs, ... }:

{
  # Enable flakes
  nix.settings.experimental-features = [ "nix-command" "flakes" ];

  # Networking
  networking.hostName = "macbox";

  # User
  users.users.thasso = {
    home = "/Users/thasso";
    shell = pkgs.zsh;
  };
  programs.zsh.enable = true;

  # Secrets (sops config kept for future use / other secrets)
  sops.defaultSopsFile = ../../secrets/macbox.yaml;
  sops.age.sshKeyPaths = [ "/etc/ssh/ssh_host_ed25519_key" ];

  # Packages
  nixpkgs.config.allowUnfree = true;
  environment.systemPackages = [
    pkgs.zsh
    (pkgs.writeShellScriptBin "jira" ''
      export JIRA_API_TOKEN="$(${pkgs._1password-cli}/bin/op read 'op://Private/Jira API Token Castlabs/password')"
      export JIRA_API_USER="$(${pkgs._1password-cli}/bin/op read 'op://Private/Jira API Token Castlabs/username')"
      exec ${pkgs.jira-cli-go}/bin/jira "$@"
    '')
  ];

  # Enable tailscale VPN
  # services.tailscale.enable = true;

  # Used for backwards compatibility
  system.stateVersion = 6;
}

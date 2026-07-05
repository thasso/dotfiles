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

  # GitHub PAT for npm auth against GitHub Packages (read at runtime in shell).
  # Lives in common.yaml so other dev hosts can reuse it; owned by the user
  # since the build runs as us, not root.
  sops.secrets.github_token = {
    owner = "thasso";
    sopsFile = ../../secrets/common.yaml;
  };

  # Work around nix-darwin's generated manual still passing the removed
  # nixos-render-docs --toc-depth flag with current nixpkgs.
  documentation.enable = false;
  system.tools.darwin-uninstaller.enable = false;

  # Packages
  nixpkgs.config.allowUnfree = true;
  nixpkgs.config.android_sdk.accept_license = true;
  environment.systemPackages = [
    pkgs.zsh
    (pkgs.writeShellScriptBin "jira" ''
      export JIRA_API_TOKEN="$(${pkgs._1password-cli}/bin/op read 'op://jira-cli/Jira API Token Castlabs/password')"
      export JIRA_API_USER="$(${pkgs._1password-cli}/bin/op read 'op://jira-cli/Jira API Token Castlabs/username')"
      exec ${pkgs.jira-cli-go}/bin/jira "$@"
    '')
  ];

  # Enable tailscale VPN
  # services.tailscale.enable = true;

  # Used for backwards compatibility
  system.stateVersion = 6;
}

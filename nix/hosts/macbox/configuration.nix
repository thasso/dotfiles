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

  # Packages
  nixpkgs.config.allowUnfree = true;
  environment.systemPackages = with pkgs; [
    zsh
  ];

  # Enable tailscale VPN
  # services.tailscale.enable = true;

  # Used for backwards compatibility
  system.stateVersion = 6;
}

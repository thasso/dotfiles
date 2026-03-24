{ config, pkgs, ... }:

{
  imports = [
    ./hardware-configuration.nix
  ];

  # Bootloader
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;

  # enable flakes
  nix.settings.experimental-features = [ "nix-command" "flakes" ];

  # Basic networking
  networking.hostName = "limabox";
  networking.networkmanager.enable = true;

  # timezone
  time.timeZone = "Europe/Berlin";

  # Internationalisation properties.
  i18n.defaultLocale = "en_US.UTF-8";
  i18n.extraLocaleSettings = {
    LC_ADDRESS = "de_DE.UTF-8";
    LC_IDENTIFICATION = "de_DE.UTF-8";
    LC_MEASUREMENT = "de_DE.UTF-8";
    LC_MONETARY = "de_DE.UTF-8";
    LC_NAME = "de_DE.UTF-8";
    LC_NUMERIC = "de_DE.UTF-8";
    LC_PAPER = "de_DE.UTF-8";
    LC_TELEPHONE = "de_DE.UTF-8";
    LC_TIME = "de_DE.UTF-8";
  };

  # Define a user account.
  users.users.thasso = {
    isNormalUser = true;
    extraGroups = [ "networkmanager" "wheel" ];
    shell = pkgs.zsh;
  };
  programs.zsh.enable = true;

  # Packages
  nixpkgs.config.allowUnfree = true;
  environment.systemPackages = with pkgs; [
    zsh
  ];

  security.sudo.wheelNeedsPassword = false;

  # Enable SSH
  services.openssh.enable = true;
  networking.firewall.allowedTCPPorts = [ 22 ];

  # leave this as it is
  system.stateVersion = "25.11";
}

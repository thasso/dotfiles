{ config, modulesPath, pkgs, lib, nixos-lima, ... }:

{
  imports = [
    (modulesPath + "/profiles/qemu-guest.nix")
    nixos-lima.nixosModules.lima
  ];

  # Lima guest agent
  services.lima.enable = true;

  # Bootloader (Lima uses GRUB, not systemd-boot)
  boot.loader.grub = {
    device = "nodev";
    efiSupport = true;
    efiInstallAsRemovable = true;
  };
  boot.kernelPackages = pkgs.linuxPackages_latest;

  # Filesystems matching the Lima image layout
  fileSystems."/" = {
    device = "/dev/disk/by-label/nixos";
    autoResize = true;
    fsType = "ext4";
    options = [ "noatime" "nodiratime" "discard" ];
  };
  fileSystems."/boot" = {
    device = lib.mkForce "/dev/vda1";
    fsType = "vfat";
  };

  # Lima host mounts (managed by lima-init, declared here so systemd doesn't fight them)
  fileSystems."/tmp/lima" = {
    device = "mount0";
    fsType = "virtiofs";
    options = [ "rw" ];
  };

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

  # User is created imperatively by lima-init from cloud-init data.
  # We still need a minimal declaration for Home Manager.
  users.mutableUsers = true;
  users.users.thasso = {
    isNormalUser = true;
    home = "/home/thasso.linux";
    extraGroups = [ "networkmanager" "wheel" ];
    shell = pkgs.zsh;
  };
  users.groups.thasso = {};
  programs.zsh.enable = true;

  # Packages
  nixpkgs.config.allowUnfree = true;
  # Ghostty terminfo so $TERM=xterm-ghostty works over SSH
  environment.enableAllTerminfo = true;

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

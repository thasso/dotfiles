{ config, modulesPath, pkgs, lib, nixos-lima, ... }:

{
  imports = [
    (modulesPath + "/profiles/qemu-guest.nix")
    nixos-lima.nixosModules.lima
    ../../modules/common.nix
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

  # Networking
  networking.hostName = "limabox";
  networking.networkmanager.enable = true;

  # User overrides for Lima
  users.mutableUsers = true;
  users.users.thasso = {
    home = "/home/thasso.linux";
    extraGroups = [ "networkmanager" "wheel" ];
  };
  users.groups.thasso = {};

  # Packages
  nixpkgs.config.allowUnfree = true;
  # Ghostty terminfo so $TERM=xterm-ghostty works over SSH
  environment.enableAllTerminfo = true;

  # leave this as it is
  system.stateVersion = "25.11";
}

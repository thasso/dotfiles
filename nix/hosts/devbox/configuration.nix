{ config, pkgs, ... }:

{
  imports = [
    ./hardware-configuration.nix
    ../../modules/common.nix
  ];

  # Bootloader (BIOS/GRUB — bare-metal AMD box, no EFI)
  boot.loader.grub.enable = true;
  boot.loader.grub.device = "/dev/nvme1n1";
  boot.loader.grub.useOSProber = false;

  # Networking
  networking.hostName = "devbox";
  networking.networkmanager.enable = true;
  users.users.thasso.extraGroups = [ "networkmanager" "wheel" ];

  # Desktop (GNOME on X11/Wayland via GDM)
  services.xserver.enable = true;
  services.displayManager.gdm.enable = true;
  services.desktopManager.gnome.enable = true;
  services.xserver.xkb = {
    layout = "us";
    variant = "";
  };

  # Printing
  services.printing.enable = true;

  # Sound (PipeWire)
  services.pulseaudio.enable = false;
  security.rtkit.enable = true;
  services.pipewire = {
    enable = true;
    alsa.enable = true;
    alsa.support32Bit = true;
    pulse.enable = true;
  };

  # Firefox
  programs.firefox.enable = true;

  # Packages
  nixpkgs.config.allowUnfree = true;
  nixpkgs.config.android_sdk.accept_license = true;

  # Tailscale VPN
  services.tailscale.enable = true;
  services.tailscale.openFirewall = true;

  # First install of this machine was NixOS 26.05 — leave as is.
  system.stateVersion = "26.05";
}

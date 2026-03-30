{ modulesPath, ... }:
{
  imports = [
    (modulesPath + "/profiles/qemu-guest.nix")
    ./common.nix
    ./hetzner-network.nix
    ./hetzner-disk.nix
  ];

  # Workaround for https://github.com/NixOS/nix/issues/8502
  services.logrotate.checkConfig = false;

  boot.tmp.cleanOnBoot = true;
  zramSwap.enable = true;

  boot.loader = {
    efi.efiSysMountPoint = "/boot";
    grub = {
      efiSupport = true;
      efiInstallAsRemovable = true;
      device = "nodev";
    };
  };

  boot.initrd.availableKernelModules = [ "ata_piix" "uhci_hcd" "xen_blkfront" "virtio_pci" "virtio_scsi" ];
  boot.initrd.kernelModules = [ "nvme" ];

  # SSH hardening
  services.openssh.settings = {
    PermitRootLogin = "prohibit-password";
    PasswordAuthentication = false;
  };

  networking.firewall.enable = true;
}

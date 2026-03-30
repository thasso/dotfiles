{ config, lib, ... }:
let
  cfg = config.hetzner.disk;
in {
  options.hetzner.disk = {
    enable = lib.mkEnableOption "Hetzner Cloud disk layout via disko";
    device = lib.mkOption {
      type = lib.types.str;
      default = "/dev/sda";
      description = "Primary disk device";
    };
  };

  config = lib.mkIf cfg.enable {
    disko.devices.disk.main = {
      device = cfg.device;
      type = "disk";
      content = {
        type = "gpt";
        partitions = {
          boot = {
            size = "512M";
            type = "EF00";
            content = {
              type = "filesystem";
              format = "vfat";
              mountpoint = "/boot";
            };
          };
          root = {
            size = "100%";
            content = {
              type = "filesystem";
              format = "ext4";
              mountpoint = "/";
            };
          };
        };
      };
    };
  };
}

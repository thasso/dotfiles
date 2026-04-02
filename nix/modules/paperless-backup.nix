{ config, lib, pkgs, ... }:
let
  cfg = config.services.my-paperless-backup;
  paperlessCfg = config.services.my-paperless;
  dataDir = paperlessCfg.dataDir;
in {
  options.services.my-paperless-backup = {
    enable = lib.mkEnableOption "Paperless-ngx backup to Hetzner Storage Box via restic";
    repository = lib.mkOption {
      type = lib.types.str;
      description = "Restic repository URL (sftp:user@host:path)";
      example = "sftp:u123456-sub1@u123456-sub1.your-storagebox.de:paperless";
    };
    sftpHost = lib.mkOption {
      type = lib.types.str;
      description = "user@host for the SFTP connection (used in ssh command)";
      example = "u123456-sub1@u123456-sub1.your-storagebox.de";
    };
  };

  config = lib.mkIf cfg.enable {
    sops.secrets.restic_repo_password = { };
    sops.secrets.storagebox_ssh_key = {
      mode = "0600";
    };

    services.restic.backups.paperless = {
      repository = cfg.repository;
      passwordFile = config.sops.secrets.restic_repo_password.path;
      initialize = true;

      paths = [
        "${dataDir}/media"
        "${dataDir}/data"
        "${dataDir}/db-backup.sqlite3"
      ];

      extraOptions = [
        "sftp.command='ssh -p 23 -i ${config.sops.secrets.storagebox_ssh_key.path} -o StrictHostKeyChecking=accept-new ${cfg.sftpHost} -s sftp'"
      ];

      pruneOpts = [
        "--keep-daily 7"
        "--keep-weekly 4"
        "--keep-monthly 6"
      ];

      backupPrepareCommand = ''
        ${pkgs.sqlite}/bin/sqlite3 "${dataDir}/db.sqlite3" ".backup '${dataDir}/db-backup.sqlite3'"
      '';

      backupCleanupCommand = ''
        rm -f "${dataDir}/db-backup.sqlite3"
      '';

      timerConfig = {
        OnCalendar = "02:00";
        Persistent = true;
        RandomizedDelaySec = "1h";
      };
    };
  };
}

{ config, lib, pkgs, ... }:
let
  cfg = config.services.my-personal-assistant-backup;
  # The assistant keeps all durable state under DATA_DIR: the KB git repo,
  # session stores, settings + integration secrets, and one SQLite DB.
  dbPath = "${cfg.dataDir}/app.sqlite3";
  # Staging dir for the consistent SQLite snapshot, outside DATA_DIR and in the
  # backup's ReadWritePaths (the job runs with ProtectSystem=strict).
  stagingDir = "/var/lib/personal-assistant-backup";
  dbSnapshot = "${stagingDir}/app.sqlite3";
in {
  options.services.my-personal-assistant-backup = {
    enable = lib.mkEnableOption "Personal assistant DATA_DIR backup to a local Borg repository";
    dataDir = lib.mkOption {
      type = lib.types.str;
      description = "The assistant DATA_DIR to back up (matches services.personal-assistant.dataDir).";
      example = "/home/thasso/pa-data";
    };
    repository = lib.mkOption {
      type = lib.types.str;
      description = ''
        Local Borg repository path, on a data disk. Being a local path, the job
        gains RequiresMountsFor on it, so it never runs (nor writes into an empty
        mountpoint) if the disk is not mounted.
      '';
      example = "/mnt/bulk/backups/personal-assistant";
    };
    startAt = lib.mkOption {
      type = lib.types.str;
      default = "*-*-* 02:45:00";
      description = "systemd OnCalendar expression for the daily backup.";
    };
  };

  config = lib.mkIf cfg.enable {
    systemd.tmpfiles.rules = [ "d ${stagingDir} 0700 root root -" ];

    # The repo lives on a `nofail` disk that may mount after systemd-tmpfiles
    # runs; create the repo dir after the mount and before the backup.
    systemd.services.personal-assistant-backup-init = {
      description = "Ensure the personal-assistant Borg repository directory exists";
      before = [ "borgbackup-job-personal-assistant.service" ];
      requiredBy = [ "borgbackup-job-personal-assistant.service" ];
      unitConfig.RequiresMountsFor = [ cfg.repository ];
      serviceConfig.Type = "oneshot";
      script = "mkdir -p ${lib.escapeShellArg cfg.repository}";
    };

    services.borgbackup.jobs.personal-assistant = {
      repo = cfg.repository;
      # First-level backup on a local disk — no encryption, hence no secret.
      encryption.mode = "none";
      compression = "auto,zstd";
      doInit = true;

      paths = [
        cfg.dataDir # KB git repo, sessions, settings/secrets, DB snapshot dir
        stagingDir # the consistent DB snapshot from preHook
      ];

      # Back up the DB via the online-backup snapshot instead of the live WAL
      # files, and skip regenerable KB caches.
      exclude = [
        dbPath
        "${dbPath}-wal"
        "${dbPath}-shm"
        "${cfg.dataDir}/knowledge/.kb/generated"
      ];

      # Consistent point-in-time DB snapshot via SQLite's online-backup API —
      # safe while the assistant is running, no downtime.
      readWritePaths = [ stagingDir ];
      preHook = ''
        ${pkgs.sqlite}/bin/sqlite3 ${lib.escapeShellArg dbPath} ".backup '${dbSnapshot}'"
      '';
      postHook = ''
        rm -f ${lib.escapeShellArg dbSnapshot}
      '';

      # One snapshot per day, keep the last week.
      prune.keep.daily = 7;

      startAt = cfg.startAt;
      persistentTimer = true; # catch up a missed run if the box was off
    };
  };
}

{ config, lib, pkgs, ... }:
let
  cfg = config.services.my-forgejo-backup;
  stateDir = config.services.forgejo.stateDir;
  dbPath = "${stateDir}/data/forgejo.db";
  # Staging dir for the consistent SQLite snapshot. Kept outside Forgejo's own
  # dirs and added to the backup's ReadWritePaths (the service is sandboxed
  # with ProtectSystem=strict, so the preHook can't write just anywhere).
  stagingDir = "/var/lib/forgejo-backup";
  dbSnapshot = "${stagingDir}/forgejo.db";
in {
  options.services.my-forgejo-backup = {
    enable = lib.mkEnableOption "Forgejo backup to a local Borg repository";
    repository = lib.mkOption {
      type = lib.types.str;
      description = ''
        Local Borg repository path, on a data disk. Because it is a local path,
        the generated service automatically gains RequiresMountsFor on it, so
        the backup never runs (nor writes into an empty mountpoint) if the disk
        is not mounted.
      '';
      example = "/mnt/bulk/backups/forgejo";
    };
    startAt = lib.mkOption {
      type = lib.types.str;
      default = "*-*-* 02:30:00";
      description = "systemd OnCalendar expression for the daily backup.";
    };
  };

  config = lib.mkIf cfg.enable {
    systemd.tmpfiles.rules = [ "d ${stagingDir} 0700 root root -" ];

    # The repo lives on a `nofail` disk that may mount after systemd-tmpfiles
    # runs, so the module's own tmpfiles-created repo dir can end up shadowed
    # under the mountpoint. Create it after the mount and before the backup, so
    # the sandboxed job's ReadWritePaths namespace setup finds it.
    systemd.services.forgejo-backup-init = {
      description = "Ensure the Forgejo Borg repository directory exists";
      before = [ "borgbackup-job-forgejo.service" ];
      requiredBy = [ "borgbackup-job-forgejo.service" ];
      unitConfig.RequiresMountsFor = [ cfg.repository ];
      serviceConfig.Type = "oneshot";
      script = "mkdir -p ${lib.escapeShellArg cfg.repository}";
    };

    services.borgbackup.jobs.forgejo = {
      repo = cfg.repository;
      # First-level backup on a local disk — no encryption, hence no secret.
      encryption.mode = "none";
      compression = "auto,zstd";
      doInit = true;

      paths = [
        "${stateDir}/repositories" # git repositories
        "${stateDir}/data" # LFS, attachments, avatars, packages, ...
        "${stateDir}/custom" # app.ini + generated secret_key/tokens (critical)
        stagingDir # the consistent DB snapshot from preHook
      ];

      # Exclude the live WAL-mode DB (backed up via the snapshot instead) and
      # transient scratch.
      exclude = [
        dbPath
        "${dbPath}-wal"
        "${dbPath}-shm"
        "${stateDir}/data/tmp"
      ];

      # Consistent point-in-time DB snapshot via SQLite's online-backup API —
      # safe while Forgejo is running, no downtime.
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

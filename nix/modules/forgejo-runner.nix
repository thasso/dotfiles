{ config, lib, pkgs, ... }:
let
  cfg = config.services.my-forgejo-runner;
in {
  options.services.my-forgejo-runner = {
    enable = lib.mkEnableOption "Forgejo Actions runner (forgejo-runner, Docker backend)";
    url = lib.mkOption {
      type = lib.types.str;
      description = "Base URL of the Forgejo instance to register with.";
      example = "https://git.example.com";
    };
    name = lib.mkOption {
      type = lib.types.str;
      default = config.networking.hostName;
      description = "Runner name shown in Forgejo.";
    };
    tokenSecret = lib.mkOption {
      type = lib.types.str;
      default = "forgejo_runner_token";
      description = ''
        Name of the sops secret holding the runner registration token. Consumed
        as a systemd EnvironmentFile, so it is rendered as TOKEN=<value> via a
        sops template.
      '';
    };
    labels = lib.mkOption {
      type = lib.types.listOf lib.types.str;
      default = [
        "ubuntu-latest:docker://catthehacker/ubuntu:act-22.04"
        "ubuntu-22.04:docker://catthehacker/ubuntu:act-22.04"
        # Host execution for Nix jobs (`runs-on: native`): builds land in the
        # host /nix/store (cached, reusable). Runs as the unprivileged
        # gitea-runner user; the nix daemon performs the store writes.
        "native:host"
      ];
      description = ''
        Runner labels mapping job runs-on names to execution backends. Docker
        labels ("<name>:docker://<image>") make the module wire the runner's
        service into the docker group automatically. "native:host" runs jobs
        directly on the host with the packages from hostPackages below.
      '';
    };
    capacity = lib.mkOption {
      type = lib.types.ints.positive;
      default = 2;
      description = ''
        How many jobs this runner executes concurrently (runner.capacity).
        forgejo-runner defaults to 1, which serializes jobs that a workflow
        declares as independent: the personal-assistant CI runs its `check`
        job (docker) and its `nix-build` job (native) back to back, so the
        ~24s nix build sits on the critical path for no reason. 2 lets them
        overlap; the box has 24 cores, so the contention is nix build vs. a
        node test suite rather than anything CPU-starved.
      '';
    };
  };

  config = lib.mkIf cfg.enable {
    sops.secrets.${cfg.tokenSecret} = { };
    sops.templates."forgejo-runner-token.env".content =
      "TOKEN=${config.sops.placeholder.${cfg.tokenSecret}}";

    services.gitea-actions-runner = {
      # Use Forgejo's official runner rather than gitea's act_runner. The
      # NixOS module is named generically for historical reasons.
      package = pkgs.forgejo-runner;
      instances.${cfg.name} = {
        enable = true;
        name = cfg.name;
        url = cfg.url;
        tokenFile = config.sops.templates."forgejo-runner-token.env".path;
        labels = cfg.labels;
        # Everything left unset here keeps forgejo-runner's own defaults; the
        # generated config.yaml is the daemon's whole configuration, not an
        # overlay on top of `generate-config`.
        settings.runner.capacity = cfg.capacity;
        # Packages available to `native:host` jobs. nix is what makes
        # `nix build`/`nix flake check` work on the host runner.
        hostPackages = with pkgs; [
          nix
          bashInteractive
          coreutils
          curl
          gawk
          gitMinimal
          gnused
          nodejs
          wget
        ];
      };
    };

    # Let `native:host` jobs read the system journal (the runner user is a
    # DynamicUser, so grant the group on the service, not the user). The CI
    # deploy job and the Ops workflow stream unit logs into the job output.
    systemd.services."gitea-runner-${cfg.name}".serviceConfig.SupplementaryGroups =
      [ "systemd-journal" ];
  };
}

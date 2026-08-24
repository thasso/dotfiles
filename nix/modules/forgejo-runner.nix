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
      default = 4;
      description = ''
        How many jobs this runner executes concurrently (runner.capacity).
        forgejo-runner defaults to 1, which serializes jobs that a workflow
        declares as independent: the personal-assistant CI runs its `check`
        job (docker) and its `nix-build` job (native) back to back, so the
        ~24s nix build sits on the critical path for no reason.

        The capacity is a single pool shared by every label, so 2 was enough
        for one workflow's fan-out but not for two at once: a pair of docker
        jobs could fill both slots and leave a `native:host` job queued behind
        them. 4 keeps a second workflow (a push landing while a PR builds)
        from waiting on the first. The box has 24 cores, so the contention is
        nix build vs. a node test suite rather than anything CPU-starved.
      '';
    };
    cacheProxyPort = lib.mkOption {
      type = lib.types.port;
      default = 34567;
      description = ''
        Port of the runner's Actions cache proxy, the endpoint jobs reach
        through ACTIONS_CACHE_URL.

        forgejo-runner defaults this to 0, meaning a fresh random high port on
        every start. Jobs run in containers, so they cross the host firewall to
        reach it, and a firewall rule has to name a port — with a random one
        there is nothing to open, every `actions/cache` step times out after
        ~20s and restores nothing. Pinning the port is what makes the rule
        below expressible.
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
        settings.cache.proxy_port = cfg.cacheProxyPort;
        # Only used to build the ACTIONS_CACHE_URL handed to jobs. docker0's
        # address is fixed for the lifetime of the host and answers both from
        # containers on any docker bridge and from `native:host` jobs, unlike
        # the runner's own guess (an outbound-facing host address that
        # containers cannot route to). `cache.port` — the cache server the
        # proxy fronts — stays random on purpose: it is host-local and must not
        # become reachable.
        settings.cache.host = "172.17.0.1";
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

    # Reach the cache proxy from job containers. The nixos-fw chain ends in a
    # log-refuse, so container traffic to the host is dropped by default.
    #
    # The rule is scoped by source range rather than by interface: with
    # `container.network` unset the runner builds a per-job network, so packets
    # arrive on a br-<id> interface that only exists while the job does — an
    # `interfaces."docker0"` rule never matches them. 172.16.0.0/12 is docker's
    # private pool, which covers those bridges while excluding both the LAN
    # (192.168.1.0/24) and the tailnet (100.x), so nothing outside this box
    # gains reach. What makes exposing the proxy to local containers acceptable
    # at all is that it authenticates: each workflow gets a single-use signed
    # URL, so a neighbouring container holding no token gets nothing.
    networking.firewall.extraCommands = ''
      iptables -I nixos-fw 1 -s 172.16.0.0/12 -p tcp \
        --dport ${toString cfg.cacheProxyPort} -j nixos-fw-accept
    '';
    networking.firewall.extraStopCommands = ''
      iptables -D nixos-fw -s 172.16.0.0/12 -p tcp \
        --dport ${toString cfg.cacheProxyPort} -j nixos-fw-accept || true
    '';

    # Let `native:host` jobs read the system journal (the runner user is a
    # DynamicUser, so grant the group on the service, not the user). The CI
    # deploy job and the Ops workflow stream unit logs into the job output.
    systemd.services."gitea-runner-${cfg.name}".serviceConfig.SupplementaryGroups =
      [ "systemd-journal" ];
  };
}

{ config, lib, options, pkgs, ... }:

let
  dotfiles = "/home/thasso/dotfiles";
  # Escape hatch for a stuck stop/drain: agent-spawned stray processes can
  # survive SIGTERM and hold the service's stop (and any deploy waiting on the
  # restart) for the full TimeoutStopSec. SIGKILL the whole cgroup, then
  # restart: `sudo systemctl start personal-assistant-force-restart.service`.
  paForceRestart = pkgs.writeShellScript "pa-force-restart" ''
    set -u
    export PATH=/run/current-system/sw/bin:$PATH
    echo "SIGKILLing personal-assistant cgroup"
    systemctl kill --kill-whom=all --signal=SIGKILL personal-assistant.service || true
    # Let the kill and the unit's own Restart=on-failure logic settle before
    # issuing the restart, otherwise the fresh instance can catch the SIGKILL.
    sleep 2
    systemctl reset-failed personal-assistant.service 2>/dev/null || true
    echo "Restarting personal-assistant"
    systemctl restart personal-assistant.service
    # Exit code reflects the real outcome: wait for a stable active state
    # (RestartSec=5 means a raced first start may need one more cycle).
    for _ in $(seq 1 30); do
      state=$(systemctl is-active personal-assistant.service) || true
      if [ "$state" = "active" ]; then
        echo "personal-assistant is active"
        exit 0
      fi
      sleep 2
    done
    echo "personal-assistant did not reach active state: $state" >&2
    systemctl status --no-pager -l personal-assistant.service || true
    exit 1
  '';
in
{
  imports = [
    ./hardware-configuration.nix
    ../../modules/common.nix
    ../../modules/caddy.nix
    ../../modules/forgejo.nix
    ../../modules/forgejo-backup.nix
    ../../modules/forgejo-runner.nix
    ../../modules/personal-assistant-backup.nix
  ];

  # Bootloader (BIOS/GRUB — bare-metal AMD box, no EFI)
  boot.loader.grub.enable = true;
  boot.loader.grub.device = "/dev/disk/by-id/nvme-Samsung_SSD_980_PRO_1TB_S5GXNF0R717108H";
  boot.loader.grub.useOSProber = false;
  boot.loader.grub.enableCryptodisk = true;
  boot.initrd.secrets."/root.key" = "/etc/luks-keys/root.key";
  boot.initrd.luks.devices."cryptroot" = {
    device = "/dev/disk/by-uuid/b4ee92cf-fda2-47b0-8eaa-a07434267299";
    keyFile = "/root.key";
  };

  # Every personal-assistant deploy mints a system generation (~8/day, 334 of
  # them in the first six weeks), and each one becomes a GRUB menu entry that
  # grub-mkconfig has to re-emit on every switch. Cap the menu; this does not
  # delete generations, so `nixos-rebuild --rollback` still reaches older ones.
  boot.loader.grub.configurationLimit = 10;

  # Networking
  networking.hostName = "devbox";
  networking.networkmanager.enable = true;
  users.users.thasso.extraGroups = [ "networkmanager" "wheel" "docker" ];

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

  # Run generic dynamically linked Linux binaries, including uv-managed Python
  # and common PyPI wheels.
  programs.nix-ld = {
    enable = true;
    libraries = with pkgs; [
      stdenv.cc.cc.lib # libstdc++ and libgcc_s for native wheels
      zlib
      openssl
      cairo # libcairo.so.2 for CairoSVG (SVG-to-PNG export)
    ];
  };

  # Packages
  nixpkgs.config.allowUnfree = true;
  nixpkgs.config.android_sdk.accept_license = true;

  # Tailscale VPN
  services.tailscale.enable = true;
  services.tailscale.openFirewall = true;

  # Exit node: tailnet clients that opt in (`tailscale set --exit-node=devbox`)
  # send their internet traffic out through devbox's home uplink. Only clients
  # that select it are affected — advertising is just an offer, and it needs a
  # one-time approval in the admin console (Machines → devbox → Edit route
  # settings → Use as exit node).
  #
  # "server" enables IPv4 *and* IPv6 forwarding. The v4 sysctl happens to be on
  # already because Docker sets it, but v6 forwarding is off, which would break
  # IPv6 egress for exit-node clients. This only touches boot.kernel.sysctl, so
  # it does not restart tailscaled.
  services.tailscale.useRoutingFeatures = "server";
  # Declarative advertisement. extraUpFlags is not an option here: it only
  # applies when authKeyFile is set, and this node was authenticated
  # interactively. extraSetFlags instead runs a `tailscale set` oneshot
  # (tailscaled-set.service) ordered after tailscaled, which is idempotent and
  # only mutates prefs — the daemon keeps running and existing sessions survive.
  services.tailscale.extraSetFlags = [ "--advertise-exit-node" ];

  # Tailscale recommends this on subnet routers / exit nodes; without it the
  # forwarding path is noticeably slower and tailscaled raises a health warning.
  # Guarded by `|| true` so a driver that lacks the knob can't fail activation.
  systemd.services.tailscale-gro = {
    description = "Tune UDP GRO forwarding on the uplink for Tailscale routing";
    after = [ "network-online.target" "sys-subsystem-net-devices-enp6s0.device" ];
    wants = [ "network-online.target" ];
    wantedBy = [ "multi-user.target" ];
    serviceConfig = {
      Type = "oneshot";
      RemainAfterExit = true;
    };
    script = ''
      ${pkgs.ethtool}/bin/ethtool -K enp6s0 rx-udp-gro-forwarding on rx-gro-list off || true
    '';
  };

  # ── Containers (Docker) ───────────────────────────────────
  # Rootful Docker; thasso is in the `docker` group above so it can drive
  # containers without sudo. (Note: docker-group access is root-equivalent.)
  # Data-root stays on the root SSD for now; relocating to /mnt/fast is a
  # later step (that disk is `nofail`, so it'd need a mount dependency).
  virtualisation.docker = {
    enable = true;
    autoPrune = {
      enable = true;
      dates = "weekly";
    };
  };

  # ── Nix store hygiene ─────────────────────────────────────
  # Hardlink byte-identical files across store paths. This box deploys the
  # personal assistant several times a day and each build is a ~750 MB output,
  # so without dedup every deploy costs its full size. Measured before turning
  # this on: the bundled `claude` binary existed as 581 distinct inodes for
  # 70 GB, 273 of which were identical copies of the same 262 MB file.
  #
  # Only applies to paths added after activation; folding what is already in
  # the store is a one-off `nix store optimise` run by hand.
  nix.settings.auto-optimise-store = true;

  # Deliberately NO nix.gc here yet: PR previews reference their build only
  # from a plain env file rather than a GC root, and the pnpmDeps FOD is not
  # rooted either, so an automatic collection would break live previews and
  # force CI to refetch the whole npm dependency set. Revisit once the
  # personal-assistant flake roots both.

  # Secrets (sops-nix). Host key derives the age identity for decryption.
  # Secret declarations live in the modules that consume them (e.g. Caddy).
  sops.defaultSopsFile = ../../secrets/devbox.yaml;
  sops.age.sshKeyPaths = [ "/etc/ssh/ssh_host_ed25519_key" ];

  # ── Self-hosted services ──────────────────────────────────
  # Caddy reverse proxy. DNS-01 via Hetzner Cloud DNS gets real Let's Encrypt
  # certs without any inbound reachability — the box stays private on the
  # tailnet (service subdomains resolve to its Tailscale IP).
  services.my-caddy = {
    enable = true;
    email = "thasso.griebel@gmail.com";
    acmeDnsProvider = "hetzner";
    dnsTokenSecret = "hetzner_dns_token";
  };

  # Forgejo — personal GitHub replacement, reachable at https://git.codecluster.net
  services.my-forgejo = {
    enable = true;
    domain = "git.codecluster.net";
  };

  # Wire Forgejo into Caddy.
  services.caddy.virtualHosts."git.codecluster.net".extraConfig = ''
    reverse_proxy localhost:${toString config.services.my-forgejo.port}
  '';

  # Expose Forgejo's git-over-SSH port to the tailnet only (loopback is always
  # allowed, so local pushes from devbox itself keep working regardless).
  networking.firewall.interfaces."tailscale0".allowedTCPPorts =
    [ config.services.my-forgejo.sshPort ];

  # Resolve git.codecluster.net to loopback on devbox itself. devbox is both
  # the server and a daily-driver client, so this lets it push/pull (and browse
  # the web UI) over 127.0.0.1 without depending on Tailscale being up. Other
  # tailnet devices still resolve the public DNS record to the Tailscale IP.
  networking.hosts."127.0.0.1" = [ "git.codecluster.net" "pa.codecluster.net" ];

  # Forgejo first-level backup: daily Borg snapshot to the bulk data disk.
  # Unencrypted (local disk), so no secret; keeps the last 7 days.
  services.my-forgejo-backup = {
    enable = true;
    repository = "/mnt/bulk/backups/forgejo";
  };

  # Forgejo Actions runner (forgejo-runner, Docker backend). Talks to Forgejo
  # over loopback (git.codecluster.net → 127.0.0.1) with a valid cert.
  services.my-forgejo-runner = {
    enable = true;
    url = "https://git.codecluster.net";
  };

  # ── Personal assistant ────────────────────────────────────
  # User-space service (runs as thasso) so it has real $HOME/filesystem access
  # and inherits logged-in credentials (~/.claude subscription, pi providers).
  # Reachable tailnet-only at https://pa.codecluster.net via Caddy.
  #
  # Integration credentials are attached to the unit below as their own
  # environment file and never enter Nix-rendered environment data.
  sops.secrets = {
    personal_assistant_token = { };
    personal_assistant_google_oauth_client_secret = { };
    personal_assistant_tempo_oauth_client_secret = { };
    personal_assistant_slack_client_secret = { };
    personal_assistant_slack_app_token = { };
  };
  sops.templates."personal-assistant-token.env" = {
    owner = "root";
    group = "root";
    mode = "0400";
    content = "ASSISTANT_TOKEN=${config.sops.placeholder.personal_assistant_token}";
  };
  sops.templates."personal-assistant-integrations.env" = {
    owner = "root";
    group = "root";
    mode = "0400";
    content = ''
      ASSISTANT_GOOGLE_OAUTH_CLIENT_SECRET=${config.sops.placeholder.personal_assistant_google_oauth_client_secret}
      ASSISTANT_TEMPO_OAUTH_CLIENT_SECRET=${config.sops.placeholder.personal_assistant_tempo_oauth_client_secret}
      ASSISTANT_SLACK_CLIENT_SECRET=${config.sops.placeholder.personal_assistant_slack_client_secret}
      ASSISTANT_SLACK_APP_TOKEN=${config.sops.placeholder.personal_assistant_slack_app_token}
    '';
  };

  services.personal-assistant = {
    enable = true;
    # The module no longer defaults the user, the preview domain, or any
    # deployment value; this host names its own.
    user = "thasso";
    dataDir = "/home/thasso/pa-data";
    publicBaseUrl = "https://pa.codecluster.net";
    allowedOrigins = [ "https://pa.codecluster.net" ];
    tokenFile = config.sops.templates."personal-assistant-token.env".path;

    # No package configuration at all. The agents' toolbox is this host's: the
    # service PATH is /etc/profiles/per-user/thasso and /run/current-system/sw,
    # which already carry claude, pi and tmux from home.packages — both hash-free
    # paths, so a `make update` cannot move the unit and restart the service. The
    # module has no extraPackages option precisely so that stays true; add a tool
    # to home.packages or environment.systemPackages instead. The app declares
    # what it needs in its own config/host-tools.json and checks it at startup.
    # (claude and pi are not needed as CLIs anyway: the server drives them as
    # libraries and resolves the Claude binary from its own node_modules.)

    # Local CPU-only composer dictation is an optional HOST capability: the app
    # ships no recognizer and no weights and only discovers what it is pointed
    # at, so BOTH halves are this host's. sherpa-onnx is in systemPackages below
    # and the weights are nix/pkgs/stt-model-*.nix — our package, our URL, our
    # hash. Nothing here reaches into the app flake. Point this elsewhere, or
    # leave it empty, and the server just reports `configured: false` with a
    # reason and disables the mic button.
    #
    # A store path, and still churn-free: that package is a fetchzip, i.e. a
    # fixed-output derivation whose path is a function of its name and output
    # hash alone. `make update` cannot move it, so it cannot move the unit.
    speech.modelDir = "${pkgs.stt-model-parakeet-tdt-600m-v2-int8}";

  }
  # Contain runaway agents (2026-09-30: a 35 GB pytest in this unit caused a
  # global OOM and systemd stopped the whole service). Best effort, not a
  # guarantee: see the app's docs/deployment.md. Budget against 47 GiB of RAM:
  #   production MemoryMax            26 GiB
  #   host baseline (forgejo, docker,  2.5 GiB (steady state, systemd-cgtop)
  #     caddy, tailscale, session)
  #   kernel, unreclaimable memory     2 GiB
  #   CI containers and nix builds     8 GiB  (docker peaked 5.5 GB)
  #   total                          38.5 GiB, ~8.5 GiB slack
  # 26G leaves ~24 GiB for agent work above the server and CLIs (~2 GiB). The
  # unit carries ~6 GiB without runaways (uncapped vitest peaked ~20 GB before
  # VITEST_MAX_WORKERS=4). swapMax keeps a runaway from thrashing the 51 GB swap
  # partition before it is killed. MemoryHigh stays unset: it throttles the
  # server too and never kills. Guarded until the pin reaches a release with the
  # option.
  // lib.optionalAttrs (options.services.personal-assistant ? memory) {
    memory = {
      max = "26G";
      swapMax = "4G";
    };
  }
  # This deployment's static, nonsecret integration config. The app package now
  # ships a neutral config/app.json, so these values live here and reach
  # production and previews as ASSISTANT_CONFIG. Their secrets stay in the sops
  # env files above. Guarded on the option existing so this can land before the
  # pin reaches a release that has it; the guard can go once it has.
  // lib.optionalAttrs (options.services.personal-assistant ? settings) {
    settings = {
      google.oauthClientId = "602439754432-ln37ljctk9ckcaf5iptflmfsh5jf997o.apps.googleusercontent.com";
      jira.host = "castlabs.atlassian.net";
      tempo.oauthClientId = "VxXpYBRLTMwa37FFz5T0tK8kbDeZYnT87fIc5VtcHUt3n6sukT";
      slack = {
        workspaceHost = "castlabs.slack.com";
        teamId = "T02FDHUPM";
        clientId = "2523606803.10788939582292";
      };
    };
  };

  # Restarts belong to deploys, not to activations. The unit is now free of
  # host store paths, so in principle only a release can change it — but keep
  # this as the belt: a hand-edited pin, a module change, or anything else that
  # does move the unit must not interrupt an agent turn as a side effect of an
  # unrelated `make switch`. A release deploy restarts the service explicitly
  # (see the personalAssistant input in flake.nix), so a restart means "a
  # release shipped" and nothing else.
  systemd.services.personal-assistant = {
    restartIfChanged = false;
    serviceConfig.EnvironmentFile = lib.mkForce [
      config.sops.templates."personal-assistant-token.env".path
      config.sops.templates."personal-assistant-integrations.env".path
    ];
  };

  # Dev tunnels are served at dev-<name>.pa.codecluster.net (Caddy route below).
  systemd.services.personal-assistant.environment.ASSISTANT_DEV_TUNNEL_DOMAIN =
    "pa.codecluster.net";
  # Cap glibc per-thread arena bloat in the Node server (see personal-assistant
  # worktree-performance investigation).
  systemd.services.personal-assistant.environment.MALLOC_ARENA_MAX = "2";
  # Agents inherit this environment; uncapped, a workspace `pnpm run test` runs
  # three vitest suites at cores-1 workers each (~69 here), which peaked the
  # cgroup at ~20 GB. Vitest 4 reads VITEST_MAX_WORKERS natively.
  systemd.services.personal-assistant.environment.VITEST_MAX_WORKERS = "4";

  # Wire the assistant into Caddy (tailnet-only, cert via DNS-01).
  services.caddy.virtualHosts."pa.codecluster.net".extraConfig = ''
    reverse_proxy localhost:${toString config.services.personal-assistant.port}
  '';

  # Dev tunnels: dev-<name>.pa.codecluster.net reaches the assistant, which
  # routes by Host. Wildcard DNS *.pa.codecluster.net → the devbox tailscale IP
  # (Hetzner DNS, set manually); the cert comes from the global DNS-01 issuer.
  services.caddy.virtualHosts."*.pa.codecluster.net".logFormat = ''
    output file ${config.services.caddy.logDir}/access-wildcard.pa.codecluster.net.log
  '';
  services.caddy.virtualHosts."*.pa.codecluster.net".extraConfig = ''
    @devtunnels header_regexp Host ^dev-[a-z0-9][a-z0-9-]*\.pa\.codecluster\.net(:[0-9]+)?$
    handle @devtunnels {
      reverse_proxy localhost:${toString config.services.personal-assistant.port}
    }
  '';

  systemd.services.personal-assistant-force-restart = {
    description = "Force-restart personal-assistant (SIGKILL stuck cgroup, then restart)";
    restartIfChanged = false;
    serviceConfig = {
      Type = "oneshot";
      ExecStart = "${paForceRestart}";
    };
  };

  # Daily Borg snapshot of the assistant's DATA_DIR (KB, sessions, settings +
  # integration secrets, SQLite DB) to the bulk disk, mirroring the Forgejo
  # backup. Consistent DB snapshot via SQLite online-backup; keeps 7 days.
  services.my-personal-assistant-backup = {
    enable = true;
    dataDir = config.services.personal-assistant.dataDir;
    repository = "/mnt/bulk/backups/personal-assistant";
  };

  # Remote dev box — must stay reachable, so never auto-suspend/sleep.
  # Mask the sleep targets so nothing (GNOME/GDM idle, logind) can suspend it.
  systemd.targets.sleep.enable = false;
  systemd.targets.suspend.enable = false;
  systemd.targets.hibernate.enable = false;
  systemd.targets.hybrid-sleep.enable = false;

  # Power measurement tools (`sudo powertop`, `sensors`) for profiling idle draw.
  # sherpa-onnx is here rather than in services.personal-assistant because the
  # assistant treats the recognizer as a host tool it discovers on PATH: the app
  # ships no recognizer package, so this host is what makes dictation possible.
  # Updating it is an ordinary host update — it cannot move the assistant's unit.
  # librsvg provides rsvg-convert, the SVG-to-PNG fallback when CairoSVG is absent.
  environment.systemPackages = with pkgs; [
    powertop
    lm_sensors
    sherpa-onnx
    librsvg
  ];

  environment.etc."crypttab".text = ''
    fast UUID=8923accb-bfff-4b7d-b0ee-0c73b5ff1de6 /etc/luks-keys/fast.key luks
    bulk UUID=7dd30a97-80d9-4b21-a9e6-12710339d42d /etc/luks-keys/bulk.key luks
  '';

  # Playwright looks for `channel: "chrome"` at the hardcoded Linux path
  # /opt/google/chrome/chrome, which doesn't exist on NixOS (the Nix Chrome —
  # installed in home/thasso.nix — lives in the store, wrapped as
  # google-chrome-stable on PATH). Symlink the expected path to the Nix binary
  # so Playwright picks it up transparently. `L+` recreates the link on every
  # activation, so it always tracks the current google-chrome build.
  systemd.tmpfiles.rules = [
    "L+ /opt/google/chrome/chrome - - - - ${pkgs.google-chrome}/bin/google-chrome-stable"
  ];

  # ── Extra data disks (added 2026-07-08) ───────────────────
  # bulk: Samsung 860 EVO 2TB SATA SSD (/dev/sda1)
  # fast: Samsung 970 PRO 512GB NVMe   (/dev/nvme0n1p1)
  # nofail so a missing/failed disk never blocks boot on this headless box.
  fileSystems."/mnt/bulk" = {
    device = "/dev/mapper/bulk";
    fsType = "ext4";
    options = [ "nofail" "x-systemd.device-timeout=30s" ];
  };
  fileSystems."/mnt/fast" = {
    device = "/dev/mapper/fast";
    fsType = "ext4";
    options = [ "nofail" "x-systemd.device-timeout=30s" ];
  };

  swapDevices = [
    {
      device = "/dev/disk/by-id/nvme-Samsung_SSD_980_PRO_1TB_S5GXNF0R717108H-part2";
      randomEncryption.enable = true;
    }
  ];

  # ── Idle power reduction ──────────────────────────────────
  # amd_pstate active mode gives power-profiles-daemon a real EPP backend
  # (on acpi-cpufreq it falls back to "placeholder" and GNOME's power-saver
  # profile is inert). CPPC is present on this Ryzen 9 3900X, so it works.
  # CPU-only, so it's safe for connectivity.
  boot.kernelParams = [ "amd_pstate=active" ];

  # NOTE: pcie_aspm.policy=powersave + powertop autotune stalled the NIC's
  # PCIe link and broke SSH (banner-exchange timeouts). Removed. Revisit only
  # with console access to test, and ideally scope ASPM per-device.
  # powerManagement.powertop.enable = true;

  # First install of this machine was NixOS 26.05 — leave as is.
  system.stateVersion = "26.05";
}

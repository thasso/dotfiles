{ config, pkgs, ... }:

let
  dotfiles = "/home/thasso/dotfiles";
  paRepo = "https://git.codecluster.net/thasso/personal-assistant.git";
  devTunnelCaddyRoute = pkgs.writeText "50-dev-tunnels.caddy" ''
    @devtunnels header_regexp Host ^dev-[a-z0-9][a-z0-9-]*\.pa\.codecluster\.net(:[0-9]+)?$
    handle @devtunnels {
    ${"\t"}reverse_proxy localhost:${toString config.services.personal-assistant.port}
    }
  '';

  # Release deploy — the ONLY thing that changes which assistant version devbox
  # runs. Rewrites the personalAssistant pin in the dotfiles checkout to a
  # published release tag, re-locks it, switches, and commits the bump (never
  # pushes). Because the pin lands in flake.nix + flake.lock, a later plain
  # `make switch` reproduces exactly this deployment rather than rolling it back,
  # and `git log nix/flake.lock` is the deploy history.
  #
  # Started by the app repo's Release workflow as
  # personal-assistant-release@<tag>.service; usable by hand as
  # `sudo pa-release v1.2.3`.
  paRelease = pkgs.writeShellScriptBin "pa-release" ''
    set -euo pipefail
    export PATH=${pkgs.git}/bin:${pkgs.gnused}/bin:${pkgs.coreutils}/bin:${pkgs.util-linux}/bin:/run/current-system/sw/bin:$PATH
    # Root's own (writable) HOME for the safe.directory write and nix's eval
    # cache; repo-touching steps get thasso's HOME via asUser below.
    export HOME=/root
    # Root evaluates thasso's checkout; avoid git "dubious ownership".
    git config --global --add safe.directory ${dotfiles} || true

    tag="''${1:-}"
    # Anything that reaches sed, a URL or a commit message is validated first:
    # once for shape, once for charset. The polkit rule constrains the instance
    # name as well, but this is the check that actually guards the script.
    case "$tag" in
      v[0-9]*.[0-9]*.[0-9]*) ;;
      *) echo "Not a release tag: '$tag' (expected vMAJOR.MINOR.PATCH)" >&2; exit 1 ;;
    esac
    case "$tag" in
      *[!v0-9.]*) echo "Release tag has unexpected characters: '$tag'" >&2; exit 1 ;;
    esac

    # Every repo operation runs as the owner, so nothing in thasso's checkout
    # ends up root-owned. Only the switch itself needs root.
    asUser() {
      runuser -u thasso -- env HOME=/home/thasso "$@"
    }

    # Annotated tags need peeling (^{}) to reach the commit; fall back to the
    # plain ref so a lightweight tag still resolves.
    refs="$(git ls-remote ${paRepo} "refs/tags/$tag" "refs/tags/$tag^{}")"
    rev="$(printf '%s\n' "$refs" | sed -n 's|^\([0-9a-f]\{40\}\)[[:space:]].*\^{}$|\1|p' | head -n1)"
    if [ -z "$rev" ]; then
      rev="$(printf '%s\n' "$refs" | sed -n 's|^\([0-9a-f]\{40\}\)[[:space:]].*|\1|p' | head -n1)"
    fi
    if [ -z "$rev" ]; then
      echo "No such release tag on the remote: $tag" >&2
      exit 1
    fi
    # The line the Release workflow greps back out of this unit's journal.
    echo "Deploying personal-assistant $tag ($rev)"

    # The pin lives in files a human edits. Never clobber work in progress.
    if ! asUser git -C ${dotfiles} diff --quiet -- nix/flake.nix nix/flake.lock ||
       ! asUser git -C ${dotfiles} diff --cached --quiet -- nix/flake.nix nix/flake.lock; then
      echo "nix/flake.nix or nix/flake.lock has uncommitted changes; refusing to rewrite the pin." >&2
      exit 1
    fi

    asUser sed -i "s|\(personal-assistant\.git?ref=refs/tags/\)v[0-9][0-9.]*|\1$tag|" ${dotfiles}/nix/flake.nix
    # --refresh so a cached tag→rev mapping cannot ship the wrong commit.
    asUser nix flake update personalAssistant --refresh --flake ${dotfiles}/nix
    if ! grep -q "\"rev\": \"$rev\"" ${dotfiles}/nix/flake.lock; then
      echo "flake.lock does not record $tag ($rev) after re-locking; aborting." >&2
      asUser git -C ${dotfiles} checkout -- nix/flake.nix nix/flake.lock
      exit 1
    fi

    if ! nixos-rebuild switch --flake ${dotfiles}/nix#devbox; then
      echo "nixos-rebuild switch failed; restoring the previous pin." >&2
      asUser git -C ${dotfiles} checkout -- nix/flake.nix nix/flake.lock
      exit 1
    fi

    # Commit only the pin: any other work in the tree stays untouched, and this
    # never pushes. Committed BEFORE the restart because the switch has already
    # happened — the system is on $tag whether or not the restart goes well, and
    # a tree that disagreed with the running system would be the worse state.
    asUser git -C ${dotfiles} commit -q \
      -m "Deploy personal-assistant $tag" \
      -m "personalAssistant pinned to refs/tags/$tag ($rev)." \
      -- nix/flake.nix nix/flake.lock

    # The switch does NOT restart the service: personal-assistant.service is
    # restartIfChanged = false (see below), so activation never interrupts a
    # running agent turn. Deploying is exactly when a restart IS wanted, so ask
    # for it here. The drain can take up to TimeoutStopSec (1h); the Release
    # workflow's `systemctl start --wait` timeout covers this whole script.
    echo "Restarting personal-assistant onto $tag"
    systemctl restart personal-assistant.service
    echo "Deployed $tag, committed the pin (not pushed), and restarted the service."
  '';

  # Manual escape hatch: switch onto the CURRENT remote main without touching
  # the pin, for a hotfix you have not cut a release for. Deliberately leaves
  # flake.lock alone, so the next plain `make switch` returns to the pinned
  # release — that asymmetry is the point, not an oversight.
  paDeploy = pkgs.writeShellScriptBin "pa-deploy" ''
    set -euo pipefail
    export PATH=${pkgs.git}/bin:${pkgs.gawk}/bin:/run/current-system/sw/bin:$PATH
    # Pin HOME to root's (writable) home so the safe.directory write and nix's
    # eval cache land somewhere deterministic regardless of who ran sudo.
    export HOME=/root
    # Root reads thasso's checkout; avoid git "dubious ownership" during eval.
    ${pkgs.git}/bin/git config --global --add safe.directory /home/thasso/dotfiles || true

    assistantRev="$(${pkgs.git}/bin/git ls-remote https://git.codecluster.net/thasso/personal-assistant.git refs/heads/main | ${pkgs.gawk}/bin/awk '{print $1}')"
    if [ -z "$assistantRev" ]; then
      echo "Could not resolve latest personal-assistant main revision" >&2
      exit 1
    fi
    echo "Deploying personalAssistant rev $assistantRev"

    # The flake lives in the repo's nix/ subdirectory (the git root is one up).
    # Pin the floating app input to the exact remote main rev and refresh Nix's
    # flake metadata so deploys cannot silently reuse a stale ref=main cache.
    exec nixos-rebuild switch \
      --refresh \
      --flake /home/thasso/dotfiles/nix#devbox \
      --override-input personalAssistant "git+https://git.codecluster.net/thasso/personal-assistant.git?ref=main&rev=$assistantRev"
  '';

  # Escape hatch for a stuck stop/drain: agent-spawned stray processes can
  # survive SIGTERM and hold the service's stop (and any deploy waiting on the
  # restart) for the full TimeoutStopSec. SIGKILL the whole cgroup, then
  # restart. Started by the repo's Ops workflow (force-restart) or manually:
  # `sudo systemctl start personal-assistant-force-restart.service`.
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
  boot.loader.grub.device = "/dev/nvme1n1";
  boot.loader.grub.useOSProber = false;
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
  # The shared auth token is injected into the SPA at serve time (not baked into
  # the build); supply it via a sops secret rendered as ASSISTANT_TOKEN=<value>.
  sops.secrets.personal_assistant_token = { };
  sops.templates."personal-assistant-token.env".content =
    "ASSISTANT_TOKEN=${config.sops.placeholder.personal_assistant_token}";

  services.personal-assistant = {
    enable = true;
    dataDir = "/home/thasso/pa-data";
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

    # Per-PR preview deployments at pr-<n>.pa.codecluster.net, seeded from a
    # consistent clone of the prod dataDir and reusing the shared token above.
    # The Forgejo runner's pr-deploy/pr-teardown jobs start the pa-pr-deploy@/
    # pa-pr-teardown@ oneshots (authorized by the polkit rule the module adds).
    prDeployments = {
      enable = true;
      repoUrl = "https://git.codecluster.net/thasso/personal-assistant.git";
    };
  };

  # Restarts belong to deploys, not to activations. The unit is now free of
  # host store paths, so in principle only a release can change it — but keep
  # this as the belt: a hand-edited pin, a module change, or anything else that
  # does move the unit must not interrupt an agent turn as a side effect of an
  # unrelated `make switch`. pa-release issues an explicit `systemctl restart`
  # after its switch, so a restart means "a release shipped" and nothing else.
  # Same shape the app module uses for pa-pr@ previews, restarted only by
  # `pa-pr deploy`.
  systemd.services.personal-assistant.restartIfChanged = false;

  # Production alone owns dev-tunnel hostnames. Setting this directly on the
  # unit keeps it out of the extra environment inherited by PR previews.
  systemd.services.personal-assistant.environment.ASSISTANT_DEV_TUNNEL_DOMAIN =
    "pa.codecluster.net";

  # Reload Caddy on activation when the generated route changes. The route is
  # imported inside pa-pr's existing wildcard site via routes/*.caddy below.
  systemd.services.caddy.reloadTriggers = [ devTunnelCaddyRoute ];

  # Wire the assistant into Caddy (tailnet-only, cert via DNS-01).
  services.caddy.virtualHosts."pa.codecluster.net".extraConfig = ''
    reverse_proxy localhost:${toString config.services.personal-assistant.port}
  '';

  # PR preview routing: import the per-PR site files pa-pr writes/removes. Each
  # pr-<n>.pa.codecluster.net gets its own cert automatically via the global
  # DNS-01 issuer. Requires a wildcard DNS record *.pa.codecluster.net → the
  # devbox tailscale IP (Hetzner DNS, set manually). The import dir is pre-created
  # by a tmpfiles rule (see below) so the glob is valid before the first deploy.
  services.caddy.extraConfig = ''
    import ${config.services.personal-assistant.prDeployments.caddyImportDir}/*.caddy
  '';

  # CD: the app repo's `release` job triggers this rebuild. Runner host jobs
  # run with NoNewPrivileges, so setuid sudo is blocked; instead the runner asks
  # systemd (over D-Bus) to start a fixed root oneshot, authorized by a narrow
  # polkit rule. The command is fixed in the unit, so the runner can only start
  # it — it gets no other root, and nixos-rebuild is atomic (a failing build
  # never switches). thasso can still run `sudo pa-release` / `sudo pa-deploy`
  # interactively.
  # These oneshots DRIVE the switch/restart they would be restarted by, so an
  # activation must never touch a running instance: when the unit file changes
  # (any nixpkgs bump moves the script's store path), switch-to-configuration
  # puts the unit in its stop list and the in-flight deploy SIGTERMs ITSELF
  # mid-activation, then gets re-started while forgejo/caddy are still down and
  # fails on `git ls-remote` (502). A oneshot picks up its new definition on the
  # next start anyway, so skipping it during activation costs nothing.
  #
  # The instance name is the release tag: personal-assistant-release@v1.2.3.
  # Templated rather than fixed because the tag IS the deploy target now, and
  # pa-release re-validates %i rather than trusting the polkit pattern.
  systemd.services."personal-assistant-release@" = {
    description = "Pin personal-assistant to release %i and switch devbox onto it";
    restartIfChanged = false;
    serviceConfig = {
      Type = "oneshot";
      ExecStart = "${paRelease}/bin/pa-release %i";
    };
  };

  # Manual-only hotfix path: ships current main without moving the pin. Kept as
  # a unit so `systemctl start` semantics (journal, serialization) match the
  # release path; no polkit rule, so CI cannot reach it.
  systemd.services.personal-assistant-deploy = {
    description = "Rebuild devbox so personal-assistant tracks the latest main";
    restartIfChanged = false;
    serviceConfig = {
      Type = "oneshot";
      ExecStart = "${paDeploy}/bin/pa-deploy";
    };
  };

  systemd.services.personal-assistant-force-restart = {
    description = "Force-restart personal-assistant (SIGKILL stuck cgroup, then restart)";
    restartIfChanged = false;
    serviceConfig = {
      Type = "oneshot";
      ExecStart = "${paForceRestart}";
    };
  };

  # The runner hosts the deploy job that triggers activation, so restarting it
  # during that activation force-kills its own in-flight job
  # ([runner].shutdown_timeout=0s) and — with forgejo/caddy restarting in the
  # same batch — the final job status can never be uploaded, leaving the CI run
  # "running" in Forgejo forever even though the deploy succeeded. Let a runner
  # version bump take effect on the next natural restart instead.
  systemd.services.gitea-runner-devbox.restartIfChanged = false;

  # This host authorizes the units this host defines. The assistant module also
  # ships a polkit rule naming the production oneshots, but it cannot be the
  # only one: that rule arrives with the PINNED release, so a newly added unit
  # would be unauthorized until a release carrying its permission is already
  # deployed — which needs the unit to work. Rules are OR'd, so the two coexist;
  # this one is what makes the release unit reachable on a fresh switch.
  #
  # The boundary is a PATTERN, not a name: only a vMAJOR.MINOR.PATCH instance is
  # reachable, and pa-release re-validates %i rather than trusting this regex.
  # personal-assistant-deploy is deliberately absent — shipping unreleased main
  # is a manual decision. (Until the pinned release carries the module change,
  # the module's own rule still grants it; harmless, and it lapses on the next
  # release.)
  security.polkit.enable = true;
  security.polkit.extraConfig = ''
    polkit.addRule(function(action, subject) {
      if (action.id == "org.freedesktop.systemd1.manage-units" &&
          subject.user == "gitea-runner") {
        var unit = action.lookup("unit");
        if (unit == "personal-assistant-force-restart.service" ||
            /^personal-assistant-release@v[0-9]+\.[0-9]+\.[0-9]+\.service$/.test(unit)) {
          return polkit.Result.YES;
        }
      }
    });
  '';

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
  environment.systemPackages = with pkgs; [
    powertop
    lm_sensors
    paDeploy
    paRelease
    sherpa-onnx
  ];

  # Playwright looks for `channel: "chrome"` at the hardcoded Linux path
  # /opt/google/chrome/chrome, which doesn't exist on NixOS (the Nix Chrome —
  # installed in home/thasso.nix — lives in the store, wrapped as
  # google-chrome-stable on PATH). Symlink the expected path to the Nix binary
  # so Playwright picks it up transparently. `L+` recreates the link on every
  # activation, so it always tracks the current google-chrome build.
  systemd.tmpfiles.rules = [
    "L+ /opt/google/chrome/chrome - - - - ${pkgs.google-chrome}/bin/google-chrome-stable"
    # Pre-create the PR-preview Caddy import dir (readable by the caddy user).
    "d ${config.services.personal-assistant.prDeployments.caddyImportDir} 0755 caddy caddy -"
    # Add dev tunnels to the wildcard site's imported routes without touching
    # the pa-pr-managed wildcard or per-preview files.
    "L+ ${config.services.personal-assistant.prDeployments.caddyImportDir}/routes/50-dev-tunnels.caddy - - - - ${devTunnelCaddyRoute}"
  ];

  # ── Extra data disks (added 2026-07-08) ───────────────────
  # bulk: Samsung 860 EVO 2TB SATA SSD (/dev/sda1)
  # fast: Samsung 970 PRO 512GB NVMe   (/dev/nvme0n1p1)
  # nofail so a missing/failed disk never blocks boot on this headless box.
  fileSystems."/mnt/bulk" = {
    device = "/dev/disk/by-uuid/e88550a2-189c-44b5-aefb-0f1802b9052d";
    fsType = "ext4";
    options = [ "nofail" "x-systemd.device-timeout=5s" ];
  };
  fileSystems."/mnt/fast" = {
    device = "/dev/disk/by-uuid/725eda7b-a820-435e-a389-932cba09bc15";
    fsType = "ext4";
    options = [ "nofail" "x-systemd.device-timeout=5s" ];
  };

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

{ config, pkgs, ... }:

let
  # Continuous-deploy command for the personal assistant. Rebuilds this host
  # from the local dotfiles checkout, floating ONLY the personalAssistant input
  # to the latest main (other inputs stay pinned by flake.lock). Run as root via
  # a scoped NOPASSWD sudo rule by the Forgejo runner's `deploy` job on green
  # main. nixos-rebuild is atomic: a failing build never switches, so the running
  # assistant keeps serving.
  paDeploy = pkgs.writeShellScriptBin "pa-deploy" ''
    set -euo pipefail
    export PATH=/run/current-system/sw/bin:$PATH
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
      --override-input personalAssistant "git+https://git.codecluster.net/thasso/personal-assistant.git?rev=$assistantRev"
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
    # Agent CLIs/tools on the service PATH (in-process SDKs read ~/.claude + pi
    # creds; the tmux Claude terminal and pi CLI need the binaries).
    extraPackages = with pkgs; [ claude-code pi-coding-agent tmux ];
  };

  # Wire the assistant into Caddy (tailnet-only, cert via DNS-01).
  services.caddy.virtualHosts."pa.codecluster.net".extraConfig = ''
    reverse_proxy localhost:${toString config.services.personal-assistant.port}
  '';

  # CD: the Forgejo runner's `deploy` job triggers this rebuild. Runner host jobs
  # run with NoNewPrivileges, so setuid sudo is blocked; instead the runner asks
  # systemd (over D-Bus) to start a fixed root oneshot, authorized by a narrow
  # polkit rule. The command is fixed in the unit, so the runner can only start
  # it — it gets no other root, and nixos-rebuild is atomic (a failing build
  # never switches). thasso can still run `sudo pa-deploy` interactively.
  systemd.services.personal-assistant-deploy = {
    description = "Rebuild devbox so personal-assistant tracks the latest main";
    serviceConfig = {
      Type = "oneshot";
      ExecStart = "${paDeploy}/bin/pa-deploy";
    };
  };

  security.polkit.enable = true;
  security.polkit.extraConfig = ''
    polkit.addRule(function(action, subject) {
      if (action.id == "org.freedesktop.systemd1.manage-units" &&
          action.lookup("unit") == "personal-assistant-deploy.service" &&
          subject.user == "gitea-runner") {
        return polkit.Result.YES;
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
  environment.systemPackages = with pkgs; [ powertop lm_sensors paDeploy ];

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

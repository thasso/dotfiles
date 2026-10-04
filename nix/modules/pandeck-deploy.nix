{ config, lib, pkgs, ... }:
let
  cfg = config.services.my-pandeck-deploy;
  unitName = "pandeck-deploy";
  stateDir = "/var/lib/${unitName}";
  mirror = "${stateDir}/pandeck.git";
  # GitHub's published ed25519 host key, pinned so the root fetch never trusts
  # on first use.
  githubKnownHosts = pkgs.writeText "pandeck-deploy-known-hosts" ''
    github.com ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIOMqqnkVzrm0SdG6UOoqKLsabgH5C9okWi0dh2l9GKJl
  '';

  # Root half of `make pandeck`: switches this host onto Pandeck <rev> and
  # queues the app restart. It deliberately trusts nothing the caller controls
  # beyond the commit id:
  #   - It fetches Pandeck itself, with its own read-only deploy key, and only
  #     accepts a commit on main or a release tag's commit. Pandeck's NixOS
  #     module is evaluated as root, so this is what keeps unmerged branch code
  #     from becoming root; branch commits stay a manual `sudo` deploy.
  #   - It rebuilds the dotfiles source the RUNNING system was built from
  #     (cfg.flake, baked in at build time), with only the personalAssistant
  #     input overridden. Edits in the dotfiles checkout, which agents can
  #     write, never reach a root switch through here; they need `make switch`.
  # The restart is --no-block so the caller's own agent turn can end: the
  # unit's ExecStop drains running turns before the new version starts.
  helper = pkgs.writeShellScript "pandeck-deploy-helper" ''
    set -euo pipefail
    export PATH=${lib.makeBinPath [ pkgs.git pkgs.openssh pkgs.util-linux pkgs.coreutils ]}:/run/current-system/sw/bin
    export HOME=${stateDir}

    rev="''${1:-}"
    # The polkit rule constrains the instance name too; this is the check that
    # actually guards the script.
    [[ "$rev" =~ ^[0-9a-f]{40}$ ]] || { echo "Not a full commit sha: '$rev'" >&2; exit 1; }

    # One deploy at a time: two concurrent switches race on the profile.
    exec 9>/run/${unitName}.lock
    flock 9

    export GIT_SSH_COMMAND="ssh -i ${config.sops.secrets.${cfg.deployKeySecret}.path} -o IdentitiesOnly=yes -o StrictHostKeyChecking=yes -o UserKnownHostsFile=${githubKnownHosts}"
    [ -d ${mirror} ] || git init -q --bare ${mirror}
    git -C ${mirror} fetch -q --prune --prune-tags ${cfg.remote} \
      '+refs/heads/main:refs/heads/main' '+refs/tags/*:refs/tags/*'

    ref=""
    if git -C ${mirror} merge-base --is-ancestor "$rev" refs/heads/main 2>/dev/null; then
      ref="main"
    else
      for tag in $(git -C ${mirror} tag -l 'v*' | grep -E '^v[0-9]+\.[0-9]+\.[0-9]+$' || true); do
        if [ "$(git -C ${mirror} rev-parse "$tag^{commit}")" = "$rev" ]; then
          ref="refs/tags/$tag"
          break
        fi
      done
    fi
    [ -n "$ref" ] || { echo "$rev is neither on main nor a release tag; refusing" >&2; exit 1; }

    echo "Deploying Pandeck $(git -C ${mirror} log -1 --format='%h %s' "$rev") ($ref)"
    nixos-rebuild switch \
      --flake '${cfg.flake}#${config.networking.hostName}' \
      --override-input personalAssistant "git+file://${mirror}?ref=$ref&rev=$rev"

    echo "Switched; queued ${cfg.appUnit} restart (it drains running agent turns first)"
    systemctl restart --no-block ${cfg.appUnit}
  '';
in {
  options.services.my-pandeck-deploy = {
    enable = lib.mkEnableOption "agent-startable Pandeck deploys (pandeck-deploy@<sha>.service)";
    flake = lib.mkOption {
      type = lib.types.str;
      description = ''
        Flake reference of the dotfiles source this system is built from, as a
        store path (set from the flake's `self`), so a deploy rebuilds exactly
        the running configuration.
      '';
      example = "path:/nix/store/...-source?dir=nix";
    };
    remote = lib.mkOption {
      type = lib.types.str;
      default = "git@github.com:thasso/pandeck.git";
      description = "Pandeck repository the root helper fetches over SSH.";
    };
    deployKeySecret = lib.mkOption {
      type = lib.types.str;
      default = "pandeck_deploy_key";
      description = "sops secret holding a read-only GitHub deploy key for `remote`.";
    };
    user = lib.mkOption {
      type = lib.types.str;
      description = "User allowed to start pandeck-deploy@<sha>.service without sudo.";
      example = "thasso";
    };
    appUnit = lib.mkOption {
      type = lib.types.str;
      default = "personal-assistant.service";
      description = "The Pandeck server unit restarted after a switch.";
    };
  };

  config = lib.mkIf cfg.enable {
    sops.secrets.${cfg.deployKeySecret} = { };

    systemd.services."${unitName}@" = {
      description = "Switch ${config.networking.hostName} onto Pandeck %i";
      # This unit DRIVES the switch it would be restarted by: an activation must
      # never stop an in-flight deploy. A oneshot picks up a new definition on
      # its next start anyway.
      restartIfChanged = false;
      serviceConfig = {
        Type = "oneshot";
        ExecStart = "${helper} %i";
        StateDirectory = unitName;
        StateDirectoryMode = "0700";
      };
    };

    # Agent sessions cannot sudo, so this is how they deploy: start the unit
    # over D-Bus. Only `start`, only a full-sha instance; the helper re-checks.
    security.polkit.enable = true;
    security.polkit.extraConfig = ''
      polkit.addRule(function(action, subject) {
        if (action.id == "org.freedesktop.systemd1.manage-units" &&
            subject.user == "${cfg.user}" &&
            action.lookup("verb") == "start" &&
            /^${unitName}@[0-9a-f]{40}\.service$/.test(action.lookup("unit"))) {
          return polkit.Result.YES;
        }
      });
    '';
  };
}

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
      ];
      description = ''
        Runner labels mapping job runs-on names to execution backends. Docker
        labels ("<name>:docker://<image>") make the module wire the runner's
        service into the docker group automatically. Add "native:host" for
        Nix-native jobs on the host.
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
      };
    };
  };
}

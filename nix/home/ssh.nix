{ lib, pkgs, ... }:
{
  # SSH client config, managed by home-manager (generates ~/.ssh/config).
  # Shared across macbox + devbox (+ limabox); the only host-specific bit is
  # the 1Password agent, which exists only on macOS.
  programs.ssh = {
    enable = true;
    # Reproduce the hand-written config faithfully: don't let home-manager
    # inject its own `Host *` defaults (ForwardAgent, etc.).
    enableDefaultConfig = false;

    matchBlocks = {
      homelab = {
        hostname = "192.168.1.200";
        user = "root";
      };
      pi = {
        hostname = "192.168.1.3";
        user = "thasso";
      };
      demo-mac = {
        hostname = "192.168.1.101";
        user = "castlabdemos";
        forwardAgent = true;
      };
      "ts.dev" = {
        hostname = "ts.dev.castlabs.com";
        port = 2222;
        user = "runner";
        forwardAgent = true;
      };
      devbox = {
        hostname = "192.168.1.67";
        user = "thasso";
        extraOptions.SetEnv = "TERM=xterm-256color";
      };
      "devbox.ts" = {
        hostname = "100.80.3.49";
        user = "thasso";
        extraOptions.SetEnv = "TERM=xterm-256color";
      };
      immobox = {
        hostname = "178.104.109.60";
        user = "thasso";
        forwardAgent = true;
        extraOptions.SetEnv = "TERM=xterm-256color";
      };

      # Forgejo git-over-SSH. Enables `git@git.codecluster.net:thasso/repo.git`.
      # On devbox the name resolves to loopback (via /etc/hosts); elsewhere it
      # resolves to the Tailscale IP via public DNS.
      "git.codecluster.net" = {
        port = 2222;
        user = "git";
      };
    }
    # macOS only: route SSH auth through the 1Password agent.
    // lib.optionalAttrs pkgs.stdenv.isDarwin {
      "*".extraOptions.IdentityAgent =
        ''"~/Library/Group Containers/2BUA8C4S2C.com.1password/t/agent.sock"'';
    };
  };
}

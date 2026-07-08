{ lib, pkgs, ... }:
{
  # SSH client config, managed by home-manager (generates ~/.ssh/config).
  # Shared across macbox + devbox (+ limabox); the only host-specific bit is
  # the 1Password agent, which exists only on macOS.
  programs.ssh = {
    enable = true;
    # Reproduce the hand-written config faithfully: don't let home-manager
    # inject its own `Host *` defaults (ForwardAgent, AddKeysToAgent, ...).
    enableDefaultConfig = false;

    # Attribute names are `Host` patterns; values use OpenSSH directive names.
    settings = {
      homelab = {
        HostName = "192.168.1.200";
        User = "root";
      };
      pi = {
        HostName = "192.168.1.3";
        User = "thasso";
      };
      demo-mac = {
        HostName = "192.168.1.101";
        User = "castlabdemos";
        ForwardAgent = true;
      };
      "ts.dev" = {
        HostName = "ts.dev.castlabs.com";
        Port = 2222;
        User = "runner";
        ForwardAgent = true;
      };
      devbox = {
        HostName = "192.168.1.67";
        User = "thasso";
        SetEnv = { TERM = "xterm-256color"; };
      };
      "devbox.ts" = {
        HostName = "100.80.3.49";
        User = "thasso";
        SetEnv = { TERM = "xterm-256color"; };
      };
      immobox = {
        HostName = "178.104.109.60";
        User = "thasso";
        ForwardAgent = true;
        SetEnv = { TERM = "xterm-256color"; };
      };

      # Forgejo git-over-SSH. Enables `git@git.codecluster.net:thasso/repo.git`.
      # On devbox the name resolves to loopback (via /etc/hosts); elsewhere it
      # resolves to the Tailscale IP via public DNS.
      "git.codecluster.net" = {
        Port = 2222;
        User = "git";
      };
    }
    # macOS only: route SSH auth through the 1Password agent.
    // lib.optionalAttrs pkgs.stdenv.isDarwin {
      "*".IdentityAgent =
        ''"~/Library/Group Containers/2BUA8C4S2C.com.1password/t/agent.sock"'';
    };
  };
}

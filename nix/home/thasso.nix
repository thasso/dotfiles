{ config, lib, pkgs, meridianPort, ... }:
{
  imports = [ ./base.nix ];

  # ── Dev Environment ──────────────────────────────────────────
  home.sessionVariables = {
    CC = "clang";
    CXX = "clang++";
  } // lib.optionalAttrs pkgs.stdenv.isDarwin {
    SSH_AUTH_SOCK = "$HOME/Library/Group Containers/2BUA8C4S2C.com.1password/t/agent.sock";
    SOPS_AGE_KEY_CMD = "op read 'op://Private/sops-age-key/private_key'";
  };

  # ── Claude Code ────────────────────────────────────────────
  programs.claude-code = lib.mkIf (!pkgs.stdenv.isDarwin) {
    enable = true;
    package = null;
    settings = {
      permissions = {
        defaultMode = "bypassPermissions";
        deny = [
          "Bash(git push)"
          "Bash(git push *)"
        ];
      };
    };
  };

  # ── Ghostty (macOS only) ──────────────────────────────────
  programs.ghostty = lib.mkIf pkgs.stdenv.isDarwin {
    enable = true;
    package = pkgs.ghostty-bin;
    enableZshIntegration = true;
    settings = {
      theme = "Catppuccin Mocha";
      bell-features = "no-system,no-audio,no-attention,no-title,no-border";
      split-divider-color = "#FFFFFF";
      auto-update-channel = "tip";
      macos-titlebar-style = "transparent";
      keybind = [
        "shift+enter=text:\\n"
        "cmd+t=text:\\x02t"
        "cmd+shift+left_bracket=text:\\x02p"
        "cmd+shift+right_bracket=text:\\x02n"
        "cmd+w=text:\\x02&"
        "cmd+r=text:\\x02,"
        "cmd+shift+r=text:\\x02$"
        "cmd+d=text:\\x02%"
        ''cmd+shift+d=text:\x02"''
        "cmd+shift+n=text:\\x02C"
        "cmd+shift+s=text:\\x02s"
        "cmd+alt+left=text:\\x02h"
        "cmd+alt+right=text:\\x02l"
        "cmd+alt+up=text:\\x02k"
        "cmd+alt+down=text:\\x02j"
        "cmd+ctrl+left=text:\\x02\\x1bh"
        "cmd+ctrl+right=text:\\x02\\x1bl"
        "cmd+ctrl+up=text:\\x02\\x1bk"
        "cmd+ctrl+down=text:\\x02\\x1bj"
        "cmd+shift+m=text:\\x02W"
        "cmd+ctrl+shift+t=new_tab"
        "cmd+ctrl+shift+r=prompt_tab_title"
        "cmd+ctrl+shift+left_bracket=previous_tab"
        "cmd+ctrl+shift+right_bracket=next_tab"
      ];
    };
  };

  # ── VS Code (macOS only) ───────────────────────────────────
  programs.vscode = lib.mkIf pkgs.stdenv.isDarwin {
    enable = true;
  };

  # ── OpenCode ────────────────────────────────────────────────
  programs.opencode = {
    enable = true;
    settings = {
      theme = "catppuccin";
      autoupdate = true;
      provider = {
        anthropic = { options = { baseURL = "http://localhost:${toString meridianPort}"; apiKey = "x"; }; };
      };
      permission = {
        external_directory = { "~/.cargo/registry/**" = "allow"; };
        edit = { "~/.cargo/registry/**" = "deny"; };
      } // (if pkgs.stdenv.isDarwin then {
        bash = {
          "git push" = "ask";
          "git merge *" = "ask";
        };
      } else {
        bash = {
          "*" = "allow";
          "git push" = "deny";
          "git push *" = "deny";
        };
      });
    };
    agents = ../../opencode/agent;
    commands = ../../opencode/command;
  };

  # ── OpenCode Plugin (session tracking for meridian proxy) ──
  xdg.configFile."opencode/plugins/claude-max-headers.ts".source =
    ../../opencode/plugins/claude-max-headers.ts;

  # ── Meridian Service (Claude Max Proxy) ─────────────────────
  systemd.user.services.meridian = lib.mkIf (!pkgs.stdenv.isDarwin) {
    Unit.Description = "Meridian - Claude Max Proxy";
    Service = {
      ExecStart = "${pkgs.meridian}/bin/meridian";
      Environment = [
        "CLAUDE_PROXY_PORT=${toString meridianPort}"
        "CLAUDE_PROXY_PASSTHROUGH=1"
        "PATH=${pkgs.claude-code}/bin:${pkgs.nodejs_22}/bin"
      ];
      Restart = "on-failure";
      RestartSec = 5;
    };
    Install.WantedBy = [ "default.target" ];
  };

  # ── Dev Packages ────────────────────────────────────────────
  home.packages = lib.optionals pkgs.stdenv.isDarwin [
    pkgs.google-chrome
    pkgs.raycast
    pkgs.lima
  ] ++ (with pkgs; [
    python314
    pyenv
    jira-cli-go
    tempomat
    awscli2
    claude-code
    sops
    ssh-to-age

    rustup
    clang
    clang-tools
    tree-sitter
    cmake
    go
    golangci-lint
    gogcli
    nodejs
    yarn
    prettier
    prettierd
    meridian
  ]);

  # ── Dev Dotfiles ────────────────────────────────────────────
  home.file = {
    # Meridian launchd agent — managed manually to avoid home-manager's
    # /bin/sh wrapper (which makes the process show as "sh" in Activity Monitor)
    "Library/LaunchAgents/meridian.plist" = lib.mkIf pkgs.stdenv.isDarwin {
      text = lib.generators.toPlist {} {
        Label = "meridian";
        ProgramArguments = [
          "/bin/bash" "-c"
          "/bin/wait4path /nix/store && exec -a meridian ${pkgs.meridian}/bin/meridian"
        ];
        EnvironmentVariables = {
          CLAUDE_PROXY_PORT = toString meridianPort;
          CLAUDE_PROXY_PASSTHROUGH = "1";
          HOME = "/Users/thasso";
          USER = "thasso";
          PATH = "${pkgs.claude-code}/bin:${pkgs.nodejs_22}/bin:/usr/bin";
        };
        KeepAlive = true;
        RunAtLoad = true;
        StandardOutPath = "/tmp/meridian.log";
        StandardErrorPath = "/tmp/meridian.err";
      };
    };
    "bin/oc".source = ../../bin/oc;
  };
}

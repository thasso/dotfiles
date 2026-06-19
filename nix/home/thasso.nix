{ config, lib, pkgs, ... }:
let
  androidSdk = pkgs.androidenv.composeAndroidPackages {
    platformToolsVersion = "36.0.2"; # 37.0.0 has a broken hash in nixpkgs
    platformVersions = [ "35" ];
    buildToolsVersions = [ "35.0.0" ];
    cmakeVersions = [ "3.22.1" ];
    includeNDK = true;
    ndkVersions = [ "28.2.13676358" ];
    includeEmulator = false;
    includeSources = false;
  };
in
{
  imports = [ ./base.nix ];

  # ── Dev Environment ──────────────────────────────────────────
  home.sessionVariables = {
    ANDROID_HOME = "${androidSdk.androidsdk}/libexec/android-sdk";
  } // lib.optionalAttrs (!pkgs.stdenv.isDarwin) {
    CC = "clang";
    CXX = "clang++";
  } // lib.optionalAttrs pkgs.stdenv.isDarwin {
    SSH_AUTH_SOCK = "$HOME/Library/Group Containers/2BUA8C4S2C.com.1password/t/agent.sock";
    SOPS_AGE_KEY_CMD = "op read 'op://Private/sops-age-key/private_key'";
  };

  # ── Claude Code ────────────────────────────────────────────
  programs.claude-code = {
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
      enabledPlugins = {
        "rust-analyzer-lsp@claude-plugins-official" = true;
      };
      skipDangerousModePermissionPrompt = true;
      voiceEnabled = true;
      statusLine = {
        type = "command";
        command = "bash ~/.claude/statusline-command.sh";
      };
    };
    agentsDir = ../../claude/agent;
    commandsDir = ../../claude/command;
  };

  home.file.".claude/statusline-command.sh".source = ../../claude/statusline-command.sh;

  # ── Ghostty shell integration (skip in tmux — breaks p10k multiline prompt)
  programs.zsh.initContent = lib.mkIf pkgs.stdenv.isDarwin ''
    if [[ -n $GHOSTTY_RESOURCES_DIR && -z $TMUX ]]; then
      source "$GHOSTTY_RESOURCES_DIR"/shell-integration/zsh/ghostty-integration
    fi
  '';

  # ── Ghostty (macOS only) ──────────────────────────────────
  programs.ghostty = lib.mkIf pkgs.stdenv.isDarwin {
    enable = true;
    package = pkgs.ghostty-bin;
    enableZshIntegration = false;
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
    tui = {
      theme = "catppuccin";
    };
    settings = {
      autoupdate = true;
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

  # ── Dev Packages ────────────────────────────────────────────
  home.packages = lib.optionals pkgs.stdenv.isDarwin [
    pkgs.google-chrome
    pkgs.raycast
    pkgs.lima
  ] ++ (with pkgs; [
    python314
    uv
    jdk21
    android-tools
    androidSdk.androidsdk
    tempomat
    awscli2
    claude-code
    sops
    ssh-to-age

    rustup
    clang-tools
    tree-sitter
  ] ++ lib.optionals (!pkgs.stdenv.isDarwin) [
    clang
  ] ++ [
    cmake
    go
    golangci-lint
    gogcli
    nodejs
    yarn
    pnpm
    prettier
    prettierd
    presenterm
    codex
    pi-coding-agent
    ffmpeg
    shaka-packager
    bento4
    gpac
  ]);

  # ── Dev Dotfiles ────────────────────────────────────────────
  home.file = {
    "bin/oc".source = ../../bin/oc;

    ".agents/skills" = {
      source = ../../agents/skills;
      recursive = true;
    };

    ".claude/skills" = {
      source = ../../agents/skills;
      recursive = true;
    };
  };
}

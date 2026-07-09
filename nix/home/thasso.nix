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
  herdrClaudeHook = pkgs.writeTextFile {
    name = "herdr-agent-state.sh";
    text = builtins.readFile "${pkgs.herdr.src}/src/integration/assets/claude/herdr-agent-state.sh";
    executable = true;
  };
in
{
  imports = [ ./base.nix ./ssh.nix ];

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
      # Claude's shell snapshot captures zoxide's functions but not the
      # imperative `chpwd_functions+=(__zoxide_hook)` registration, so the
      # zoxide "doctor" false-positives on every prepended `cd`. Silence it
      # only inside Claude's shell; the interactive doctor stays enabled.
      env = {
        _ZO_DOCTOR = "0";
      };
      skipDangerousModePermissionPrompt = true;
      voiceEnabled = true;
      statusLine = {
        type = "command";
        command = "bash ~/.claude/statusline-command.sh";
      };
      hooks = {
        SessionStart = [{
          matcher = "*";
          hooks = [{
            type = "command";
            command = "bash '${config.home.homeDirectory}/.claude/hooks/herdr-agent-state.sh' session";
            timeout = 10;
          }];
        }];
      };
    };
    agentsDir = ../../claude/agent;
    commandsDir = ../../claude/command;
  };

  home.file.".claude/statusline-command.sh".source = ../../claude/statusline-command.sh;
  home.file.".claude/hooks/herdr-agent-state.sh" = {
    source = herdrClaudeHook;
    force = true;
  };
  home.file.".pi/agent/extensions/herdr-agent-state.ts" = {
    text = builtins.readFile "${pkgs.herdr.src}/src/integration/assets/pi/herdr-agent-state.ts";
    force = true;
  };

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
        "cmd+shift+up=text:\\x02u"
        "cmd+shift+down=text:\\x02d"
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

  # ── Herdr ──────────────────────────────────────────────────
  xdg.configFile."herdr/config.toml".text = ''
    # Nix manages this file, so skip Herdr's first-run config writer/dialog.
    onboarding = false

    [theme]
    name = "catppuccin"

    [terminal]
    new_cwd = "follow"

    [ui]
    # Match tmux: Cmd-T creates a tab immediately instead of prompting.
    prompt_new_tab_name = false

    [keys]
    prefix = "ctrl+b"

    # Ghostty sends tmux-style Ctrl-B sequences for these macOS shortcuts.
    # Keep Herdr listening on the same post-prefix keys so the same shortcuts
    # work in either multiplexer.
    settings = ""
    new_tab = [ "prefix+t", "prefix+c" ]
    previous_tab = "prefix+p"
    next_tab = "prefix+n"
    close_tab = [ "prefix+ampersand", "prefix+shift+x" ]
    rename_tab = [ "prefix+comma", "prefix+shift+t" ]

    # Tmux sessions map most closely to Herdr workspaces.
    new_workspace = [ "prefix+shift+c", "prefix+shift+n" ]
    workspace_picker = [ "prefix+s", "prefix+w" ]
    rename_workspace = "prefix+$"
    previous_workspace = "prefix+u"
    next_workspace = "prefix+d"

    # In navigate mode (prefix+s), Shift-Up/Shift-Down jump between agents.
    previous_agent = "prefix+shift+up"
    next_agent = "prefix+shift+down"

    # Cmd-D: side-by-side split; Cmd-Shift-D: top/bottom split.
    split_vertical = [ "prefix+percent", "prefix+v" ]
    split_horizontal = [ "prefix+double_quote", "prefix+minus" ]

    # Cmd-Alt-arrows already arrive as prefix+h/j/k/l via Ghostty and match
    # Herdr defaults. Cmd-Ctrl-arrows arrive as prefix+Alt+h/j/k/l; use API
    # commands to emulate tmux's repeatable resize bindings.

    [[keys.command]]
    key = "prefix+alt+h"
    type = "shell"
    command = "herdr pane resize --direction left --amount 0.05 --current"
    description = "Resize pane left"

    [[keys.command]]
    key = "prefix+alt+j"
    type = "shell"
    command = "herdr pane resize --direction down --amount 0.05 --current"
    description = "Resize pane down"

    [[keys.command]]
    key = "prefix+alt+k"
    type = "shell"
    command = "herdr pane resize --direction up --amount 0.05 --current"
    description = "Resize pane up"

    [[keys.command]]
    key = "prefix+alt+l"
    type = "shell"
    command = "herdr pane resize --direction right --amount 0.05 --current"
    description = "Resize pane right"
  '';

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
    google-chrome
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
    herdr
    ffmpeg
    shaka-packager
    bento4
    gpac
    python3Packages.weasyprint
    worktrunk
  ]);

  # ── Dev Dotfiles ────────────────────────────────────────────
  home.file = {
    "bin/oc".source = ../../bin/oc;
    "bin/cca".source = ../../bin/cca;

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

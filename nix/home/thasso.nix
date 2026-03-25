{ config, lib, pkgs, ... }:
let
  dotfilesPath = "${config.home.homeDirectory}/${if pkgs.stdenv.isDarwin then "git/dotfiles" else "dotfiles"}";
in
{
  home.stateVersion = "25.11";

  # ── Environment ──────────────────────────────────────────────
  home.sessionPath = [ "$HOME/bin" ];
  home.sessionVariables = {
    EDITOR = "nvim";
    VISUAL = "nvim";
    LANG = "en_US.UTF-8";
  } // lib.optionalAttrs pkgs.stdenv.isDarwin {
    SSH_AUTH_SOCK = "$HOME/Library/Group Containers/2BUA8C4S2C.com.1password/t/agent.sock";
  };

  # ── Zsh ──────────────────────────────────────────────────────
  programs.zsh = {
    enable = true;
    autosuggestion.enable = true;
    syntaxHighlighting.enable = true;
    enableCompletion = true;

    history = {
      size = 10000;
      save = 10000;
      ignoreDups = true;
      share = true;
      expireDuplicatesFirst = true;
    };

    completionInit = ''
      autoload -Uz compinit && compinit
      zstyle ':completion:*' menu select
    '';

    shellAliases = {
      # Git
      gs  = "git status";
      gst = "git status";
      gc  = "git commit";
      gco = "git checkout";
      gcm = "git cm";
      gp  = "git push";
      lg  = "lazygit";

      # Tool replacements
      cat = "bat";
      ls  = "eza --icons=always";
      ll  = "eza -l --no-user --no-time --no-permissions --icons=always";
    };

    initContent = ''
      # Powerlevel10k instant prompt (must be at top)
      if [[ -r "''${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-''${(%):-%n}.zsh" ]]; then
        source "''${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-''${(%):-%n}.zsh"
      fi

      source ${pkgs.zsh-powerlevel10k}/share/zsh-powerlevel10k/powerlevel10k.zsh-theme
      [[ -f ~/.p10k.zsh ]] && source ~/.p10k.zsh

      # Source secrets if present
      [[ -f ~/.zsecrets ]] && source ~/.zsecrets
    '';
  };

  # ── Fzf ──────────────────────────────────────────────────────
  programs.fzf = {
    enable = true;
    enableZshIntegration = true;
    defaultCommand = "fd --hidden --strip-cwd-prefix --exclude .git";
    changeDirWidgetCommand = "fd --type=d --hidden --strip-cwd-prefix --exclude .git";
    changeDirWidgetOptions = [ "--preview 'eza --tree --color=always {} | head -200'" ];
    fileWidgetCommand = "fd --hidden --strip-cwd-prefix --exclude .git";
    fileWidgetOptions = [ "--preview 'bat -n --color=always --line-range :500 {}'" ];
  };

  # ── Zoxide (better cd) ──────────────────────────────────────
  programs.zoxide = {
    enable = true;
    enableZshIntegration = true;
    options = [ "--cmd" "cd" ];
  };

  # ── Eza (better ls) ─────────────────────────────────────────
  programs.eza = {
    enable = true;
    icons = "auto";
    extraOptions = [ "--icons=always" ];
  };

  # ── Bat (better cat) ────────────────────────────────────────
  programs.bat = {
    enable = true;
    config.theme = "Dracula";
  };

  # ── Atuin (shell history) ───────────────────────────────────
  programs.atuin = {
    enable = true;
    enableZshIntegration = true;
    flags = [ "--disable-up-arrow" ];
    settings = {
      filter_mode = "global";
      filter_mode_shell_up_key_binding = "directory";
      enter_accept = true;
      sync.records = true;
    };
  };

  # ── Fd (used by fzf) ───────────────────────────────────────
  programs.fd.enable = true;

  # ── Delta (git pager) ───────────────────────────────────────
  programs.delta = {
    enable = true;
    enableGitIntegration = true;
    options = {
      navigate = true;
      side-by-side = true;
    };
  };

  # ── Git ─────────────────────────────────────────────────────
  programs.git = {
    enable = true;

    lfs.enable = true;

    signing = {
      key = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIG+CLIkUMfm+8w4AFuVES+o9z124opVlyRfTbwUxwiUV";
      signByDefault = true;
      format = "ssh";
    };

    ignores = [
      ".DS_Store"
      "*.swp"
      "*.swo"
      "*~"
    ];

    settings = {
      user = {
        name = "Thasso Griebel";
        email = "thasso.griebel@gmail.com";
      };

      alias = {
        dt = "difftool";
        subup = "submodule update --init --recursive";
        tags = ''!sh -c "git for-each-ref --format='%(color:green)%(refname:short)|%(color:white)[%(taggerdate:relative)]|%(color:blue)%(objectname:short)|%(color:yellow)%(contents:subject)|%(color:white)Tagged by %(taggername)' --sort='-taggerdate' --count=10 refs/tags | awk -F'|' '{printf \"%-12s %-20s %s %-35s %s\\n\", \$1, \$2, \$3, \$5, \$4}'"'';
        branches = "branch -a";
        remotes = "remote -v";

        # Shorten common commands
        co = "checkout";
        st = "status";
        br = "branch";
        ci = "commit";
        d = "diff";

        # Show outgoing commits
        out = "log @{u}..";

        # Current branch name
        currentbranch = "!git branch --contains HEAD | grep '*' | tr -s ' ' | cut -d ' ' -f2";

        # Better diffs for prose
        wdiff = "diff --color-words";

        # Amend last commit without modifying commit message
        amend = ''!git log -n 1 --pretty=tformat:%s%n%n%b | git commit -F - --amend'';

        # Fixup commit for autosquash
        fixup = "commit --fixup=HEAD";
      };

      push.default = "simple";
      branch.autosetuprebase = "always";
      merge.conflictstyle = "diff3";
      diff.colorMoved = "default";
      core = {
        autocrlf = "input";
        editor = "nvim";
      };
      init.defaultBranch = "main";
      pull.rebase = true;
      tag.gpgsign = true;
    } // lib.optionalAttrs pkgs.stdenv.isDarwin {
      gpg.ssh.program = "/Applications/1Password.app/Contents/MacOS/op-ssh-sign";
    };
  };

  # ── Tmux ────────────────────────────────────────────────────
  programs.tmux = {
    enable = true;
    mouse = true;
    terminal = "tmux-256color";
    escapeTime = 0;
    historyLimit = 30000;
    baseIndex = 1;
    keyMode = "vi";
    focusEvents = true;

    plugins = with pkgs.tmuxPlugins; [
      {
        plugin = catppuccin;
        extraConfig = ''
          set -g @catppuccin_flavor "mocha"
          set -g @catppuccin_window_status_style "rounded"
          set -g @catppuccin_window_text " #W"
          set -g @catppuccin_window_current_text " #W"
        '';
      }
    ];

    extraConfig = ''
      # Window and pane behavior
      set-option -g allow-rename off
      set-option -g automatic-rename off
      set -g display-panes-time 3000
      set -g bell-action none
      set -g visual-bell on

      # Splits preserving current path
      bind '"' split-window -c "#{pane_current_path}"
      bind % split-window -h -c "#{pane_current_path}"

      # New window/session preserving current path
      bind c new-window -c "#{pane_current_path}"
      bind C new-session -c "#{pane_current_path}"

      # Copy mode
      bind-key Escape copy-mode
      bind-key -T copy-mode-vi 'v' send -X begin-selection

      # Pane navigation (prefix + h/j/k/l)
      bind h select-pane -L
      bind j select-pane -D
      bind k select-pane -U
      bind l select-pane -R

      # Swap pane (prefix + W)
      bind W display-panes "swap-pane -t '%%'"

      # Pane resize (prefix + M-h/j/k/l)
      bind -r M-h resize-pane -L 2
      bind -r M-j resize-pane -D 2
      bind -r M-k resize-pane -U 2
      bind -r M-l resize-pane -R 2

      # Window navigation
      bind t new-window -c "#{pane_current_path}"
      bind C-f command-prompt -p find-session 'switch-client -t %%'

      # Status bar
      set -g status-position top
      set -g status-justify left
      set -g status-right-length 100
      set -g status-left-length 100
      set -g status-left ""
      set -g status-right "#{E:@catppuccin_status_session}"
    '';
  };

  # ── Ghostty (macOS only) ──────────────────────────────────
  programs.ghostty = lib.mkIf pkgs.stdenv.isDarwin {
    enable = true;
    package = pkgs.ghostty-bin; # ghostty is Linux-only; ghostty-bin supports macOS
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
      ];
    };
  };

  # ── VS Code (macOS only) ───────────────────────────────────
  programs.vscode = lib.mkIf pkgs.stdenv.isDarwin {
    enable = true;
  };

  # ── Google Chrome (macOS only) ─────────────────────────────
  home.packages = lib.optionals pkgs.stdenv.isDarwin [
    pkgs.google-chrome
    pkgs.raycast
    pkgs.lima
  ] ++

  # ── Extra packages ──────────────────────────────────────────
  (with pkgs; [
    zsh-powerlevel10k
    lazygit
    neovim
    ripgrep
    python314
    pyenv
    jq
    gh
    jira-cli-go
    awscli2
    claude-code
    gnumake
    tig
    rustup
    go
    nodejs
    yarn
  ]);

  # ── OpenCode ────────────────────────────────────────────────
  programs.opencode = {
    enable = true;
    settings = {
      theme = "catppuccin";
      autoupdate = true;
      provider = {};
      permission = {
        external_directory = { "~/.cargo/registry/**" = "allow"; };
        edit = { "~/.cargo/registry/**" = "deny"; };
        bash = {
          "git push" = "ask";
          "git merge *" = "ask";
        };
      };
    };
    agents = ../../opencode/agent;
    commands = ../../opencode/command;
  };

  # ── Dotfiles ────────────────────────────────────────────────
  home.file = {
    ".p10k.zsh".source = ./zsh/p10k.zsh;
    ".config/nvim".source = config.lib.file.mkOutOfStoreSymlink "${dotfilesPath}/nvim";
    "bin/git-cm".source = ../../bin/git-cm;
    "bin/oc".source = ../../bin/oc;
  };
}

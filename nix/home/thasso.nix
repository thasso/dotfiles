{ config, pkgs, ... }:
{
  home.stateVersion = "25.11";

  # ── Environment ──────────────────────────────────────────────
  home.sessionVariables = {
    EDITOR = "nvim";
    VISUAL = "nvim";
    LANG = "en_US.UTF-8";
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

  # ── Git ─────────────────────────────────────────────────────
  programs.git.enable = true;

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

  # ── Extra packages ──────────────────────────────────────────
  home.packages = with pkgs; [
    zsh-powerlevel10k
    lazygit
    neovim
    ripgrep
    python314
    pyenv
    jq
    gh
    jira-cli-go
  ];

  # ── Dotfiles ────────────────────────────────────────────────
  home.file = {
    ".p10k.zsh".source = ./zsh/p10k.zsh;
  };
}

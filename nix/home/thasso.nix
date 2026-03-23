{ config, pkgs, ... }:

let
 dotfiles = "${config.home.homeDirectory}/dotfiles";
in

{
  home.stateVersion = "25.11";

  programs.zsh = {
    enable = true;
    initContent = ''
      source ${pkgs.zsh-powerlevel10k}/share/zsh-powerlevel10k/powerlevel10k.zsh-theme
      ${builtins.readFile ./zsh/init.zsh}
    '';
  };

  programs.tmux = {
    enable = true;
    mouse = true;
    terminal = "tmux-256color";
    escapeTime = 0;
    historyLimit = 30000;
    baseIndex = 1;
    keyMode = "vi";

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

  home.packages = with pkgs; [
    zsh-powerlevel10k
  ];

  # Symlink config files from dotfiles repo
  home.file = {
   ".p10k.zsh".source = ./zsh/p10k.zsh;
  };

}

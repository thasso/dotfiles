# Nice things to have for interactive shells

# Enable Powerlevel10k instant prompt. Should stay close to the top of ~/.zshrc.
# Initialization code that may require console input (password prompts, [y/n]
# confirmations, etc.) must go above this block; everything else may go below.
if [[ -r "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh" ]]; then
  source "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh"
fi

if [[ -d "${HOMEBREW_PREFIX}" ]]; then
  source $HOMEBREW_PREFIX/share/powerlevel10k/powerlevel10k.zsh-theme
else
  source ~/opt/powerlevel10k/powerlevel10k.zsh-theme
fi

# To customize prompt, run `p10k configure` or edit ~/.p10k.zsh.
[[ ! -f ~/.p10k.zsh ]] || source ~/.p10k.zsh

# history setup
HISTFILE=$HOME/.zhistory
SAVEHIST=10000
HISTSIZE=9999
setopt share_history
setopt hist_expire_dups_first
setopt hist_ignore_dups
setopt hist_verify

# Load auto suggestions plugin
source $HOMEBREW_PREFIX/share/zsh-autosuggestions/zsh-autosuggestions.zsh

# Load syntax highlighting
source $HOMEBREW_PREFIX/share/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh

# completion menu for zsh
autoload -U compinit; compinit
zstyle ':completion:*' menu select
#zstyle ':*' menu select


# The following things we ONLY want to do in
# interactive shells. We are not using them in scripts and
# the do confuse agents
#
# This file SHOULD already be the right place, but sometimes
# someone or something thinks its a good idea to source this file even
# in non interactive shells.
if [[ $- == *i* ]]; then
  # EZA Setup
  alias ls="eza --icons=always"
  alias ll="eza -l --no-user --no-time --no-permissions --icons=always"
 
  # Zoxide (better cd)
  eval "$(zoxide init --cmd cd zsh)"

  # FZF
  # Set up fzf key bindings and fuzzy completion
  eval "$(fzf --zsh)"
  # -- Use fd instead of fzf --
  export FZF_DEFAULT_COMMAND="fd --hidden --strip-cwd-prefix --exclude .git"
  export FZF_CTRL_T_COMMAND="$FZF_DEFAULT_COMMAND"
  export FZF_ALT_C_COMMAND="fd --type=d --hidden --strip-cwd-prefix --exclude .git"

  # Use fd (https://github.com/sharkdp/fd) for listing path candidates.
  # - The first argument to the function ($1) is the base path to start traversal
  # - See the source code (completion.{bash,zsh}) for the details.
  _fzf_compgen_path() {
    fd --hidden --exclude .git . "$1"
  }

  # Use fd to generate the list for directory completion
  _fzf_compgen_dir() {
    fd --type=d --hidden --exclude .git . "$1"
  }

  export FZF_CTRL_T_OPTS="--preview 'bat -n --color=always --line-range :500 {}'"
  export FZF_ALT_C_OPTS="--preview 'eza --tree --color=always {} | head -200'"

  # Advanced customization of fzf options via _fzf_comprun function
  # - The first argument to the function is the name of the command.
  # - You should make sure to pass the rest of the arguments to fzf.
  _fzf_comprun() {
    local command=$1
    shift

    case "$command" in
      cd)           fzf --preview 'eza --tree --color=always {} | head -200' "$@" ;;
      export|unset) fzf --preview "eval 'echo $'{}"         "$@" ;;
      ssh)          fzf --preview 'dig {}'                   "$@" ;;
      *)            fzf --preview "bat -n --color=always --line-range :500 {}" "$@" ;;
    esac
  }

  # Bat (better cat)
  export BAT_THEME=Dracula
  alias cat=bat

  # Git
  alias gst="git status"
  alias gco="git checkout"
  alias gcm="git cm"
  alias lg="lazygit"

  # Helpers
  alias sizes="du -h -d1 2>/dev/null | sort -h"

  # Setup auin
  eval "$(atuin init zsh)"
fi


export PATH="$HOME/.local/bin:$PATH"

# init apm
eval "$(apm init zsh)"

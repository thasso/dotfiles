# ---- Powerlevel10k instant prompt (keep at very top) ----
if [[ -r "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh" ]]; then
  source "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh"
fi

# ---- Load your p10k config if present ----
[[ -f ~/.p10k.zsh ]] && source ~/.p10k.zsh

# ---- Basic shell setup ----
export EDITOR=nvim
export VISUAL=nvim

# History
HISTSIZE=10000
SAVEHIST=10000
HISTFILE=~/.zsh_history

setopt HIST_IGNORE_DUPS
setopt SHARE_HISTORY

# ---- Aliases ----
alias ll="ls -la"
alias gs="git status"
alias gc="git commit"
alias gp="git push"

# ---- Completion ----
autoload -Uz compinit
compinit

# ---- Prompt fallback (in case p10k fails) ----
#PROMPT='%n@%m:%~ %# '

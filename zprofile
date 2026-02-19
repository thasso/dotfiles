# macOS Homebrew
if [[ -x $HOMEBREW_PREFIX/bin/brew ]]; then
  eval "$(${HOMEBREW_PREFIX}/bin/brew shellenv)"
fi

# Source shared PATH logic
if [[ -f $HOME/.zpath ]]; then
  source $HOME/.zpath
fi

# Pyenv
if command -v pyenv >/dev/null 2>&1; then
  export PYENV_ROOT="$HOME/.pyenv"
  [[ -d $PYENV_ROOT/bin ]] && export PATH="$PYENV_ROOT/bin:$PATH"
  eval "$(pyenv init - zsh)"
  eval "$(pyenv virtualenv-init -)"
else
  echo "pyenv not installed. skipping"
fi

# Extend the path for things we want we a login shell
# most of the basic are aleady sourced from .zpath
# ensure no duplicates when we manipulate $path (zsh array form)
typeset -U path PATH
path=(
  $HOME/Library/Application\ Support/JetBrains/Toolbox/scripts
  $path
)
export PATH

# Source shared tokens and secrets
if [[ -f $HOME/.zsecrets ]]; then
  source $HOME/.zsecrets
fi


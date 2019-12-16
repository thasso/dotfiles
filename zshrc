# Homebrew path
export PATH=$HOME/bin:$HOME/usr/bin:/usr/local/bin:$PATH
# Path to your oh-my-zsh installation.
export ZSH=$HOME/.oh-my-zsh
#ZSH_THEME="sorin"
#ZSH_THEME="avit"
ZSH_THEME="sorin"
DISABLE_AUTO_UPDATE="true"
DISABLE_AUTO_TITLE="true"
ZSH_CUSTOM=$HOME/.zshext
plugins=(gitfast virtualenv adb themes gradle)
source $ZSH/oh-my-zsh.sh

# language and base shell
export LC_ALL=en_US.UTF-8
export LANG=en_US.UTF-8

# aliases
alias tmux="env TERM=screen-256color tmux -2"
alias lg="lazygit"
function github () {
    open `git remote get-url origin | sed -e 's/git@//; s/:/\//; s/\.git$//; s/^/https:\/\//'`
}

# Android setup
export NDK_CCACHE=/usr/local/bin/ccache
export NDK_HOME=$HOME/usr/android/ndk
export ANDROID_HOME=$HOME/usr/android/sdk
export PATH=$NDK_HOME:$ANDROID_HOME/tools:$ANDROID_HOME/platform-tools:$PATH
# ccache
export CACHE_BASEDIR=$HOME/

# Node setup
export NODE_PATH="/usr/local/lib/node:/usr/local/lib/node_modules"
export PATH="/usr/local/share/npm/bin:$PATH"

# more paths
export PATH=/usr/local/lib/ruby/gems/2.2.0/bin:$PATH
export MANPATH="/usr/local/man:$MANPATH"

# vim and editor
alias vim=nvim
export EDITOR=nvim
export NVIM_TUI_ENABLE_TRUE_COLOR=1

#Pyenv setup
# export PATH=/usr/local/opt/python/libexec/bin:$PATH
eval "$(pyenv init -)"
eval "$(pyenv virtualenv-init -)"

export JAVA_HOME=/Library/Java/JavaVirtualMachines/jdk1.8.0_192.jdk/Contents/Home

# fzf setup
[ -f ~/.fzf.zsh ] && source ~/.fzf.zsh
